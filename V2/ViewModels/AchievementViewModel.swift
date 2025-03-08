import Foundation
import Supabase

@MainActor
class AchievementViewModel: ObservableObject {
    @Published var userAchievements: [Achievement] = []
    @Published var allAchievements: [Achievement] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    private let supabase = SupabaseService.shared
    
    // Achievement definitions that the system can award
    private let achievementDefinitions: [AchievementType: (title: String, description: String, icon: String)] = [
        .meetCreated: (
            title: "Meet Organizer",
            description: "Created your first car meet",
            icon: "calendar.badge.plus"
        ),
        .meetJoined: (
            title: "Joiner",
            description: "Joined your first car meet",
            icon: "person.2.fill"
        ),
        .meetCompleted: (
            title: "Meet Completer",
            description: "Completed your first car meet",
            icon: "checkmark.circle.fill"
        ),
        .routeCreated: (
            title: "Route Master",
            description: "Created your first driving route",
            icon: "map.fill"
        ),
        .routeShared: (
            title: "Route Sharer",
            description: "Shared your first driving route",
            icon: "square.and.arrow.up.fill"
        ),
        .friendAdded: (
            title: "Friendly",
            description: "Added your first friend",
            icon: "person.badge.plus.fill"
        ),
        .profileComplete: (
            title: "Identity Established",
            description: "Completed your profile with all information",
            icon: "person.fill.checkmark"
        ),
        .firstMeet: (
            title: "First Step",
            description: "Attended your first car meet",
            icon: "1.circle.fill"
        ),
        .meetStreak: (
            title: "Committed",
            description: "Attended meets 3 weeks in a row",
            icon: "flame.fill"
        ),
        .socialButterfly: (
            title: "Social Butterfly",
            description: "Added 5 friends to your network",
            icon: "person.3.fill"
        ),
        .attendFiveMeets: (
            title: "Car Enthusiast",
            description: "Attended 5 different car meets",
            icon: "5.circle.fill"
        )
    ]
    
    // Load user achievements from the database
    func loadUserAchievements(userId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let achievementsData = try await supabase.client
                .from("achievements")
                .select()
                .eq("user_id", value: userId)
                .order("earned_at", ascending: false)
                .execute()
            
            let achievements: [Achievement] = {
                guard let jsonObject = try? JSONSerialization.jsonObject(with: achievementsData.data),
                      let achievementsArray = jsonObject as? [[String: Any]] else { return [] }
                
                return achievementsArray.compactMap { dict -> Achievement? in
                    guard let id = dict["id"] as? String,
                          let typeStr = dict["type"] as? String,
                          let achievementType = AchievementType(rawValue: typeStr),
                          let title = dict["title"] as? String,
                          let description = dict["description"] as? String,
                          let icon = dict["icon"] as? String,
                          let earnedAtStr = dict["earned_at"] as? String,
                          let earnedAt = ISO8601DateFormatter().date(from: earnedAtStr) else {
                        return nil
                    }
                    
                    return Achievement(
                        id: id,
                        type: achievementType,
                        title: title,
                        description: description,
                        icon: icon,
                        earnedAt: earnedAt
                    )
                }
            }()
            
            DispatchQueue.main.async {
                self.userAchievements = achievements
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to load achievements: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // Award a new achievement to a user
    func awardAchievement(userId: String, type: AchievementType) async -> Bool {
        guard let achievementInfo = achievementDefinitions[type] else {
            errorMessage = "Achievement type not found"
            return false
        }
        
        // Create achievement in the database
        do {
            // Create achievement using AnyJSON for proper encoding
            let newAchievement: [String: AnyJSON] = [
                "user_id": try AnyJSON(userId),
                "type": try AnyJSON(type.rawValue),
                "title": try AnyJSON(achievementInfo.title),
                "description": try AnyJSON(achievementInfo.description),
                "icon": try AnyJSON(achievementInfo.icon)
            ]
            
            let _ = try await supabase.client
                .from("achievements")
                .insert(newAchievement)
                .execute()
                
            // Create an activity for the achievement
            let activityData: [String: AnyJSON] = [
                "user_id": try AnyJSON(userId),
                "type": try AnyJSON(ActivityType.achievementEarned.rawValue),
                "title": try AnyJSON("Achievement Earned: \(achievementInfo.title)"),
                "description": try AnyJSON(achievementInfo.description)
            ]
            
            _ = try await supabase.client
                .from("user_activities")
                .insert(activityData)
                .execute()
                
            // Add the achievement to the user's achievements array
            let userResponse = try await supabase.client
                .from("users")
                .select("achievements")
                .eq("id", value: userId)
                .single()
                .execute()
                
            guard let userData = try? JSONSerialization.jsonObject(with: userResponse.data) as? [String: Any],
                  var achievementsArray = userData["achievements"] as? [[String: Any]] else {
                await loadUserAchievements(userId: userId)
                return true
            }
                
            // Create new achievement JSON data
            let newAchievementJson: [String: Any] = [
                "id": UUID().uuidString,
                "type": type.rawValue,
                "title": achievementInfo.title,
                "description": achievementInfo.description,
                "icon": achievementInfo.icon,
                "earned_at": ISO8601DateFormatter().string(from: Date())
            ]
            
            achievementsArray.append(newAchievementJson)
            
            // Convert to JSON string and then to AnyJSON
            let jsonData = try JSONSerialization.data(withJSONObject: achievementsArray)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? "[]"
            let achievementsJSON = try AnyJSON(jsonString)
            
            // Update the user with the new achievements array
            let updateData: [String: AnyJSON] = ["achievements": achievementsJSON]
            _ = try await supabase.client
                .from("users")
                .update(updateData)
                .eq("id", value: userId)
                .execute()
            
            // Reload achievements
            await loadUserAchievements(userId: userId)
            return true
        } catch {
            errorMessage = "Failed to award achievement: \(error.localizedDescription)"
            return false
        }
    }
    
    // Check for possible achievements based on user activity
    func checkForAchievements(userId: String) async {
        do {
            // Check for profile completeness
            try await checkProfileComplete(userId: userId)
            
            // Check for meeting attendance achievements
            try await checkMeetAttendance(userId: userId)
            
            // Check for social achievements
            try await checkSocialAchievements(userId: userId)
            
            // Reload achievements
            await loadUserAchievements(userId: userId)
        } catch {
            errorMessage = "Failed to check for achievements: \(error.localizedDescription)"
        }
    }
    
    // Check profile completeness
    private func checkProfileComplete(userId: String) async throws {
        let response = try await supabase.client
            .from("users")
            .select("profile")
            .eq("id", value: userId)
            .single()
            .execute()
            
        guard let userData = try? JSONSerialization.jsonObject(with: response.data) as? [String: Any],
              let profileData = userData["profile"] as? [String: Any] else {
            return
        }
        
        // Check if profile has all required fields
        let hasName = profileData["name"] as? String != nil && (profileData["name"] as? String)?.isEmpty == false
        let hasBio = profileData["bio"] as? String != nil && (profileData["bio"] as? String)?.isEmpty == false
        let hasAvatar = profileData["avatar"] as? String != nil && (profileData["avatar"] as? String)?.isEmpty == false
        let hasLocation = (profileData["location"] as? [String: Any])?["address"] as? String != nil
        
        if hasName && hasBio && hasAvatar && hasLocation {
            _ = await awardAchievement(userId: userId, type: .profileComplete)
        }
    }
    
    // Check meet attendance
    private func checkMeetAttendance(userId: String) async throws {
        // Check for meets attended
        let attendeeResponse = try await supabase.client
            .from("meet_attendees")
            .select("meet_id")
            .eq("user_id", value: userId)
            .execute()
            
        guard let attendeeData = try? JSONSerialization.jsonObject(with: attendeeResponse.data) as? [[String: Any]] else {
            return
        }
        
        // Award firstMeet achievement if user has attended at least one meet
        if !attendeeData.isEmpty {
            _ = await awardAchievement(userId: userId, type: .firstMeet)
        }
        
        // Award attendFiveMeets achievement if user has attended at least 5 meets
        if attendeeData.count >= 5 {
            _ = await awardAchievement(userId: userId, type: .attendFiveMeets)
        }
        
        // Check for meet streak - 3 meets in a month
        let now = Date()
        let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: now) ?? now
        
        let meetIds = attendeeData.compactMap { $0["meet_id"] as? String }
        
        if !meetIds.isEmpty {
            // Get meets with their dates
            let meetResponse = try await supabase.client
                .from("meets")
                .select("id, start_date")
                .in("id", values: meetIds)
                .execute()
                
            guard let meetData = try? JSONSerialization.jsonObject(with: meetResponse.data) as? [[String: Any]] else {
                return
            }
            
            // Count meets in the last month
            var recentMeetsCount = 0
            for meet in meetData {
                if let startDateStr = meet["start_date"] as? String,
                   let startDate = ISO8601DateFormatter().date(from: startDateStr),
                   startDate >= oneMonthAgo {
                    recentMeetsCount += 1
                }
            }
            
            // Award meetStreak achievement if user attended at least 3 meets in the last month
            if recentMeetsCount >= 3 {
                _ = await awardAchievement(userId: userId, type: .meetStreak)
            }
        }
    }
    
    // Check social achievements
    private func checkSocialAchievements(userId: String) async throws {
        // Check friends count for socialButterfly achievement
        let userResponse = try await supabase.client
            .from("users")
            .select("friends")
            .eq("id", value: userId)
            .single()
            .execute()
            
        guard let userData = try? JSONSerialization.jsonObject(with: userResponse.data) as? [String: Any],
              let friends = userData["friends"] as? [String] else {
            return
        }
        
        // Award friendAdded achievement if user has at least one friend
        if !friends.isEmpty {
            _ = await awardAchievement(userId: userId, type: .friendAdded)
        }
        
        // Award socialButterfly achievement if user has at least 5 friends
        if friends.count >= 5 {
            _ = await awardAchievement(userId: userId, type: .socialButterfly)
        }
    }
    
    // Track specific activities that might earn achievements
    func trackActivity(userId: String, type: ActivityType, relatedId: String? = nil) async {
        // Map activity types to achievement types
        let achievementMapping: [ActivityType: AchievementType] = [
            .meetCreated: .meetCreated,
            .meetJoined: .meetJoined,
            .meetCompleted: .meetCompleted,
            .routeCreated: .routeCreated,
            .routeShared: .routeShared
        ]
        
        // If the activity maps to an achievement, award it
        if let achievementType = achievementMapping[type] {
            _ = await awardAchievement(userId: userId, type: achievementType)
        }
        
        // After any activity, check if any new achievements have been earned
        await checkForAchievements(userId: userId)
    }
} 
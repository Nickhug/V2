import Foundation
import Combine
import Supabase

// MARK: - Achievement Extension for AuthManager
extension AuthManager {
    
    // Track an activity and potentially award achievements
    func trackActivity(_ type: ActivityType, relatedId: String? = nil) {
        guard let currentUserId = currentUser?.id else { return }
        
        // Create an activity record in the database
        Task {
            do {
                // Use AnyJSON for Supabase operations
                let activityData: [String: AnyJSON] = [
                    "user_id": try AnyJSON(currentUserId),
                    "type": try AnyJSON(type.rawValue),
                    "title": try AnyJSON(getActivityTitle(for: type)),
                    "description": try AnyJSON(getActivityDescription(for: type))
                ]
                
                // Insert the activity record using SupabaseService
                try await SupabaseService.shared.client
                    .from("user_activities")
                    .insert(activityData)
                    .execute()
                
                // Use AchievementViewModel to check for and award achievements
                let achievementViewModel = AchievementViewModel()
                await achievementViewModel.trackActivity(userId: currentUserId, type: type, relatedId: relatedId)
                
                // If achievements were awarded, refresh user profile to get the updated achievements
                if !achievementViewModel.userAchievements.isEmpty {
                    try await fetchUserAndUpdateState()
                }
            } catch {
                print("Failed to track activity: \(error.localizedDescription)")
            }
        }
    }
    
    // Helper method to get a user-friendly title for an activity
    private func getActivityTitle(for activityType: ActivityType) -> String {
        switch activityType {
        case .meetCreated:
            return "Created a New Meet"
        case .meetJoined:
            return "Joined a Meet"
        case .meetCompleted:
            return "Completed a Meet"
        case .achievementEarned:
            return "Earned an Achievement"
        case .friendAdded:
            return "Added a Friend"
        case .routeCreated:
            return "Created a Route"
        case .routeShared:
            return "Shared a Route"
        case .vehicleAdded:
            return "Added a Vehicle"
        }
    }
    
    // Helper method to get a user-friendly description for an activity
    private func getActivityDescription(for activityType: ActivityType) -> String {
        switch activityType {
        case .meetCreated:
            return "You created a new car meet event"
        case .meetJoined:
            return "You joined a car meet"
        case .meetCompleted:
            return "You completed a car meet"
        case .achievementEarned:
            return "You earned a new achievement"
        case .friendAdded:
            return "You added a new friend to your network"
        case .routeCreated:
            return "You created a new driving route"
        case .routeShared:
            return "You shared a driving route with others"
        case .vehicleAdded:
            return "You added a new vehicle to your profile"
        }
    }
    
    // Sync achievements from separate table to user record
    func syncAchievements() async {
        guard let userId = currentUser?.id else { return }
        
        do {
            // Get achievements from the achievements table
            let achievementsResponse = try await SupabaseService.shared.client
                .from("achievements")
                .select()
                .eq("user_id", value: userId)
                .order("earned_at", ascending: false)
                .execute()
            
            guard let data = try? JSONSerialization.jsonObject(with: achievementsResponse.data) as? [[String: Any]] else {
                return
            }
            
            // First convert dictionary data to JSON string, then to AnyJSON
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? "[]"
            let achievementsJSON = try AnyJSON(jsonString)
            
            // Update the user record with the achievements
            let updateData: [String: AnyJSON] = ["achievements": achievementsJSON]
            _ = try await SupabaseService.shared.client
                .from("users")
                .update(updateData)
                .eq("id", value: userId)
                .execute()
            
            // Refresh the user to get the updated achievements
            try await fetchUserAndUpdateState()
            
        } catch {
            print("Failed to sync achievements: \(error.localizedDescription)")
        }
    }
    
    // Helper method to fetch user data and update state
    private func fetchUserAndUpdateState() async throws {
        guard let userId = currentUser?.id else { return }
        
        // Direct database query since we can't access userService
        let response = try await SupabaseService.shared.client
            .from("users")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        let profile: User = try decoder.decode(User.self, from: response.data)
        self.currentUser = profile
    }
} 
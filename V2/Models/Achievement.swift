import Foundation

enum AchievementType: String, Codable {
    case meetCreated = "meet_created"
    case meetJoined = "meet_joined"
    case meetCompleted = "meet_completed"
    case routeCreated = "route_created"
    case routeShared = "route_shared"
    case friendAdded = "friend_added"
    case profileComplete = "profile_complete"
    case firstMeet = "first_meet"
    case meetStreak = "meet_streak"
    case socialButterfly = "social_butterfly"
    case attendFiveMeets = "attend_five_meets"
}

struct Achievement: Identifiable, Codable, Equatable {
    let id: String
    let type: AchievementType
    let title: String
    let description: String
    let icon: String
    let earnedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case title
        case description
        case icon
        case earnedAt = "earned_at"
    }
    
    static var mockAchievements: [Achievement] = [
        Achievement(
            id: UUID().uuidString,
            type: .firstMeet,
            title: "First Step",
            description: "Attended your first car meet",
            icon: "1.circle.fill",
            earnedAt: Date().addingTimeInterval(-86400 * 7)
        ),
        Achievement(
            id: UUID().uuidString,
            type: .attendFiveMeets,
            title: "Car Enthusiast",
            description: "Attended 5 different car meets",
            icon: "5.circle.fill",
            earnedAt: Date().addingTimeInterval(-86400 * 3)
        ),
        Achievement(
            id: UUID().uuidString,
            type: .profileComplete,
            title: "Profile Master",
            description: "Completed your profile with all information",
            icon: "person.fill.checkmark",
            earnedAt: Date().addingTimeInterval(-86400 * 1)
        )
    ]
} 
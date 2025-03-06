import Foundation

enum ActivityType: String, Codable {
    case meetCreated = "meet_created"
    case meetJoined = "meet_joined"
    case meetCompleted = "meet_completed"
    case achievementEarned = "achievement_earned"
    case friendAdded = "friend_added"
    case routeCreated = "route_created"
    case routeShared = "route_shared"
    case vehicleAdded = "vehicle_added"
    
    var icon: String {
        switch self {
        case .meetCreated:
            return "calendar.badge.plus"
        case .meetJoined:
            return "person.2.fill"
        case .meetCompleted:
            return "checkmark.circle.fill"
        case .routeCreated:
            return "map.fill"
        case .routeShared:
            return "square.and.arrow.up.fill"
        case .achievementEarned:
            return "trophy.fill"
        case .vehicleAdded:
            return "car.fill"
        case .friendAdded:
            return "person.badge.plus.fill"
        }
    }
}

struct Activity: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    let type: ActivityType
    let title: String
    let description: String
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case type
        case title
        case description
        case timestamp
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
} 
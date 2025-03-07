import Foundation

enum NotificationType: String, Codable, CaseIterable {
    case meetInvite = "meet_invite"
    case meetJoin = "meet_join"
    case meetStarting = "meet_starting"
    case friendRequest = "friend_request"
    case routeShared = "route_shared"
    case systemMessage = "system_message"
    
    var description: String {
        switch self {
        case .meetInvite:
            return "Meet Invitation"
        case .meetJoin:
            return "Meet Join"
        case .meetStarting:
            return "Meet Starting"
        case .friendRequest:
            return "Friend Request"
        case .routeShared:
            return "Route Shared"
        case .systemMessage:
            return "System Message"
        }
    }
} 
import Foundation

struct NotificationModel: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    let title: String
    let message: String
    let type: NotificationType
    let relatedId: String?
    var isRead: Bool
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case message
        case type
        case relatedId = "related_id"
        case isRead = "is_read"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    static func == (lhs: NotificationModel, rhs: NotificationModel) -> Bool {
        lhs.id == rhs.id
    }
    
    // Formatted relative time (e.g., "2 hours ago")
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    // Icon for the notification type
    var icon: String {
        switch type {
        case .meetInvite:
            return "person.2.fill"
        case .meetJoin:
            return "person.badge.plus"
        case .meetStarting:
            return "calendar.badge.clock"
        case .friendRequest:
            return "person.crop.circle.badge.plus"
        case .routeShared:
            return "map.fill"
        case .systemMessage:
            return "bell.fill"
        }
    }
    
    // Background color for the notification icon
    var iconBackground: String {
        switch type {
        case .meetInvite, .meetJoin:
            return "#7E22CE" // Purple
        case .meetStarting:
            return "#FD4B93" // Pink
        case .friendRequest:
            return "#3B82F6" // Blue
        case .routeShared:
            return "#10B981" // Green
        case .systemMessage:
            return "#F59E0B" // Amber
        }
    }
}

// Add a simpler version for the existing views to avoid requiring lots of changes immediately
extension NotificationModel {
    func toNotification() -> Notification {
        Notification(
            id: id,
            title: title,
            message: message,
            timestamp: createdAt,
            isRead: isRead
        )
    }
}

// For previews and testing
extension NotificationModel {
    static let mockNotifications: [NotificationModel] = [
        NotificationModel(
            id: UUID().uuidString,
            userId: "user123",
            title: "New Meet Request",
            message: "John Doe invited you to join 'Sunday Drive'",
            type: .meetInvite,
            relatedId: "meet123",
            isRead: false,
            createdAt: Date().addingTimeInterval(-3600), // 1 hour ago
            updatedAt: Date().addingTimeInterval(-3600)
        ),
        NotificationModel(
            id: UUID().uuidString,
            userId: "user123",
            title: "Route Shared",
            message: "Sarah Smith shared a new route with you",
            type: .routeShared,
            relatedId: "route456",
            isRead: true,
            createdAt: Date().addingTimeInterval(-86400), // 1 day ago
            updatedAt: Date().addingTimeInterval(-86400)
        ),
        NotificationModel(
            id: UUID().uuidString,
            userId: "user123",
            title: "Meet Reminder",
            message: "Your meet 'Mountain Drive' is tomorrow at 10:00 AM",
            type: .meetStarting,
            relatedId: "meet789",
            isRead: false,
            createdAt: Date().addingTimeInterval(-172800), // 2 days ago
            updatedAt: Date().addingTimeInterval(-172800)
        ),
        NotificationModel(
            id: UUID().uuidString,
            userId: "user123",
            title: "Friend Request",
            message: "Michael Johnson sent you a friend request",
            type: .friendRequest,
            relatedId: "user456",
            isRead: false,
            createdAt: Date().addingTimeInterval(-259200), // 3 days ago
            updatedAt: Date().addingTimeInterval(-259200)
        ),
        NotificationModel(
            id: UUID().uuidString,
            userId: "user123",
            title: "Welcome to MeetSpot",
            message: "Thanks for joining MeetSpot! Discover car meets around you.",
            type: .systemMessage,
            relatedId: nil,
            isRead: true,
            createdAt: Date().addingTimeInterval(-604800), // 1 week ago
            updatedAt: Date().addingTimeInterval(-604800)
        )
    ]
} 
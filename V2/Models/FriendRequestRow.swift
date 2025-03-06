import Foundation

struct FriendRequestRow: Identifiable, Codable {
    let id: UUID
    let sender: User
    let timestamp: Date
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case sender
        case timestamp = "created_at"
        case status
    }
}

// MARK: - Mock Data
extension FriendRequestRow {
    static let mockFriendRequests = [
        FriendRequestRow(id: UUID(), sender: User.mockFriends[0], timestamp: Date(), status: "pending"),
        FriendRequestRow(id: UUID(), sender: User.mockFriends[1], timestamp: Date(), status: "pending")
    ]
} 
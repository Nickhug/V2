import Foundation

struct FriendRequest: Codable {
    let id: UUID
    let senderId: String
    let receiverId: String
    var status: String
    let createdAt: Date
    let sender: User?
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case senderId = "sender_id"
        case receiverId = "receiver_id"
        case status
        case createdAt = "created_at"
        case sender
        case timestamp
    }
} 
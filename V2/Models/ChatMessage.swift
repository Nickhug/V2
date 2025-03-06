import Foundation

public struct ChatMessage: Codable {
    public let id: UUID
    public let meetId: UUID
    public let userId: UUID
    public let message: String
    public let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case meetId = "meet_id"
        case userId = "user_id"
        case message
        case createdAt = "created_at"
    }
} 
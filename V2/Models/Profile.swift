import Foundation

public struct Profile: Codable {
    public let id: String
    public var username: String
    public var fullName: String?
    public var avatarUrl: String?
    public var bio: String?
    public var location: String?
    public var createdAt: Date
    public var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
        case bio
        case location
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
} 
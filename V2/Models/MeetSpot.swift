import Foundation
import CoreLocation

// MARK: - Enums
// Remove duplicate enums that are defined in separate files
// RouteType and MeetStatus are now imported from their own files

// MARK: - Models
// Profile model is now defined in User.swift

public struct MeetSpot: Identifiable, Codable {
    public let id: UUID
    public let name: String
    public let description: String
    public let address: String
    public let latitude: Double
    public let longitude: Double
    public let rating: Double
    public let reviewCount: Int
    public let photos: [String]
    public let amenities: [String]
    public let hours: [String: String]
    public let createdAt: Date
    public let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case address
        case latitude
        case longitude
        case rating
        case reviewCount = "review_count"
        case photos
        case amenities
        case hours
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
} 
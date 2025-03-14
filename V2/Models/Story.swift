import Foundation
import CoreLocation
import Supabase

struct Story: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID
    let mediaUrl: String
    let mediaType: MediaType
    let caption: String?
    let location: CLLocationCoordinate2D?
    let locationName: String?
    let viewers: [UUID]
    let isActive: Bool
    let createdAt: Date
    let expiresAt: Date
    
    // Additional properties from joined data
    let username: String?
    let profileImageUrl: String?
    let hasViewed: Bool
    
    enum MediaType: String, Codable {
        case image
        case video
    }
    
    enum CodingKeys: String, CodingKey {
        case id, username, caption, viewers, location, locationName = "location_name", isActive = "is_active"
        case userId = "user_id"
        case mediaUrl = "media_url"
        case mediaType = "media_type"
        case createdAt = "created_at"
        case expiresAt = "expires_at"
        case profileImageUrl = "profile_image_url"
        case hasViewed = "has_viewed"
    }
    
    // Computed properties
    var timeRemaining: TimeInterval {
        return expiresAt.timeIntervalSince(Date())
    }
    
    var viewCount: Int {
        return viewers.count
    }
    
    var isExpired: Bool {
        return Date() >= expiresAt
    }
    
    var percentageRemaining: Double {
        let totalDuration: TimeInterval = 24 * 60 * 60 // 24 hours in seconds
        let remainingTime = timeRemaining
        return max(0, min(100, (remainingTime / totalDuration) * 100))
    }
    
    static func == (lhs: Story, rhs: Story) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Custom initializer for creating Story instances programmatically
    init(id: UUID, userId: UUID, mediaUrl: String, mediaType: MediaType, caption: String?, 
         location: CLLocationCoordinate2D?, locationName: String?, viewers: [UUID], 
         isActive: Bool, createdAt: Date, expiresAt: Date, username: String?, 
         profileImageUrl: String?, hasViewed: Bool) {
        self.id = id
        self.userId = userId
        self.mediaUrl = mediaUrl
        self.mediaType = mediaType
        self.caption = caption
        self.location = location
        self.locationName = locationName
        self.viewers = viewers
        self.isActive = isActive
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.username = username
        self.profileImageUrl = profileImageUrl
        self.hasViewed = hasViewed
    }
    
    // Custom decoder for handling PostgreSQL point type for location
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        mediaUrl = try container.decode(String.self, forKey: .mediaUrl)
        mediaType = try container.decode(MediaType.self, forKey: .mediaType)
        caption = try container.decodeIfPresent(String.self, forKey: .caption)
        viewers = try container.decode([UUID].self, forKey: .viewers)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        expiresAt = try container.decode(Date.self, forKey: .expiresAt)
        username = try container.decodeIfPresent(String.self, forKey: .username)
        profileImageUrl = try container.decodeIfPresent(String.self, forKey: .profileImageUrl)
        hasViewed = try container.decodeIfPresent(Bool.self, forKey: .hasViewed) ?? false
        
        // Decode PostgreSQL point type for location
        if let locationString = try container.decodeIfPresent(String.self, forKey: .location),
           locationString.hasPrefix("(") && locationString.hasSuffix(")") {
            let pointString = locationString.dropFirst().dropLast()
            let coordinates = pointString.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
            
            if coordinates.count == 2, 
               let longitude = Double(coordinates[0]),
               let latitude = Double(coordinates[1]) {
                location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            } else {
                location = nil
            }
        } else {
            location = nil
        }
        
        locationName = try container.decodeIfPresent(String.self, forKey: .locationName)
    }
    
    // Custom encoder for handling PostgreSQL point type for location
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(mediaUrl, forKey: .mediaUrl)
        try container.encode(mediaType, forKey: .mediaType)
        try container.encodeIfPresent(caption, forKey: .caption)
        try container.encode(viewers, forKey: .viewers)
        try container.encode(isActive, forKey: .isActive)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(expiresAt, forKey: .expiresAt)
        try container.encodeIfPresent(username, forKey: .username)
        try container.encodeIfPresent(profileImageUrl, forKey: .profileImageUrl)
        try container.encode(hasViewed, forKey: .hasViewed)
        
        // Encode location as PostgreSQL point type
        if let locationCoords = location {
            // PostgreSQL format: "(longitude,latitude)"
            let pointString = "(\(locationCoords.longitude),\(locationCoords.latitude))"
            try container.encode(pointString, forKey: .location)
        }
        
        try container.encodeIfPresent(locationName, forKey: .locationName)
    }
}

// Group of stories by user
struct UserStories: Identifiable, Hashable {
    let id: UUID // user_id
    let username: String
    let profileImageUrl: String?
    var stories: [Story]
    
    // Computed property to check if user has any unviewed stories
    var hasUnviewedStories: Bool {
        return stories.contains(where: { !$0.hasViewed })
    }
    
    // Computed property to get the latest story
    var latestStory: Story? {
        return stories.max(by: { $0.createdAt < $1.createdAt })
    }
    
    // Used for object comparison
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: UserStories, rhs: UserStories) -> Bool {
        return lhs.id == rhs.id
    }
} 
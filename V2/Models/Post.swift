import Foundation
import SwiftUI
import MapKit
import CoreLocation

struct Post: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    let vehicleId: String?
    let caption: String
    let imageUrls: [String]
    var location: CLLocationCoordinate2D?
    var locationName: String?
    let createdAt: Date
    let updatedAt: Date
    
    // Computed properties for UI
    var likeCount: Int = 0
    var commentCount: Int = 0
    var isLikedByCurrentUser: Bool = false
    
    // Related objects
    var user: User?
    var vehicle: Vehicle?
    
    // Standard initializer
    init(id: String, userId: String, vehicleId: String?, caption: String, imageUrls: [String], location: CLLocationCoordinate2D?, locationName: String?, createdAt: Date, updatedAt: Date, likeCount: Int = 0, commentCount: Int = 0, isLikedByCurrentUser: Bool = false, user: User? = nil, vehicle: Vehicle? = nil) {
        self.id = id
        self.userId = userId
        self.vehicleId = vehicleId
        self.caption = caption
        self.imageUrls = imageUrls
        self.location = location
        self.locationName = locationName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.isLikedByCurrentUser = isLikedByCurrentUser
        self.user = user
        self.vehicle = vehicle
    }
    
    // For Codable
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case vehicleId = "vehicle_id"
        case caption
        case imageUrls = "image_urls"
        case location
        case locationName = "location_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case likeCount = "like_count"
        case commentCount = "comment_count"
        case isLikedByCurrentUser = "is_liked"
        case user
        case vehicle
    }
    
    static func == (lhs: Post, rhs: Post) -> Bool {
        return lhs.id == rhs.id
    }
    
    // CLLocationCoordinate2D custom encoding/decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        vehicleId = try container.decodeIfPresent(String.self, forKey: .vehicleId)
        caption = try container.decode(String.self, forKey: .caption)
        imageUrls = try container.decode([String].self, forKey: .imageUrls)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        
        // Optional fields
        locationName = try container.decodeIfPresent(String.self, forKey: .locationName)
        
        // Handle location decoding from point
        if let locationString = try container.decodeIfPresent(String.self, forKey: .location) {
            // Format expected from Postgres POINT: "(lat,long)"
            let trimmed = locationString.trimmingCharacters(in: CharacterSet(charactersIn: "()"))
            let coords = trimmed.split(separator: ",").map { Double($0.trimmingCharacters(in: .whitespaces)) ?? 0 }
            if coords.count == 2 {
                location = CLLocationCoordinate2D(latitude: coords[0], longitude: coords[1])
            }
        }
        
        // Analytics data
        likeCount = try container.decodeIfPresent(Int.self, forKey: .likeCount) ?? 0
        commentCount = try container.decodeIfPresent(Int.self, forKey: .commentCount) ?? 0
        isLikedByCurrentUser = try container.decodeIfPresent(Bool.self, forKey: .isLikedByCurrentUser) ?? false
        
        // Related objects
        user = try container.decodeIfPresent(User.self, forKey: .user)
        vehicle = try container.decodeIfPresent(Vehicle.self, forKey: .vehicle)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encodeIfPresent(vehicleId, forKey: .vehicleId)
        try container.encode(caption, forKey: .caption)
        try container.encode(imageUrls, forKey: .imageUrls)
        
        // Encode location as a string
        if let location = location {
            let locationString = "(\(location.latitude),\(location.longitude))"
            try container.encode(locationString, forKey: .location)
        }
        
        try container.encodeIfPresent(locationName, forKey: .locationName)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        
        // Not encoding analytics data or related objects as they're computed on fetch
    }
}

struct PostComment: Identifiable, Codable, Equatable {
    let id: String
    let postId: String
    let userId: String
    let content: String
    let createdAt: Date
    let updatedAt: Date
    
    // Related objects
    var user: User?
    
    // For Codable
    enum CodingKeys: String, CodingKey {
        case id
        case postId = "post_id"
        case userId = "user_id"
        case content
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case user
    }
    
    static func == (lhs: PostComment, rhs: PostComment) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Factory methods
extension Post {
    static func createNew(userId: String, vehicleId: String?, caption: String, imageUrls: [String], location: CLLocationCoordinate2D? = nil, locationName: String? = nil) -> Post {
        return Post(
            id: UUID().uuidString,
            userId: userId,
            vehicleId: vehicleId,
            caption: caption,
            imageUrls: imageUrls,
            location: location,
            locationName: locationName,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

// MARK: - Mock Data
extension Post {
    static let mockPosts = [
        Post(
            id: UUID().uuidString,
            userId: "user123",
            vehicleId: "vehicle123",
            caption: "Just detailed my ride! #carlife #detailing",
            imageUrls: ["https://images.unsplash.com/photo-1542362567-b07e54358753"],
            location: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            locationName: "San Francisco, CA",
            createdAt: Date().addingTimeInterval(-86400), // 1 day ago
            updatedAt: Date().addingTimeInterval(-86400),
            likeCount: 42,
            commentCount: 7,
            isLikedByCurrentUser: true,
            user: User.mockCurrentUser,
            vehicle: nil
        ),
        Post(
            id: UUID().uuidString,
            userId: "user456",
            vehicleId: "vehicle456",
            caption: "Morning drive through the mountains #scenery #roadtrip",
            imageUrls: ["https://images.unsplash.com/photo-1533473359331-0135ef1b58bf"],
            location: CLLocationCoordinate2D(latitude: 39.5501, longitude: -105.7821),
            locationName: "Rocky Mountains",
            createdAt: Date().addingTimeInterval(-172800), // 2 days ago
            updatedAt: Date().addingTimeInterval(-172800),
            likeCount: 104,
            commentCount: 15,
            isLikedByCurrentUser: false,
            user: User.mockCurrentUser,
            vehicle: nil
        )
    ]
} 
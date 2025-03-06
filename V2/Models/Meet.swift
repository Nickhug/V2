import SwiftUI
import MapKit
import Foundation
import CoreLocation
import Supabase

struct Meet: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let date: Date
    let location: CLLocationCoordinate2D
    let address: String
    let type: V2MeetType
    let coverImage: String
    let rules: [String]
    let tags: [String]
    let isPremium: Bool
    let capacity: Int
    var attendees: [User]
    var comments: [MeetComment]
    let creatorId: String
    let status: MeetStatus
    let vehicleType: VehicleType
    let routeType: RouteType
    var primaryRouteId: String?
    let createdAt: Date
    let updatedAt: Date
    
    var locationName: String {
        // Extract city/area name from the address
        let components = address.components(separatedBy: ",")
        return components.count > 1 ? components[1].trimmingCharacters(in: .whitespaces) : address
    }
    
    var formattedDate: String {
        date.formatted(date: .abbreviated, time: .shortened)
    }
    
    var distanceFromUser: Double? {
        // TODO: Implement actual distance calculation from user's location
        // For now, return nil to indicate distance is not available
        nil
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case date
        case location
        case address
        case type
        case coverImage = "cover_image"
        case rules
        case tags
        case isPremium = "is_premium"
        case capacity
        case creatorId = "organizer_id"
        case status
        case vehicleType = "vehicle_type"
        case routeType = "route_type"
        case primaryRouteId = "primary_route_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(id: String = UUID().uuidString, 
         title: String, 
         description: String, 
         date: Date, 
         location: CLLocationCoordinate2D, 
         address: String, 
         type: V2MeetType, 
         coverImage: String, 
         rules: [String], 
         tags: [String], 
         isPremium: Bool = false, 
         capacity: Int, 
         creatorId: String,
         status: MeetStatus = .upcoming,
         vehicleType: VehicleType,
         routeType: RouteType,
         primaryRouteId: String? = nil,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.description = description
        self.date = date
        self.location = location
        self.address = address
        self.type = type
        self.coverImage = coverImage
        self.rules = rules
        self.tags = tags
        self.isPremium = isPremium
        self.capacity = capacity
        self.attendees = []
        self.comments = []
        self.creatorId = creatorId
        self.status = status
        self.vehicleType = vehicleType
        self.routeType = routeType
        self.primaryRouteId = primaryRouteId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        date = try container.decode(Date.self, forKey: .date)
        location = try container.decode(CLLocationCoordinate2D.self, forKey: .location)
        address = try container.decode(String.self, forKey: .address)
        type = try container.decode(V2MeetType.self, forKey: .type)
        coverImage = try container.decode(String.self, forKey: .coverImage)
        rules = try container.decode([String].self, forKey: .rules)
        tags = try container.decode([String].self, forKey: .tags)
        isPremium = try container.decode(Bool.self, forKey: .isPremium)
        capacity = try container.decode(Int.self, forKey: .capacity)
        creatorId = try container.decode(String.self, forKey: .creatorId)
        status = try container.decode(MeetStatus.self, forKey: .status)
        vehicleType = try container.decode(VehicleType.self, forKey: .vehicleType)
        routeType = try container.decode(RouteType.self, forKey: .routeType)
        primaryRouteId = try container.decodeIfPresent(String.self, forKey: .primaryRouteId)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        
        // Initialize these as empty arrays since they're not in the database
        attendees = []
        comments = []
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(date, forKey: .date)
        try container.encode(location, forKey: .location)
        try container.encode(address, forKey: .address)
        try container.encode(type, forKey: .type)
        try container.encode(coverImage, forKey: .coverImage)
        try container.encode(rules, forKey: .rules)
        try container.encode(tags, forKey: .tags)
        try container.encode(isPremium, forKey: .isPremium)
        try container.encode(capacity, forKey: .capacity)
        try container.encode(creatorId, forKey: .creatorId)
        try container.encode(status, forKey: .status)
        try container.encode(vehicleType, forKey: .vehicleType)
        try container.encode(routeType, forKey: .routeType)
        try container.encodeIfPresent(primaryRouteId, forKey: .primaryRouteId)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
    
    static func fromRealtimePayload(_ payload: [String: Any]) -> Meet? {
        guard let record = payload["new"] as? [String: Any] else { return nil }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: record)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(Meet.self, from: data)
        } catch {
            print("Error decoding Meet from payload: \(error)")
            return nil
        }
    }
}

struct MeetComment: Identifiable, Codable {
    let id: String
    let userId: String
    let meetId: String
    let text: String
    let timestamp: Date
    var likes: Int
    var replies: [MeetComment]
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case meetId = "meet_id"
        case text
        case timestamp
        case likes
        case replies
    }
    
    init(id: String = UUID().uuidString, userId: String, meetId: String, text: String, timestamp: Date = Date(), likes: Int = 0) {
        self.id = id
        self.userId = userId
        self.meetId = meetId
        self.text = text
        self.timestamp = timestamp
        self.likes = likes
        self.replies = []
    }
    
    static func fromRealtimePayload(_ payload: [String: Any]) -> MeetComment? {
        guard let record = payload["new"] as? [String: Any] else { return nil }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: record)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(MeetComment.self, from: data)
        } catch {
            print("Error decoding MeetComment from payload: \(error)")
            return nil
        }
    }
}

// MARK: - Mock Data
extension Meet {
    static let mockMeets = [
        Meet(
            id: UUID().uuidString,
            title: "Sunday Morning Cars & Coffee",
            description: "Join us for our weekly cars & coffee meetup! All cars welcome.",
            date: Date().addingTimeInterval(86400 * 2),
            location: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            address: "123 Main St, San Francisco, CA",
            type: .car,
            coverImage: "https://images.unsplash.com/photo-1503736334956-4c8f8e92946d?w=800&q=80",
            rules: ["No burnouts", "Respect the venue", "Clean up after yourself"],
            tags: ["Cars & Coffee", "Weekly Meet", "All Welcome"],
            isPremium: false,
            capacity: 50,
            creatorId: User.mockCurrentUser.id,
            status: .upcoming,
            vehicleType: .car,
            routeType: .city,
            primaryRouteId: nil,
            createdAt: Date(),
            updatedAt: Date()
        ),
        Meet(
            id: UUID().uuidString,
            title: "Night Riders Motorcycle Meet",
            description: "Monthly motorcycle enthusiast gathering. Food trucks and music!",
            date: Date().addingTimeInterval(86400 * 5),
            location: CLLocationCoordinate2D(latitude: 37.7858, longitude: -122.4064),
            address: "456 Market St, San Francisco, CA",
            type: .bike,
            coverImage: "https://images.unsplash.com/photo-1558981806-ec527fa84c39?w=800&q=80",
            rules: ["Helmets required", "No wheelies", "Follow traffic laws"],
            tags: ["Motorcycles", "Monthly", "Night Ride"],
            isPremium: true,
            capacity: 100,
            creatorId: User.mockCurrentUser.id,
            status: .upcoming,
            vehicleType: .bike,
            routeType: .scenic,
            primaryRouteId: nil,
            createdAt: Date(),
            updatedAt: Date()
        ),
        Meet(
            id: UUID().uuidString,
            title: "Mountain Adventure Drive",
            description: "Experience the thrill of mountain roads with fellow enthusiasts.",
            date: Date().addingTimeInterval(86400 * 7),
            location: CLLocationCoordinate2D(latitude: 37.8199, longitude: -122.4783),
            address: "789 Panoramic Hwy, Mill Valley, CA",
            type: .mixed,
            coverImage: "https://images.unsplash.com/photo-1504198322253-cfa87a0ff25f?w=800&q=80",
            rules: ["Bring warm clothes", "Check weather", "Full tank required"],
            tags: ["Mountain", "Adventure", "Scenic"],
            isPremium: true,
            capacity: 30,
            creatorId: User.mockCurrentUser.id,
            status: .upcoming,
            vehicleType: .both,
            routeType: .mountain,
            primaryRouteId: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    ]
} 
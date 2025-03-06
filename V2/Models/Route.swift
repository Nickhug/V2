import Foundation
import MapKit
import CoreLocation

struct Route: Identifiable, Codable {
    let id: String
    let meetId: String?
    let creatorId: String
    var title: String
    var description: String
    var routeData: RouteData
    var distance: Double // in kilometers
    var estimatedTime: Int // in minutes
    var difficulty: RouteDifficulty
    let createdAt: Date?
    var updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case meetId = "meet_id"
        case creatorId = "creator_id"
        case title
        case description
        case routeData = "route_data"
        case distance
        case estimatedTime = "estimated_time"
        case difficulty
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // For new routes
    init(
        id: String = UUID().uuidString,
        meetId: String? = nil,
        creatorId: String,
        title: String,
        description: String = "",
        routeData: RouteData,
        distance: Double = 0.0,
        estimatedTime: Int = 0,
        difficulty: RouteDifficulty = .moderate,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.meetId = meetId
        self.creatorId = creatorId
        self.title = title
        self.description = description
        self.routeData = routeData
        self.distance = distance
        self.estimatedTime = estimatedTime
        self.difficulty = difficulty
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Computed property to create MKPolyline for MapKit
    var polyline: MKPolyline {
        let coordinates = routeData.coordinates.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
        return MKPolyline(coordinates: coordinates, count: coordinates.count)
    }
    
    // Computed property for formatted distance string
    var formattedDistance: String? {
        guard distance > 0 else { return nil }
        
        if distance >= 1.0 {
            return String(format: "%.1f km", distance)
        } else {
            let meters = Int(distance * 1000)
            return "\(meters) m"
        }
    }
    
    // Calculate route details based on coordinates
    mutating func calculateRouteDetails() {
        // Calculate distance
        var totalDistance: Double = 0
        
        if routeData.coordinates.count > 1 {
            for i in 0..<(routeData.coordinates.count - 1) {
                let coord1 = CLLocation(
                    latitude: routeData.coordinates[i].latitude,
                    longitude: routeData.coordinates[i].longitude
                )
                let coord2 = CLLocation(
                    latitude: routeData.coordinates[i+1].latitude,
                    longitude: routeData.coordinates[i+1].longitude
                )
                
                totalDistance += coord1.distance(from: coord2) / 1000 // Convert to km
            }
        }
        
        self.distance = totalDistance
        
        // Estimate time (using average speed of 30 km/h for driving, adjust as needed)
        let averageSpeedKmPerHour: Double = 30
        self.estimatedTime = Int((totalDistance / averageSpeedKmPerHour) * 60) // Convert to minutes
    }
}

struct RouteData: Codable {
    var coordinates: [Coordinate]
    var waypoints: [Waypoint]
    
    init(coordinates: [Coordinate] = [], waypoints: [Waypoint] = []) {
        self.coordinates = coordinates
        self.waypoints = waypoints
    }
}

struct Coordinate: Codable {
    var latitude: Double
    var longitude: Double
    
    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    init(from coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }
    
    var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct Waypoint: Identifiable, Codable {
    var id: String = UUID().uuidString
    var coordinate: Coordinate
    var title: String
    var subtitle: String?
    var type: WaypointType
    
    init(
        id: String = UUID().uuidString,
        coordinate: Coordinate,
        title: String,
        subtitle: String? = nil,
        type: WaypointType = .regular
    ) {
        self.id = id
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.type = type
    }
}

enum WaypointType: String, Codable {
    case start = "start"
    case end = "end"
    case regular = "regular"
    case checkpoint = "checkpoint"
    case scenic = "scenic"
    case rest = "rest"
    case fuel = "fuel"
    case food = "food"
    
    var iconName: String {
        switch self {
        case .start: return "flag.fill"
        case .end: return "flag.checkered"
        case .regular: return "mappin"
        case .checkpoint: return "checkmark.circle"
        case .scenic: return "camera.fill"
        case .rest: return "bed.double"
        case .fuel: return "fuelpump"
        case .food: return "fork.knife"
        }
    }
    
    var color: String {
        switch self {
        case .start: return "#00FF00" // Green
        case .end: return "#FF0000"   // Red
        case .regular: return "#007AFF" // Blue
        case .checkpoint: return "#FF9500" // Orange
        case .scenic: return "#5856D6" // Purple
        case .rest: return "#34C759" // Green
        case .fuel: return "#FFCC00" // Yellow
        case .food: return "#FF2D55" // Pink
        }
    }
    
    var defaultTitle: String {
        switch self {
        case .start: return "Start"
        case .end: return "End"
        case .regular: return "Waypoint"
        case .checkpoint: return "Checkpoint"
        case .scenic: return "Scenic View"
        case .rest: return "Rest Stop"
        case .fuel: return "Fuel Station"
        case .food: return "Food Stop"
        }
    }
}

enum RouteDifficulty: String, Codable, CaseIterable {
    case easy = "easy"
    case moderate = "moderate"
    case challenging = "challenging"
    
    var description: String {
        switch self {
        case .easy: return "Easy - Suitable for beginners"
        case .moderate: return "Moderate - Some experience required"
        case .challenging: return "Challenging - Experienced riders/drivers only"
        }
    }
} 
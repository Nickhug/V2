import Foundation
import CoreLocation

struct User: Identifiable, Codable, Equatable {
    var id: String
    var email: String
    var profile: Profile
    var vehicles: [Vehicle]
    var friends: [String] // Friend IDs
    var isPremium: Bool
    var achievements: [Achievement]
    var preferences: Preferences
    var upcomingMeets: [Meet]?
    
    struct Profile: Codable, Equatable {
        var name: String
        var avatar: String
        var avatarUrl: String? // For storing the full URL
        var bio: String
        var location: Location
        var joinDate: Date?
        var social: Social?
        var statusMessage: String?
        
        struct Location: Codable, Equatable {
            var latitude: Double
            var longitude: Double
            var address: String
            
            var coordinate: CLLocationCoordinate2D {
                CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            }
        }
        
        struct Social: Codable, Equatable {
            var instagram: String
            var facebook: String
            var twitter: String
            
            static let empty = Social(instagram: "", facebook: "", twitter: "")
        }
        
        static let empty = Profile(
            name: "",
            avatar: "",
            avatarUrl: nil,
            bio: "",
            location: Location(latitude: 0, longitude: 0, address: ""),
            joinDate: Date(),
            social: nil,
            statusMessage: "Available"
        )
    }
    
    struct Preferences: Codable, Equatable {
        var darkMode: Bool
        var notifications: NotificationPreferences
        var privacySettings: PrivacySettings
        
        struct NotificationPreferences: Codable, Equatable {
            var newMeets: Bool
            var meetUpdates: Bool
            var friendRequests: Bool
            var comments: Bool
            
            static let defaultPrefs = NotificationPreferences(
                newMeets: true,
                meetUpdates: true,
                friendRequests: true,
                comments: true
            )
        }
        
        struct PrivacySettings: Codable, Equatable {
            var showVehicles: Bool
            var showLocation: Bool
            var showSocial: Bool
            
            static let defaultSettings = PrivacySettings(
                showVehicles: true,
                showLocation: true,
                showSocial: true
            )
        }
        
        static let defaultPreferences = Preferences(
            darkMode: false,
            notifications: NotificationPreferences.defaultPrefs,
            privacySettings: PrivacySettings.defaultSettings
        )
    }
    
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
    
    static var empty: User {
        User(
            id: "",
            email: "",
            profile: Profile.empty,
            vehicles: [],
            friends: [],
            isPremium: false,
            achievements: [],
            preferences: Preferences.defaultPreferences,
            upcomingMeets: nil
        )
    }
}

// Separate Vehicle model to avoid nesting
struct Vehicle: Identifiable, Codable {
    let id: String
    let userId: String?
    var make: String
    var model: String
    var year: Int
    var type: VehicleType // Use the imported VehicleType
    var modifications: [String]
    var photos: [String]
    let createdAt: Date?
    var updatedAt: Date?
    
    // Add formatted year property to ensure it displays without commas
    var formattedYear: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        return formatter.string(from: NSNumber(value: year)) ?? "\(year)"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case make
        case model
        case year
        case type
        case modifications
        case photos
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
} 

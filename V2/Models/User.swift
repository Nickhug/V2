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
    
    // Regular initializer to create a User directly
    init(
        id: String,
        email: String,
        profile: Profile,
        vehicles: [Vehicle],
        friends: [String],
        isPremium: Bool,
        achievements: [Achievement],
        preferences: Preferences,
        upcomingMeets: [Meet]? = nil
    ) {
        self.id = id
        self.email = email
        self.profile = profile
        self.vehicles = vehicles
        self.friends = friends
        self.isPremium = isPremium
        self.achievements = achievements
        self.preferences = preferences
        self.upcomingMeets = upcomingMeets
    }
    
    // For decoding achievements from JSON
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case profile
        case vehicles
        case friends
        case isPremium
        case achievements
        case preferences
        case upcomingMeets
    }
    
    // Custom decoder to handle achievements array
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        profile = try container.decode(Profile.self, forKey: .profile)
        vehicles = try container.decodeIfPresent([Vehicle].self, forKey: .vehicles) ?? []
        friends = try container.decodeIfPresent([String].self, forKey: .friends) ?? []
        isPremium = try container.decodeIfPresent(Bool.self, forKey: .isPremium) ?? false
        preferences = try container.decodeIfPresent(Preferences.self, forKey: .preferences) ?? Preferences.defaultPreferences
        upcomingMeets = try container.decodeIfPresent([Meet].self, forKey: .upcomingMeets)
        
        // Try to decode achievements manually if they come as JSON objects
        if let achievementsData = try? container.decode(Data.self, forKey: .achievements) {
            // Attempt to decode as array of Achievement objects
            if let decodedAchievements = try? JSONDecoder().decode([Achievement].self, from: achievementsData) {
                achievements = decodedAchievements
            } else {
                // Fallback to manual decoding from Dictionary format
                let achievementsDict = try JSONSerialization.jsonObject(with: achievementsData) as? [[String: Any]] ?? []
                
                achievements = achievementsDict.compactMap { dict -> Achievement? in
                    guard 
                        let id = dict["id"] as? String,
                        let typeStr = dict["type"] as? String,
                        let type = AchievementType(rawValue: typeStr),
                        let title = dict["title"] as? String,
                        let description = dict["description"] as? String,
                        let icon = dict["icon"] as? String,
                        let earnedAtStr = dict["earned_at"] as? String,
                        let earnedAt = ISO8601DateFormatter().date(from: earnedAtStr)
                    else {
                        return nil
                    }
                    
                    return Achievement(
                        id: id,
                        type: type,
                        title: title,
                        description: description,
                        icon: icon,
                        earnedAt: earnedAt
                    )
                }
            }
        } else {
            achievements = try container.decodeIfPresent([Achievement].self, forKey: .achievements) ?? []
        }
    }
    
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

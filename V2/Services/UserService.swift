import Foundation
import Supabase
import UIKit

// Struct for database operations
private struct SupabaseUser: Encodable {
    let id: String
    let email: String
    let profile: Profile
    let vehicles: [Vehicle]
    let friends: [String]
    let isPremium: Bool
    let upcomingMeets: [Meet]?
    
    struct Profile: Encodable {
        let name: String
        let avatar: String
        let bio: String
        let location: Location
        let joinDate: Date
        let social: Social?
        
        struct Location: Encodable {
            let latitude: Double
            let longitude: Double
            let address: String
        }
        
        struct Social: Encodable {
            let instagram: String
            let facebook: String
            let twitter: String
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case profile
        case vehicles
        case friends
        case isPremium = "is_premium"
        case upcomingMeets = "upcoming_meets"
    }
    
    init(from user: User) {
        self.id = user.id
        self.email = user.email
        self.profile = Profile(
            name: user.profile.name,
            avatar: user.profile.avatar,
            bio: user.profile.bio,
            location: Profile.Location(
                latitude: user.profile.location.latitude,
                longitude: user.profile.location.longitude,
                address: user.profile.location.address
            ),
            joinDate: user.profile.joinDate ?? Date(),
            social: user.profile.social.map { social in
                Profile.Social(
                    instagram: social.instagram,
                    facebook: social.facebook,
                    twitter: social.twitter
                )
            }
        )
        self.vehicles = user.vehicles
        self.friends = user.friends
        self.isPremium = user.isPremium
        self.upcomingMeets = user.upcomingMeets
    }
}

class UserService {
    static let shared = UserService()
    private let supabase: SupabaseClient
    
    private init() {
        self.supabase = SupabaseConfig.client
    }
    
    var currentUserId: String? {
        get async throws {
            let session = try await supabase.auth.session
            return session.user.id.uuidString
        }
    }
    
    func signIn(email: String, password: String) async throws -> User {
        let auth = try await supabase.auth.signIn(
            email: email,
            password: password
        )
        
        return try await fetchUser(id: auth.user.id.uuidString)
    }
    
    func signUp(email: String, password: String) async throws -> User {
        // First, sign up the user in auth.users
        let auth = try await supabase.auth.signUp(
            email: email,
            password: password
        )
        
        // Create initial user profile
        let newUser = User(
            id: auth.user.id.uuidString,
            email: email,
            profile: User.Profile(
                name: "New User",
                avatar: "person.circle.fill",
                bio: "",
                location: User.Profile.Location(
                    latitude: 0,
                    longitude: 0,
                    address: ""
                ),
                joinDate: Date(),
                social: nil
            ),
            vehicles: [],
            friends: [],
            isPremium: false,
            achievements: [],
            preferences: User.Preferences.defaultPreferences
        )
        
        // Wait a moment to ensure the auth user is fully created
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Create database user for insertion
        let dbUser = SupabaseUser(from: newUser)
        
        // Then create the profile in public.users
        try await supabase
            .from("users")
            .insert(dbUser)
            .execute()
        
        // Return the user without signing in
        // The user will need to confirm their email first
        return newUser
    }
    
    func signOut() async throws {
        try await supabase.auth.signOut()
    }
    
    func fetchUser(id: String) async throws -> User {
        let response = try await supabase
            .from("users")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
        
        // Print the raw response data for debugging
        if let jsonString = String(data: response.data, encoding: .utf8) {
            print("Raw response data: \(jsonString)")
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(User.self, from: response.data)
    }
    
    func saveUser(_ user: User) async throws {
        try await supabase
            .from("users")
            .upsert(user)
            .execute()
    }
    
    func updateProfile(_ profile: User.Profile) async throws {
        guard let userId = try await currentUserId else {
            throw AuthError.notAuthenticated
        }
        var user = try await fetchUser(id: userId)
        user.profile = profile
        try await saveUser(user)
    }
    
    func uploadProfileImage(_ image: UIImage) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw AuthError.invalidImage
        }
        
        let fileName = "\(UUID().uuidString).jpg"
        let path = "profiles/\(fileName)"
        
        try await supabase.storage
            .from("avatars")
            .upload(path, data: imageData, options: FileOptions(contentType: "image/jpeg"))
        
        let url = try await supabase.storage
            .from("avatars")
            .createSignedURL(path: path, expiresIn: 3600 * 24 * 365) // 1 year
        
        return url.absoluteString
    }
} 

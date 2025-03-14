import Foundation
import Supabase
import UIKit
import CoreLocation
import Combine

// Define StoryMediaType enum directly
enum StoryMediaType: String, Codable {
    case image
    case video
}

enum SupabaseError: Error {
    case userNotFound
    case failedToCreateUser
    case failedToGetUser
    case failedToUpdateUser
    case failedToGetMeets
    case failedToCreateMeet
    case failedToGetComments
    case failedToCreateComment
    case imageConversionFailed
    case imageUploadFailed
    case notAuthenticated
    case authenticationError
    case failedToFetchNotifications
    case failedToUpdateNotification
    case failedToDeleteNotification
    case failedToFetchStories
    case failedToCreateStory
    case failedToUpdateStory
    case failedToDeleteStory
    case mediaUploadFailed
    case videoUploadFailed
}

@MainActor
class SupabaseService {
    static nonisolated let shared = SupabaseService()
    
    private(set) var client: SupabaseClient!
    
    nonisolated private init() {
        // Initialize client in a nonisolated context
        self.client = SupabaseConfig.client
    }
    
    // MARK: - Authentication
    func signUp(email: String, password: String) async throws -> Session {
        let response = try await client.auth.signUp(
            email: email,
            password: password
        )
        guard let session = response.session else {
            throw SupabaseError.failedToCreateUser
        }
        return session
    }
    
    func signIn(email: String, password: String) async throws -> Session {
        let response = try await client.auth.signIn(
            email: email,
            password: password
        )
        return response
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
    }
    
    // MARK: - Profile
    func fetchProfile() async throws -> Profile {
        let session = try await client.auth.session
        let result = try await client
            .from("profiles")
            .select("*")
            .eq("id", value: session.user.id)
            .single()
            .execute()
        
        return try JSONDecoder().decode(Profile.self, from: result.data)
    }
    
    func updateProfile(_ profile: Profile) async throws -> Profile {
        let result = try await client
            .from("profiles")
            .update(profile)
            .eq("id", value: profile.id)
            .select("*")
            .single()
            .execute()
        
        return try JSONDecoder().decode(Profile.self, from: result.data)
    }
    
    // MARK: - Vehicles
    func fetchVehicles() async throws -> [Vehicle] {
        let session = try await client.auth.session
        let result = try await client
            .from("vehicles")
            .select("*")
            .eq("user_id", value: session.user.id)
            .execute()
        
        return try JSONDecoder().decode([Vehicle].self, from: result.data)
    }
    
    func addVehicle(_ vehicle: Vehicle) async throws -> Vehicle {
        let result = try await client
            .from("vehicles")
            .insert(vehicle)
            .select("*")
            .single()
            .execute()
        
        return try JSONDecoder().decode(Vehicle.self, from: result.data)
    }
    
    // MARK: - Vehicle Queries
    func fetchVehiclesWithUsers() async throws -> [(Vehicle, User)] {
        let response = try await client
            .from("vehicles")
            .select("""
                *,
                user:users(*)
            """)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        struct VehicleWithUser: Codable {
            let vehicle: Vehicle
            let user: User
        }
        
        let vehiclesWithUsers = try decoder.decode([VehicleWithUser].self, from: response.data)
        return vehiclesWithUsers.map { ($0.vehicle, $0.user) }
    }
    
    func fetchVehicleWithUser(vehicleId: String) async throws -> (Vehicle, User)? {
        let response = try await client
            .from("vehicles")
            .select("""
                *,
                user:users(*)
            """)
            .eq("id", value: vehicleId)
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        struct VehicleWithUser: Codable {
            let vehicle: Vehicle
            let user: User
        }
        
        let vehicleWithUser = try decoder.decode(VehicleWithUser.self, from: response.data)
        return (vehicleWithUser.vehicle, vehicleWithUser.user)
    }
    
    // MARK: - Meet Management
    func fetchMeets(
        status: String? = nil,
        vehicleType: String? = nil,
        routeType: String? = nil,
        nearLatitude: Double? = nil,
        nearLongitude: Double? = nil,
        radius: Double = 50 // km
    ) async throws -> [Meet] {
        var query = client
            .from("meets")
            .select("*")
        
        if let status = status {
            query = query.filter("status", operator: "eq", value: status)
        }
        
        if let vehicleType = vehicleType {
            query = query.filter("vehicle_type", operator: "eq", value: vehicleType)
        }
        
        if let routeType = routeType {
            query = query.filter("route_type", operator: "eq", value: routeType)
        }
        
        if let lat = nearLatitude, let lon = nearLongitude {
            let distanceQuery = "earth_distance(ll_to_earth(latitude, longitude), ll_to_earth(\(lat), \(lon)))"
            query = query.filter(distanceQuery, operator: "lt", value: "\(radius * 1000)")
        }
        
        let result = try await query.execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Meet].self, from: result.data)
    }
    
    func createMeet(_ meet: Meet) async throws -> Meet {
        let result = try await client
            .from("meets")
            .insert(meet)
            .select("*")
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Meet.self, from: result.data)
    }
    
    func joinMeet(meetId: UUID, userId: UUID, vehicleId: UUID) async throws -> MeetParticipant {
        let participant = MeetParticipant(
            meetId: meetId,
            userId: userId,
            vehicleId: vehicleId,
            joinedAt: Date()
        )
        
        let result = try await client
            .from("meet_participants")
            .insert(participant)
            .select("*")
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(MeetParticipant.self, from: result.data)
    }
    
    func leaveMeet(meetId: UUID, userId: UUID) async throws {
        try await client
            .from("meet_participants")
            .delete()
            .eq("meet_id", value: meetId)
            .eq("user_id", value: userId)
            .execute()
    }
    
    func updateMeetPrimaryRoute(meetId: UUID, routeId: String) async throws {
        try await client
            .from("meets")
            .update(["primary_route_id": routeId])
            .eq("id", value: meetId)
            .execute()
    }
    
    // MARK: - Chat
    func fetchMessages(for meetId: UUID) async throws -> [ChatMessage] {
        let result = try await client
            .from("chat_messages")
            .select("*")
            .eq("meet_id", value: meetId)
            .order("created_at")
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([ChatMessage].self, from: result.data)
    }
    
    func sendMessage(_ message: ChatMessage) async throws -> ChatMessage {
        let result = try await client
            .from("chat_messages")
            .insert(message)
            .select("*")
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ChatMessage.self, from: result.data)
    }
    
    // MARK: - Real-time subscriptions
    func subscribeToChatMessages(
        meetId: UUID,
        onMessage: @escaping (ChatMessage) -> Void
    ) async throws -> RealtimeChannelV2 {
        let channel = client.realtimeV2
            .channel("chat:\(meetId.uuidString)")
        
        _ = channel.onPostgresChange(
            InsertAction.self,
            schema: "public",
            table: "chat_messages"
        ) { insert in
            if let message = try? insert.record.decode(as: ChatMessage.self) {
                Task { @MainActor in
                    onMessage(message)
                }
            }
        }
        
        await channel.subscribe()
        
        return channel
    }
    
    func subscribeToMeetChanges(onMeetChange: @escaping (Meet) -> Void) async throws {
        let channel = client.realtimeV2
            .channel("public:meets")
        
        _ = channel.onPostgresChange(
            InsertAction.self,
            schema: "public",
            table: "meets"
        ) { insert in
            if let meet = try? insert.record.decode(as: Meet.self) {
                Task { @MainActor in
                    onMeetChange(meet)
                }
            }
        }
        
        _ = channel.onPostgresChange(
            UpdateAction.self,
            schema: "public",
            table: "meets"
        ) { update in
            if let meet = try? update.record.decode(as: Meet.self) {
                Task { @MainActor in
                    onMeetChange(meet)
                }
            }
        }
        
        _ = channel.onPostgresChange(
            DeleteAction.self,
            schema: "public",
            table: "meets"
        ) { delete in
            if let meet = try? delete.oldRecord.decode(as: Meet.self) {
                Task { @MainActor in
                    onMeetChange(meet)
                }
            }
        }
        
        await channel.subscribe()
    }
    
    // MARK: - Comments
    
    func fetchComments(meetId: String) async throws -> [MeetComment] {
        let result = try await client
            .from("meet_comments")
            .select("*")
            .eq("meet_id", value: meetId)
            .order("timestamp")
            .execute()
        
        return try JSONDecoder().decode([MeetComment].self, from: result.data)
    }
    
    func addComment(_ comment: MeetComment) async throws -> MeetComment {
        let result = try await client
            .from("meet_comments")
            .insert(comment)
            .select("*")
            .single()
            .execute()
        
        return try JSONDecoder().decode(MeetComment.self, from: result.data)
    }
    
    func likeComment(_ commentId: String) async throws {
        let result = try await client.rpc(
            "increment_comment_likes",
            params: ["comment_id": commentId]
        ).execute()
        
        guard !result.data.isEmpty else {
            throw SupabaseError.failedToUpdateUser
        }
    }
    
    func unlikeComment(_ commentId: String) async throws {
        let result = try await client.rpc(
            "decrement_comment_likes",
            params: ["comment_id": commentId]
        ).execute()
        
        guard !result.data.isEmpty else {
            throw SupabaseError.failedToUpdateUser
        }
    }
    
    // MARK: - Helper Methods
    
    func getCurrentUser() async throws -> Auth.User? {
        let session = try await client.auth.session
        return session.user
    }
    
    func getCurrentUserId() async throws -> UUID? {
        guard let user = try await getCurrentUser() else {
            return nil
        }
        return user.id
    }
    
    // Upload an image to Supabase storage and return the public URL
    func uploadImage(_ image: UIImage, path: String) async throws -> String {
        // First verify we have an active session
        do {
            _ = try await client.auth.session
        } catch {
            print("Authentication error during image upload: \(error)")
            throw SupabaseError.notAuthenticated
        }
        
        // Convert UIImage to Data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw SupabaseError.imageConversionFailed
        }
        
        // Generate a unique filename
        let filename = "\(UUID().uuidString).jpg"
        let filePath = "\(path)/\(filename)"
        
        do {
            // Upload the image to Supabase storage
            _ = try await client.storage
                .from("meet-images")
                .upload(
                    filePath,
                    data: imageData,
                    options: .init(contentType: "image/jpeg", upsert: true)
                )
            
            // Get the public URL from the upload result
            let publicURL = try await client.storage
                .from("meet-images")
                .createSignedURL(path: filePath, expiresIn: 3600 * 24 * 365) // 1 year expiry
            
            return publicURL.absoluteString
        } catch let error as StorageError {
            print("Storage error during image upload: \(error)")
            // Check for authentication-related errors
            if error.localizedDescription.contains("authentication") || 
               error.localizedDescription.contains("auth") || 
               error.localizedDescription.contains("token") || 
               error.localizedDescription.contains("permission") {
                throw SupabaseError.notAuthenticated
            }
            throw SupabaseError.imageUploadFailed
        } catch {
            print("Unexpected error during image upload: \(error)")
            throw SupabaseError.imageUploadFailed
        }
    }
    
    // MARK: - Friend Requests
    
    func sendFriendRequest(to email: String) async throws {
        let friendService = FriendRequestService(supabaseService: self)
        try await friendService.sendFriendRequest(to: email)
    }
    
    func acceptFriendRequest(from userId: String) async throws {
        let friendService = FriendRequestService(supabaseService: self)
        try await friendService.acceptFriendRequest(from: userId)
    }
    
    func rejectFriendRequest(from userId: String) async throws {
        let friendService = FriendRequestService(supabaseService: self)
        try await friendService.rejectFriendRequest(from: userId)
    }
    
    // MARK: - Routes
    func fetchRoutes() async throws -> [Route] {
        let result = try await client
            .from("routes")
            .select("*")
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Route].self, from: result.data)
    }
    
    func fetchRoutesByCreator() async throws -> [Route] {
        let session = try await client.auth.session
        let userId = session.user.id
        
        let result = try await client
            .from("routes")
            .select("*")
            .eq("creator_id", value: userId)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Route].self, from: result.data)
    }
    
    func fetchRoutesByMeet(meetId: String) async throws -> [Route] {
        let result = try await client
            .from("routes")
            .select("*")
            .eq("meet_id", value: meetId)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Route].self, from: result.data)
    }
    
    func fetchRoute(id: String) async throws -> Route {
        let result = try await client
            .from("routes")
            .select("*")
            .eq("id", value: id)
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Route.self, from: result.data)
    }
    
    func createRoute(_ route: Route) async throws -> Route {
        let result = try await client
            .from("routes")
            .insert(route)
            .select("*")
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Route.self, from: result.data)
    }
    
    func updateRoute(_ route: Route) async throws -> Route {
        let result = try await client
            .from("routes")
            .update(route)
            .eq("id", value: route.id)
            .select("*")
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Route.self, from: result.data)
    }
    
    func deleteRoute(id: String) async throws {
        _ = try await client
            .from("routes")
            .delete()
            .eq("id", value: id)
            .execute()
    }
    
    // MARK: - Notifications
    
    func fetchNotifications() async throws -> [NotificationModel] {
        guard let userId = try await getCurrentUserId() else {
            throw SupabaseError.userNotFound
        }
        
        do {
            let result = try await client
                .from("notifications")
                .select("*")
                .eq("user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601
            
            return try decoder.decode([NotificationModel].self, from: result.data)
        } catch {
            print("Error fetching notifications: \(error)")
            throw SupabaseError.failedToFetchNotifications
        }
    }
    
    func getUnreadNotificationsCount() async throws -> Int {
        guard let userId = try await getCurrentUserId() else {
            throw SupabaseError.userNotFound
        }
        
        do {
            let result = try await client
                .from("notifications")
                .select("id")
                .eq("user_id", value: userId.uuidString)
                .eq("is_read", value: false)
                .execute()
            
            // Parse the JSON array to count the number of objects
            let json = try JSONSerialization.jsonObject(with: result.data)
            if let array = json as? [[String: Any]] {
                return array.count
            }
            return 0
        } catch let error as PostgrestError {
            // Silently handle the "relation does not exist" error
            if error.code == "42P01" {
                // Notifications table doesn't exist yet - just return 0
                return 0
            }
            
            // For other Postgrest errors, log with a simpler message
            print("Could not retrieve notifications count: \(error.code ?? "unknown")")
            return 0 // Return 0 instead of throwing to prevent UI issues
        } catch {
            // For other errors, log a simpler message without the full error
            print("Error with notifications count")
            return 0 // Return 0 instead of throwing to prevent UI issues
        }
    }
    
    func markNotificationAsRead(_ notificationId: String) async throws {
        do {
            _ = try await client
                .from("notifications")
                .update(["is_read": true])
                .eq("id", value: notificationId)
                .execute()
        } catch {
            print("Error marking notification as read: \(error)")
            throw SupabaseError.failedToUpdateNotification
        }
    }
    
    func markAllNotificationsAsRead() async throws {
        guard let userId = try await getCurrentUserId() else {
            throw SupabaseError.userNotFound
        }
        
        do {
            _ = try await client
                .from("notifications")
                .update(["is_read": true])
                .eq("user_id", value: userId.uuidString)
                .execute()
        } catch {
            print("Error marking all notifications as read: \(error)")
            throw SupabaseError.failedToUpdateNotification
        }
    }
    
    func deleteNotification(_ notificationId: String) async throws {
        do {
            _ = try await client
                .from("notifications")
                .delete()
                .eq("id", value: notificationId)
                .execute()
        } catch {
            print("Error deleting notification: \(error)")
            throw SupabaseError.failedToDeleteNotification
        }
    }
    
    func createNotification(userId: String, title: String, message: String, type: NotificationType, relatedId: String? = nil) async throws {
        // Define a codable struct for the notification insert
        struct NotificationInsert: Codable {
            let user_id: String
            let title: String
            let message: String
            let type: String
            let related_id: String?
            let is_read: Bool
        }
        
        // Create a properly typed notification object
        let notificationData = NotificationInsert(
            user_id: userId,
            title: title,
            message: message,
            type: type.rawValue,
            related_id: relatedId,
            is_read: false
        )
        
        do {
            _ = try await client
                .from("notifications")
                .insert(notificationData)
                .execute()
        } catch {
            print("Error creating notification: \(error)")
            throw SupabaseError.failedToUpdateNotification
        }
    }
    
    // MARK: - Feed Posts
    
    func currentUserId() async -> String? {
        do {
            let session = try await client.auth.session
            return session.user.id.uuidString
        } catch {
            return nil
        }
    }
    
    func fetchFeedPosts(count: Int, offset: Int) async throws -> [Post] {
        // Enable detailed debugging
        let debug = true
        if debug { print("DEBUG: SupabaseService - fetchFeedPosts called with count: \(count), offset: \(offset)") }
        
        do {
            // Create a JSONDecoder with proper date decoding strategy
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            if debug { print("DEBUG: SupabaseService - Executing get_feed_posts RPC with params: count=\(count), offset=\(offset)") }
            
            // Call the get_feed_posts Postgres function using the recommended rpc method
            let response = try await client.rpc(
                "get_feed_posts", 
                params: ["post_count": count, "post_offset": offset]
            ).execute()
            
            if debug { print("DEBUG: SupabaseService - get_feed_posts executed successfully") }
            
            // Data from response is already non-optional, so we don't need conditional binding
            let data = response.data
            
            // Print the raw data size for debugging
            if debug { 
                print("DEBUG: SupabaseService - Received data size: \(data.count) bytes") 
                
                // Attempt to convert the raw data to a JSON string for inspection
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("DEBUG: SupabaseService - Raw JSON response: \(jsonString)")
                    
                    // Print the first-level structure of the JSON
                    if let json = try? JSONSerialization.jsonObject(with: data, options: []) {
                        print("DEBUG: SupabaseService - JSON structure type: \(type(of: json))")
                        
                        // Check if it's an array
                        if let jsonArray = json as? [[String: Any]] {
                            print("DEBUG: SupabaseService - JSON is an array with \(jsonArray.count) elements")
                            
                            // Print the keys of the first element to understand the structure
                            if let firstElement = jsonArray.first {
                                print("DEBUG: SupabaseService - First element keys: \(firstElement.keys.joined(separator: ", "))")
                            }
                        } 
                        // Check if it's a dictionary containing an array
                        else if let jsonDict = json as? [String: Any], 
                                let jsonArray = jsonDict["posts"] as? [[String: Any]] {
                            print("DEBUG: SupabaseService - JSON is a dictionary containing 'posts' array with \(jsonArray.count) elements")
                            
                            // Print the keys of the first element to understand the structure
                            if let firstElement = jsonArray.first {
                                print("DEBUG: SupabaseService - First post element keys: \(firstElement.keys.joined(separator: ", "))")
                            }
                        }
                        else {
                            print("DEBUG: SupabaseService - JSON is not in expected format. Raw structure: \(json)")
                        }
                    }
                }
            }
            
            // ATTEMPT 1: Try to decode the data as an array of Post objects directly
            do {
                if debug { print("DEBUG: SupabaseService - Attempting to decode data as [Post] directly") }
                let posts = try decoder.decode([Post].self, from: data)
                if debug { print("DEBUG: SupabaseService - Successfully decoded \(posts.count) posts as direct [Post] array") }
                return posts
            } catch {
                if debug { 
                    print("DEBUG: SupabaseService - Failed to decode as [Post] directly: \(error)")
                    
                    // Detailed error analysis for Post decoding
                    if let decodingError = error as? DecodingError {
                        switch decodingError {
                        case .keyNotFound(let key, let context):
                            print("DEBUG: SupabaseService - Key '\(key.stringValue)' not found in Post: \(context.debugDescription)")
                            print("DEBUG: SupabaseService - CodingPath: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                        case .typeMismatch(let type, let context):
                            print("DEBUG: SupabaseService - Type mismatch for type '\(type)': \(context.debugDescription)")
                            print("DEBUG: SupabaseService - CodingPath: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                        case .valueNotFound(let type, let context):
                            print("DEBUG: SupabaseService - Value of type '\(type)' not found: \(context.debugDescription)")
                            print("DEBUG: SupabaseService - CodingPath: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                        case .dataCorrupted(let context):
                            print("DEBUG: SupabaseService - Data corrupted: \(context.debugDescription)")
                            print("DEBUG: SupabaseService - CodingPath: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                        @unknown default:
                            print("DEBUG: SupabaseService - Unknown decoding error: \(decodingError)")
                        }
                    }
                    
                    // Examine the Post model structure to compare with JSON
                    print("DEBUG: SupabaseService - Expected Post model properties:")
                    print("DEBUG: SupabaseService - id: String")
                    print("DEBUG: SupabaseService - userId: String")
                    print("DEBUG: SupabaseService - vehicleId: String?")
                    print("DEBUG: SupabaseService - caption: String")
                    print("DEBUG: SupabaseService - imageUrls: [String]")
                    print("DEBUG: SupabaseService - location: CLLocationCoordinate2D?")
                    print("DEBUG: SupabaseService - locationName: String?")
                    print("DEBUG: SupabaseService - createdAt: Date")
                    print("DEBUG: SupabaseService - updatedAt: Date")
                    print("DEBUG: SupabaseService - likeCount: Int")
                    print("DEBUG: SupabaseService - commentCount: Int")
                    print("DEBUG: SupabaseService - isLikedByCurrentUser: Bool")
                    print("DEBUG: SupabaseService - user: User?")
                    print("DEBUG: SupabaseService - vehicle: Vehicle?")
                }
                
                // ATTEMPT 2: Try to decode the data as a JSON object containing a "posts" array
                do {
                    if debug { print("DEBUG: SupabaseService - Attempting to decode data as JSON object with 'posts' array") }
                    let response = try decoder.decode(PostsResponse.self, from: data)
                    if debug { print("DEBUG: SupabaseService - Successfully decoded \(response.posts.count) posts from PostsResponse") }
                    return response.posts
                } catch {
                    if debug { 
                        print("DEBUG: SupabaseService - Failed to decode as PostsResponse: \(error)")
                        
                        if let decodingError = error as? DecodingError {
                            switch decodingError {
                            case .keyNotFound(let key, let context):
                                print("DEBUG: SupabaseService - Key '\(key.stringValue)' not found in PostsResponse: \(context.debugDescription)")
                            case .typeMismatch(let type, let context):
                                print("DEBUG: SupabaseService - Type mismatch for type '\(type)' in PostsResponse: \(context.debugDescription)")
                            default:
                                print("DEBUG: SupabaseService - Other decoding error in PostsResponse: \(decodingError)")
                            }
                        }
                    }
                    
                    // ATTEMPT 3: Last resort - try to parse the JSON manually and decode each post individually
                    do {
                        if debug { print("DEBUG: SupabaseService - Attempting manual JSON parsing as fallback") }
                        var posts: [Post] = []
                        
                        if let json = try? JSONSerialization.jsonObject(with: data, options: []) {
                            if let jsonArray = json as? [[String: Any]] {
                                if debug { print("DEBUG: SupabaseService - Manual parsing: Found JSON array with \(jsonArray.count) elements") }
                                
                                // Try to decode each post individually
                                for (index, postDict) in jsonArray.enumerated() {
                                    do {
                                        let postData = try JSONSerialization.data(withJSONObject: postDict, options: [])
                                        let post = try decoder.decode(Post.self, from: postData)
                                        posts.append(post)
                                        if debug { print("DEBUG: SupabaseService - Successfully decoded post at index \(index)") }
                                    } catch {
                                        if debug { print("DEBUG: SupabaseService - Failed to decode post at index \(index): \(error)") }
                                    }
                                }
                            } else if let jsonDict = json as? [String: Any], let postsArray = jsonDict["posts"] as? [[String: Any]] {
                                if debug { print("DEBUG: SupabaseService - Manual parsing: Found JSON object with 'posts' array containing \(postsArray.count) elements") }
                                
                                // Try to decode each post individually
                                for (index, postDict) in postsArray.enumerated() {
                                    do {
                                        let postData = try JSONSerialization.data(withJSONObject: postDict, options: [])
                                        let post = try decoder.decode(Post.self, from: postData)
                                        posts.append(post)
                                        if debug { print("DEBUG: SupabaseService - Successfully decoded post at index \(index) from posts array") }
                                    } catch {
                                        if debug { print("DEBUG: SupabaseService - Failed to decode post at index \(index) from posts array: \(error)") }
                                    }
                                }
                            } else {
                                if debug { print("DEBUG: SupabaseService - Manual parsing: JSON structure doesn't match expected formats") }
                            }
                        }
                        
                        if debug { print("DEBUG: SupabaseService - Manual parsing completed, recovered \(posts.count) posts") }
                        return posts
                    }
                }
            }
        } catch {
            if debug { print("DEBUG: SupabaseService - RPC call to get_feed_posts failed: \(error)") }
            throw error
        }
    }
    
    func fetchUserPosts(userId: String, limit: Int = 10, offset: Int = 0) async throws -> [Post] {
        let result = try await client.rpc(
            "get_user_posts",
            params: [
                "user_id_val": userId,
                "limit_val": String(limit),
                "offset_val": String(offset)
            ]
        ).execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        // The result is a JSON array of post objects with nested user and vehicle
        let postsData = result.data
        
        guard !postsData.isEmpty else {
            return []
        }
        
        // Process the response to convert it into an array of Post objects
        if let postsArray = try? JSONSerialization.jsonObject(with: postsData) as? [[String: Any]] {
            var posts: [Post] = []
            
            for postDict in postsArray {
                if let postData = try? JSONSerialization.data(withJSONObject: postDict) {
                    if let post = try? decoder.decode(Post.self, from: postData) {
                        posts.append(post)
                    }
                }
            }
            
            return posts
        }
        
        return []
    }
    
    func createPost(_ post: Post) async throws -> Post {
        // Insert the post
        let result = try await client
            .from("posts")
            .insert(post)
            .select()
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        var createdPost = try decoder.decode(Post.self, from: result.data)
        
        // Fetch the detailed post with counts
        let detailedResult = try await client.rpc(
            "get_post_with_details",
            params: ["post_id": createdPost.id]
        ).execute()
        
        // Process the detailed post result
        if let detailedDict = try? JSONSerialization.jsonObject(with: detailedResult.data) as? [String: Any],
           let detailedData = try? JSONSerialization.data(withJSONObject: detailedDict) {
            if let detailedPost = try? decoder.decode(Post.self, from: detailedData) {
                createdPost = detailedPost
            }
        }
        
        return createdPost
    }
    
    func togglePostLike(postId: String) async throws -> Bool {
        let result = try await client.rpc(
            "toggle_post_like",
            params: ["post_id_val": postId]
        ).execute()
        
        // The result is a boolean indicating if the post is now liked (true) or unliked (false)
        if let isLiked = try? JSONDecoder().decode(Bool.self, from: result.data) {
            return isLiked
        }
        
        throw NSError(domain: "SupabaseService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to toggle post like"])
    }
    
    func fetchPostComments(postId: String, limit: Int = 20, offset: Int = 0) async throws -> [PostComment] {
        let result = try await client
            .from("post_comments")
            .select("""
                *,
                user:users(id, email, profile)
            """)
            .eq("post_id", value: postId)
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        return try decoder.decode([PostComment].self, from: result.data)
    }
    
    func addPostComment(postId: String, content: String) async throws -> PostComment {
        guard let userId = try await getCurrentUserId()?.uuidString else {
            throw SupabaseError.notAuthenticated
        }
        
        let comment = PostComment(
            id: UUID().uuidString,
            postId: postId,
            userId: userId,
            content: content,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let result = try await client
            .from("post_comments")
            .insert(comment)
            .select("""
                *,
                user:users(id, email, profile)
            """)
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        return try decoder.decode(PostComment.self, from: result.data)
    }
    
    func deletePostComment(commentId: String) async throws {
        _ = try await client
            .from("post_comments")
            .delete()
            .eq("id", value: commentId)
            .execute()
    }
    
    func subscribeToFeed(onEvent: @escaping (FeedUpdateEvent) -> Void) async throws -> RealtimeChannelV2 {
        let channel = client.realtimeV2
            .channel("public:posts")
        
        // Subscribe to post inserts
        _ = channel.onPostgresChange(
            InsertAction.self,
            schema: "public",
            table: "posts"
        ) { insert in
            if let post = try? insert.record.decode(as: Post.self) {
                Task { @MainActor in
                    onEvent(.postCreated(post))
                }
            }
        }
        
        // Subscribe to post updates
        _ = channel.onPostgresChange(
            UpdateAction.self,
            schema: "public",
            table: "posts"
        ) { update in
            if let post = try? update.record.decode(as: Post.self) {
                Task { @MainActor in
                    onEvent(.postUpdated(post))
                }
            }
        }
        
        // Subscribe to post deletions
        _ = channel.onPostgresChange(
            DeleteAction.self,
            schema: "public",
            table: "posts"
        ) { delete in
            if let post = try? delete.oldRecord.decode(as: Post.self) {
                Task { @MainActor in
                    onEvent(.postDeleted(post.id))
                }
            }
        }
        
        // Subscribe to post_likes inserts
        _ = channel.onPostgresChange(
            InsertAction.self,
            schema: "public",
            table: "post_likes"
        ) { insert in
            if let postLike = try? insert.record.decode(as: PostLike.self) {
                let postId = postLike.postId
                Task {
                    do {
                        let count = try await self.getPostLikeCount(postId: postId)
                        await MainActor.run {
                            onEvent(.postLiked(postId, count))
                        }
                    } catch {
                        print("Error getting post like count: \(error)")
                    }
                }
            }
        }
        
        // Subscribe to post_likes deletions
        _ = channel.onPostgresChange(
            DeleteAction.self,
            schema: "public",
            table: "post_likes"
        ) { delete in
            if let postLike = try? delete.oldRecord.decode(as: PostLike.self) {
                let postId = postLike.postId
                Task {
                    do {
                        let count = try await self.getPostLikeCount(postId: postId)
                        await MainActor.run {
                            onEvent(.postLiked(postId, count))
                        }
                    } catch {
                        print("Error getting post like count: \(error)")
                    }
                }
            }
        }
        
        // Subscribe to post_comments inserts
        _ = channel.onPostgresChange(
            InsertAction.self,
            schema: "public",
            table: "post_comments"
        ) { insert in
            if let comment = try? insert.record.decode(as: PostComment.self) {
                let postId = comment.postId
                Task {
                    do {
                        let count = try await self.getPostCommentCount(postId: postId)
                        await MainActor.run {
                            onEvent(.postCommented(postId, count))
                        }
                    } catch {
                        print("Error getting post comment count: \(error)")
                    }
                }
            }
        }
        
        await channel.subscribe()
        
        return channel
    }
    
    private func getPostLikeCount(postId: String) async throws -> Int {
        let result = try await client
            .from("post_likes")
            .select("*", head: true, count: CountOption.exact)
            .eq("post_id", value: postId)
            .execute()
        
        return result.count ?? 0
    }
    
    private func getPostCommentCount(postId: String) async throws -> Int {
        let result = try await client
            .from("post_comments")
            .select("*", head: true, count: CountOption.exact)
            .eq("post_id", value: postId)
            .execute()
        
        return result.count ?? 0
    }
    
    // MARK: - Debug Helpers
    
    func debugSupabaseConnection() async -> Bool {
        print("DEBUG: SupabaseService - Testing Supabase connection")
        
        do {
            // Test 1: Try to get the auth session (doesn't require actual data fetch)
            print("DEBUG: SupabaseService - Testing auth connection")
            let session = try await client.auth.session
            print("DEBUG: SupabaseService - Auth connection successful, user ID: \(session.user.id)")
            
            // Test 2: Try a simple database query that should always work
            print("DEBUG: SupabaseService - Testing database connection")
            _ = try await client.rpc("test_connection", params: [String: String]()).execute()
            print("DEBUG: SupabaseService - Database RPC connection successful")
            
            // Test 3: Try a simple storage access
            print("DEBUG: SupabaseService - Testing storage connection")
            let buckets = try await client.storage.listBuckets()
            print("DEBUG: SupabaseService - Storage connection successful, found \(buckets.count) buckets")
            
            print("DEBUG: SupabaseService - All connection tests passed!")
            return true
        } catch {
            print("DEBUG: SupabaseService - Connection test failed: \(error)")
            
            // Get more detailed error information
            let nsError = error as NSError
            print("DEBUG: SupabaseService - Error domain: \(nsError.domain), code: \(nsError.code)")
            if let errorDescription = nsError.localizedDescription as String? {
                print("DEBUG: SupabaseService - Error description: \(errorDescription)")
            }
            
            return false
        }
    }
    
    private func inspectFeedPostsJson(jsonString: String) {
        print("DEBUG: inspectFeedPostsJson - Starting JSON inspection")
        
        // Try to convert JSON string to dictionary
        guard let jsonData = jsonString.data(using: .utf8) else {
            print("DEBUG: inspectFeedPostsJson - Failed to convert string to data")
            return
        }
        
        do {
            // First check if it's an array
            if let postsArray = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] {
                print("DEBUG: inspectFeedPostsJson - JSON is an array with \(postsArray.count) items")
                
                // Inspect the first post in detail
                if let firstPost = postsArray.first {
                    inspectPostObject(firstPost, prefix: "First post")
                }
            } 
            // Then check if it's an object containing an array
            else if let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                print("DEBUG: inspectFeedPostsJson - JSON is an object with \(jsonObject.count) top-level keys")
                
                // Print the top-level keys
                print("DEBUG: inspectFeedPostsJson - Top-level keys: \(jsonObject.keys.joined(separator: ", "))")
                
                // Look for array values
                for (key, value) in jsonObject {
                    if let postsArray = value as? [[String: Any]] {
                        print("DEBUG: inspectFeedPostsJson - Found array under key '\(key)' with \(postsArray.count) items")
                        
                        // Inspect the first post in detail
                        if let firstPost = postsArray.first {
                            inspectPostObject(firstPost, prefix: "First post in '\(key)'")
                        }
                    }
                }
            } else {
                print("DEBUG: inspectFeedPostsJson - JSON is neither an array nor an object. Format unknown.")
            }
        } catch {
            print("DEBUG: inspectFeedPostsJson - Error parsing JSON: \(error)")
        }
    }
    
    private func inspectPostObject(_ post: [String: Any], prefix: String) {
        print("DEBUG: \(prefix) - Keys found: \(post.keys.joined(separator: ", "))")
        
        // Check for required Post model properties
        let requiredKeys = ["id", "user_id", "caption", "image_urls", "created_at", "updated_at"]
        let missingKeys = requiredKeys.filter { !post.keys.contains($0) }
        
        if !missingKeys.isEmpty {
            print("DEBUG: \(prefix) - MISSING REQUIRED KEYS: \(missingKeys.joined(separator: ", "))")
        }
        
        // Check image_urls type
        if let imageUrls = post["image_urls"] {
            print("DEBUG: \(prefix) - image_urls is of type: \(type(of: imageUrls))")
            
            if let imageUrlsArray = imageUrls as? [String] {
                print("DEBUG: \(prefix) - image_urls is an array with \(imageUrlsArray.count) items")
            } else {
                print("DEBUG: \(prefix) - image_urls is NOT an array of strings - THIS IS A PROBLEM")
            }
        }
        
        // Check user object
        if let user = post["user"] as? [String: Any] {
            print("DEBUG: \(prefix) - user object found with keys: \(user.keys.joined(separator: ", "))")
            
            // Check profile object in user
            if let profile = user["profile"] as? [String: Any] {
                print("DEBUG: \(prefix) - profile object found with keys: \(profile.keys.joined(separator: ", "))")
            } else {
                print("DEBUG: \(prefix) - profile object NOT found in user - THIS IS A PROBLEM")
            }
        } else {
            print("DEBUG: \(prefix) - user object NOT found - THIS IS A PROBLEM")
        }
        
        // Check location format
        if let location = post["location"] as? String {
            print("DEBUG: \(prefix) - location is a string: \(location)")
            
            // Check if it matches the expected format (lat,long)
            let pattern = "\\([+-]?\\d+(\\.\\d+)?,[+-]?\\d+(\\.\\d+)?\\)"
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(location: 0, length: location.utf16.count)
                if regex.firstMatch(in: location, range: range) != nil {
                    print("DEBUG: \(prefix) - location string matches expected format")
                } else {
                    print("DEBUG: \(prefix) - location string does NOT match expected format - THIS IS A PROBLEM")
                }
            }
        }
    }
    
    // MARK: - Stories
    
    func fetchActiveStories() async throws -> [Story] {
        guard let userId = try await getCurrentUserId() else {
            throw SupabaseError.userNotFound
        }
        
        do {
            let result = try await client.rpc(
                "get_active_stories",
                params: ["p_user_id": userId.uuidString]
            ).execute()
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601
            
            return try decoder.decode([Story].self, from: result.data)
        } catch {
            print("Error fetching active stories: \(error)")
            throw SupabaseError.failedToFetchStories
        }
    }
    
    func fetchUserStories(userId: UUID) async throws -> [Story] {
        guard let currentUserId = try await getCurrentUserId() else {
            throw SupabaseError.userNotFound
        }
        
        do {
            let result = try await client.rpc(
                "get_user_stories",
                params: [
                    "p_user_id": userId.uuidString,
                    "p_viewer_id": currentUserId.uuidString
                ]
            ).execute()
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601
            
            return try decoder.decode([Story].self, from: result.data)
        } catch {
            print("Error fetching user stories: \(error)")
            throw SupabaseError.failedToFetchStories
        }
    }
    
    func createStory(userId: UUID, mediaUrl: String, mediaType: Story.MediaType, caption: String?, location: CLLocationCoordinate2D?, locationName: String?) async throws -> UUID {
        // Create parameters for the RPC call
        var params: [String: String] = [
            "p_user_id": userId.uuidString,
            "p_media_url": mediaUrl,
            "p_media_type": mediaType.rawValue
        ]
        
        if let caption = caption {
            params["p_caption"] = caption
        }
        
        if let location = location {
            // Format as PostgreSQL point: "(longitude,latitude)"
            params["p_location"] = "(\(location.longitude),\(location.latitude))"
        }
        
        if let locationName = locationName {
            params["p_location_name"] = locationName
        }
        
        do {
            let result = try await client.rpc(
                "create_story",
                params: params
            ).execute()
            
            // The result should contain the UUID of the new story
            guard let storyIdString = try? JSONDecoder().decode(String.self, from: result.data),
                  let storyId = UUID(uuidString: storyIdString) else {
                throw SupabaseError.failedToCreateStory
            }
            
            return storyId
        } catch {
            print("Error creating story: \(error)")
            throw SupabaseError.failedToCreateStory
        }
    }
    
    func markStoryAsViewed(storyId: UUID) async throws -> Bool {
        guard let userId = try await getCurrentUserId() else {
            throw SupabaseError.userNotFound
        }
        
        do {
            let result = try await client.rpc(
                "mark_story_as_viewed",
                params: [
                    "p_story_id": storyId.uuidString,
                    "p_viewer_id": userId.uuidString
                ]
            ).execute()
            
            // The function returns a boolean indicating success
            return try JSONDecoder().decode(Bool.self, from: result.data)
        } catch {
            print("Error marking story as viewed: \(error)")
            throw SupabaseError.failedToUpdateStory
        }
    }
    
    func deleteStory(storyId: UUID) async throws -> Bool {
        guard let userId = try await getCurrentUserId() else {
            throw SupabaseError.userNotFound
        }
        
        do {
            let result = try await client.rpc(
                "delete_story",
                params: [
                    "p_story_id": storyId.uuidString,
                    "p_user_id": userId.uuidString
                ]
            ).execute()
            
            // The function returns a boolean indicating success
            return try JSONDecoder().decode(Bool.self, from: result.data)
        } catch {
            print("Error deleting story: \(error)")
            throw SupabaseError.failedToDeleteStory
        }
    }
    
    // MARK: - Story Media Upload
    
    private func uploadStoryMedia(data: Data, fileName: String, contentType: String) async throws -> String {
        let filePath = "\(UUID().uuidString)-\(fileName)"
        
        // Ensure the stories bucket exists
        do {
            try await ensureStorageBucketExists(bucketName: "stories")
        } catch {
            print("Error ensuring stories bucket exists: \(error)")
            throw SupabaseError.mediaUploadFailed
        }
        
        do {
            let result = try await client.storage
                .from("stories")
                .upload(
                    filePath,
                    data: data,
                    options: FileOptions(contentType: contentType)
                )
            
            // Get the public URL for the uploaded media
            let publicURL = try client.storage.from("stories").getPublicURL(path: result.path)
            return publicURL.absoluteString
        } catch {
            print("Error uploading story media: \(error)")
            throw SupabaseError.mediaUploadFailed
        }
    }
    
    func uploadStoryImage(image: UIImage) async throws -> String {
        guard let userId = try await getCurrentUserId() else {
            throw SupabaseError.userNotFound
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw SupabaseError.imageUploadFailed
        }
        
        let filePath = "\(userId.uuidString)-\(Date().timeIntervalSince1970).jpg"
        
        do {
            try await ensureStorageBucketExists(bucketName: "stories")
        } catch {
            print("Error ensuring stories bucket exists: \(error)")
            throw SupabaseError.imageUploadFailed
        }
        
        do {
            let result = try await client.storage
                .from("stories")
                .upload(
                    filePath,
                    data: imageData,
                    options: FileOptions(contentType: "image/jpeg")
                )
            
            // Get the public URL for the uploaded image
            let publicURL = try client.storage.from("stories").getPublicURL(path: result.path)
            return publicURL.absoluteString
        } catch {
            print("Error uploading story image: \(error)")
            throw SupabaseError.imageUploadFailed
        }
    }
    
    func uploadStoryVideo(videoURL: URL) async throws -> String {
        guard let userId = try await getCurrentUserId() else {
            throw SupabaseError.userNotFound
        }
        
        guard let videoData = try? Data(contentsOf: videoURL) else {
            throw SupabaseError.videoUploadFailed
        }
        
        let filePath = "\(userId.uuidString)-\(Date().timeIntervalSince1970).mp4"
        
        do {
            try await ensureStorageBucketExists(bucketName: "stories")
        } catch {
            print("Error ensuring stories bucket exists: \(error)")
            throw SupabaseError.imageUploadFailed
        }
        
        do {
            let result = try await client.storage
                .from("stories")
                .upload(
                    filePath,
                    data: videoData,
                    options: FileOptions(contentType: "video/mp4")
                )
            
            // Get the public URL for the uploaded video
            let publicURL = try client.storage.from("stories").getPublicURL(path: result.path)
            return publicURL.absoluteString
        } catch {
            print("Error uploading story video: \(error)")
            throw SupabaseError.imageUploadFailed
        }
    }
    
    // Helper method to ensure a storage bucket exists
    private func ensureStorageBucketExists(bucketName: String) async throws {
        do {
            // Check if the bucket exists
            let buckets = try await client.storage.listBuckets()
            let bucketExists = buckets.contains { $0.name == bucketName }
            
            if !bucketExists {
                // Create the bucket if it doesn't exist
                try await client.storage.createBucket(bucketName, options: BucketOptions(public: true))
            }
        } catch {
            print("Error checking/creating bucket: \(error)")
            throw error
        }
    }
}

// MARK: - Models

struct MeetAttendee: Codable {
    let meetId: String
    let userId: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case meetId = "meet_id"
        case userId = "user_id"
        case createdAt = "created_at"
    }
}

struct PostLike: Codable {
    let id: String
    let postId: String
    let userId: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case postId = "post_id"
        case userId = "user_id"
        case createdAt = "created_at"
    }
}

// Helper struct for decoding JSON object containing posts array
private struct PostsResponse: Codable {
    let posts: [Post]
} 

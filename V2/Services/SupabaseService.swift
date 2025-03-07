import Foundation
import Supabase
import UIKit

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
        return try JSONDecoder().decode([Meet].self, from: result.data)
    }
    
    func createMeet(_ meet: Meet) async throws -> Meet {
        let result = try await client
            .from("meets")
            .insert(meet)
            .select("*")
            .single()
            .execute()
        
        return try JSONDecoder().decode(Meet.self, from: result.data)
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
        
        return try JSONDecoder().decode(MeetParticipant.self, from: result.data)
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
        
        return try JSONDecoder().decode([ChatMessage].self, from: result.data)
    }
    
    func sendMessage(_ message: ChatMessage) async throws -> ChatMessage {
        let result = try await client
            .from("chat_messages")
            .insert(message)
            .select("*")
            .single()
            .execute()
        
        return try JSONDecoder().decode(ChatMessage.self, from: result.data)
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
        
        return try JSONDecoder().decode([Route].self, from: result.data)
    }
    
    func fetchRoutesByCreator() async throws -> [Route] {
        let session = try await client.auth.session
        let userId = session.user.id
        
        let result = try await client
            .from("routes")
            .select("*")
            .eq("creator_id", value: userId)
            .execute()
        
        return try JSONDecoder().decode([Route].self, from: result.data)
    }
    
    func fetchRoutesByMeet(meetId: String) async throws -> [Route] {
        let result = try await client
            .from("routes")
            .select("*")
            .eq("meet_id", value: meetId)
            .execute()
        
        return try JSONDecoder().decode([Route].self, from: result.data)
    }
    
    func fetchRoute(id: String) async throws -> Route {
        let result = try await client
            .from("routes")
            .select("*")
            .eq("id", value: id)
            .single()
            .execute()
        
        return try JSONDecoder().decode(Route.self, from: result.data)
    }
    
    func createRoute(_ route: Route) async throws -> Route {
        let result = try await client
            .from("routes")
            .insert(route)
            .select("*")
            .single()
            .execute()
        
        return try JSONDecoder().decode(Route.self, from: result.data)
    }
    
    func updateRoute(_ route: Route) async throws -> Route {
        let result = try await client
            .from("routes")
            .update(route)
            .eq("id", value: route.id)
            .select("*")
            .single()
            .execute()
        
        return try JSONDecoder().decode(Route.self, from: result.data)
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
        } catch {
            print("Error counting unread notifications: \(error)")
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

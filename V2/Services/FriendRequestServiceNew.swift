import Foundation
import Supabase

class FriendRequestService {
    private let supabaseService: SupabaseService
    
    init(supabaseService: SupabaseService) {
        self.supabaseService = supabaseService
    }
    
    func sendFriendRequest(to email: String) async throws {
        guard let currentUser = try await supabaseService.getCurrentUser() else {
            throw SupabaseError.userNotFound
        }
        
        let currentUserId = currentUser.id.uuidString
        
        // Find target user by email
        let targetUser: User = try await supabaseService.client
            .from("users")
            .select()
            .eq("email", value: email)
            .single()
            .execute()
            .value
        
        // Check if they're already friends (assuming we have this info from the database)
        // We need to fetch the current user's full profile to access the friends array
        let currentUserProfile: User = try await supabaseService.client
            .from("users")
            .select()
            .eq("id", value: currentUserId)
            .single()
            .execute()
            .value
            
        if currentUserProfile.friends.contains(targetUser.id) {
            throw SupabaseError.failedToCreateUser
        }
        
        // Check if a request has already been sent
        do {
            let _ = try await supabaseService.client
                .from("friend_requests")
                .select()
                .eq("sender_id", value: currentUserId)
                .eq("receiver_id", value: targetUser.id)
                .eq("status", value: "pending")
                .single()
                .execute()
                
            // If we reach here, it means the query succeeded and a request exists
            throw SupabaseError.failedToCreateUser
        } catch {
            // If the error is because no rows were found, we can continue
            // Otherwise, propagate the error
            if error.localizedDescription.contains("no rows returned") {
                // This is the expected error when no request exists
                // Continue with creating a new request
            } else {
                // This is some other error we should propagate
                throw error
            }
        }
        
        // Create friend request object using Encodable-compatible type
        let requestData = FriendRequestData(
            id: UUID().uuidString,
            sender_id: currentUserId,
            receiver_id: targetUser.id,
            status: "pending",
            created_at: Date().ISO8601Format(),
            timestamp: Date().ISO8601Format()
        )
        
        try await supabaseService.client
            .from("friend_requests")
            .insert(requestData)
            .execute()
    }
    
    func acceptFriendRequest(from userId: String) async throws {
        guard let currentUser = try await supabaseService.getCurrentUser() else {
            throw SupabaseError.userNotFound
        }
        
        let currentUserId = currentUser.id.uuidString
        
        // Find the pending friend request
        do {
            // Find the request that matches criteria
            let response = try await supabaseService.client
                .from("friend_requests")
                .select()
                .eq("sender_id", value: userId)
                .eq("receiver_id", value: currentUserId)
                .eq("status", value: "pending")
                .single()
                .execute()
            
            // Extract request ID directly from the response JSON
            guard let json = try? JSONSerialization.jsonObject(with: response.data, options: []) as? [String: Any],
                  let requestId = json["id"] as? String else {
                throw SupabaseError.failedToCreateUser
            }
            
            // Update request status
            try await supabaseService.client
                .from("friend_requests")
                .update(["status": "accepted"])
                .eq("id", value: requestId)
                .execute()
            
            // Update both users' friends lists
            // First get the current user's friends list
            let currentUserResponse = try await supabaseService.client
                .from("users")
                .select("friends")
                .eq("id", value: currentUserId)
                .single()
                .execute()
                
            var currentUserFriends: [String] = []
            if let json = try? JSONSerialization.jsonObject(with: currentUserResponse.data, options: []) as? [String: Any],
               let friends = json["friends"] as? [String] {
                currentUserFriends = friends
            }
            
            // Add the new friend if not already in the list
            if !currentUserFriends.contains(userId) {
                currentUserFriends.append(userId)
            }
            
            // Update the current user's friends list
            try await supabaseService.client
                .from("users")
                .update(["friends": currentUserFriends])
                .eq("id", value: currentUserId)
                .execute()
            
            // Now do the same for the other user
            let otherUserResponse = try await supabaseService.client
                .from("users")
                .select("friends")
                .eq("id", value: userId)
                .single()
                .execute()
                
            var otherUserFriends: [String] = []
            if let json = try? JSONSerialization.jsonObject(with: otherUserResponse.data, options: []) as? [String: Any],
               let friends = json["friends"] as? [String] {
                otherUserFriends = friends
            }
            
            // Add the current user if not already in the list
            if !otherUserFriends.contains(currentUserId) {
                otherUserFriends.append(currentUserId)
            }
            
            // Update the other user's friends list
            try await supabaseService.client
                .from("users")
                .update(["friends": otherUserFriends])
                .eq("id", value: userId)
                .execute()
        } catch {
            throw error
        }
    }
    
    func rejectFriendRequest(from userId: String) async throws {
        guard let currentUser = try await supabaseService.getCurrentUser() else {
            throw SupabaseError.userNotFound
        }
        
        let currentUserId = currentUser.id.uuidString
        
        // Find the pending friend request
        do {
            // Find the request that matches criteria
            let response = try await supabaseService.client
                .from("friend_requests")
                .select()
                .eq("sender_id", value: userId)
                .eq("receiver_id", value: currentUserId)
                .eq("status", value: "pending")
                .single()
                .execute()
            
            // Extract request ID directly from the response JSON
            guard let json = try? JSONSerialization.jsonObject(with: response.data, options: []) as? [String: Any],
                  let requestId = json["id"] as? String else {
                throw SupabaseError.failedToCreateUser
            }
            
            // Update request status
            try await supabaseService.client
                .from("friend_requests")
                .update(["status": "rejected"])
                .eq("id", value: requestId)
                .execute()
        } catch {
            throw error
        }
    }
    
    func getFriendRequests() async throws -> [[String: Any]] {
        guard let currentUser = try await supabaseService.getCurrentUser() else {
            throw SupabaseError.userNotFound
        }
        
        let currentUserId = currentUser.id.uuidString
        
        do {
            let response = try await supabaseService.client
                .from("friend_requests")
                .select("*, sender:users(*)")
                .eq("receiver_id", value: currentUserId)
                .eq("status", value: "pending")
                .order("created_at", ascending: false)
                .execute()
            
            // Parse the raw data into JSON
            if let json = try? JSONSerialization.jsonObject(with: response.data, options: []) as? [[String: Any]] {
                return json
            }
            return []
        } catch {
            print("Error fetching friend requests: \(error)")
            return []
        }
    }
}

// Helper struct for Encodable data
struct FriendRequestData: Encodable {
    let id: String
    let sender_id: String
    let receiver_id: String
    let status: String
    let created_at: String
    let timestamp: String
} 
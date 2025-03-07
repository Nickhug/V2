import Foundation
import Supabase
import SwiftUI
import CoreLocation

class FindFriendsViewModel: ObservableObject {
    // Published properties for UI state
    @Published var searchQuery: String = ""
    @Published var searchResults: [User] = []
    @Published var suggestedFriends: [User] = []
    @Published var nearbyUsers: [User] = []
    @Published var popularUsers: [User] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var successMessage: String? = nil
    @Published var pendingRequests: [FriendRequestViewModel] = []
    
    // Dependencies
    private let supabase: SupabaseClient
    private let userService: UserService
    private let friendRequestService: FriendRequestService
    private let locationManager = LocationManager()
    
    // Current user reference
    private var currentUser: User?
    
    init() {
        self.supabase = SupabaseConfig.client
        self.userService = UserService.shared
        self.friendRequestService = FriendRequestService(supabaseService: SupabaseService.shared)
        
        Task {
            await loadCurrentUser()
            await fetchSuggestedFriends()
            await fetchPendingRequests()
            if let location = locationManager.location {
                await findNearbyUsers(location: location)
            } else {
                locationManager.requestLocation()
            }
            await fetchPopularUsers()
        }
    }
    
    // MARK: - Public Methods
    
    /// Search for users by name or email
    func searchUsers() async {
        guard !searchQuery.isEmpty else {
            await MainActor.run {
                searchResults = []
            }
            return
        }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let results = try await performSearch(query: searchQuery)
            
            await MainActor.run {
                searchResults = results
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to search users: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    /// Send a friend request to a user
    func sendFriendRequest(to user: User) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            successMessage = nil
        }
        
        do {
            try await friendRequestService.sendFriendRequest(to: user.email)
            
            await MainActor.run {
                successMessage = "Friend request sent to \(user.profile.name)"
                isLoading = false
            }
        } catch {
            let errorMsg: String
            
            if let friendError = error as? FriendError {
                errorMsg = friendError.localizedDescription
            } else {
                errorMsg = "Failed to send friend request: \(error.localizedDescription)"
            }
            
            await MainActor.run {
                errorMessage = errorMsg
                isLoading = false
            }
        }
    }
    
    /// Load pending friend requests
    func fetchPendingRequests() async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let requests = try await friendRequestService.getFriendRequests()
            
            // Convert raw dictionary responses to view models
            var localViewModels: [FriendRequestViewModel] = []
            
            for request in requests {
                if let id = request["id"] as? String,
                   let senderId = request["sender_id"] as? String,
                   let receiverId = request["receiver_id"] as? String,
                   let status = request["status"] as? String,
                   let createdAtString = request["created_at"] as? String,
                   let senderDict = request["sender"] as? [String: Any] {
                    
                    // Convert sender dictionary to User
                    let senderData = try JSONSerialization.data(withJSONObject: senderDict)
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    decoder.dateDecodingStrategy = .iso8601
                    
                    do {
                        let sender = try decoder.decode(User.self, from: senderData)
                        let dateFormatter = ISO8601DateFormatter()
                        if let createdAt = dateFormatter.date(from: createdAtString) {
                            let viewModel = FriendRequestViewModel(
                                id: UUID(uuidString: id) ?? UUID(),
                                senderId: senderId,
                                receiverId: receiverId,
                                status: status,
                                timestamp: createdAt,
                                sender: sender
                            )
                            localViewModels.append(viewModel)
                        }
                    } catch {
                        print("Error decoding sender for request \(id): \(error)")
                    }
                }
            }
            
            // Create a copy of viewModels to use in the MainActor context
            let finalViewModels = localViewModels
            
            await MainActor.run {
                pendingRequests = finalViewModels
                isLoading = false
            }
        } catch {
            print("Error fetching friend requests: \(error)")
            await MainActor.run {
                pendingRequests = []
                isLoading = false
            }
        }
    }
    
    /// Accept a friend request
    func acceptFriendRequest(from user: User) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            try await friendRequestService.acceptFriendRequest(from: user.id)
            
            await MainActor.run {
                successMessage = "You are now friends with \(user.profile.name)"
                isLoading = false
                
                // Refresh the requests list
                Task {
                    await fetchPendingRequests()
                    await fetchSuggestedFriends()
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to accept friend request: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    /// Reject a friend request
    func rejectFriendRequest(from user: User) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            try await friendRequestService.rejectFriendRequest(from: user.id)
            
            await MainActor.run {
                successMessage = "Friend request rejected"
                isLoading = false
                
                // Refresh the requests list
                Task {
                    await fetchPendingRequests()
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to reject friend request: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    /// Refresh all data
    func refreshAll() async {
        await MainActor.run {
            isLoading = true
        }
        
        await loadCurrentUser()
        await fetchSuggestedFriends()
        await fetchPendingRequests()
        if let location = locationManager.location {
            await findNearbyUsers(location: location)
        }
        await fetchPopularUsers()
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    // MARK: - Private Methods
    
    /// Load the current user
    private func loadCurrentUser() async {
        do {
            guard let userId = try await userService.currentUserId else {
                return
            }
            
            let user = try await userService.fetchUser(id: userId)
            await MainActor.run {
                self.currentUser = user
            }
        } catch {
            print("Error loading current user: \(error)")
        }
    }
    
    /// Fetch suggested friends (users who might be relevant to the current user)
    private func fetchSuggestedFriends() async {
        guard let currentUser = self.currentUser else { return }
        
        do {
            // In a real implementation, we would use a recommendation algorithm
            // For now, we'll get random users who aren't already friends
            let response = try await supabase
                .from("users")
                .select()
                .not("id", operator: .eq, value: currentUser.id)
                .not("id", operator: .in, value: currentUser.friends)
                .limit(10)
                .execute()
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601
            
            let users = try decoder.decode([User].self, from: response.data)
            
            await MainActor.run {
                suggestedFriends = users
            }
        } catch {
            print("Error fetching suggested friends: \(error)")
        }
    }
    
    /// Find users who are geographically close to the current user
    private func findNearbyUsers(location: CLLocation) async {
        guard let currentUser = self.currentUser else { return }
        
        // Define a search radius (in degrees, roughly 50km)
        let searchRadius = 0.5
        
        do {
            // Query users within the radius
            let response = try await supabase
                .from("users")
                .select()
                .not("id", operator: .eq, value: currentUser.id)
                .not("id", operator: .in, value: currentUser.friends)
                .gte("profile->>location->>latitude", value: location.coordinate.latitude - searchRadius)
                .lte("profile->>location->>latitude", value: location.coordinate.latitude + searchRadius)
                .gte("profile->>location->>longitude", value: location.coordinate.longitude - searchRadius)
                .lte("profile->>location->>longitude", value: location.coordinate.longitude + searchRadius)
                .limit(10)
                .execute()
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601
            
            let users = try decoder.decode([User].self, from: response.data)
            
            // Filter and sort by distance
            let sortedUsers = users.sorted { user1, user2 in
                let location1 = CLLocation(
                    latitude: user1.profile.location.latitude,
                    longitude: user1.profile.location.longitude
                )
                let location2 = CLLocation(
                    latitude: user2.profile.location.latitude,
                    longitude: user2.profile.location.longitude
                )
                
                return location1.distance(from: location) < location2.distance(from: location)
            }
            
            await MainActor.run {
                nearbyUsers = sortedUsers
            }
        } catch {
            print("Error finding nearby users: \(error)")
        }
    }
    
    /// Fetch popular users (users with many friends or activities)
    private func fetchPopularUsers() async {
        guard let currentUser = self.currentUser else { return }
        
        do {
            // In a real app, we might have a more complex popularity algorithm
            // For now, we'll use users with the most friends
            let response = try await supabase
                .from("users")
                .select()
                .not("id", operator: .eq, value: currentUser.id)
                .not("id", operator: .in, value: currentUser.friends)
                .order("friends", ascending: false)
                .limit(10)
                .execute()
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601
            
            let users = try decoder.decode([User].self, from: response.data)
            
            await MainActor.run {
                popularUsers = users
            }
        } catch {
            print("Error fetching popular users: \(error)")
        }
    }
    
    /// Perform a search for users
    private func performSearch(query: String) async throws -> [User] {
        guard let currentUser = self.currentUser else { return [] }
        
        // Search by name or email
        let response = try await supabase
            .from("users")
            .select()
            .not("id", operator: .eq, value: currentUser.id)
            .not("id", operator: .in, value: currentUser.friends)
            .or("profile->>name.ilike.%\(query)%,email.ilike.%\(query)%")
            .limit(20)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode([User].self, from: response.data)
    }
    
    /// Check if a user already has a pending friend request
    func hasPendingRequest(to userId: String) -> Bool {
        // Check if there's a request with the current user as sender and the specified user as receiver
        return false // In a real implementation, we would check against a requests array
    }
} 
import SwiftUI

@MainActor
class UserViewModel: ObservableObject {
    @Published var currentUser: User
    @Published var friends: [User]
    @Published var friendRequests: [User]
    @Published var isLoading = false
    @Published var error: Error?
    
    init() {
        // Using mock data for now
        self.currentUser = User.mockCurrentUser
        self.friends = User.mockFriends
        self.friendRequests = []
    }
    
    func updateProfile(_ profile: User.Profile) async {
        isLoading = true
        // Simulate API call
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        currentUser.profile = profile
        isLoading = false
    }
    
    func addVehicle(_ vehicle: Vehicle) async {
        isLoading = true
        // Simulate API call
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        currentUser.vehicles.append(vehicle)
        isLoading = false
    }
    
    func sendFriendRequest(userId: String) async {
        isLoading = true
        // Simulate API call
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        // In real app, this would send a friend request
        isLoading = false
    }
    
    func acceptFriendRequest(userId: String) async {
        isLoading = true
        // Simulate API call
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        if let index = friendRequests.firstIndex(where: { $0.id == userId }) {
            let user = friendRequests.remove(at: index)
            friends.append(user)
            currentUser.friends.append(user.id)
        }
        isLoading = false
    }
    
    func removeFriend(userId: String) async {
        isLoading = true
        // Simulate API call
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        friends.removeAll { $0.id == userId }
        currentUser.friends.removeAll { $0 == userId }
        isLoading = false
    }
} 
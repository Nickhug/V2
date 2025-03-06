import SwiftUI
import MapKit
import Foundation
import CoreLocation
import Supabase

enum MeetError: LocalizedError {
    case networkError
    case authenticationError
    case invalidData
    case imageUploadError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Network error occurred. Please check your connection."
        case .authenticationError:
            return "Authentication error. Please sign in again."
        case .invalidData:
            return "Invalid data received from server."
        case .imageUploadError:
            return "Image upload error. Please try again later."
        case .unknown:
            return "An unknown error occurred."
        }
    }
}

@MainActor
class MeetViewModel: ObservableObject {
    @Published var meets: [Meet] = []
    @Published var users: [User] = []
    @Published var currentUser: User?
    @Published var friendRequests: [FriendRequestRow] = []
    @Published var selectedMeet: Meet?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var userMeets: [Meet] = [] // Meets created by the user
    @Published var attendingMeets: [Meet] = [] // Meets the user is attending
    @Published var upcomingMeets: [Meet] = []
    @Published var nearbyMeets: [Meet] = []
    @Published var notificationCount: Int = 0
    @Published var participants: [MeetParticipant] = []
    @Published var comments: [MeetComment] = []
    @Published var followers: [User] = []
    @Published var recentAchievements: [Achievement] = []
    @Published var recentActivity: [Activity] = []
    
    private let supabase = SupabaseService.shared
    private let userService = UserService.shared
    private var meetsSubscription: RealtimeChannelV2?
    private var commentsSubscriptions: [String: RealtimeChannelV2] = [:]
    private var pollingTask: Task<Void, Never>?
    private let locationManager = LocationManager()
    
    init() {
        // Initialize without async calls
        setupInitialState()
        
        // Start subscriptions using Task
        Task { @MainActor in
            await setupSubscriptions()
        }
    }
    
    private func setupInitialState() {
        // Any synchronous initialization can go here
    }
    
    private func setupSubscriptions() async {
        // Subscribe to meets changes
        let channel = supabase.client.realtimeV2.channel("public:meets")
        await channel.subscribe()
        meetsSubscription = channel
        
        // Initial fetch
        do {
            try await fetchMeets()
        } catch {
            print("Error in initial fetch: \(error)")
            self.error = MeetError.networkError
        }
        
        startPolling()
    }
    
    private func startPolling() {
        // Cancel any existing polling task
        pollingTask?.cancel()
        
        // Create a new polling task
        pollingTask = Task { @MainActor in
            while !Task.isCancelled {
                do {
                    try await fetchMeets()
                } catch {
                    if !Task.isCancelled {
                        print("Error in polling: \(error)")
                        self.error = MeetError.networkError
                    }
                }
                
                do {
                    try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                } catch {
                    // Task was cancelled
                    break
                }
            }
        }
    }
    
    private func fetchMeets() async throws {
        let meets: [Meet] = try await supabase.client
            .from("meets")
            .select()
            .execute()
            .value
        
        await MainActor.run {
            self.meets = meets
            Task {
                await fetchUpcomingMeets()
                await fetchNearbyMeets()
            }
        }
    }
    
    deinit {
        // Cancel polling task
        pollingTask?.cancel()
        
        // Capture subscriptions locally to avoid capturing self in the Task
        let subscriptionToCancel = meetsSubscription
        let commentsToCancel = commentsSubscriptions
        
        Task { @MainActor in
            await subscriptionToCancel?.unsubscribe()
            for channel in commentsToCancel.values {
                await channel.unsubscribe()
            }
        }
    }
    
    private func setupCommentsSubscription(for meetId: String) async {
        guard commentsSubscriptions[meetId] == nil else { return }
        
        let channel = supabase.client.realtimeV2.channel("public:meet_comments")
        await channel.subscribe()
        commentsSubscriptions[meetId] = channel
        
        startCommentsPolling(for: meetId)
    }
    
    private func startCommentsPolling(for meetId: String) {
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                do {
                    try await self.fetchComments(for: meetId)
                } catch {
                    print("Error in comments polling: \(error)")
                }
            }
        }
    }
    
    func fetchComments(for meetId: String) async throws {
        // Fetch comments from the supabase service
        let comments: [MeetComment] = try await supabase.fetchComments(meetId: meetId)
        
        // Update the comments for this meet
        await MainActor.run {
            if let meetIndex = self.meets.firstIndex(where: { $0.id == meetId }) {
                var updatedMeet = self.meets[meetIndex]
                updatedMeet.comments = comments
                self.meets[meetIndex] = updatedMeet
                self.comments = comments // Also update the public comments array
            }
        }
        
        // Setup real-time comments subscription for this meet
        await setupCommentsSubscription(for: meetId)
    }
    
    // MARK: - Authentication
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        do {
            let authResponse = try await supabase.signIn(email: email, password: password)
            // Fetch the user using the ID from the auth response
            currentUser = try await userService.fetchUser(id: authResponse.user.id.uuidString)
            try await fetchMeets()
        } catch {
            self.error = MeetError.authenticationError
            throw error
        }
        isLoading = false
    }
    
    func signUp(email: String, password: String) async throws {
        isLoading = true
        do {
            let authResponse = try await supabase.signUp(email: email, password: password)
            // Fetch the user using the ID from the auth response
            currentUser = try await userService.fetchUser(id: authResponse.user.id.uuidString)
            try await fetchMeets()
        } catch {
            self.error = MeetError.authenticationError
            throw error
        }
        isLoading = false
    }
    
    func signOut() async throws {
        isLoading = true
        do {
            try await supabase.signOut()
            currentUser = nil
            meets = []
            userMeets = []
            attendingMeets = []
        } catch {
            self.error = MeetError.authenticationError
            throw error
        }
        isLoading = false
    }
    
    // MARK: - Meets
    
    func refreshMeets() async {
        do {
            try await fetchMeets()
        } catch {
            self.error = MeetError.networkError
            print("Error refreshing meets: \(error)")
        }
    }
    
    func fetchMeets(status: MeetStatus? = nil, vehicleType: VehicleType? = nil, routeType: RouteType? = nil) async throws {
        isLoading = true
        do {
            meets = try await supabase.fetchMeets(
                status: status?.rawValue,
                vehicleType: vehicleType?.rawValue,
                routeType: routeType?.rawValue
            )
            
            // Update filtered lists
            userMeets = meets.filter { $0.creatorId == currentUser?.id }
            attendingMeets = meets.filter { isAttending($0) }
            upcomingMeets = meets.filter { $0.date > Date() }
            await fetchNearbyMeets()
        } catch {
            self.error = MeetError.networkError
            throw error
        }
        isLoading = false
    }
    
    func createMeet(
        title: String,
        description: String,
        date: Date,
        type: V2MeetType,
        location: CLLocationCoordinate2D,
        address: String,
        rules: [String],
        tags: [String],
        coverImage: UIImage,
        capacity: Int,
        vehicleType: VehicleType,
        routeType: RouteType
    ) async throws {
        // Try to use current user or fetch a new one if nil
        if currentUser == nil {
            // Attempt to refresh authentication before failing
            do {
                let session = try await supabase.client.auth.session
                let user = try await userService.fetchUser(id: session.user.id.uuidString)
                // If we get here, we found a valid auth session and user
                self.currentUser = user
            } catch {
                print("Authentication check failed: \(error)")
                throw MeetError.authenticationError
            }
        }
        
        // Ensure we have a valid user after the refresh attempt
        guard let user = self.currentUser else {
            throw MeetError.authenticationError
        }
        
        isLoading = true
        do {
            // Upload the image first
            let coverImageUrl = try await supabase.uploadImage(coverImage, path: "meets")
            
            let newMeet = Meet(
                title: title,
                description: description,
                date: date,
                location: location,
                address: address,
                type: type,
                coverImage: coverImageUrl,
                rules: rules.filter { !$0.isEmpty },
                tags: tags.filter { !$0.isEmpty },
                capacity: capacity,
                creatorId: user.id,
                status: .upcoming,
                vehicleType: vehicleType,
                routeType: routeType
            )
            
            let createdMeet = try await supabase.createMeet(newMeet)
            
            await MainActor.run {
                meets.append(createdMeet)
                userMeets.append(createdMeet)
                attendingMeets.append(createdMeet)
                Task {
                    await fetchUpcomingMeets()
                    await fetchNearbyMeets()
                }
                isLoading = false
            }
        } catch let error as SupabaseError where error == .imageUploadFailed || error == .imageConversionFailed {
            throw MeetError.imageUploadError
        } catch {
            self.error = MeetError.networkError
            throw error
        }
    }
    
    func cancelMeet(_ meet: Meet) async throws {
        guard meet.creatorId == currentUser?.id else {
            throw MeetError.authenticationError
        }
        
        isLoading = true
        do {
            try await supabase.client
                .from("meets")
                .delete()
                .eq("id", value: meet.id)
                .execute()
            meets.removeAll { $0.id == meet.id }
            userMeets.removeAll { $0.id == meet.id }
            attendingMeets.removeAll { $0.id == meet.id }
        } catch {
            self.error = MeetError.networkError
            throw error
        }
        isLoading = false
    }
    
    // MARK: - Meet Attendance
    
    func isAttending(_ meet: Meet) -> Bool {
        guard currentUser != nil else { return false }
        return meet.attendees.contains { $0.id == currentUser?.id }
    }
    
    func attendMeet(_ meet: Meet) async {
        guard currentUser != nil else { return }
        do {
            try await toggleAttendance(for: meet)
        } catch {
            self.error = error
        }
    }
    
    func leaveMeet(_ meet: Meet) async throws {
        guard let userId = currentUser?.id else {
            throw MeetError.authenticationError
        }
        
        isLoading = true
        do {
            try await supabase.client
                .from("meet_participants")
                .delete()
                .eq("meet_id", value: meet.id)
                .eq("user_id", value: userId)
                .execute()
            
            // Convert UUID to string for comparison
            participants.removeAll { $0.userId.uuidString == userId && $0.meetId.uuidString == meet.id }
            
            if let index = meets.firstIndex(where: { $0.id == meet.id }) {
                var updatedMeet = meet
                updatedMeet.attendees.removeAll { $0.id == userId }
                meets[index] = updatedMeet
                attendingMeets.removeAll { $0.id == meet.id }
            }
        } catch {
            self.error = MeetError.networkError
            throw error
        }
        isLoading = false
    }
    
    func toggleAttendance(for meet: Meet) async throws {
        guard currentUser != nil else {
            throw MeetError.authenticationError
        }
        
        isLoading = true
        do {
            if isAttending(meet) {
                try await supabase.client
                    .from("meet_participants")
                    .delete()
                    .eq("meet_id", value: meet.id)
                    .eq("user_id", value: currentUser!.id)
                    .execute()
                if let index = meets.firstIndex(where: { $0.id == meet.id }) {
                    var updatedMeet = meet
                    updatedMeet.attendees.removeAll { $0.id == currentUser?.id }
                    meets[index] = updatedMeet
                    attendingMeets.removeAll { $0.id == meet.id }
                }
            } else {
                try await supabase.client
                    .from("meet_participants")
                    .insert([
                        "meet_id": meet.id,
                        "user_id": currentUser!.id
                    ])
                    .execute()
                if let index = meets.firstIndex(where: { $0.id == meet.id }) {
                    var updatedMeet = meet
                    updatedMeet.attendees.append(currentUser!)
                    meets[index] = updatedMeet
                    attendingMeets.append(updatedMeet)
                }
            }
        } catch {
            self.error = MeetError.networkError
            throw error
        }
        isLoading = false
    }
    
    // MARK: - Comments
    
    func addComment(_ text: String, to meet: Meet) async throws {
        // Try to use current user or fetch a new one if nil
        if currentUser == nil {
            // Attempt to refresh authentication before failing
            do {
                let session = try await supabase.client.auth.session
                let user = try await userService.fetchUser(id: session.user.id.uuidString)
                // If we get here, we found a valid auth session and user
                self.currentUser = user
            } catch {
                print("Authentication check failed: \(error)")
                throw MeetError.authenticationError
            }
        }
        
        // Ensure we have a valid user after the refresh attempt
        guard let user = self.currentUser else {
            throw MeetError.authenticationError
        }
        
        isLoading = true
        do {
            let comment = MeetComment(
                id: UUID().uuidString,
                userId: user.id,
                meetId: meet.id,
                text: text,
                timestamp: Date(),
                likes: 0
            )
            
            let newComment = try await supabase.addComment(comment)
            if let index = meets.firstIndex(where: { $0.id == meet.id }) {
                var updatedMeet = meet
                updatedMeet.comments.append(newComment)
                meets[index] = updatedMeet
            }
        } catch let error as SupabaseError where error == .notAuthenticated {
            isLoading = false
            print("Authentication failure during comment creation: \(error)")
            throw MeetError.authenticationError
        } catch {
            self.error = MeetError.networkError
            throw error
        }
        isLoading = false
    }
    
    func addReply(_ text: String, to comment: MeetComment, in meet: Meet) async throws {
        guard let currentUser = currentUser else {
            throw MeetError.authenticationError
        }
        
        isLoading = true
        do {
            let reply = MeetComment(
                id: UUID().uuidString,
                userId: currentUser.id,
                meetId: meet.id,
                text: text,
                timestamp: Date(),
                likes: 0
            )
            
            let newReply = try await supabase.addComment(reply)
            if let meetIndex = meets.firstIndex(where: { $0.id == meet.id }),
               let commentIndex = meet.comments.firstIndex(where: { $0.id == comment.id }) {
                var updatedMeet = meet
                updatedMeet.comments[commentIndex].replies.append(newReply)
                meets[meetIndex] = updatedMeet
            }
        } catch {
            self.error = MeetError.networkError
            throw error
        }
        isLoading = false
    }
    
    func deleteComment(_ comment: MeetComment, from meet: Meet) async throws {
        guard currentUser != nil else {
            throw MeetError.authenticationError
        }
        
        isLoading = true
        do {
            try await supabase.client
                .from("meet_comments")
                .delete()
                .eq("id", value: comment.id)
                .execute()
            if let meetIndex = meets.firstIndex(where: { $0.id == meet.id }) {
                var updatedMeet = meet
                updatedMeet.comments.removeAll { $0.id == comment.id }
                meets[meetIndex] = updatedMeet
            }
        } catch {
            self.error = MeetError.networkError
            throw error
        }
        isLoading = false
    }
    
    func likeComment(_ comment: MeetComment, in meet: Meet) async throws {
        guard currentUser != nil else {
            throw MeetError.authenticationError
        }
        
        isLoading = true
        do {
            try await supabase.likeComment(comment.id)
            if let meetIndex = meets.firstIndex(where: { $0.id == meet.id }) {
                var updatedMeet = meet
                if let commentIndex = updatedMeet.comments.firstIndex(where: { $0.id == comment.id }) {
                    updatedMeet.comments[commentIndex].likes += 1
                    meets[meetIndex] = updatedMeet
                }
            }
        } catch {
            self.error = MeetError.networkError
            throw error
        }
        isLoading = false
    }
    
    // MARK: - Friend Requests
    
    func sendFriendRequest(email: String) async throws {
        guard currentUser != nil else {
            throw MeetError.authenticationError
        }
        
        isLoading = true
        do {
            try await supabase.sendFriendRequest(to: email)
        } catch {
            self.error = MeetError.networkError
            throw error
        }
        isLoading = false
    }
    
    func handleFriendRequest(_ request: FriendRequestRow, accept: Bool) async {
        guard currentUser != nil else { return }
        
        isLoading = true
        do {
            if accept {
                try await supabase.acceptFriendRequest(from: request.sender.id)
                // Update current user's friends list
                if var updatedUser = currentUser {
                    updatedUser.friends.append(request.sender.id)
                    self.currentUser = updatedUser
                }
            } else {
                try await supabase.rejectFriendRequest(from: request.sender.id)
            }
            
            // Remove the request from the list
            friendRequests.removeAll { $0.id == request.id }
        } catch {
            self.error = MeetError.networkError
        }
        isLoading = false
    }
    
    // MARK: - Helper Methods
    
    func fetchUpcomingMeets() async {
        upcomingMeets = meets.filter { $0.date > Date() }
            .sorted { $0.date < $1.date }
    }
    
    func fetchNearbyMeets() async {
        // Get user's current location from LocationManager
        if let userLocation = locationManager.location?.coordinate {
            nearbyMeets = meets.filter { meet in
                // Calculate distance between user and meet
                let meetLocation = CLLocation(latitude: meet.location.latitude, longitude: meet.location.longitude)
                let userLoc = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
                let distance = meetLocation.distance(from: userLoc) / 1000 // Convert to kilometers
                
                // Return meets within 50km and happening in the future
                return distance <= 50 && meet.date > Date()
            }
            .sorted { $0.date < $1.date }
        } else {
            // If no location available, just show future meets
            nearbyMeets = meets.filter { $0.date > Date() }
                .sorted { $0.date < $1.date }
        }
    }
    
    // MARK: - Search Methods
    
    func searchMeets(query: String, sortByDistance: Bool = false) async -> [Meet] {
        // Filter meets based on title, description, or address containing the query
        let filteredMeets = meets.filter { meet in
            let searchText = query.lowercased()
            return meet.title.lowercased().contains(searchText) ||
                   meet.description.lowercased().contains(searchText) ||
                   meet.address.lowercased().contains(searchText)
        }
        
        if sortByDistance {
            // In a real app, we would sort by actual distance from user
            return filteredMeets
        }
        
        return filteredMeets
    }
    
    func searchVehicles(query: String) async -> [Vehicle] {
        // Collect all vehicles from all users
        let allVehicles = users.flatMap { $0.vehicles }
        
        // Filter vehicles based on make, model, or modifications containing the query
        return allVehicles.filter { vehicle in
            let searchText = query.lowercased()
            return vehicle.make.lowercased().contains(searchText) ||
                   vehicle.model.lowercased().contains(searchText) ||
                   vehicle.modifications.joined(separator: " ").lowercased().contains(searchText)
        }
    }
    
    func searchUsers(query: String) async -> [User] {
        // Filter users based on name, bio, or location containing the query
        return users.filter { user in
            let searchText = query.lowercased()
            return user.profile.name.lowercased().contains(searchText) ||
                   user.profile.bio.lowercased().contains(searchText) ||
                   user.profile.location.address.lowercased().contains(searchText)
        }
    }
    
    // MARK: - Participant Management
    
    func fetchParticipants(meetId: String) async {
        isLoading = true
        error = nil
        
        do {
            let participants: [MeetParticipant] = try await supabase.client
                .from("meet_participants")
                .select()
                .eq("meet_id", value: meetId)
                .execute()
                .value
            self.participants = participants
        } catch {
            self.error = MeetError.networkError
            print("Error fetching participants: \(error)")
        }
        
        isLoading = false
    }
    
    func joinMeet(_ meet: Meet) async throws {
        guard let userId = currentUser?.id,
              let vehicleId = currentUser?.vehicles.first?.id else {
            throw MeetError.authenticationError
        }
        
        isLoading = true
        do {
            let participant: MeetParticipant = try await supabase.client
                .from("meet_participants")
                .insert([
                    "meet_id": meet.id,
                    "user_id": userId,
                    "vehicle_id": vehicleId
                ])
                .execute()
                .value
            participants.append(participant)
            if let index = meets.firstIndex(where: { $0.id == meet.id }) {
                var updatedMeet = meet
                updatedMeet.attendees.append(currentUser!)
                meets[index] = updatedMeet
                attendingMeets.append(updatedMeet)
            }
        } catch {
            self.error = MeetError.networkError
            throw error
        }
        isLoading = false
    }
    
    // MARK: - Route Management
    
    func updatePrimaryRoute(meetId: String, routeId: String) async throws {
        isLoading = true
        do {
            try await supabase.client
                .from("meets")
                .update(["primary_route_id": routeId])
                .eq("id", value: meetId)
                .execute()
            if let index = meets.firstIndex(where: { $0.id == meetId }) {
                var updatedMeet = meets[index]
                updatedMeet.primaryRouteId = routeId
                meets[index] = updatedMeet
            }
        } catch {
            self.error = MeetError.networkError
            throw error
        }
        isLoading = false
    }
    
    // MARK: - User Data
    
    @MainActor
    func fetchUserData() async {
        guard let userId = currentUser?.id else { return }
        
        do {
            // Fetch followers
            let followersData = try await supabase.client
                .from("followers")
                .select("follower:users(*)")
                .eq("following_id", value: userId)
                .eq("status", value: "accepted")
                .execute()
            
            let followers: [User] = try {
                let data = followersData.data // No need for conditional binding since data is not optional
                let jsonObject = try JSONSerialization.jsonObject(with: data)
                guard let followersArray = jsonObject as? [[String: Any]] else { return [] }
                
                return followersArray.compactMap { dict -> User? in
                    guard let followerData = dict["follower"] as? [String: Any],
                          let followerJson = try? JSONSerialization.data(withJSONObject: followerData) else {
                        return nil
                    }
                    return try? JSONDecoder().decode(User.self, from: followerJson)
                }
            }()
            
            self.followers = followers
            
            // Fetch recent achievements
            let achievementsData = try await supabase.client
                .from("achievements")
                .select()
                .eq("user_id", value: userId)
                .order("earned_at", ascending: false)
                .limit(5)
                .execute()
            
            let achievements: [Achievement] = try {
                let data = achievementsData.data // No need for conditional binding
                let jsonObject = try JSONSerialization.jsonObject(with: data)
                guard let achievementsArray = jsonObject as? [[String: Any]] else { return [] }
                
                return achievementsArray.compactMap { dict -> Achievement? in
                    guard let id = dict["id"] as? String,
                          let type = dict["type"] as? String,
                          let title = dict["title"] as? String,
                          let description = dict["description"] as? String,
                          let icon = dict["icon"] as? String,
                          let earnedAt = dict["earned_at"] as? String else {
                        return nil
                    }
                    
                    let dateFormatter = ISO8601DateFormatter()
                    guard let date = dateFormatter.date(from: earnedAt),
                          let achievementType = AchievementType(rawValue: type) else {
                        return nil
                    }
                    
                    return Achievement(
                        id: id,
                        type: achievementType,
                        title: title,
                        description: description,
                        icon: icon,
                        earnedAt: date
                    )
                }
            }()
            
            self.recentAchievements = achievements
            
            // Fetch recent activity
            let activityData = try await supabase.client
                .from("user_activities")
                .select()
                .eq("user_id", value: userId)
                .order("timestamp", ascending: false)
                .limit(10)
                .execute()
            
            let activities: [Activity] = try {
                let data = activityData.data // No need for conditional binding
                let jsonObject = try JSONSerialization.jsonObject(with: data)
                guard let activityArray = jsonObject as? [[String: Any]] else { return [] }
                
                return activityArray.compactMap { dict -> Activity? in
                    guard let id = dict["id"] as? String,
                          let type = dict["type"] as? String,
                          let title = dict["title"] as? String,
                          let description = dict["description"] as? String,
                          let timestamp = dict["timestamp"] as? String else {
                        return nil
                    }
                    
                    let dateFormatter = ISO8601DateFormatter()
                    guard let date = dateFormatter.date(from: timestamp),
                          let activityType = ActivityType(rawValue: type) else {
                        return nil
                    }
                    
                    return Activity(
                        id: id,
                        userId: userId,
                        type: activityType,
                        title: title,
                        description: description,
                        timestamp: date
                    )
                }
            }()
            
            self.recentActivity = activities
        } catch {
            print("Error fetching user data: \(error)")
            self.followers = []
            self.recentAchievements = []
            self.recentActivity = []
        }
    }
}

// MARK: - Mock Data
extension User {
    static let mockCurrentUser = User(
        id: "current_user",
        email: "user@example.com",
        profile: Profile(
            name: "John Doe",
            avatar: "profile1",
            bio: "Car enthusiast",
            location: Profile.Location(
                latitude: 37.7749,
                longitude: -122.4194,
                address: "San Francisco"
            ),
            joinDate: Date(),
            social: Profile.Social.empty
        ),
        vehicles: [],
        friends: [],
        isPremium: false,
        achievements: [],
        preferences: Preferences.defaultPreferences
    )
    
    static let mockFriends = [
        User(
            id: "friend1",
            email: "friend1@example.com",
            profile: Profile(
                name: "Jane Smith",
                avatar: "profile2",
                bio: "Racing fan",
                location: Profile.Location(
                    latitude: 34.0522,
                    longitude: -118.2437,
                    address: "Los Angeles"
                ),
                joinDate: Date(),
                social: Profile.Social.empty
            ),
            vehicles: [],
            friends: [],
            isPremium: false,
            achievements: [],
            preferences: Preferences.defaultPreferences
        ),
        User(
            id: "friend2",
            email: "friend2@example.com",
            profile: Profile(
                name: "Mike Johnson",
                avatar: "profile3",
                bio: "Track day regular",
                location: Profile.Location(
                    latitude: 32.7157,
                    longitude: -117.1611,
                    address: "San Diego"
                ),
                joinDate: Date(),
                social: Profile.Social.empty
            ),
            vehicles: [],
            friends: [],
            isPremium: false,
            achievements: [],
            preferences: Preferences.defaultPreferences
        )
    ]
} 

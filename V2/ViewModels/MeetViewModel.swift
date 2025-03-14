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
    case vehicleRequired
    
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
        case .vehicleRequired:
            return "A vehicle is required to join this meet."
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
    @Published var searchQuery: String = ""
    @Published var activelyFilteringByStatus = false
    @Published var selectedStatusFilter: MeetStatus?
    @Published var meetsByStatus: [MeetStatus: [Meet]] = [:]
    @Published var isInitialized = false // Track when the view model has completed its initial data loading
    @Published var isInScrollBoundary: Bool = false
    
    // Track status transitions to prevent UI flickering
    private var statusTransitionTimers: [MeetStatus: Timer] = [:]
    @MainActor private var transitionalStatuses: Set<MeetStatus> = []
    
    // Status refresh throttling
    private static var lastStatusRefreshTime: Date = .distantPast
    private let statusRefreshInterval: TimeInterval = 300 // 5 minutes in seconds
    
    private var allLocations: [Location] = []
    
    private let supabase = SupabaseService.shared
    private let userService = UserService.shared
    private var meetsSubscription: RealtimeChannelV2?
    private var commentsSubscriptions: [String: RealtimeChannelV2] = [:]
    private var pollingTask: Task<Void, Never>?
    private let locationManager: LocationManager = LocationManager()
    
    // Add state to track if background operations are paused
    private var areBackgroundOperationsPaused = false
    private var backgroundTimers: [Timer] = []
    
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
        Task {
            await forceRefreshAll()
        }
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
        
        // Use 30-second polling interval instead of 5 seconds
        startPolling(interval: 30)
    }
    
    private func startPolling(interval: Double = 30) {
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
                    // Use a much longer interval for polling (30 seconds instead of 5)
                    try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
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
        
        // After loading the meets
        updateMeetsByStatus()
        
        // Mark as initialized
        await MainActor.run {
            if !isInitialized {
                isInitialized = true
            }
        }
        
        // Check status only every 5 minutes instead of every poll
        if Date().timeIntervalSince(Self.lastStatusRefreshTime) > statusRefreshInterval {
            // It's been more than 5 minutes since our last status check
            Self.lastStatusRefreshTime = Date()
            
            Task {
                await refreshMeetStatuses()
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
        await forceRefreshAll()
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
        routeType: RouteType,
        primaryRouteId: String? = nil
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
                routeType: routeType,
                primaryRouteId: primaryRouteId
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
    
    func joinMeet(_ meet: Meet, vehicleId: String? = nil) async throws {
        guard let userId = currentUser?.id else {
            throw MeetError.authenticationError
        }
        
        // Use provided vehicleId if available, otherwise fall back to the first vehicle
        let selectedVehicleId = vehicleId ?? currentUser?.vehicles.first?.id
        
        guard let vehicleId = selectedVehicleId else {
            throw MeetError.vehicleRequired
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
    
    // Returns meets filtered by searchQuery
    var filteredMeets: [Meet] {
        if searchQuery.isEmpty {
            return meets
        }
        
        return meets.filter { meet in
            meet.title.localizedCaseInsensitiveContains(searchQuery) ||
            meet.description.localizedCaseInsensitiveContains(searchQuery) ||
            meet.locationName.localizedCaseInsensitiveContains(searchQuery)
        }
    }
    
    // Returns locations filtered by searchQuery
    var filteredLocations: [Location] {
        if searchQuery.isEmpty {
            return allLocations
        }
        
        return allLocations.filter { location in
            location.name.localizedCaseInsensitiveContains(searchQuery) ||
            location.address.localizedCaseInsensitiveContains(searchQuery) ||
            location.city?.localizedCaseInsensitiveContains(searchQuery) ?? false ||
            location.state?.localizedCaseInsensitiveContains(searchQuery) ?? false ||
            location.country?.localizedCaseInsensitiveContains(searchQuery) ?? false
        }
    }
    
    // Method to search for locations from an API or backend
    func searchLocations(query: String) async {
        guard !query.isEmpty else {
            await MainActor.run {
                allLocations = []
            }
            return
        }
        
        isLoading = true
        
        // In a real app, this would call an API to search for locations
        // For demo purposes, we'll simulate a delay and return mock data
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
        
        let mockLocations = [
            Location(id: "1", name: "Central Park", address: "Central Park, New York, NY", latitude: 40.7812, longitude: -73.9665, city: "New York", state: "NY", country: "USA"),
            Location(id: "2", name: "Miami Beach", address: "Miami Beach, FL", latitude: 25.7907, longitude: -80.1300, city: "Miami", state: "FL", country: "USA"),
            Location(id: "3", name: "Golden Gate Park", address: "Golden Gate Park, San Francisco, CA", latitude: 37.7694, longitude: -122.4862, city: "San Francisco", state: "CA", country: "USA"),
            Location(id: "4", name: "Starbucks Coffee", address: "123 Main St, Seattle, WA", latitude: 47.6062, longitude: -122.3321, city: "Seattle", state: "WA", country: "USA"),
            Location(id: "5", name: "Downtown Coffeehouse", address: "456 Market St, San Francisco, CA", latitude: 37.7941, longitude: -122.3970, city: "San Francisco", state: "CA", country: "USA")
        ]
        
        let filtered = mockLocations.filter { location in
            location.name.localizedCaseInsensitiveContains(query) ||
            location.address.localizedCaseInsensitiveContains(query) ||
            location.city?.localizedCaseInsensitiveContains(query) ?? false ||
            location.state?.localizedCaseInsensitiveContains(query) ?? false ||
            location.country?.localizedCaseInsensitiveContains(query) ?? false
        }
        
        await MainActor.run {
            allLocations = filtered
            isLoading = false
        }
    }
    
    // Add a new computed property to filter meets by status
    var filteredMeetsByStatus: [Meet] {
        if let selectedStatus = selectedStatusFilter {
            return meets.filter { $0.status == selectedStatus }
        } else {
            return meets
        }
    }
    
    // Add a new method to refresh meet statuses
    func refreshMeetStatuses() async {
        var updatedMeets = 0
        var statusChanges: [String: MeetStatus] = [:]
        
        // Skip status updates if we're at a scroll boundary
        if isInScrollBoundary {
            return // Skip status checking entirely
        }
        
        for (_, meet) in meets.enumerated() {
            let calculatedStatus = MeetStatus.determineStatus(meetDate: meet.date)
            
            // Only update if the status has changed
            if calculatedStatus != meet.status {
                statusChanges[meet.id] = calculatedStatus
            }
        }
        
        // Only make db calls if we actually have status changes
        if !statusChanges.isEmpty {
            // Process in batches to reduce individual calls
            for (meetId, newStatus) in statusChanges {
                do {
                    try await updateMeetStatus(meetId: meetId, status: newStatus, skipLogging: true)
                    updatedMeets += 1
                } catch {
                    // Don't print error for every single meet to reduce console spam
                }
            }
        
            // Single log statement for all updates
            if updatedMeets > 0 {
                print("Updated status for \(updatedMeets) meets")
                try? await fetchMeets() // Refresh the meets list
            }
        }
        
        // Categorize meets by status
        updateMeetsByStatus()
    }
    
    // Add a method to update a single meet status
    func updateMeetStatus(meetId: String, status: MeetStatus, skipLogging: Bool = false) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Skip status updates if we're at a scroll boundary to reduce console spam
        if isInScrollBoundary {
            return // Skip status checking
        }
        
        do {
            try await supabase.client.from("meets")
                .update(["status": status.rawValue, "updated_at": ISO8601DateFormatter().string(from: Date())])
                .eq("id", value: meetId)
                .execute()
            
            // Update the meet locally
            if let index = meets.firstIndex(where: { $0.id == meetId }) {
                // Create a new Meet with updated status using the helper method
                let updatedMeet = meets[index].withUpdatedStatus(status)
                meets[index] = updatedMeet
                
                // Also update in any other arrays that might contain this meet
                updateMeetInArrays(updatedMeet)
                
                // Only log individual status changes if skipLogging is false
                if !skipLogging {
                    print("Updated meet \(meetId) status to \(status.rawValue)")
                }
            }
        } catch {
            if !skipLogging {
                print("Error updating meet status: \(error)")
            }
            throw MeetError.networkError
        }
    }
    
    // Helper to update meet in all arrays
    private func updateMeetInArrays(_ updatedMeet: Meet) {
        // Update in userMeets
        if let index = userMeets.firstIndex(where: { $0.id == updatedMeet.id }) {
            userMeets[index] = updatedMeet
        }
        
        // Update in attendingMeets
        if let index = attendingMeets.firstIndex(where: { $0.id == updatedMeet.id }) {
            attendingMeets[index] = updatedMeet
        }
        
        // Update in upcomingMeets
        if let index = upcomingMeets.firstIndex(where: { $0.id == updatedMeet.id }) {
            upcomingMeets[index] = updatedMeet
        }
        
        // Update in nearbyMeets
        if let index = nearbyMeets.firstIndex(where: { $0.id == updatedMeet.id }) {
            nearbyMeets[index] = updatedMeet
        }
        
        // Update the meetsByStatus dictionary
        updateMeetsByStatus()
    }
    
    // Update meetsByStatus dictionary with current status of all meets
    private func updateMeetsByStatus() {
        // Skip if we're already at scroll boundary or in a transition to prevent excessive updates
        guard !isInScrollBoundary else { return }
        
        // Create a dictionary to hold meets grouped by status
        var categorized: [MeetStatus: [Meet]] = [:]
        
        // Initialize all status categories with empty arrays to ensure consistent UI
        for status in MeetStatus.allCases {
            categorized[status] = []
        }
        
        // Loop through all meets and categorize by status
        for meet in meets {
            let status = meet.status
            var meetsWithStatus = categorized[status] ?? []
            meetsWithStatus.append(meet)
            categorized[status] = meetsWithStatus
            
            // Check for status transitions - compare with previous counts
            let previousCount = meetsByStatus[status]?.count ?? 0
            let currentCount = meetsWithStatus.count
            
            if previousCount != currentCount {
                handleStatusCountChange(status: status, oldCount: previousCount, newCount: currentCount)
            }
        }
        
        // Update the dictionary without logging
        meetsByStatus = categorized
    }
    
    // Handle changes in meet counts for a status to prevent UI flickering
    private func handleStatusCountChange(status: MeetStatus, oldCount: Int, newCount: Int) {
        // Skip status transitions handling when we're at scroll boundary to prevent UI glitches
        guard !isInScrollBoundary else { return }
        
        // Determine if this is a transition worth tracking
        let isSignificantTransition = (oldCount == 0 && newCount > 0) || (oldCount > 0 && newCount == 0)
        
        // Only track significant transitions
        if isSignificantTransition {
            // Cancel existing timer if there is one
            statusTransitionTimers[status]?.invalidate()
            
            // Critical status changes (like empty to non-empty) might need transition
            // but keep transition extremely short to improve scrolling
            transitionalStatuses.insert(status)
            
            // Use DispatchQueue instead of Timer for better threading behavior
            // This prevents blocking during scrolling
            let statusCopy = status // Create a local copy
            statusTransitionTimers[status] = nil // Clear existing timer
            
            // Use a very short delay - just 0.2 seconds instead of 0.75
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                guard let self = self else { return }
                // Clear transitional state on main actor
                Task { @MainActor in
                    if self.transitionalStatuses.contains(statusCopy) {
                        self.transitionalStatuses.remove(statusCopy)
                        self.objectWillChange.send()
                    }
                }
            }
        }
    }
    
    // Check if a status is currently in transition - make it public and clear for UI
    public func isStatusTransitioning(_ status: MeetStatus) -> Bool {
        // Optimization: Never use transitions for these frequently viewed statuses
        // to prevent UI stuttering
        if status == .completed || status == .upcoming {
            return false
        }
        
        // Skip transition checking when at scroll boundary to prevent UI jitter
        guard !isInScrollBoundary else { return false }
        
        // Simple check if status is transitioning without setting up another timer
        return transitionalStatuses.contains(status)
    }
    
    // Helper method to clear transition for a specific status
    @MainActor
    private func clearTransitionForStatus(_ status: MeetStatus) {
        statusTransitionTimers[status]?.invalidate()
        statusTransitionTimers[status] = nil
        transitionalStatuses.remove(status)
        objectWillChange.send()
    }
    
    // Enable/disable status checking when at scroll boundaries
    public func setScrollBoundaryState(_ state: Bool) {
        isInScrollBoundary = state
        
        // When at boundary, prevent unnecessary status checks
        if state {
            // If we're at boundary, don't perform status checks to reduce console spam
            print("Scroll boundary reached - pausing status checks")
        }
    }
    
    // Get meets for a specific status, even if in transition
    public func getMeetsForStatus(_ status: MeetStatus) -> [Meet] {
        return meetsByStatus[status] ?? []
    }
    
    // Add status filter toggle functionality
    func toggleStatusFilter(_ status: MeetStatus?) {
        if selectedStatusFilter == status {
            // If tapping the same status again, clear the filter
            selectedStatusFilter = nil
            activelyFilteringByStatus = false
        } else {
            // Set the new status filter
            selectedStatusFilter = status
            activelyFilteringByStatus = true
        }
    }
    
    // MARK: - Data Refresh Methods
    
    /// Forces a complete refresh of all meet collections
    func forceRefreshAll() async {
        isLoading = true
        
        // Clear any transitional states first
        transitionalStatuses.removeAll()
        for timer in statusTransitionTimers.values {
            timer.invalidate()
        }
        statusTransitionTimers.removeAll()
        
        // Initialize the meetsByStatus dictionary with empty arrays for all statuses
        for status in MeetStatus.allCases {
            meetsByStatus[status] = []
        }
        
        do {
            try await fetchMeets()
            await fetchUpcomingMeets()
            await fetchNearbyMeets()
            updateMeetsByStatus()
            await refreshMeetStatuses()
            print("✅ Successfully loaded \(meets.count) meets")
            
            if meets.isEmpty {
                print("⚠️ No meets found in database. Loading mock data for preview.")
                // If no meets found, use mock data for preview
                meets = Meet.mockMeets
                await fetchUpcomingMeets()
                await fetchNearbyMeets()
                updateMeetsByStatus()
            }
        } catch {
            print("❌ Error refreshing meets: \(error)")
            self.error = MeetError.networkError
            
            // Fall back to mock data if fetch fails
            meets = Meet.mockMeets
            await fetchUpcomingMeets()
            await fetchNearbyMeets()
            updateMeetsByStatus()
        }
        
        // Mark as initialized after all data is loaded
        isInitialized = true
        isLoading = false
    }
    
    // Clear any transitional states that might be stuck
    @MainActor
    public func clearAllTransitionalStates() {
        // Immediately clear all transitional states
        if !transitionalStatuses.isEmpty {
            transitionalStatuses.removeAll()
            
            // Cancel any pending timers
            for (status, timer) in statusTransitionTimers {
                timer.invalidate()
                statusTransitionTimers[status] = nil
            }
            
            // Force UI update
            objectWillChange.send()
        }
    }
    
    // Method to pause all background operations during transitions
    func pauseAllBackgroundOperations() {
        areBackgroundOperationsPaused = true
        
        // Cancel any active timers
        backgroundTimers.forEach { $0.invalidate() }
        backgroundTimers.removeAll()
        
        // Cancel any ongoing network requests if needed
        // This depends on how you're handling network requests
        // For URLSession tasks, you would need to store and cancel them here
    }
    
    // Method to resume background operations after transitions
    func resumeAllBackgroundOperations() {
        areBackgroundOperationsPaused = false
        
        // Restart any necessary background operations
        // If there are timers or background tasks that need to be resumed,
        // reinitialize them here
    }
    
    // Helper to check if operations are allowed
    func canPerformBackgroundOperation() -> Bool {
        return !areBackgroundOperationsPaused
    }
    
    // Add the createVehicle method
    
    func createVehicle(_ vehicle: Vehicle) async throws {
        isLoading = true
        
        do {
            // Use the SupabaseService to add the vehicle to the database
            _ = try await supabase.addVehicle(vehicle)
            
            // If successful, refresh the current user data to include the new vehicle
            await fetchUserData()
        } catch {
            self.error = MeetError.networkError
            throw error
        }
        
        isLoading = false
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

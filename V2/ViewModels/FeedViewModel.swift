import Foundation
import SwiftUI
import Combine
import CoreLocation
import Supabase

@MainActor
class FeedViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var loadingMore = false
    @Published var error: Error?
    @Published var selectedPost: Post?
    @Published var showPostDetail = false
    @Published var showNewPostForm = false
    
    private var currentPage = 0
    private let pageSize = 10
    private var canLoadMorePages = true
    private var feedSubscription: RealtimeChannelV2?
    private var cancellables = Set<AnyCancellable>()
    
    private let supabaseService = SupabaseService.shared
    
    init() {
        setupSubscriptions()
    }
    
    // MARK: - Feed Loading
    
    func loadFeed() async {
        guard !isLoading else { return }
        
        print("DEBUG: FeedViewModel.loadFeed - Starting feed load")
        isLoading = true
        currentPage = 0
        canLoadMorePages = true
        
        do {
            // First check the Supabase connection
            print("DEBUG: FeedViewModel.loadFeed - Testing Supabase connection")
            let connectionOk = await supabaseService.debugSupabaseConnection()
            if !connectionOk {
                print("ERROR: FeedViewModel.loadFeed - Supabase connection test failed")
                throw NSError(domain: "FeedViewModel", code: 2, 
                              userInfo: [NSLocalizedDescriptionKey: "Failed to connect to Supabase"])
            }
            
            // Try to fetch the feed posts
            print("DEBUG: FeedViewModel.loadFeed - Calling fetchFeedPosts")
            let feedPosts = try await fetchFeedPosts(limit: pageSize, offset: 0)
            print("DEBUG: FeedViewModel.loadFeed - Received \(feedPosts.count) posts from fetchFeedPosts")
            
            // Debug post data
            for (index, post) in feedPosts.enumerated() {
                print("DEBUG: Post \(index) - ID: \(post.id), Caption: \(post.caption), Images: \(post.imageUrls.count)")
            }
            
            posts = feedPosts
            canLoadMorePages = feedPosts.count == pageSize
            
            // If no posts were loaded from Supabase, add test posts
            if posts.isEmpty {
                print("DEBUG: FeedViewModel.loadFeed - No posts loaded from Supabase, adding test posts")
                addTestPosts()
            }
            
            print("DEBUG: FeedViewModel.loadFeed - Updated posts array, now has \(posts.count) posts")
        } catch {
            self.error = error
            print("ERROR: FeedViewModel.loadFeed - Failed with error: \(error)")
            
            // If there was an error loading posts, add test posts to showcase UI
            print("DEBUG: FeedViewModel.loadFeed - Loading failed, adding test posts to showcase UI")
            addTestPosts()
        }
        
        isLoading = false
        print("DEBUG: FeedViewModel.loadFeed - Completed feed load, isLoading set to false")
    }
    
    func loadMoreContentIfNeeded(currentItem: Post? = nil) async {
        guard !loadingMore, canLoadMorePages else { return }
        
        // If we don't have a current item, load more content
        guard let currentItem = currentItem else {
            await loadMoreContent()
            return
        }
        
        // Get the threshold index for pagination (5 items from the end)
        let thresholdIndex = posts.index(posts.endIndex, offsetBy: -5, limitedBy: posts.startIndex) ?? posts.startIndex
        
        // If we've reached the threshold, load more content
        if let itemIndex = posts.firstIndex(where: { $0.id == currentItem.id }),
           itemIndex == thresholdIndex {
            await loadMoreContent()
        }
    }
    
    private func loadMoreContent() async {
        guard !loadingMore, canLoadMorePages else { return }
        
        loadingMore = true
        currentPage += 1
        
        do {
            let nextPagePosts = try await fetchFeedPosts(
                limit: pageSize,
                offset: currentPage * pageSize
            )
            
            posts.append(contentsOf: nextPagePosts)
            canLoadMorePages = nextPagePosts.count == pageSize
        } catch {
            self.error = error
            print("Error loading more content: \(error)")
        }
        
        loadingMore = false
    }
    
    // MARK: - Post Interactions
    
    func likePost(_ post: Post) async {
        do {
            let isLiked = try await supabaseService.togglePostLike(postId: post.id)
            
            // Update the post in our collection
            if let index = posts.firstIndex(where: { $0.id == post.id }) {
                var updatedPost = posts[index]
                updatedPost.isLikedByCurrentUser = isLiked
                updatedPost.likeCount += isLiked ? 1 : -1
                posts[index] = updatedPost
            }
        } catch {
            self.error = error
            print("Error liking post: \(error)")
        }
    }
    
    func addComment(to post: Post, content: String) async {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        do {
            _ = try await supabaseService.addPostComment(
                postId: post.id,
                content: content
            )
            
            // Update the post comment count
            if let index = posts.firstIndex(where: { $0.id == post.id }) {
                var updatedPost = posts[index]
                updatedPost.commentCount += 1
                posts[index] = updatedPost
            }
            
            // If we're looking at the selected post, we could update its comments directly
            if let selectedPost = selectedPost, selectedPost.id == post.id {
                self.selectedPost?.commentCount += 1
            }
        } catch {
            self.error = error
            print("Error adding comment: \(error)")
        }
    }
    
    func createPost(caption: String, images: [UIImage], vehicle: Vehicle? = nil, location: CLLocationCoordinate2D? = nil, locationName: String? = nil) async -> Bool {
        isLoading = true
        
        do {
            // 1. Upload images
            var imageUrls: [String] = []
            
            guard let userId = await SupabaseService.shared.currentUserId() else {
                throw NSError(domain: "FeedViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
            }
            
            for image in images {
                let imageUrl = try await ImageUploadService.shared.uploadPostImage(
                    image,
                    userId: userId
                )
                imageUrls.append(imageUrl)
            }
            
            // 2. Create the post
            let newPost = Post.createNew(
                userId: userId,
                vehicleId: vehicle?.id,
                caption: caption,
                imageUrls: imageUrls,
                location: location,
                locationName: locationName
            )
            
            let createdPost = try await supabaseService.createPost(newPost)
            
            // 3. Add to the beginning of the feed
            posts.insert(createdPost, at: 0)
            
            isLoading = false
            return true
        } catch {
            self.error = error
            print("Error creating post: \(error)")
            isLoading = false
            return false
        }
    }
    
    // MARK: - Private Methods
    
    private func fetchFeedPosts(limit: Int, offset: Int) async throws -> [Post] {
        print("DEBUG: FeedViewModel.fetchFeedPosts - Starting call with count: \(limit), offset: \(offset)")
        
        do {
            print("DEBUG: FeedViewModel.fetchFeedPosts - Calling supabaseService.fetchFeedPosts")
            let posts = try await supabaseService.fetchFeedPosts(count: limit, offset: offset)
            print("DEBUG: FeedViewModel.fetchFeedPosts - Successfully received \(posts.count) posts")
            
            // Debug the post content if available
            if !posts.isEmpty {
                print("DEBUG: FeedViewModel.fetchFeedPosts - First post ID: \(posts[0].id), Caption: \(posts[0].caption)")
            } else {
                print("DEBUG: FeedViewModel.fetchFeedPosts - Received empty posts array")
            }
            
            return posts
        } catch {
            print("ERROR: FeedViewModel.fetchFeedPosts - Failed with error: \(error)")
            
            // Extract more detailed error information
            let nsError = error as NSError
            print("ERROR: FeedViewModel.fetchFeedPosts - Error domain: \(nsError.domain), code: \(nsError.code)")
            
            // Check for specific Postgrest errors
            if let errorDescription = nsError.userInfo[NSLocalizedDescriptionKey] as? String {
                print("ERROR: FeedViewModel.fetchFeedPosts - Error description: \(errorDescription)")
                
                if errorDescription.contains("function") && errorDescription.contains("get_feed_posts") {
                    print("ERROR: FeedViewModel.fetchFeedPosts - This appears to be an issue with the get_feed_posts database function")
                }
            }
            
            // Check for network connectivity issues
            if nsError.domain == NSURLErrorDomain {
                print("ERROR: FeedViewModel.fetchFeedPosts - This appears to be a network connectivity issue")
            }
            
            // Rethrow the error for the caller to handle
            throw error
        }
    }
    
    private func setupSubscriptions() {
        // Subscribe to post updates
        Task {
            do {
                feedSubscription = try await supabaseService.subscribeToFeed { [weak self] event in
                    Task { @MainActor in
                        guard let self = self else { return }
                        
                        switch event {
                        case .postCreated(let post):
                            // Add new post if it's not from the current user
                            Task {
                                if let currentUserId = await SupabaseService.shared.currentUserId(),
                                   post.userId != currentUserId,
                                   !self.posts.contains(where: { $0.id == post.id }) {
                                    await MainActor.run {
                                        self.posts.insert(post, at: 0)
                                    }
                                }
                            }
                            
                        case .postUpdated(let post):
                            // Update post if it exists
                            if let index = self.posts.firstIndex(where: { $0.id == post.id }) {
                                self.posts[index] = post
                            }
                            
                        case .postDeleted(let postId):
                            // Remove post if it exists
                            self.posts.removeAll(where: { $0.id == postId })
                            
                        case .postLiked(let postId, let likesCount):
                            // Update like count
                            if let index = self.posts.firstIndex(where: { $0.id == postId }) {
                                var updatedPost = self.posts[index]
                                updatedPost.likeCount = likesCount
                                self.posts[index] = updatedPost
                            }
                            
                        case .postCommented(let postId, let commentsCount):
                            // Update comment count
                            if let index = self.posts.firstIndex(where: { $0.id == postId }) {
                                var updatedPost = self.posts[index]
                                updatedPost.commentCount = commentsCount
                                self.posts[index] = updatedPost
                            }
                        }
                    }
                }
            } catch {
                print("Error setting up feed subscription: \(error)")
            }
        }
    }
    
    func cleanup() {
        Task {
            if let subscription = feedSubscription {
                await subscription.unsubscribe()
            }
        }
    }
    
    deinit {
        // Capture the subscription locally to avoid capturing self
        let localSubscription = feedSubscription
        
        // Create a Task to handle the cleanup without capturing self
        Task {
            if let subscription = localSubscription {
                await subscription.unsubscribe()
            }
        }
    }
    
    // MARK: - Test Posts for UI Development
    // This function adds test posts for UI development purposes
    // Note: This is a temporary function that can be removed once Supabase is properly configured
    func addTestPosts() {
        // Create test user
        let testUser = User(
            id: "test-user-1",
            email: "test@example.com",
            profile: User.Profile(
                name: "Test User",
                avatar: "person.circle.fill",
                avatarUrl: "https://images.pexels.com/photos/614810/pexels-photo-614810.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2",
                bio: "This is a test user for UI development",
                location: User.Profile.Location(
                    latitude: 37.7749,
                    longitude: -122.4194,
                    address: "San Francisco, CA"
                ),
                joinDate: Date(),
                social: User.Profile.Social(
                    instagram: "testuser",
                    facebook: "testuser",
                    twitter: "testuser"
                ),
                statusMessage: "Testing the app"
            ),
            vehicles: [],
            friends: [],
            isPremium: true,
            achievements: [],
            preferences: User.Preferences.defaultPreferences
        )
        
        // Create test vehicle
        let testVehicle = Vehicle(
            id: "test-vehicle-1",
            userId: testUser.id,
            make: "Toyota",
            model: "Supra",
            year: 2022,
            type: .car,
            modifications: ["Custom exhaust", "Lowered suspension", "ECU tune"],
            photos: ["https://images.pexels.com/photos/11546115/pexels-photo-11546115.jpeg?auto=compress&cs=tinysrgb&w=600"],
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Create test posts with car meet images from Pexels
        let post1 = Post(
            id: UUID().uuidString,
            userId: testUser.id,
            vehicleId: testVehicle.id,
            caption: "Just detailed my ride! Love how it turned out. #carlife #detailing #supra",
            imageUrls: [
                "https://images.pexels.com/photos/11546115/pexels-photo-11546115.jpeg?auto=compress&cs=tinysrgb&w=600",
                "https://images.pexels.com/photos/17358274/pexels-photo-17358274/free-photo-of-back-of-tuned-nissan-skyline.jpeg?auto=compress&cs=tinysrgb&w=300"
            ],
            location: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            locationName: "San Francisco, CA",
            createdAt: Date().addingTimeInterval(-86400), // 1 day ago
            updatedAt: Date().addingTimeInterval(-86400),
            likeCount: 42,
            commentCount: 7,
            isLikedByCurrentUser: true,
            user: testUser,
            vehicle: testVehicle
        )
        
        let post2 = Post(
            id: UUID().uuidString,
            userId: testUser.id,
            vehicleId: testVehicle.id,
            caption: "Early morning mountain run. Perfect weather and empty roads! #drivinglife #mountainroads",
            imageUrls: [
                "https://images.pexels.com/photos/18105162/pexels-photo-18105162/free-photo-of-green-audi-r8-at-dusk.jpeg?auto=compress&cs=tinysrgb&w=600",
                "https://images.pexels.com/photos/29248427/pexels-photo-29248427/free-photo-of-ford-mustang-drifting-at-outdoor-car-event.jpeg?auto=compress&cs=tinysrgb&w=300",
                "https://images.pexels.com/photos/10020075/pexels-photo-10020075.jpeg?auto=compress&cs=tinysrgb&w=300"
            ],
            location: CLLocationCoordinate2D(latitude: 37.8199, longitude: -122.4783),
            locationName: "Marin Headlands, CA",
            createdAt: Date().addingTimeInterval(-172800), // 2 days ago
            updatedAt: Date().addingTimeInterval(-172800),
            likeCount: 128,
            commentCount: 15,
            isLikedByCurrentUser: false,
            user: testUser,
            vehicle: testVehicle
        )
        
        let post3 = Post(
            id: UUID().uuidString,
            userId: testUser.id,
            vehicleId: testVehicle.id,
            caption: "New wheels just installed! What do you think? #wheels #newlook #modded",
            imageUrls: [
                "https://images.pexels.com/photos/19165516/pexels-photo-19165516/free-photo-of-custom-volkswagen-golf-gti.jpeg?auto=compress&cs=tinysrgb&w=600",
                "https://images.pexels.com/photos/30454671/pexels-photo-30454671/free-photo-of-vibrant-blue-and-maroon-cars-at-outdoor-car-show.jpeg?auto=compress&cs=tinysrgb&w=300"
            ],
            location: CLLocationCoordinate2D(latitude: 37.6879, longitude: -122.4702),
            locationName: "South San Francisco, CA",
            createdAt: Date().addingTimeInterval(-259200), // 3 days ago
            updatedAt: Date().addingTimeInterval(-259200),
            likeCount: 85,
            commentCount: 21,
            isLikedByCurrentUser: true,
            user: testUser,
            vehicle: testVehicle
        )
        
        // Add a fourth post with the car meet image
        let post4 = Post(
            id: UUID().uuidString,
            userId: testUser.id,
            vehicleId: testVehicle.id,
            caption: "Amazing turnout at the weekend car meet! #carmeet #autoshow #carculture",
            imageUrls: [
                "https://images.pexels.com/photos/17716334/pexels-photo-17716334/free-photo-of-a-group-of-cars-parked-in-a-parking-lot.jpeg?auto=compress&cs=tinysrgb&w=600",
                "https://images.pexels.com/photos/13010597/pexels-photo-13010597.jpeg?auto=compress&cs=tinysrgb&w=300"
            ],
            location: CLLocationCoordinate2D(latitude: 37.7847, longitude: -122.4095),
            locationName: "Golden Gate Park, SF",
            createdAt: Date().addingTimeInterval(-345600), // 4 days ago
            updatedAt: Date().addingTimeInterval(-345600),
            likeCount: 156,
            commentCount: 32,
            isLikedByCurrentUser: false,
            user: testUser,
            vehicle: testVehicle
        )
        
        // Add posts to the posts array
        posts = [post1, post2, post3, post4]
        
        print("DEBUG: FeedViewModel.addTestPosts - Added \(posts.count) test posts")
    }
}

enum FeedUpdateEvent {
    case postCreated(Post)
    case postUpdated(Post)
    case postDeleted(String)
    case postLiked(String, Int)
    case postCommented(String, Int)
} 
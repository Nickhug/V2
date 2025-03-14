import Foundation
import SwiftUI
import Combine
import CoreLocation

@MainActor
class StoriesViewModel: ObservableObject {
    // Published properties
    @Published var allUserStories: [UserStories] = []
    @Published var selectedUserStories: UserStories?
    @Published var currentStoryIndex: Int = 0
    @Published var isLoading: Bool = false
    @Published var isUploading: Bool = false
    @Published var error: Error?
    @Published var showStoryCreator: Bool = false
    @Published var showErrorMessage: Bool = false
    @Published var errorMessage: String = ""
    
    // Private properties
    private var cancellables = Set<AnyCancellable>()
    private let supabaseService = SupabaseService.shared
    private var currentUserId: UUID?
    
    init() {
        Task {
            currentUserId = try? await supabaseService.getCurrentUserId()
        }
    }
    
    // MARK: - Story Loading Methods
    
    /// Load all active stories from users the current user follows
    func loadAllStories() async {
        guard !isLoading else { return }
        
        isLoading = true
        do {
            // Fetch all active stories
            let stories = try await supabaseService.fetchActiveStories()
            
            // Group stories by user
            let storyDictionary = Dictionary(grouping: stories) { $0.userId }
            
            // Create UserStories objects
            var userStoriesArray: [UserStories] = []
            
            for (userId, userStories) in storyDictionary {
                if let firstStory = userStories.first {
                    let userStory = UserStories(
                        id: userId,
                        username: firstStory.username ?? "Unknown",
                        profileImageUrl: firstStory.profileImageUrl,
                        stories: userStories
                    )
                    userStoriesArray.append(userStory)
                }
            }
            
            // Sort: first the current user's stories, then by unviewed status, then by creation time
            userStoriesArray.sort { first, second in
                // Store current user ID to avoid async calls in sort
                let currentUserId = currentUserId
                
                // First, prioritize current user's stories
                if first.id == currentUserId {
                    return true
                }
                if second.id == currentUserId {
                    return false
                }
                
                // Then, prioritize stories with unviewed content
                if first.hasUnviewedStories && !second.hasUnviewedStories {
                    return true
                }
                if !first.hasUnviewedStories && second.hasUnviewedStories {
                    return false
                }
                
                // Finally, sort by latest story's creation time
                if let firstLatest = first.latestStory?.createdAt,
                   let secondLatest = second.latestStory?.createdAt {
                    return firstLatest > secondLatest
                }
                
                return false
            }
            
            // Update the published property
            allUserStories = userStoriesArray
            
            if allUserStories.isEmpty {
                print("No stories found")
            } else {
                print("Loaded \(allUserStories.count) user stories")
                for userStory in allUserStories {
                    print("User \(userStory.username): \(userStory.stories.count) stories")
                }
            }
        } catch {
            self.error = error
            showErrorMessage = true
            errorMessage = "Failed to load stories: \(error.localizedDescription)"
            print("Error loading stories: \(error)")
        }
        
        isLoading = false
    }
    
    /// Load stories for a specific user
    func loadUserStories(userId: UUID) async {
        guard !isLoading else { return }
        
        isLoading = true
        do {
            // Fetch user's stories
            let stories = try await supabaseService.fetchUserStories(userId: userId)
            
            if !stories.isEmpty, let firstStory = stories.first {
                // Create UserStories object
                selectedUserStories = UserStories(
                    id: userId,
                    username: firstStory.username ?? "Unknown",
                    profileImageUrl: firstStory.profileImageUrl,
                    stories: stories
                )
                
                // Reset current story index
                currentStoryIndex = 0
            } else {
                // No stories found
                selectedUserStories = nil
                currentStoryIndex = 0
            }
        } catch {
            self.error = error
            showErrorMessage = true
            errorMessage = "Failed to load user stories: \(error.localizedDescription)"
            print("Error loading user stories: \(error)")
        }
        
        isLoading = false
    }
    
    /// Mark a story as viewed
    func markStoryAsViewed(storyId: UUID) async {
        do {
            let success = try await supabaseService.markStoryAsViewed(storyId: storyId)
            
            if success {
                // Update UI to reflect viewed status
                if let selectedStories = selectedUserStories,
                   let storyIndex = selectedStories.stories.firstIndex(where: { $0.id == storyId }) {
                    // Update the story in selectedUserStories
                    let updatedStory = selectedStories.stories[storyIndex]
                    
                    // Create a new story object with hasViewed set to true
                    let viewedStory = Story(
                        id: updatedStory.id,
                        userId: updatedStory.userId,
                        mediaUrl: updatedStory.mediaUrl,
                        mediaType: updatedStory.mediaType,
                        caption: updatedStory.caption,
                        location: updatedStory.location,
                        locationName: updatedStory.locationName,
                        viewers: updatedStory.viewers,
                        isActive: updatedStory.isActive,
                        createdAt: updatedStory.createdAt,
                        expiresAt: updatedStory.expiresAt,
                        username: updatedStory.username,
                        profileImageUrl: updatedStory.profileImageUrl,
                        hasViewed: true
                    )
                    
                    // Update the story in the array
                    var updatedStories = selectedStories.stories
                    updatedStories[storyIndex] = viewedStory
                    
                    // Update the UserStories object
                    selectedUserStories = UserStories(
                        id: selectedStories.id,
                        username: selectedStories.username,
                        profileImageUrl: selectedStories.profileImageUrl,
                        stories: updatedStories
                    )
                    
                    // Also update the story in allUserStories
                    updateStoryInAllUserStories(storyId: storyId)
                }
            }
        } catch {
            print("Error marking story as viewed: \(error)")
            // Non-critical error, don't show to user
        }
    }
    
    /// Update a story in the allUserStories array to reflect viewed status
    private func updateStoryInAllUserStories(storyId: UUID) {
        // Find the UserStories object containing this story
        for (userIndex, userStories) in allUserStories.enumerated() {
            if let storyIndex = userStories.stories.firstIndex(where: { $0.id == storyId }) {
                // Create a new story with hasViewed set to true
                let updatedStory = userStories.stories[storyIndex]
                
                let viewedStory = Story(
                    id: updatedStory.id,
                    userId: updatedStory.userId,
                    mediaUrl: updatedStory.mediaUrl,
                    mediaType: updatedStory.mediaType,
                    caption: updatedStory.caption,
                    location: updatedStory.location,
                    locationName: updatedStory.locationName,
                    viewers: updatedStory.viewers,
                    isActive: updatedStory.isActive,
                    createdAt: updatedStory.createdAt,
                    expiresAt: updatedStory.expiresAt,
                    username: updatedStory.username,
                    profileImageUrl: updatedStory.profileImageUrl,
                    hasViewed: true
                )
                
                // Update the story in the array
                var updatedStories = userStories.stories
                updatedStories[storyIndex] = viewedStory
                
                // Update the UserStories object
                var updatedUserStories = userStories
                updatedUserStories.stories = updatedStories
                
                // Update the allUserStories array
                allUserStories[userIndex] = updatedUserStories
                
                break
            }
        }
    }
    
    // MARK: - Story Creation Methods
    
    /// Create a new story with an image
    func createImageStory(image: UIImage, caption: String? = nil, 
                         location: CLLocationCoordinate2D? = nil, locationName: String? = nil) async -> Bool {
        guard !isUploading else { return false }
        
        isUploading = true
        
        do {
            // First upload the image
            let mediaUrl = try await supabaseService.uploadStoryImage(image: image)
            
            // Get current user ID
            guard let userId = try await supabaseService.getCurrentUserId() else {
                throw NSError(domain: "StoriesViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not found"])
            }
            
            // Then create the story with the image URL
            _ = try await supabaseService.createStory(
                userId: userId,
                mediaUrl: mediaUrl,
                mediaType: .image,
                caption: caption,
                location: location,
                locationName: locationName
            )
            
            // Reload stories to include the new one
            await loadAllStories()
            
            isUploading = false
            return true
        } catch {
            isUploading = false
            self.error = error
            showErrorMessage = true
            errorMessage = "Failed to create story: \(error.localizedDescription)"
            print("Error creating image story: \(error)")
            return false
        }
    }
    
    /// Create a new story with a video
    func createVideoStory(videoURL: URL, caption: String? = nil, 
                         location: CLLocationCoordinate2D? = nil, locationName: String? = nil) async -> Bool {
        guard !isUploading else { return false }
        
        isUploading = true
        
        do {
            // First upload the video
            let mediaUrl = try await supabaseService.uploadStoryVideo(videoURL: videoURL)
            
            // Get current user ID
            guard let userId = try await supabaseService.getCurrentUserId() else {
                throw NSError(domain: "StoriesViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not found"])
            }
            
            // Then create the story with the video URL
            _ = try await supabaseService.createStory(
                userId: userId,
                mediaUrl: mediaUrl,
                mediaType: .video,
                caption: caption,
                location: location,
                locationName: locationName
            )
            
            // Reload stories to include the new one
            await loadAllStories()
            
            isUploading = false
            return true
        } catch {
            isUploading = false
            self.error = error
            showErrorMessage = true
            errorMessage = "Failed to create story: \(error.localizedDescription)"
            print("Error creating video story: \(error)")
            return false
        }
    }
    
    /// Delete a story
    func deleteStory(storyId: UUID) async -> Bool {
        do {
            let success = try await supabaseService.deleteStory(storyId: storyId)
            
            if success {
                // Remove the story from selectedUserStories
                if var selectedStories = selectedUserStories {
                    selectedStories.stories.removeAll { $0.id == storyId }
                    
                    if selectedStories.stories.isEmpty {
                        // If no stories left, set selectedUserStories to nil
                        selectedUserStories = nil
                    } else {
                        // Update selectedUserStories
                        selectedUserStories = selectedStories
                        
                        // Adjust currentStoryIndex if needed
                        if currentStoryIndex >= selectedStories.stories.count {
                            currentStoryIndex = selectedStories.stories.count - 1
                        }
                    }
                }
                
                // Remove the story from allUserStories
                for (index, userStories) in allUserStories.enumerated() {
                    if userStories.stories.contains(where: { $0.id == storyId }) {
                        var updatedUserStories = userStories
                        updatedUserStories.stories.removeAll { $0.id == storyId }
                        
                        if updatedUserStories.stories.isEmpty {
                            // If no stories left for this user, remove them from the array
                            allUserStories.remove(at: index)
                        } else {
                            // Update the user's stories
                            allUserStories[index] = updatedUserStories
                        }
                        
                        break
                    }
                }
                
                return true
            }
            
            return false
        } catch {
            self.error = error
            showErrorMessage = true
            errorMessage = "Failed to delete story: \(error.localizedDescription)"
            print("Error deleting story: \(error)")
            return false
        }
    }
    
    /// Share a story with an image
    func shareImageStory(image: UIImage, caption: String?, location: CLLocationCoordinate2D?, locationName: String?) async throws -> Bool {
        guard !isUploading else { return false }
        
        isUploading = true
        
        do {
            // First upload the image
            guard let mediaUrl = try await uploadMedia(image: image) else {
                isUploading = false
                throw NSError(domain: "StoriesViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to upload image"])
            }
            
            // Get current user ID
            guard let userId = try await supabaseService.getCurrentUserId() else {
                isUploading = false
                throw NSError(domain: "StoriesViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not found"])
            }
            
            // Then create the story with the image URL
            _ = try await supabaseService.createStory(
                userId: userId,
                mediaUrl: mediaUrl,
                mediaType: .image,
                caption: caption,
                location: location,
                locationName: locationName
            )
            
            // Reload stories to include the new one
            await loadAllStories()
            
            isUploading = false
            return true
        } catch {
            self.error = error
            showErrorMessage = true
            errorMessage = "Failed to share story: \(error.localizedDescription)"
            isUploading = false
            return false
        }
    }
    
    /// Share a story with a video
    func shareVideoStory(videoURL: URL, caption: String?, location: CLLocationCoordinate2D?, locationName: String?) async throws -> Bool {
        guard !isUploading else { return false }
        
        isUploading = true
        
        do {
            // First upload the video
            guard let mediaUrl = try await uploadMedia(videoURL: videoURL) else {
                isUploading = false
                throw NSError(domain: "StoriesViewModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to upload video"])
            }
            
            // Get current user ID
            guard let userId = try await supabaseService.getCurrentUserId() else {
                isUploading = false
                throw NSError(domain: "StoriesViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not found"])
            }
            
            // Then create the story with the video URL
            _ = try await supabaseService.createStory(
                userId: userId,
                mediaUrl: mediaUrl,
                mediaType: .video,
                caption: caption,
                location: location,
                locationName: locationName
            )
            
            // Reload stories to include the new one
            await loadAllStories()
            
            isUploading = false
            return true
        } catch {
            self.error = error
            showErrorMessage = true
            errorMessage = "Failed to share story: \(error.localizedDescription)"
            isUploading = false
            return false
        }
    }
    
    // MARK: - Story Navigation Methods
    
    /// Navigate to the next story
    func nextStory() async {
        guard let stories = selectedUserStories?.stories, !stories.isEmpty else {
            return
        }
        
        if currentStoryIndex < stories.count - 1 {
            // Move to the next story of the current user
            currentStoryIndex += 1
        } else {
            // Move to the first story of the next user
            await nextUser()
        }
    }
    
    /// Navigate to the previous story
    func previousStory() async {
        if currentStoryIndex > 0 {
            // Move to the previous story of the current user
            currentStoryIndex -= 1
        } else {
            // Move to the last story of the previous user
            await previousUser()
        }
    }
    
    /// Navigate to the next user's stories
    func nextUser() async {
        guard let currentUser = selectedUserStories, let userIndex = allUserStories.firstIndex(where: { $0.id == currentUser.id }) else {
            return
        }
        
        if userIndex < allUserStories.count - 1 {
            // Move to the next user
            selectedUserStories = allUserStories[userIndex + 1]
            currentStoryIndex = 0
        } else {
            // If we're at the last user, close the story viewer
            selectedUserStories = nil
            currentStoryIndex = 0
        }
    }
    
    /// Navigate to the previous user's stories
    func previousUser() async {
        guard let currentUser = selectedUserStories, let userIndex = allUserStories.firstIndex(where: { $0.id == currentUser.id }) else {
            return
        }
        
        if userIndex > 0 {
            // Move to the previous user
            selectedUserStories = allUserStories[userIndex - 1]
            // Start with the last story of the previous user
            currentStoryIndex = allUserStories[userIndex - 1].stories.count - 1
        } else {
            // If we're at the first user, stay on the first story
            currentStoryIndex = 0
        }
    }
    
    /// Select a specific user's stories by ID
    func selectUserStories(userId: UUID) {
        if let userStories = allUserStories.first(where: { $0.id == userId }) {
            selectedUserStories = userStories
            currentStoryIndex = 0
        }
    }
    
    // MARK: - Helper Methods
    
    /// Check if the current user has any active stories
    func currentUserHasStories() async -> Bool {
        guard let currentUserId = try? await supabaseService.getCurrentUserId() else {
            return false
        }
        
        return allUserStories.contains { $0.id == currentUserId && !$0.stories.isEmpty }
    }
    
    /// Get the current user's stories
    func getCurrentUserStories() async -> UserStories? {
        guard let currentUserId = try? await supabaseService.getCurrentUserId() else {
            return nil
        }
        
        return allUserStories.first { $0.id == currentUserId }
    }
    
    /// Get the current story being viewed
    var currentStory: Story? {
        guard let selectedStories = selectedUserStories, !selectedStories.stories.isEmpty else {
            return nil
        }
        
        guard currentStoryIndex >= 0 && currentStoryIndex < selectedStories.stories.count else {
            return nil
        }
        
        return selectedStories.stories[currentStoryIndex]
    }
    
    /// Upload media (image or video) to storage and return the public URL
    private func uploadMedia(image: UIImage? = nil, videoURL: URL? = nil) async throws -> String? {
        if let image = image {
            // Handle image upload
            return try await supabaseService.uploadStoryImage(image: image)
        } else if let videoURL = videoURL {
            // Handle video upload
            return try await supabaseService.uploadStoryVideo(videoURL: videoURL)
        }
        
        return nil
    }
} 
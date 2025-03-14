# Stories Feature Implementation Plan

## Overview
The goal is to implement an Instagram-like Stories feature for the FeedView, allowing users to create, view, and interact with ephemeral content that disappears after 24 hours.

## Database Schema Updates

### 1. Create new `stories` table
```sql
CREATE TABLE public.stories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    media_url TEXT NOT NULL,
    media_type TEXT NOT NULL DEFAULT 'image', -- 'image' or 'video'
    caption TEXT,
    location POINT,
    location_name TEXT,
    viewers UUID[] DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()),
    expires_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now() + interval '24 hours')
);
```

### 2. Create indices for performance
```sql
CREATE INDEX stories_user_id_idx ON public.stories(user_id);
CREATE INDEX stories_expires_at_idx ON public.stories(expires_at);
```

### 3. Create RPC functions for Stories
- `get_active_stories` - Get all active stories from users you follow
- `get_user_stories` - Get a specific user's active stories
- `create_story` - Create a new story
- `mark_story_as_viewed` - Add current user to the viewers array
- `delete_story` - Delete a specific story

## Swift Models

### 1. Story Model
```swift
struct Story: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID
    let mediaUrl: String
    let mediaType: MediaType
    let caption: String?
    let location: CLLocationCoordinate2D?
    let locationName: String?
    let viewers: [UUID]
    let isActive: Bool
    let createdAt: Date
    let expiresAt: Date
    
    enum MediaType: String, Codable {
        case image
        case video
    }
    
    // Computed properties
    var timeRemaining: TimeInterval {
        return expiresAt.timeIntervalSince(Date())
    }
    
    var viewCount: Int {
        return viewers.count
    }
    
    var isExpired: Bool {
        return Date() >= expiresAt
    }
}
```

### 2. User Stories Model
```swift
struct UserStories: Identifiable {
    let id: UUID // user_id
    let username: String
    let profileImageUrl: String?
    var stories: [Story]
    var hasUnviewedStories: Bool
    
    // Computed properties
    var latestStory: Story? {
        return stories.max(by: { $0.createdAt < $1.createdAt })
    }
}
```

## View Models

### 1. StoriesViewModel
```swift
class StoriesViewModel: ObservableObject {
    @Published var allUserStories: [UserStories] = []
    @Published var selectedUserStories: UserStories?
    @Published var currentStoryIndex: Int = 0
    @Published var isLoading: Bool = false
    @Published var error: Error?
    @Published var showStoryCreator: Bool = false
    
    // Methods
    func loadAllStories() async
    func loadUserStories(userId: UUID) async
    func markStoryAsViewed(storyId: UUID) async
    func createStory(mediaUrl: String, mediaType: Story.MediaType, caption: String?, location: CLLocationCoordinate2D?, locationName: String?) async
    func deleteStory(storyId: UUID) async
}
```

### 2. StoryCreationViewModel
```swift
class StoryCreationViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var selectedVideo: URL?
    @Published var caption: String = ""
    @Published var location: CLLocationCoordinate2D?
    @Published var locationName: String?
    @Published var isLoading: Bool = false
    @Published var error: Error?
    
    // Methods
    func uploadStory() async -> Bool
    func capturePhoto()
    func recordVideo()
    func selectFromLibrary()
}
```

## UI Components

### 1. StoriesBarView
- Horizontal scrolling bar at the top of FeedView showing story avatars
- Gradient ring for unviewed stories, gray ring for viewed stories
- "+" button for creating your own story

### 2. StoryPlayerView
- Fullscreen view for viewing stories
- Progress bars at top showing story segments
- Tap left/right to navigate between stories
- Swipe to navigate between users
- Story creation UI (camera, gallery selection)
- User info and caption display
- Animation for transitions and progress

### 3. StoryCreationView
- Camera access for capturing photos/videos
- Gallery access for selecting media
- Text input for captions
- Location selection
- Upload progress indicator
- Preview of the story before posting

## Implementation Steps

### Phase 1: Database Setup
1. Create the stories table in Supabase
2. Create necessary indices for performance
3. Implement RPC functions for story operations

### Phase 2: Backend Integration
1. Create Story and UserStories models in Swift
2. Update SupabaseService to include story-related methods
3. Create StoriesViewModel and StoryCreationViewModel

### Phase 3: UI Implementation
1. Create StoriesBarView for FeedView
2. Implement StoryPlayerView for viewing stories
3. Build StoryCreationView for creating new stories

### Phase 4: Integration with FeedView
1. Add StoriesBarView to the top of FeedView
2. Connect view models and update FeedViewModel
3. Handle navigation and state management

### Phase 5: Testing and Optimization
1. Test the feature with different user scenarios
2. Optimize performance, especially for video stories
3. Handle edge cases (expired stories, network issues)

## Timeline
- Phase 1 (Database Setup): 1 day
- Phase 2 (Backend Integration): 2 days
- Phase 3 (UI Implementation): 3 days
- Phase 4 (Integration with FeedView): 1 day
- Phase 5 (Testing and Optimization): 1 day

Total: ~8 days for complete implementation

## Required Assets
- Camera and gallery access
- Story creation icon
- Story navigation icons
- Story viewing UI elements
- Progress indicators

## Key Considerations
- Stories should expire automatically after 24 hours
- Handle proper permissions for camera and photo library access
- Optimize media loading for performance
- Implement proper caching for viewed stories
- Ensure smooth transitions between stories
- Consider privacy settings for story viewing 
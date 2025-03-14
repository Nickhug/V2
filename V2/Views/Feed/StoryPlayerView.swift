import SwiftUI
import AVKit

struct StoryPlayerView: View {
    @ObservedObject var viewModel: StoriesViewModel
    @Binding var isVisible: Bool
    
    // Story progress timer
    @State private var storyProgress: CGFloat = 0
    @State private var timer: Timer? = nil
    @State private var storyDuration: TimeInterval = 5.0 // 5 seconds for images, varies for videos
    @State private var isPaused: Bool = false
    @State private var videoPlayer: AVPlayer? = nil
    
    // Gesture properties
    @State private var offset: CGFloat = 0
    @State private var dragDirection: DragDirection = .none
    enum DragDirection {
        case left, right, up, down, none
    }
    
    var body: some View {
        ZStack {
            // Background color
            Color.black.edgesIgnoringSafeArea(.all)
            
            if let story = viewModel.currentStory {
                // Content based on story
                VStack(spacing: 0) {
                    // Progress bar at the top
                    progressBar
                    
                    // Story content with gestures
                    ZStack {
                        // Media content (image or video)
                        mediaContent(for: story)
                        
                        // Overlay elements
                        VStack {
                            // User info at the top
                            userInfoHeader(for: story)
                            
                            Spacer()
                            
                            // Caption at the bottom if exists
                            if let caption = story.caption, !caption.isEmpty {
                                captionView(caption: caption)
                            }
                        }
                        .padding(.vertical)
                    }
                }
                .onAppear {
                    resetTimer()
                    startStoryTimer()
                    // Mark the story as viewed
                    Task {
                        await viewModel.markStoryAsViewed(storyId: story.id)
                    }
                }
                .onDisappear {
                    stopTimer()
                    videoPlayer?.pause()
                    videoPlayer = nil
                }
                .gesture(
                    DragGesture(minimumDistance: 20)
                        .onChanged { gesture in
                            let translation = gesture.translation
                            
                            // Determine drag direction
                            if abs(translation.width) > abs(translation.height) {
                                // Horizontal drag
                                if translation.width > 0 {
                                    dragDirection = .right
                                } else {
                                    dragDirection = .left
                                }
                                offset = translation.width
                            } else {
                                // Vertical drag
                                if translation.height > 0 {
                                    dragDirection = .down
                                } else {
                                    dragDirection = .up
                                }
                                offset = translation.height
                            }
                            
                            // Pause the timer while dragging
                            isPaused = true
                        }
                        .onEnded { gesture in
                            // Apply the appropriate action based on drag direction
                            switch dragDirection {
                            case .left:
                                Task { @MainActor in
                                    await viewModel.nextStory()
                                }
                            case .right:
                                Task { @MainActor in
                                    await viewModel.previousStory()
                                }
                            case .down:
                                isVisible = false
                            default:
                                break
                            }
                            
                            // Reset states
                            offset = 0
                            dragDirection = .none
                            isPaused = false
                            resetTimer()
                        }
                )
                // Tap gestures for navigation
                .contentShape(Rectangle())
                .onTapGesture { location in
                    let width = UIScreen.main.bounds.width
                    if location.x < width * 0.3 {
                        // Left side tap - go to previous story
                        Task { @MainActor in
                            await viewModel.previousStory()
                        }
                    } else if location.x > width * 0.7 {
                        // Right side tap - go to next story
                        Task { @MainActor in
                            await viewModel.nextStory()
                        }
                    } else {
                        // Middle tap - pause/resume
                        isPaused.toggle()
                    }
                }
                .onChange(of: viewModel.currentStoryIndex) { _, _ in
                    resetTimer()
                    videoPlayer?.pause()
                    videoPlayer = nil
                }
            } else {
                // No story available - show close button
                Button("Close") {
                    isVisible = false
                }
                .foregroundColor(.white)
            }
        }
        .onDisappear {
            stopTimer()
            videoPlayer?.pause()
            videoPlayer = nil
        }
    }
    
    // MARK: - UI Components
    
    private var progressBar: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let segmentWidth = totalWidth / CGFloat(viewModel.selectedUserStories?.stories.count ?? 1)
            let padding: CGFloat = 2
            
            HStack(spacing: padding) {
                if let userStories = viewModel.selectedUserStories {
                    ForEach(0..<userStories.stories.count, id: \.self) { index in
                        ZStack(alignment: .leading) {
                            // Background bar
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 2)
                            
                            // Progress bar
                            Rectangle()
                                .fill(Color.white)
                                .frame(width: index < viewModel.currentStoryIndex ? segmentWidth : 
                                      (index == viewModel.currentStoryIndex ? segmentWidth * storyProgress : 0), 
                                      height: 2)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .frame(height: 10)
        }
        .frame(height: 10)
    }
    
    private func userInfoHeader(for story: Story) -> some View {
        HStack {
            // User avatar
            AsyncImageView(imageName: "", avatarUrl: story.profileImageUrl)
                .frame(width: 36, height: 36)
                .clipShape(Circle())
            
            // Username and time
            VStack(alignment: .leading) {
                Text(story.username ?? "Unknown")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(timeAgo(from: story.createdAt))
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // Close button
            Button(action: {
                isVisible = false
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Circle().fill(Color.black.opacity(0.3)))
            }
        }
        .padding(.horizontal)
    }
    
    private func captionView(caption: String) -> some View {
        Text(caption)
            .font(.callout)
            .foregroundColor(.white)
            .padding()
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.3)))
            .padding(.horizontal)
    }
    
    private func mediaContent(for story: Story) -> some View {
        Group {
            if story.mediaType == .image {
                // Image content
                imageView(url: story.mediaUrl)
            } else {
                // Video content
                videoView(url: story.mediaUrl)
            }
        }
    }
    
    private func imageView(url: String) -> some View {
        AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .tint(.white)
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .transition(.opacity)
            case .failure:
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundColor(.white)
            @unknown default:
                EmptyView()
            }
        }
        .onAppear {
            // Set duration for image
            storyDuration = 5.0
            resetTimer()
        }
    }
    
    private func videoView(url: String) -> some View {
        VideoPlayerView(url: URL(string: url), player: $videoPlayer, isPlaying: .constant(!isPaused))
            .onAppear {
                // Set duration for video (retrieved from the video's duration)
                if let player = videoPlayer {
                    // Observe when the player is ready
                    NotificationCenter.default.addObserver(
                        forName: .AVPlayerItemDidPlayToEndTime,
                        object: player.currentItem,
                        queue: .main
                    ) { _ in
                        Task { @MainActor in
                            await viewModel.nextStory()
                        }
                    }
                    
                    // Get video duration
                    if let item = player.currentItem {
                        storyDuration = item.duration.seconds
                        resetTimer()
                    }
                }
            }
    }
    
    // MARK: - Timer Functions
    
    private func startStoryTimer() {
        guard timer == nil else { return }
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if !isPaused {
                let increment = 0.1 / storyDuration
                storyProgress += CGFloat(increment)
                
                if storyProgress >= 1.0 {
                    stopTimer()
                    Task { @MainActor in
                        await viewModel.nextStory()
                    }
                }
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func resetTimer() {
        stopTimer()
        storyProgress = 0
        startStoryTimer()
    }
    
    // MARK: - Utility Functions
    
    private func timeAgo(from date: Date) -> String {
        let now = Date()
        let components = Calendar.current.dateComponents([.second, .minute, .hour, .day], from: date, to: now)
        
        if let day = components.day, day > 0 {
            return "\(day)d ago"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)h ago"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute)m ago"
        } else if let second = components.second, second > 0 {
            return "\(second)s ago"
        }
        return "now"
    }
}

// Helper view for video playback
struct VideoPlayerView: UIViewControllerRepresentable {
    let url: URL?
    @Binding var player: AVPlayer?
    @Binding var isPlaying: Bool
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        
        if let validURL = url {
            let player = AVPlayer(url: validURL)
            controller.player = player
            self.player = player
            
            // Configure player
            controller.showsPlaybackControls = false
            controller.videoGravity = .resizeAspectFill
            player.play()
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        if isPlaying {
            uiViewController.player?.play()
        } else {
            uiViewController.player?.pause()
        }
    }
}

struct StoryPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        StoryPlayerView(
            viewModel: StoriesViewModel(),
            isVisible: .constant(true)
        )
    }
} 
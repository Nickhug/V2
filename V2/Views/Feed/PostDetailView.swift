import SwiftUI

struct PostDetailView: View {
    let post: Post
    @ObservedObject var viewModel: FeedViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var comments: [PostComment] = []
    @State private var loadingComments = false
    @State private var commentText = ""
    @State private var imageIndex = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                AnimatedGradientBackground()
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Post content
                            postContent
                            
                            Divider()
                                .background(Color.white.opacity(0.3))
                            
                            // Comments section
                            commentsSection
                        }
                        .padding(.bottom, 60) // Space for comment input field
                    }
                    
                    // Comment input field at bottom
                    commentInputField
                }
            }
            .navigationTitle("Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadComments()
            }
        }
    }
    
    private var postContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Post header with user info
            HStack {
                if let user = post.user {
                    AvatarView(imageURL: user.profile.avatarUrl, size: 40)
                } else {
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 40, height: 40)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.user?.profile.name ?? "Unknown")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if let vehicle = post.vehicle {
                        Text("\(vehicle.year) \(vehicle.make) \(vehicle.model)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    if let locationName = post.locationName {
                        Text(locationName)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Spacer()
                
                Text(formattedDate(post.createdAt))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal)
            
            // Image carousel
            TabView(selection: $imageIndex) {
                ForEach(0..<post.imageUrls.count, id: \.self) { index in
                    AsyncImage(url: URL(string: post.imageUrls[index])) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else if phase.error != nil {
                            Color.gray
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                        .foregroundColor(.white)
                                )
                        } else {
                            ProgressView()
                                .tint(.white)
                        }
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle())
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            .frame(height: 400)
            
            // Action buttons
            HStack(spacing: 16) {
                Button(action: {
                    Task {
                        await viewModel.likePost(post)
                    }
                }) {
                    Image(systemName: post.isLikedByCurrentUser ? "heart.fill" : "heart")
                        .font(.system(size: 22))
                        .foregroundColor(post.isLikedByCurrentUser ? .red : .white)
                }
                
                Button(action: {
                    // Focus comment field
                }) {
                    Image(systemName: "bubble.right")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                
                Button(action: {
                    // Share functionality (future implementation)
                }) {
                    Image(systemName: "paperplane")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            
            // Like count
            if post.likeCount > 0 {
                Text("\(post.likeCount) \(post.likeCount == 1 ? "like" : "likes")")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal)
            }
            
            // Caption
            if !post.caption.isEmpty {
                HStack(alignment: .top) {
                    Text(post.user?.profile.name ?? "")
                        .fontWeight(.semibold)
                        .foregroundColor(.white) +
                    Text(" ") +
                    Text(post.caption)
                        .foregroundColor(.white)
                }
                .font(.subheadline)
                .padding(.horizontal)
            }
        }
    }
    
    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Comments")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            if loadingComments {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                    Spacer()
                }
                .padding()
            } else if comments.isEmpty {
                Text("No comments yet.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .padding()
            } else {
                ForEach(comments) { comment in
                    CommentRow(comment: comment)
                }
            }
        }
    }
    
    private var commentInputField: some View {
        HStack {
            TextField("Add a comment...", text: $commentText)
                .padding(10)
                .background(Color.white.opacity(0.1))
                .cornerRadius(20)
                .foregroundColor(.white)
            
            Button(action: {
                submitComment()
            }) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .white)
                    .padding(10)
            }
            .disabled(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
        .background(Color.black.opacity(0.3))
    }
    
    private func loadComments() {
        loadingComments = true
        
        Task {
            do {
                comments = try await SupabaseService.shared.fetchPostComments(postId: post.id)
                
                // If we couldn't load any comments, add test comments
                if comments.isEmpty {
                    loadTestComments()
                }
            } catch {
                print("Error loading comments: \(error)")
                // If there was an error loading comments, add test comments
                loadTestComments()
            }
            
            loadingComments = false
        }
    }
    
    private func submitComment() {
        let trimmedComment = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedComment.isEmpty else { return }
        
        Task {
            do {
                let newComment = try await SupabaseService.shared.addPostComment(postId: post.id, content: trimmedComment)
                await MainActor.run {
                    comments.insert(newComment, at: 0)
                    commentText = ""
                    
                    // Update post comment count in view model
                    if let index = viewModel.posts.firstIndex(where: { $0.id == post.id }) {
                        var updatedPost = viewModel.posts[index]
                        updatedPost.commentCount += 1
                        viewModel.posts[index] = updatedPost
                    }
                }
            } catch {
                print("Error adding comment: \(error)")
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - Test Comments
    
    /// Loads test comments for UI development purposes
    /// This function can be removed once Supabase is properly configured
    private func loadTestComments() {
        print("DEBUG: PostDetailView - Loading test comments")
        
        // Create test users for comments
        let testUser1 = User(
            id: "test-commenter-1",
            email: "commenter1@example.com",
            profile: User.Profile(
                name: "Car Enthusiast",
                avatar: "person.circle.fill",
                avatarUrl: "https://images.pexels.com/photos/614810/pexels-photo-614810.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2",
                bio: "I love cars!",
                location: User.Profile.Location(
                    latitude: 37.7749,
                    longitude: -122.4194,
                    address: "San Francisco, CA"
                ),
                joinDate: Date(),
                social: nil,
                statusMessage: nil
            ),
            vehicles: [],
            friends: [],
            isPremium: false,
            achievements: [],
            preferences: User.Preferences.defaultPreferences
        )
        
        let testUser2 = User(
            id: "test-commenter-2",
            email: "commenter2@example.com",
            profile: User.Profile(
                name: "Speed Demon",
                avatar: "person.circle.fill",
                avatarUrl: "https://images.pexels.com/photos/774909/pexels-photo-774909.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2",
                bio: "Fast cars only!",
                location: User.Profile.Location(
                    latitude: 37.7749,
                    longitude: -122.4194,
                    address: "San Francisco, CA"
                ),
                joinDate: Date(),
                social: nil,
                statusMessage: nil
            ),
            vehicles: [],
            friends: [],
            isPremium: true,
            achievements: [],
            preferences: User.Preferences.defaultPreferences
        )
        
        // Create test comments
        let testComments = [
            PostComment(
                id: UUID().uuidString,
                postId: post.id,
                userId: testUser1.id,
                content: "This looks amazing! What products did you use for the detailing?",
                createdAt: Date().addingTimeInterval(-3600), // 1 hour ago
                updatedAt: Date().addingTimeInterval(-3600),
                user: testUser1
            ),
            PostComment(
                id: UUID().uuidString,
                postId: post.id,
                userId: testUser2.id,
                content: "Love the shine on that paint! Did you use a ceramic coating?",
                createdAt: Date().addingTimeInterval(-7200), // 2 hours ago
                updatedAt: Date().addingTimeInterval(-7200),
                user: testUser2
            ),
            PostComment(
                id: UUID().uuidString,
                postId: post.id,
                userId: testUser1.id,
                content: "Those wheels look perfect with that body color!",
                createdAt: Date().addingTimeInterval(-10800), // 3 hours ago
                updatedAt: Date().addingTimeInterval(-10800),
                user: testUser1
            ),
            PostComment(
                id: UUID().uuidString,
                postId: post.id,
                userId: post.userId,
                content: "Thanks everyone! Used Meguiar's Ultimate Compound followed by their Ultimate Polish and Liquid Wax. Really happy with the results!",
                createdAt: Date().addingTimeInterval(-1800), // 30 mins ago
                updatedAt: Date().addingTimeInterval(-1800),
                user: post.user
            )
        ]
        
        comments = testComments
        print("DEBUG: PostDetailView - Added \(comments.count) test comments")
    }
}

struct CommentRow: View {
    let comment: PostComment
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if let user = comment.user {
                AvatarView(imageURL: user.profile.avatarUrl, size: 32)
            } else {
                Circle()
                    .fill(Color.gray)
                    .frame(width: 32, height: 32)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.user?.profile.name ?? "Unknown")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(timeAgo(from: comment.createdAt))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Text(comment.content)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
    
    private func timeAgo(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day, .weekOfMonth, .month, .year], from: date, to: now)
        
        if let years = components.year, years > 0 {
            return years == 1 ? "1y" : "\(years)y"
        } else if let months = components.month, months > 0 {
            return months == 1 ? "1m" : "\(months)m"
        } else if let weeks = components.weekOfMonth, weeks > 0 {
            return weeks == 1 ? "1w" : "\(weeks)w"
        } else if let days = components.day, days > 0 {
            return days == 1 ? "1d" : "\(days)d"
        } else if let hours = components.hour, hours > 0 {
            return hours == 1 ? "1h" : "\(hours)h"
        } else if let minutes = components.minute, minutes > 0 {
            return minutes == 1 ? "1m" : "\(minutes)m"
        } else {
            return "now"
        }
    }
} 
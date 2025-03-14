import SwiftUI

struct PostCardView: View {
    let post: Post
    @ObservedObject var viewModel: FeedViewModel
    
    @State private var imageIndex = 0
    @State private var commentText = ""
    @State private var showingCommentField = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Post header with user info
            postHeader
            
            // Post images with pager
            imageCarousel
            
            // Action buttons (like, comment)
            actionButtons
            
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
            
            // Comment count & view all comments button
            if post.commentCount > 0 {
                Button(action: {
                    viewModel.selectedPost = post
                    viewModel.showPostDetail = true
                }) {
                    Text("View all \(post.commentCount) comments")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal)
                }
            }
            
            // Timestamp
            Text(timeAgo(from: post.createdAt))
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal)
                .padding(.top, 2)
            
            // Comment field
            if showingCommentField {
                HStack {
                    TextField("Add a comment...", text: $commentText)
                        .font(.subheadline)
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                    
                    Button(action: {
                        submitComment()
                    }) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16))
                            .foregroundColor(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .white)
                    }
                    .disabled(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
            }
        }
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
    
    private var postHeader: some View {
        HStack {
            // User avatar
            if let user = post.user {
                AvatarView(imageURL: user.profile.avatarUrl, size: 36)
            } else {
                Circle()
                    .fill(Color.gray)
                    .frame(width: 36, height: 36)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                // Username
                Text(post.user?.profile.name ?? "Unknown")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                // Vehicle info if available
                if let vehicle = post.vehicle {
                    Text("\(vehicle.year) \(vehicle.make) \(vehicle.model)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // Location if available
                if let locationName = post.locationName {
                    Text(locationName)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Spacer()
            
            // More options button
            Button(action: {
                // Show options menu (for future implementation)
            }) {
                Image(systemName: "ellipsis")
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal)
    }
    
    private var imageCarousel: some View {
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
        .cornerRadius(8)
        .padding(.horizontal, 8)
    }
    
    private var actionButtons: some View {
        HStack(spacing: 16) {
            // Like button
            Button(action: {
                Task {
                    await viewModel.likePost(post)
                }
            }) {
                Image(systemName: post.isLikedByCurrentUser ? "heart.fill" : "heart")
                    .font(.system(size: 22))
                    .foregroundColor(post.isLikedByCurrentUser ? .red : .white)
            }
            
            // Comment button
            Button(action: {
                withAnimation {
                    showingCommentField.toggle()
                }
            }) {
                Image(systemName: "bubble.right")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
            
            // Share button
            Button(action: {
                // Share functionality (future implementation)
            }) {
                Image(systemName: "paperplane")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Pagination indicators if multiple images
            if post.imageUrls.count > 1 {
                HStack(spacing: 4) {
                    ForEach(0..<post.imageUrls.count, id: \.self) { index in
                        Circle()
                            .fill(index == imageIndex ? Color.white : Color.white.opacity(0.4))
                            .frame(width: 6, height: 6)
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private func submitComment() {
        let trimmedComment = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedComment.isEmpty else { return }
        
        Task {
            await viewModel.addComment(to: post, content: trimmedComment)
            commentText = ""
            
            // Close comment field
            withAnimation {
                showingCommentField = false
            }
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day, .weekOfMonth, .month, .year], from: date, to: now)
        
        if let years = components.year, years > 0 {
            return years == 1 ? "1 year ago" : "\(years) years ago"
        } else if let months = components.month, months > 0 {
            return months == 1 ? "1 month ago" : "\(months) months ago"
        } else if let weeks = components.weekOfMonth, weeks > 0 {
            return weeks == 1 ? "1 week ago" : "\(weeks) weeks ago"
        } else if let days = components.day, days > 0 {
            return days == 1 ? "1 day ago" : "\(days) days ago"
        } else if let hours = components.hour, hours > 0 {
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        } else if let minutes = components.minute, minutes > 0 {
            return minutes == 1 ? "1 minute ago" : "\(minutes) minutes ago"
        } else {
            return "Just now"
        }
    }
} 
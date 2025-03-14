import SwiftUI

struct StoriesBarView: View {
    @ObservedObject var viewModel: StoriesViewModel
    @Binding var showStoryViewer: Bool
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Add story button
                createStoryButton
                
                // Story avatars
                ForEach(viewModel.allUserStories) { userStory in
                    StoryAvatarView(userStory: userStory)
                        .onTapGesture {
                            viewModel.selectUserStories(userId: userStory.id)
                            showStoryViewer = true
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(height: 100)
    }
    
    private var createStoryButton: some View {
        Button(action: {
            viewModel.showStoryCreator = true
        }) {
            VStack {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 68, height: 68)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 28))
                        .foregroundColor(.black)
                }
                
                Text("Your Story")
                    .font(.caption)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .frame(width: 70)
            }
        }
    }
}

struct StoryAvatarView: View {
    let userStory: UserStories
    
    var body: some View {
        VStack {
            ZStack {
                // Gradient ring for unwatched stories, gray ring for watched stories
                if userStory.hasUnviewedStories {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.purple, Color.blue, Color.cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2.5
                        )
                        .frame(width: 68, height: 68)
                } else {
                    Circle()
                        .stroke(Color.gray, lineWidth: 1.5)
                        .frame(width: 68, height: 68)
                }
                
                // Profile image
                AsyncImageView(imageName: "", avatarUrl: userStory.profileImageUrl)
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
            }
            
            // Username
            Text(userStory.username)
                .font(.caption)
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(width: 70)
        }
    }
}

// Remove the duplicate AsyncImageView definition since we're using the one from Components

struct StoriesBarView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            StoriesBarView(
                viewModel: StoriesViewModel(),
                showStoryViewer: .constant(false)
            )
        }
    }
} 
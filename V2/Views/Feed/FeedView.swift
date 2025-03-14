import SwiftUI

struct FeedView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = FeedViewModel()
    @StateObject private var storiesViewModel = StoriesViewModel()
    @State private var isRefreshing = false
    @State private var showStoryViewer = false
    
    var body: some View {
        ZStack {
            AnimatedGradientBackground()
            
            VStack(spacing: 0) {
                // Feed header
                feedHeader
                
                if viewModel.isLoading && viewModel.posts.isEmpty {
                    // Loading state when initially loading posts
                    loadingView
                        .debugPrint("FeedView - Showing loading state")
                } else if viewModel.posts.isEmpty {
                    // Empty state
                    emptyFeedView
                        .debugPrint("FeedView - Showing empty state, posts array is empty")
                } else {
                    // Posts feed
                    feedContent
                        .debugPrint("FeedView - Showing feed content with", viewModel.posts.count)
                }
            }
        }
        .onAppear {
            // Load feed when view appears
            print("DEBUG: FeedView - onAppear triggered")
            Task {
                print("DEBUG: FeedView - Starting loadFeed task")
                await viewModel.loadFeed()
                print("DEBUG: FeedView - Completed loadFeed task")
                
                // Load stories
                await storiesViewModel.loadAllStories()
            }
        }
        .sheet(isPresented: $viewModel.showNewPostForm) {
            PostCreationView(viewModel: viewModel)
        }
        .sheet(item: $viewModel.selectedPost) { post in
            PostDetailView(post: post, viewModel: viewModel)
        }
        .sheet(isPresented: $storiesViewModel.showStoryCreator) {
            StoryCreationView(viewModel: StoryCreationViewModel(storiesViewModel: storiesViewModel), isPresented: $storiesViewModel.showStoryCreator)
                .onDisappear {
                    // Reload stories after creation
                    Task {
                        await storiesViewModel.loadAllStories()
                    }
                }
        }
        .fullScreenCover(isPresented: $showStoryViewer) {
            StoryPlayerView(viewModel: storiesViewModel, isVisible: $showStoryViewer)
        }
        .onChange(of: viewModel.posts) { oldValue, newValue in
            print("DEBUG: FeedView - posts changed from \(oldValue.count) to \(newValue.count) items")
        }
        .onChange(of: viewModel.isLoading) { _, newValue in 
            print("DEBUG: FeedView - isLoading changed to \(newValue)")
        }
    }
    
    private var feedHeader: some View {
        HStack {
            Text("Feed")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: {
                viewModel.showNewPostForm = true
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var feedContent: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Stories bar at the top
                StoriesBarView(viewModel: storiesViewModel, showStoryViewer: $showStoryViewer)
                    .padding(.top, 8)
                
                // Pull to refresh indicator
                PullToRefreshView(isRefreshing: $isRefreshing) {
                    Task {
                        await viewModel.loadFeed()
                        await storiesViewModel.loadAllStories()
                        isRefreshing = false
                    }
                }
                
                // Posts
                ForEach(viewModel.posts) { post in
                    PostCardView(post: post, viewModel: viewModel)
                        .onAppear {
                            // Load more content when reaching the last few posts
                            Task {
                                await viewModel.loadMoreContentIfNeeded(currentItem: post)
                            }
                        }
                        .onTapGesture {
                            viewModel.selectedPost = post
                            viewModel.showPostDetail = true
                        }
                }
                
                // Loading indicator at the bottom for pagination
                if viewModel.loadingMore {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            }
            .padding(.horizontal, 8)
        }
        .refreshable {
            await viewModel.loadFeed()
            await storiesViewModel.loadAllStories()
        }
    }
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .tint(.white)
                .scaleEffect(1.5)
            Text("Loading feed...")
                .foregroundColor(.white)
                .padding(.top)
            Spacer()
        }
    }
    
    private var emptyFeedView: some View {
        VStack(spacing: 20) {
            // Even if there are no posts, we still want to show stories
            if !storiesViewModel.allUserStories.isEmpty {
                StoriesBarView(viewModel: storiesViewModel, showStoryViewer: $showStoryViewer)
                    .padding(.top, 8)
            }
            
            Spacer()
            
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.7))
            
            Text("No posts yet")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text("Be the first to share your vehicle!")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            
            Button(action: {
                viewModel.showNewPostForm = true
            }) {
                Text("Create Post")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .background(
                        Capsule()
                            .fill(Color.white)
                    )
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .padding()
    }
}

struct PullToRefreshView: View {
    @Binding var isRefreshing: Bool
    let onRefresh: () -> Void
    
    @State private var offset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                if isRefreshing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(offset > 40 ? 180 : 0))
                        .opacity(offset > 0 ? 1 : 0)
                }
            }
            .frame(width: geometry.size.width, height: max(offset, 0))
            .offset(y: -max(offset, 0))
            .onChange(of: offset) { _, newValue in
                if newValue > 80 && !isRefreshing {
                    isRefreshing = true
                    onRefresh()
                }
            }
        }
        .frame(height: 0)
        .background(
            GeometryReader { proxy in
                Color.clear
                    .preference(key: ScrollOffsetPreferenceKey.self, value: proxy.frame(in: .global).minY)
            }
        )
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            offset = value
        }
    }
}

// ScrollOffsetPreferenceKey is now defined in HomeView.swift and shared across the app

struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView()
            .environmentObject(AuthManager())
    }
} 
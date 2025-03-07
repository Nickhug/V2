import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject var viewModel = HomeViewModel()
    @StateObject var meetViewModel = MeetViewModel()
    @State private var searchText = ""
    @State private var selectedFeedTab = 0
    @State private var showingCreateMeet = false
    @State private var notificationRefreshTimer: Timer?
    @State private var showingNotifications = false
    
    private let tabs = ["Recent", "Popular", "Nearby"]
    
    // Modern feed view with horizontally scrolling categories
    private var modernFeedView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Featured Meet (most recent with status badge)
                if let featuredMeet = meetViewModel.upcomingMeets.first {
                    featuredMeetCard(featuredMeet)
                }
                
                // Status-based sections (horizontal scrolling)
                MeetsByStatusView(viewModel: meetViewModel)
                
                // Tab-specific feed content
                tabSpecificContent
                    .padding(.top, 16)
            }
            .padding(.bottom, 80)
        }
        .refreshable {
            Task {
                await viewModel.refresh()
                await meetViewModel.forceRefreshAll()
            }
        }
    }
    
    // Featured meet card with larger style and status badge
    private func featuredMeetCard(_ meet: Meet) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                // Cover image
                AsyncImageView(imageName: meet.coverImage)
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: MeetSpotStyle.Radius.large))
                    .overlay(
                        LinearGradient(
                            colors: [
                                .clear,
                                .black.opacity(0.4),
                                .black.opacity(0.7)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .clipShape(RoundedRectangle(cornerRadius: MeetSpotStyle.Radius.large))
                    )
                    .pronouncedShadow()
                
                // Status badge
                AnimatedStatusBadge(status: meet.status, size: .regular)
                    .padding(12)
            }
            
            // Content overlay
            VStack(alignment: .leading, spacing: 8) {
                // Title, date and location
                Text(meet.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(MeetSpotColors.pink500)
                    Text(meet.date.formatted(date: .abbreviated, time: .shortened))
                        .foregroundColor(.white.opacity(0.9))
                    
                    Spacer()
                    
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(MeetSpotColors.pink500)
                    Text(meet.address.components(separatedBy: ",").first ?? meet.address)
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(1)
                }
                .font(.subheadline)
                
                // Attendance and type
                HStack {
                    HStack(spacing: 2) {
                        Image(systemName: "person.3.fill")
                            .foregroundColor(MeetSpotColors.pink500)
                        Text("\(meet.attendees.count) attending")
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Spacer()
                    
                    Text(meet.type.rawValue.capitalized)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(meet.type.color)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                .font(.subheadline)
                
                // Action button
                Button {
                    showingCreateMeet = true
                } label: {
                    Text("View Details")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(MeetSpotColors.accentGradient)
                        .clipShape(RoundedRectangle(cornerRadius: MeetSpotStyle.Radius.medium))
                        .mediumShadow()
                }
                .padding(.top, 8)
            }
            .padding(16)
            .background(Color.black.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: MeetSpotStyle.Radius.large))
            .offset(y: -70)
            .padding(.bottom, -70)
        }
        .padding(.horizontal)
    }
    
    // Tab-specific content for each feed tab
    @ViewBuilder
    private var tabSpecificContent: some View {
        switch selectedFeedTab {
        case 0: // Recent
            meetsFeedSection(
                title: "Recently Added",
                meets: viewModel.filteredUpcomingMeets,
                emptyMessage: "No upcoming meets found"
            )
            
        case 1: // Popular
            meetsFeedSection(
                title: "Popular Meets",
                meets: viewModel.filteredRecommendedMeets,
                emptyMessage: "No recommended meets found"
            )
            
        case 2: // Nearby
            meetsFeedSection(
                title: "Meets Near You",
                meets: viewModel.filteredNearbyMeets,
                emptyMessage: "No nearby meets found"
            )
            
        default:
            EmptyView()
        }
    }
    
    // Section for specific meet categories
    private func meetsFeedSection(title: String, meets: [Meet], emptyMessage: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            if meets.isEmpty {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text(emptyMessage)
                            .font(.headline)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        if !viewModel.searchQuery.isEmpty {
                            Text("Try a different search term")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: MeetSpotStyle.Radius.large))
                    .padding(.horizontal)
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(meets) { meet in
                            MeetCard(meet: meet, onTap: {
                                selectedMeet = meet
                                showingMeetDetail = true
                            })
                            .frame(width: 300)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    var body: some View {
        ZStack {
            AnimatedGradientBackground()
            
            VStack(spacing: 0) {
                // Header with tabs
                VStack(spacing: 0) {
                    HStack {
                        Text("Feeds")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Logo
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        // Simple button to show notifications
                        Button(action: {
                            showingNotifications = true
                        }) {
                            NotificationButton(count: viewModel.unreadNotificationsCount)
                        }
                        .buttonStyle(PlainButtonStyle()) // Ensure proper tap handling
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Search Bar
                    SearchBar(
                        text: $viewModel.searchQuery,
                        placeholder: "Search meets...",
                        onTextChange: { _ in
                            // The HomeViewModel already handles search through debounce and computed properties
                        }
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Status Filter
                    StatusFilterView(viewModel: meetViewModel)
                    .padding(.bottom, 4)
                    
                    // Tab Selection
                    HStack {
                        ForEach(Array(tabs.enumerated()), id: \.element) { index, tab in
                            Button(action: {
                                withAnimation {
                                    selectedFeedTab = index
                                }
                            }) {
                                VStack(spacing: 8) {
                                    Text(tab)
                                        .foregroundColor(selectedFeedTab == index ? .white : .white.opacity(0.5))
                                        .fontWeight(selectedFeedTab == index ? .bold : .regular)
                                    
                                    if selectedFeedTab == index {
                                        Circle()
                                            .fill(MeetSpotColors.pink500)
                                            .frame(width: 6, height: 6)
                                    } else {
                                        Circle()
                                            .fill(Color.clear)
                                            .frame(width: 6, height: 6)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    
                    Divider()
                        .background(Color.white.opacity(0.15))
                        .padding(.horizontal)
                }
                .background(Color.black.opacity(0.2))
                .mediumShadow()
                
                // Main feed content
                modernFeedView
            }
            
            // Floating Action Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showingCreateMeet = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2.weight(.semibold))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(MeetSpotColors.accentGradient)
                            .clipShape(Circle())
                            .pronouncedShadow()
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            // Set up timer to refresh notification count every 30 seconds
            notificationRefreshTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
                Task {
                    await viewModel.fetchUnreadNotificationsCount()
                }
            }
            
            // Refresh immediately
            Task {
                await viewModel.fetchUnreadNotificationsCount()
                await meetViewModel.forceRefreshAll()
            }
        }
        .onDisappear {
            // Clean up timer when view disappears
            notificationRefreshTimer?.invalidate()
            notificationRefreshTimer = nil
        }
        .sheet(isPresented: $showingCreateMeet) {
            // This would navigate to your create meet view
            NavigationView {
                CreateMeetView(viewModel: meetViewModel)
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        .sheet(isPresented: $showingNotifications) {
            NavigationView {
                NotificationsView()
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        .task {
            await meetViewModel.forceRefreshAll()
        }
    }
    
    // MARK: - State for Navigation
    @State private var selectedMeet: Meet?
    @State private var showingMeetDetail = false
}

struct FeedCard: View {
    let meet: Meet
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var meetViewModel: MeetViewModel
    @State private var likeCount = Int.random(in: 5...120)
    @State private var commentCount = Int.random(in: 1...20)
    @State private var hasReacted = false
    @State private var selectedReaction: String?
    @State private var showReactions = false
    @State private var showingMeetDetail = false
    
    private let reactions = ["👍", "❤️", "😍", "🚀", "🔥"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: MeetSpotStyle.Spacing.medium) {
            // User info header
            HStack {
                // Avatar - Check if this is the current user's post
                if meet.creatorId == authManager.currentUser?.id,
                   let avatarUrl = authManager.currentUser?.profile.avatarUrl {
                    AsyncImageView(imageName: "", avatarUrl: avatarUrl)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } else {
                    // Generic avatar with initial
                    ZStack {
                        Circle()
                            .fill(MeetSpotColors.accentGradient)
                            .frame(width: 40, height: 40)
                        
                        Text(String(getCreatorName(for: meet).prefix(1)))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(getCreatorName(for: meet))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(getPostText(for: meet))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                }
                
                Spacer()
                
                Button(action: {
                    // More options
                }) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // Post content
            Text(meet.description)
                .font(.subheadline)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .padding(.bottom, 4)
            
            // Post image
            Button(action: {
                showingMeetDetail = true
            }) {
                AsyncImageView(imageName: meet.coverImage)
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: MeetSpotStyle.Radius.medium))
                    .mediumShadow()
            }
            
            // Location and date info
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(MeetSpotColors.pink500)
                Text(meet.address)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Image(systemName: "calendar")
                    .foregroundColor(MeetSpotColors.pink500)
                Text(meet.formattedDate)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // Reactions section
            if showReactions {
                HStack(spacing: 12) {
                    ForEach(reactions, id: \.self) { reaction in
                        Button(action: {
                            selectedReaction = reaction
                            hasReacted = true
                            showReactions = false
                            likeCount += 1
                        }) {
                            Text(reaction)
                                .font(.title3)
                                .padding(8)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                                .subtleShadow()
                        }
                    }
                }
                .transition(.scale.combined(with: .opacity))
                .padding(.vertical, 8)
            }
            
            // Social stats
            HStack {
                HStack(spacing: 2) {
                    ForEach(getReactions(), id: \.self) { reaction in
                        Text(reaction)
                            .font(.system(size: 14))
                            .padding(4)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                
                Spacer()
                
                Text("\(likeCount) likes • \(commentCount) comments")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // Action buttons
            HStack {
                Button(action: {
                    withAnimation {
                        showReactions.toggle()
                    }
                }) {
                    HStack {
                        if let reaction = selectedReaction, hasReacted {
                            Text(reaction)
                                .font(.callout)
                        } else {
                            Image(systemName: "heart")
                                .foregroundColor(hasReacted ? MeetSpotColors.pink500 : .white)
                        }
                        Text("Like")
                            .font(.callout)
                            .foregroundColor(hasReacted ? MeetSpotColors.pink500 : .white)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Capsule())
                    .subtleShadow()
                }
                
                Spacer()
                
                Button(action: {
                    // Comment action
                }) {
                    Text("Set Reaction")
                        .font(.callout)
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(MeetSpotColors.accentGradient)
                        .clipShape(Capsule())
                        .mediumShadow()
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: MeetSpotStyle.Radius.large))
        .mediumShadow()
        .onTapGesture {
            showingMeetDetail = true
        }
        .sheet(isPresented: $showingMeetDetail) {
            // Navigate to meet detail view
            NavigationView {
                MeetDetailView(meet: meet, viewModel: meetViewModel)
            }
        }
    }
    
    private func getCreatorName(for meet: Meet) -> String {
        // In a real app, this would get the user's name from the creatorId
        ["George Lotko", "Vitaly Boyko", "Nikita Oxinov"].randomElement() ?? "Car Enthusiast"
    }
    
    private func getPostText(for meet: Meet) -> String {
        [
            "Hi everyone, today I was on the most beautiful mountain in the world",
            "I visited a wonderful coffee today, I wanted to tell you about it",
            "Just hiked to the top of a breathtaking mountain"
        ].randomElement() ?? "Shared a new meet"
    }
    
    private func getReactions() -> [String] {
        if let selected = selectedReaction {
            return [selected, "👍", "❤️"].shuffled()
        }
        return ["👍", "❤️", "🔥"].shuffled()
    }
}

struct NotificationButton: View {
    let count: Int
    @State private var isAnimating = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Bell icon with glass effect
            Image(systemName: "bell.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .padding(MeetSpotStyle.Spacing.small)
                .background(
                    Circle()
                        .fill(Material.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            MeetSpotColors.pink500.opacity(0.7),
                                            MeetSpotColors.purple900.opacity(0.5)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                )
                .mediumShadow()
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .onAppear {
                    if count > 0 {
                        withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                            isAnimating = true
                        }
                    } else {
                        // Stop animation if count becomes 0
                        isAnimating = false
                    }
                }
                .onChange(of: count) { _, newCount in
                    if newCount > 0 && !isAnimating {
                        withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                            isAnimating = true
                        }
                    } else if newCount == 0 {
                        isAnimating = false
                    }
                }
            
            // Notification badge
            if count > 0 {
                Text("\(count)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(5)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [MeetSpotColors.pink500, MeetSpotColors.purple900],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .subtleShadow()
                    )
                    .offset(x: 5, y: -5)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .contentShape(Circle())
    }
} 
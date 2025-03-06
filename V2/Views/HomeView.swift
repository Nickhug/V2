import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject var viewModel = HomeViewModel()
    @StateObject var meetViewModel = MeetViewModel()
    @State private var searchText = ""
    @State private var selectedFeedTab = 0
    @State private var showingCreateMeet = false
    
    private let tabs = ["Recent", "Friends", "Popular"]
    
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
                        
                        NavigationLink(destination: NotificationsView()) {
                            NotificationButton(count: viewModel.unreadNotificationsCount)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
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
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    Divider()
                        .background(Color.white.opacity(0.15))
                        .padding(.horizontal)
                }
                .background(Color.black.opacity(0.2))
                
                // Feed Content
                ScrollView {
                    LazyVStack(spacing: MeetSpotStyle.Spacing.medium) {
                        ForEach(getFeedItems()) { meet in
                            FeedCard(meet: meet)
                                .environmentObject(meetViewModel)
                        }
                    }
                    .padding()
                }
                .refreshable {
                    Task {
                        await viewModel.refresh()
                        await meetViewModel.fetchUpcomingMeets()
                        await meetViewModel.fetchNearbyMeets()
                    }
                }
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
                            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showingCreateMeet) {
            // This would navigate to your create meet view
            NavigationView {
                Text("Create New Meet")
                    .navigationTitle("New Meet")
            }
        }
        .task {
            await meetViewModel.fetchUpcomingMeets()
            await meetViewModel.fetchNearbyMeets()
        }
    }
    
    private func getFeedItems() -> [Meet] {
        switch selectedFeedTab {
        case 0: // Recent
            return meetViewModel.upcomingMeets + meetViewModel.nearbyMeets
        case 1: // Friends
            // This would filter for friend's meets
            return meetViewModel.upcomingMeets.filter { _ in
                // Placeholder logic - in reality, we'd check if the creator is a friend
                Bool.random()
            }
        case 2: // Popular
            // This would sort meets by some popularity metric
            return meetViewModel.nearbyMeets.sorted { _, _ in
                // Placeholder logic - in reality, we'd sort by number of attendees or similar
                Bool.random()
            }
        default:
            return meetViewModel.upcomingMeets
        }
    }
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
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: MeetSpotStyle.Radius.large))
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
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: "bell.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(MeetSpotColors.text)
                .padding(MeetSpotStyle.Spacing.small)
                .background(MeetSpotColors.accentGradient)
                .clipShape(Circle())
            
            if count > 0 {
                Text("\(count)")
                    .font(.caption2)
                    .foregroundColor(MeetSpotColors.text)
                    .padding(4)
                    .background(MeetSpotColors.pink500)
                    .clipShape(Circle())
                    .offset(x: 4, y: -4)
            }
        }
    }
} 
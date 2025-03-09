import SwiftUI
import CoreLocation
import MapKit

struct FindFriendsView: View {
    @StateObject private var viewModel = FindFriendsViewModel()
    @State private var searchActive = false
    @State private var selectedTab = "suggested"
    @State private var showingRequestsSheet = false
    
    var body: some View {
        ZStack {
            // Background
            AnimatedGradientBackground()
            
            VStack(spacing: 0) {
                // Header with search bar
                VStack(spacing: 16) {
                    HStack {
                        Text("Find Friends")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Friend requests button
                        Button {
                            showingRequestsSheet = true
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Material.ultraThinMaterial)
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                                    .mediumShadow()
                                
                                Image(systemName: "person.badge.plus")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                
                                // Badge for pending requests
                                if !viewModel.pendingRequests.isEmpty {
                                    Text("\(viewModel.pendingRequests.count)")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding(6)
                                        .background(MeetSpotColors.pink500)
                                        .clipShape(Circle())
                                        .offset(x: 14, y: -14)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(searchActive ? MeetSpotColors.pink500 : .white.opacity(0.6))
                        
                        TextField("Search by name or email", text: $viewModel.searchQuery)
                            .foregroundColor(.white)
                            .autocorrectionDisabled()
                            .onSubmit {
                                if !viewModel.searchQuery.isEmpty {
                                    Task {
                                        await viewModel.searchUsers()
                                    }
                                }
                            }
                            .onChange(of: viewModel.searchQuery) { _, newValue in
                                if newValue.isEmpty {
                                    // Reset search results when query is cleared
                                    Task {
                                        await viewModel.searchUsers()
                                    }
                                } else if newValue.count > 2 {
                                    // Only search when we have at least 3 characters
                                    Task {
                                        await viewModel.searchUsers()
                                    }
                                }
                            }
                        
                        if !viewModel.searchQuery.isEmpty {
                            Button(action: {
                                viewModel.searchQuery = ""
                                // Reset search results
                                Task {
                                    await viewModel.searchUsers()
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Material.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        searchActive ? MeetSpotColors.pink500 : Color.white.opacity(0.2),
                                        lineWidth: searchActive ? 2 : 1
                                    )
                            )
                    )
                    .onTapGesture {
                        searchActive = true
                    }
                    .padding(.horizontal)
                }
                .padding(.top)
                .background(
                    Rectangle()
                        .fill(Material.ultraThinMaterial.opacity(0.3))
                        .edgesIgnoringSafeArea(.top)
                )
                
                // Content based on search state
                if !viewModel.searchQuery.isEmpty {
                    // Search results view
                    searchResultsView
                } else {
                    // Tabs and categories
                    categoriesTabView
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                }
            }
            
            // Error/success message overlay
            if let errorMessage = viewModel.errorMessage {
                VStack {
                    Spacer()
                    
                    Text(errorMessage)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .onAppear {
                            // Automatically dismiss after 3 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                viewModel.errorMessage = nil
                            }
                        }
                }
                .transition(.opacity)
                .animation(.easeInOut, value: viewModel.errorMessage != nil)
            } else if let successMessage = viewModel.successMessage {
                VStack {
                    Spacer()
                    
                    Text(successMessage)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green.opacity(0.8))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .onAppear {
                            // Automatically dismiss after 3 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                viewModel.successMessage = nil
                            }
                        }
                }
                .transition(.opacity)
                .animation(.easeInOut, value: viewModel.successMessage != nil)
            }
        }
        .onTapGesture {
            // Dismiss keyboard when tapping outside
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            searchActive = false
        }
        .sheet(isPresented: $showingRequestsSheet) {
            FriendRequestsSheet(requests: viewModel.pendingRequests)
                .onDisappear {
                    // Refresh data when sheet is dismissed
                    Task {
                        await viewModel.refreshAll()
                    }
                }
        }
        .refreshable {
            await viewModel.refreshAll()
        }
    }
    
    // MARK: - Subviews
    
    private var searchResultsView: some View {
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.searchResults.isEmpty {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                            .padding(.top, 100)
                    } else {
                        VStack(spacing: 20) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 50))
                                .foregroundColor(.white.opacity(0.6))
                            
                            Text("No users found")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("Try a different search term")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.top, 100)
                    }
                } else {
                    Text("Search Results")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    ForEach(viewModel.searchResults, id: \.id) { user in
                        UserCard(
                            user: user,
                            onAddFriend: {
                                Task {
                                    await viewModel.sendFriendRequest(to: user)
                                }
                            },
                            isPending: viewModel.hasPendingRequest(to: user.id)
                        )
                        .padding(.horizontal)
                    }
                    .padding(.bottom)
                }
            }
        }
    }
    
    private var categoriesTabView: some View {
        VStack(spacing: 0) {
            // Category tabs
            HStack(spacing: 0) {
                tabButton(title: "Suggested", tag: "suggested")
                tabButton(title: "Nearby", tag: "nearby")
                tabButton(title: "Popular", tag: "popular")
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Tab content
            ScrollView {
                VStack(spacing: 16) {
                    switch selectedTab {
                    case "suggested":
                        suggestedFriendsView
                    case "nearby":
                        nearbyFriendsView
                    case "popular":
                        popularFriendsView
                    default:
                        suggestedFriendsView
                    }
                }
                .padding()
            }
            .refreshable {
                await viewModel.refreshAll()
            }
        }
    }
    
    private var suggestedFriendsView: some View {
        Group {
            if viewModel.suggestedFriends.isEmpty {
                emptyStateView(
                    icon: "person.badge.plus",
                    title: "No Suggestions Yet",
                    message: "We'll suggest people you might know once you start using the app more."
                )
            } else {
                Text("People you might know")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ForEach(viewModel.suggestedFriends, id: \.id) { user in
                    UserCard(
                        user: user,
                        onAddFriend: {
                            Task {
                                await viewModel.sendFriendRequest(to: user)
                            }
                        },
                        isPending: viewModel.hasPendingRequest(to: user.id)
                    )
                }
            }
        }
    }
    
    private var nearbyFriendsView: some View {
        Group {
            if viewModel.nearbyUsers.isEmpty {
                emptyStateView(
                    icon: "location.fill",
                    title: "No Nearby Users Found",
                    message: "We couldn't find any users near your current location."
                )
            } else {
                Text("People near you")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ForEach(viewModel.nearbyUsers, id: \.id) { user in
                    let distance = CLLocation(
                        latitude: user.profile.location.latitude,
                        longitude: user.profile.location.longitude
                    ).distance(
                        from: CLLocation(
                            latitude: LocationManager().location?.coordinate.latitude ?? 0,
                            longitude: LocationManager().location?.coordinate.longitude ?? 0
                        )
                    )
                    
                    UserCard(
                        user: user,
                        onAddFriend: {
                            Task {
                                await viewModel.sendFriendRequest(to: user)
                            }
                        },
                        isPending: viewModel.hasPendingRequest(to: user.id),
                        distance: distance
                    )
                }
            }
        }
    }
    
    private var popularFriendsView: some View {
        Group {
            if viewModel.popularUsers.isEmpty {
                emptyStateView(
                    icon: "star.fill",
                    title: "No Popular Users Found",
                    message: "We couldn't find any popular users at the moment."
                )
            } else {
                Text("Popular users")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ForEach(viewModel.popularUsers, id: \.id) { user in
                    UserCard(
                        user: user,
                        onAddFriend: {
                            Task {
                                await viewModel.sendFriendRequest(to: user)
                            }
                        },
                        isPending: viewModel.hasPendingRequest(to: user.id)
                    )
                }
            }
        }
    }
    
    // Empty state view helper
    private func emptyStateView(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(.white.opacity(0.6))
            
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top, 60)
        .frame(maxWidth: .infinity)
    }
    
    // Helper for creating tab buttons
    private func tabButton(title: String, tag: String) -> some View {
        Button(action: {
            selectedTab = tag
        }) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(selectedTab == tag ? .white : .white.opacity(0.6))
                
                // Indicator for selected tab
                Rectangle()
                    .fill(selectedTab == tag ? Color.white : Color.clear)
                    .frame(height: 3)
                    .cornerRadius(1.5)
            }
            .padding(.vertical, 10)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Supporting Views

struct FriendRequestsSheet: View {
    let requests: [FriendRequestViewModel]
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = FindFriendsViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                AnimatedGradientBackground()
                
                VStack {
                    if requests.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 50))
                                .foregroundColor(.white.opacity(0.6))
                            
                            Text("No Pending Requests")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("You don't have any friend requests at the moment.")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding()
                    } else {
                        List {
                            ForEach(requests) { request in
                                HStack(spacing: 16) {
                                    // Avatar
                                    ZStack {
                                        Circle()
                                            .fill(MeetSpotColors.accentGradient)
                                            .frame(width: 50, height: 50)
                                        
                                        if let avatarUrl = request.sender.profile.avatarUrl, !avatarUrl.isEmpty, let url = URL(string: avatarUrl) {
                                            AsyncImage(url: url) { image in
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 50, height: 50)
                                                    .clipShape(Circle())
                                            } placeholder: {
                                                Image(systemName: "person.fill")
                                                    .font(.system(size: 20))
                                                    .foregroundColor(.white)
                                            }
                                        } else {
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    
                                    // Request info
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(request.sender.profile.name)
                                            .font(.headline)
                                        
                                        Text(request.formattedTimestamp)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    // Accept button
                                    Button {
                                        Task {
                                            await viewModel.acceptFriendRequest(from: request.sender)
                                        }
                                    } label: {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.green)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                    
                                    // Reject button
                                    Button {
                                        Task {
                                            await viewModel.rejectFriendRequest(from: request.sender)
                                        }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }
                .navigationTitle("Friend Requests")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Close") {
                            dismiss()
                        }
                    }
                }
                
                // Overlay for error/success messages
                if let errorMessage = viewModel.errorMessage {
                    VStack {
                        Spacer()
                        
                        Text(errorMessage)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(10)
                            .padding(.horizontal)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .onAppear {
                                // Automatically dismiss after 3 seconds
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    viewModel.errorMessage = nil
                                }
                            }
                    }
                } else if let successMessage = viewModel.successMessage {
                    VStack {
                        Spacer()
                        
                        Text(successMessage)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.green.opacity(0.8))
                            .cornerRadius(10)
                            .padding(.horizontal)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .onAppear {
                                // Automatically dismiss after 3 seconds
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    viewModel.successMessage = nil
                                }
                            }
                    }
                }
            }
        }
    }
}

#Preview {
    FindFriendsView()
} 
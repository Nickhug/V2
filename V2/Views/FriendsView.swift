import SwiftUI

struct FriendsView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject var meetViewModel = MeetViewModel()
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var showingFilterOptions = false
    
    var body: some View {
        ZStack {
            // Same animated background as in HomeView
            AnimatedGradientBackground()
            
            VStack(spacing: 0) {
                // Custom header for Friends view
                HStack {
                    Text("Friends")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Search button
                    Button(action: {
                        // Toggle search field
                    }) {
                        Image(systemName: "magnifyingglass")
                            .font(.title2)
                            .foregroundColor(.black)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.white)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.black, lineWidth: 1.5)
                                    )
                            )
                            .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 1)
                    }
                    
                    // Filter button
                    Button(action: {
                        showingFilterOptions.toggle()
                    }) {
                        Image(systemName: "line.3.horizontal.decrease")
                            .font(.title2)
                            .foregroundColor(.black)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.white)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.black, lineWidth: 1.5)
                                    )
                            )
                            .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 1)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.2))
                .mediumShadow()
                
                // Friend categories
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        CategoryButton(title: "All Friends", icon: "person.2.fill", isSelected: true)
                        CategoryButton(title: "Nearby", icon: "location.fill", isSelected: false)
                        CategoryButton(title: "Recent", icon: "clock.fill", isSelected: false)
                        CategoryButton(title: "Favorites", icon: "star.fill", isSelected: false)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
                
                if isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    Spacer()
                } else {
                    // Friend content
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(1...10, id: \.self) { index in
                                FriendCard(
                                    name: mockNames.randomElement() ?? "Friend",
                                    status: mockStatuses.randomElement() ?? "Active now",
                                    avatarName: "person.circle.fill",
                                    hasUnreadMessage: Bool.random()
                                )
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        // Pull to refresh
                        await refresh()
                    }
                }
            }
        }
        .task {
            isLoading = true
            // Simulate data loading
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            isLoading = false
        }
    }
    
    private func refresh() async {
        isLoading = true
        // Simulate refreshing data
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        isLoading = false
    }
    
    // Mock data
    private let mockNames = ["Alex Kim", "Jordan Smith", "Taylor Johnson", "Casey Williams", "Morgan Lee", "Riley Brown", "Quinn Davis"]
    private let mockStatuses = ["Active now", "Last seen 2h ago", "Driving", "At a meet", "Planning a route", "Active now"]
}

// MARK: - Supporting Views

struct CategoryButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    
    var body: some View {
        Button(action: {
            // Select this category
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)
                Text(title)
                    .font(.subheadline)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                Group {
                    if isSelected {
                        Capsule()
                            .fill(Color.white)
                            .overlay(
                                Capsule()
                                    .stroke(Color.black, lineWidth: 1.5)
                            )
                    } else {
                        Capsule()
                            .fill(Material.ultraThinMaterial)
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                }
            )
            .foregroundColor(isSelected ? .black : .white)
            .mediumShadow()
        }
    }
}

struct FriendCard: View {
    let name: String
    let status: String
    let avatarName: String
    let hasUnreadMessage: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle()
                            .stroke(Color.black, lineWidth: 1.5)
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 1)
                
                Image(systemName: avatarName)
                    .font(.system(size: 24))
                    .foregroundColor(.black)
                
                // Online indicator
                if status == "Active now" {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color.black.opacity(0.2), lineWidth: 1)
                        )
                        .offset(x: 18, y: 18)
                }
            }
            
            // Friend info
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(status)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 12) {
                // Message button
                Button(action: {
                    // Open message
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .stroke(Color.black, lineWidth: 1.5)
                            )
                            .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 1)
                        
                        Image(systemName: "message.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.black)
                        
                        // Unread indicator
                        if hasUnreadMessage {
                            Circle()
                                .fill(MeetSpotColors.pink500)
                                .frame(width: 10, height: 10)
                                .offset(x: 12, y: -12)
                        }
                    }
                }
                
                // Meet button
                Button(action: {
                    // Plan a meet
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .stroke(Color.black, lineWidth: 1.5)
                            )
                            .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 1)
                        
                        Image(systemName: "map.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.black)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: MeetSpotStyle.Radius.medium)
                .fill(Color.white.opacity(0.08))
        )
        .mediumShadow()
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        FriendsView()
            .environmentObject(AuthManager())
    }
} 
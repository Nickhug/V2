import SwiftUI
import PhotosUI

struct ProfileView: View {
    @ObservedObject var viewModel: MeetViewModel
    @State private var showingEditProfile = false
    @State private var showingSettings = false
    @State private var showingVehicleManager = false
    @State private var showingAchievements = false
    @State private var showingFriends = false
    @State private var selectedVehicle: Vehicle?
    @State private var isLoading = false
    @State private var showSettings = false
    @State private var showingLogoutConfirmation = false
    @State private var selectedTab = "Posts"
    
    private let tabs = ["Posts", "Collections", "About"]
    
    var body: some View {
        NavigationView {
            ZStack {
                AnimatedGradientBackground()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Profile Header
                        profileHeader
                            .padding(.top)
                        
                        // Stats Section
                        statsSection
                            .padding(.top, 5)
                        
                        // Action Buttons
                        actionButtons
                            .padding(.vertical, 15)
                        
                        // Tab Selector
                        tabSelector
                            .padding(.horizontal)
                            .padding(.bottom, 10)
                        
                        // Tab Content
                        tabContent
                            .padding(.horizontal)
                            .padding(.bottom, 30)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: settingsMenu)
            .task {
                await viewModel.fetchUserData()
            }
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView()
                .environmentObject(AuthManager())
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(meetViewModel: viewModel)
        }
        .sheet(isPresented: $showingVehicleManager) {
            VehiclesView()
                .environmentObject(AuthManager())
        }
        .sheet(isPresented: $showingAchievements) {
            AchievementsView()
                .environmentObject(AuthManager())
        }
        .sheet(isPresented: $showingFriends) {
            NavigationView {
                FriendsView()
                    .environmentObject(AuthManager())
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        .alert("Log Out", isPresented: $showingLogoutConfirmation) {
            Button(role: .cancel) {
                // Do nothing on cancel
            } label: {
                Text("Cancel")
            }
            
            Button(role: .destructive) {
                // Handle logout
            } label: {
                Text("Log Out")
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
    }
    
    private var profileHeader: some View {
        VStack(spacing: 12) {
            // Profile Image
            if let imageURL = viewModel.currentUser?.profile.avatarUrl {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(.white.opacity(0.3))
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(DesignSystem.Colors.accentGradient, lineWidth: 3)
                )
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 100, height: 100)
            }
            
            VStack(spacing: 4) {
                Text(viewModel.currentUser?.profile.name ?? "Car Enthusiast")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("@\(viewModel.currentUser?.email.split(separator: "@").first ?? "carenthusiast")")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                
                if let status = viewModel.currentUser?.profile.statusMessage {
                    Text(status)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var statsSection: some View {
        HStack(spacing: 0) {
            Spacer()
            
            StatPill(
                value: "\(viewModel.userMeets.count)",
                label: "Meets"
            )
            
            Spacer()
            
            StatPill(
                value: "\(viewModel.currentUser?.vehicles.count ?? 0)",
                label: "Vehicles"
            )
            
            Spacer()
            
            StatPill(
                value: "\(viewModel.followers.count)",
                label: "Followers"
            )
            
            Spacer()
        }
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.2))
    }
    
    private var actionButtons: some View {
        HStack(spacing: 16) {
            Button {
                showingEditProfile = true
            } label: {
                Text("Edit Profile")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(height: 36)
                    .frame(minWidth: 120)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(DesignSystem.Colors.accentGradient)
                    )
            }
            
            NavigationLink(destination: FindFriendsView()) {
                Text("Find Friends")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(height: 36)
                    .frame(minWidth: 120)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(18)
                    )
            }
        }
    }
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 8) {
                        Text(tab)
                            .font(.subheadline)
                            .fontWeight(selectedTab == tab ? .semibold : .regular)
                            .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.6))
                        
                        Rectangle()
                            .fill(selectedTab == tab ? DesignSystem.Colors.accentGradient : LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing))
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    private var tabContent: some View {
        Group {
            switch selectedTab {
            case "Posts":
                postsContent
            case "Collections":
                collectionsContent
            case "About":
                aboutContent
            default:
                EmptyView()
            }
        }
    }
    
    private var postsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !viewModel.userMeets.isEmpty {
                ForEach(viewModel.userMeets) { meet in
                    MeetCard(meet: meet, style: .dark)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("No meets yet")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Create or join a meet to see it here")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                    
                    Button {
                        // Navigate to create meet
                    } label: {
                        Text("Create a Meet")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(DesignSystem.Colors.accentGradient)
                            .cornerRadius(20)
                    }
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 50)
            }
        }
    }
    
    private var collectionsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let user = viewModel.currentUser, !user.vehicles.isEmpty {
                Text("Your Vehicles")
                    .font(.headline)
                    .foregroundColor(.white)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(user.vehicles) { vehicle in
                        VehicleGridItem(vehicle: vehicle, user: user)
                            .onTapGesture {
                                selectedVehicle = vehicle
                            }
                    }
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "car.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("No vehicles yet")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Add your vehicles to showcase them")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                    
                    Button {
                        showingVehicleManager = true
                    } label: {
                        Text("Add a Vehicle")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(DesignSystem.Colors.accentGradient)
                            .cornerRadius(20)
                    }
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 50)
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            Text("Achievements")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.top, 8)
            
            if !viewModel.recentAchievements.isEmpty {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(viewModel.recentAchievements) { achievement in
                        AchievementGridItem(achievement: achievement)
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("No achievements yet")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            }
        }
    }
    
    private var aboutContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Bio Section
            VStack(alignment: .leading, spacing: 12) {
                Label {
                    Text("Bio")
                        .font(.headline)
                        .foregroundColor(.white)
                } icon: {
                    Image(systemName: "person.fill")
                        .foregroundColor(Theme.Colors.accent)
                }
                
                Text(viewModel.currentUser?.profile.bio ?? "No bio yet. Edit your profile to add one.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
            }
            
            // Location
            VStack(alignment: .leading, spacing: 12) {
                Label {
                    Text("Location")
                        .font(.headline)
                        .foregroundColor(.white)
                } icon: {
                    Image(systemName: "location.fill")
                        .foregroundColor(Theme.Colors.accent)
                }
                
                Text(viewModel.currentUser?.profile.location.address ?? "Location not set")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
            }
            
            // Activity Feed
            VStack(alignment: .leading, spacing: 12) {
                Label {
                    Text("Recent Activity")
                        .font(.headline)
                        .foregroundColor(.white)
                } icon: {
                    Image(systemName: "clock.fill")
                        .foregroundColor(Theme.Colors.accent)
                }
                
                if viewModel.recentActivity.isEmpty {
                    Text("No recent activity")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                } else {
                    VStack(spacing: 2) {
                        ForEach(viewModel.recentActivity) { activity in
                            HStack(spacing: 16) {
                                Image(systemName: activity.type.icon)
                                    .foregroundColor(Theme.Colors.accent)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(activity.title)
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                    
                                    Text(activity.timeAgo)
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(8)
                        }
                    }
                }
            }
        }
    }
    
    private var settingsMenu: some View {
        Menu {
            Button(action: { showingEditProfile = true }) {
                Label("Edit Profile", systemImage: "pencil")
            }
            
            Button(action: { showingSettings = true }) {
                Label("Settings", systemImage: "gear")
            }
            
            Button(role: .destructive, action: { showingLogoutConfirmation = true }) {
                Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
            }
        } label: {
            Image(systemName: "ellipsis")
                .foregroundColor(.white)
                .padding(8)
                .background(Color.black.opacity(0.3))
                .clipShape(Circle())
        }
    }
}

// A more compact stat view similar to the inspiration image
struct StatPill: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(minWidth: 70)
    }
}

struct VehicleGridItem: View {
    let vehicle: Vehicle
    let user: User
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Vehicle Image
            ZStack {
                if let imageUrl = vehicle.photos.first {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ProgressView()
                    }
                } else {
                    Rectangle()
                        .fill(DesignSystem.Colors.accentGradient.opacity(0.3))
                        .overlay(
                            Image(systemName: "car.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white.opacity(0.6))
                        )
                }
            }
            .aspectRatio(1, contentMode: .fill)
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Text("\(vehicle.make) \(vehicle.model)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .lineLimit(1)
            
            Text("\(vehicle.formattedYear) • \(vehicle.type.rawValue)")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(1)
        }
        .padding(8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

struct AchievementGridItem: View {
    let achievement: Achievement
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: achievement.icon)
                .font(.title3)
                .foregroundColor(Theme.Colors.accent)
                .frame(width: 32, height: 32)
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(achievement.earnedAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// Original components (renamed to avoid conflicts)
struct QuickActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(Theme.Colors.accent)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .glassCard()
        }
    }
} 
import SwiftUI

struct AchievementsGridView: View {
    @EnvironmentObject private var authManager: AuthManager
    @StateObject private var viewModel = AchievementViewModel()
    @State private var showingDetail: Achievement? = nil
    @State private var gridColumns = [GridItem(.adaptive(minimum: 100, maximum: 120), spacing: 15)]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Achievements")
                            .font(.largeTitle)
                            .bold()
                        
                        Text("Earn achievements by participating in meets, creating routes, and more!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // Progress bar
                    achievementProgressSection
                        .padding(.horizontal)
                    
                    // Recent achievements
                    if !viewModel.userAchievements.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Recently Earned")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            recentAchievementsRow
                        }
                    }
                    
                    // All achievements grid
                    VStack(alignment: .leading, spacing: 10) {
                        Text("All Achievements")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        achievementsGrid
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Manually trigger achievement check for testing
                        Task {
                            guard let userId = authManager.currentUser?.id else { return }
                            await viewModel.checkForAchievements(userId: userId)
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .sheet(item: $showingDetail) { achievement in
                AchievementDetailView(achievement: achievement)
            }
            .onAppear {
                loadUserAchievements()
            }
        }
    }
    
    // Achievement progress section
    private var achievementProgressSection: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Progress")
                    .font(.headline)
                
                Spacer()
                
                Text("\(viewModel.userAchievements.count)/\(totalPossibleAchievements)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, min(progressPercentage * geometry.size.width, geometry.size.width)), height: 12)
                }
            }
            .frame(height: 12)
        }
    }
    
    // Recent achievements horizontal scrolling row
    private var recentAchievementsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(Array(viewModel.userAchievements.prefix(5))) { achievement in
                    AchievementCardView(achievement: achievement)
                        .onTapGesture {
                            showingDetail = achievement
                        }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // All achievements grid
    private var achievementsGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: 20) {
            if viewModel.userAchievements.isEmpty {
                ForEach(0..<6) { _ in
                    LockedAchievementView()
                }
            } else {
                ForEach(viewModel.userAchievements) { achievement in
                    AchievementIconView(achievement: achievement)
                        .onTapGesture {
                            showingDetail = achievement
                        }
                }
                
                // Placeholders for locked achievements
                let remainingCount = max(0, totalPossibleAchievements - viewModel.userAchievements.count)
                ForEach(0..<min(remainingCount, 10), id: \.self) { _ in
                    LockedAchievementView()
                }
            }
        }
    }
    
    // Helper computed properties
    private var totalPossibleAchievements: Int {
        // Total number of possible achievements - could be fetched from a central definition
        return 11 // Based on AchievementType enum count
    }
    
    private var progressPercentage: CGFloat {
        guard totalPossibleAchievements > 0 else { return 0 }
        return CGFloat(viewModel.userAchievements.count) / CGFloat(totalPossibleAchievements)
    }
    
    // Load achievements function
    private func loadUserAchievements() {
        guard let userId = authManager.currentUser?.id else { return }
        
        Task {
            await viewModel.loadUserAchievements(userId: userId)
        }
    }
}

// MARK: - Achievement Card View
struct AchievementCardView: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 12) {
            // Achievement icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue.opacity(0.6), .purple.opacity(0.6)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 30))
                    .foregroundColor(.white)
            }
            
            // Achievement info
            VStack(spacing: 4) {
                Text(achievement.title)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text(achievement.earnedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 120)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
}

// MARK: - Achievement Icon View
struct AchievementIconView: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue.opacity(0.6), .purple.opacity(0.6)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 30))
                    .foregroundColor(.white)
            }
            
            Text(achievement.title)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(height: 30)
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Locked Achievement View
struct LockedAchievementView: View {
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "lock.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.gray)
            }
            
            Text("Locked")
                .font(.caption)
                .foregroundColor(.gray)
                .frame(height: 30)
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Achievement Detail View
struct AchievementDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let achievement: Achievement
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Trophy icon with glowing effect
                ZStack {
                    // Glow
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [.yellow.opacity(0.7), .yellow.opacity(0)]),
                                center: .center,
                                startRadius: 30,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                    
                    // Background
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    // Icon
                    Image(systemName: achievement.icon)
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                }
                .padding(.top, 30)
                
                // Achievement info
                VStack(spacing: 12) {
                    Text(achievement.title)
                        .font(.title)
                        .bold()
                        .multilineTextAlignment(.center)
                    
                    Text(achievement.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Text("Earned on \(achievement.earnedAt.formatted(date: .long, time: .omitted))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 5)
                }
                
                // Achievement type info
                VStack(spacing: 10) {
                    HStack {
                        Text("Type:")
                            .font(.headline)
                        
                        Text(achievementTypeDescription(achievement.type))
                            .font(.body)
                    }
                    
                    HStack {
                        Text("Rarity:")
                            .font(.headline)
                        
                        Text(achievementRarity(achievement.type))
                            .font(.body)
                            .foregroundColor(rarityColor(achievement.type))
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(.systemGray6))
                )
                .padding(.horizontal)
                
                Spacer()
                
                // Dismiss button
                Button(action: { dismiss() }) {
                    Text("Done")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 50)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.blue, .purple]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
                .padding(.bottom, 30)
            }
        }
    }
    
    // Helper methods for formatting achievement types
    private func achievementTypeDescription(_ type: AchievementType) -> String {
        switch type {
        case .meetCreated:
            return "Meet Creation"
        case .meetJoined:
            return "Meet Participation"
        case .meetCompleted:
            return "Meet Completion"
        case .routeCreated:
            return "Route Creation"
        case .routeShared:
            return "Social Sharing"
        case .friendAdded:
            return "Social Networking"
        case .profileComplete:
            return "Profile Completion"
        case .firstMeet:
            return "Beginner"
        case .meetStreak:
            return "Consistency"
        case .socialButterfly:
            return "Social Networking"
        case .attendFiveMeets:
            return "Dedication"
        }
    }
    
    private func achievementRarity(_ type: AchievementType) -> String {
        switch type {
        case .profileComplete, .firstMeet, .meetCreated, .meetJoined:
            return "Common"
        case .routeCreated, .friendAdded, .routeShared:
            return "Uncommon"
        case .meetCompleted, .attendFiveMeets:
            return "Rare"
        case .meetStreak, .socialButterfly:
            return "Epic"
        }
    }
    
    private func rarityColor(_ type: AchievementType) -> Color {
        switch type {
        case .profileComplete, .firstMeet, .meetCreated, .meetJoined:
            return .blue
        case .routeCreated, .friendAdded, .routeShared:
            return .green
        case .meetCompleted, .attendFiveMeets:
            return .purple
        case .meetStreak, .socialButterfly:
            return .orange
        }
    }
}

// MARK: - Preview
struct AchievementsGridView_Previews: PreviewProvider {
    static var previews: some View {
        AchievementsGridView()
            .environmentObject(AuthManager())
    }
} 
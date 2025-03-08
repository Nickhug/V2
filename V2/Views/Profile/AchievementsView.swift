import SwiftUI

struct AchievementsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthManager
    @StateObject private var viewModel = AchievementViewModel()
    @State private var showProgressOverlay = false
    @State private var newlyEarnedAchievement: Achievement? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                List {
                    if viewModel.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                                .padding()
                            Spacer()
                        }
                    } else if viewModel.userAchievements.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "trophy")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary.opacity(0.7))
                            
                            Text("No Achievements Yet")
                                .font(.headline)
                            
                            Text("Complete activities to earn achievements")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            // Suggestion buttons for activities that could earn achievements
                            VStack(spacing: 12) {
                                Text("Try these activities:")
                                    .font(.subheadline)
                                    .padding(.top)
                                
                                ForEach(suggestedActivities, id: \.self) { activity in
                                    HStack {
                                        Image(systemName: activityIcon(for: activity))
                                            .foregroundColor(.blue)
                                        Text(activity)
                                            .font(.subheadline)
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    } else {
                        achievementsSections
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .refreshable {
                    loadUserAchievements()
                }
                .overlay(
                    Group {
                        if let error = viewModel.errorMessage {
                            VStack {
                                Text("Error")
                                    .font(.headline)
                                Text(error)
                                    .font(.subheadline)
                                    .multilineTextAlignment(.center)
                                Button("Retry") {
                                    loadUserAchievements()
                                }
                                .padding(.top)
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemBackground)))
                            .shadow(radius: 5)
                        }
                    }
                )
                
                // Achievement earned overlay
                if showProgressOverlay, let achievement = newlyEarnedAchievement {
                    AchievementEarnedView(achievement: achievement, onDismiss: {
                        withAnimation {
                            showProgressOverlay = false
                            newlyEarnedAchievement = nil
                        }
                    })
                    .transition(.opacity)
                    .zIndex(10)
                }
            }
            .navigationTitle("Achievements")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadUserAchievements()
            }
        }
    }
    
    private var achievementsSections: some View {
        Group {
            // Recent achievements section
            Section(header: Text("Recently Earned")) {
                let recentAchievements = Array(viewModel.userAchievements.prefix(3))
                ForEach(recentAchievements) { achievement in
                    AchievementRow(achievement: achievement)
                }
            }
            
            // All achievements section
            Section(header: Text("All Achievements")) {
                ForEach(viewModel.userAchievements) { achievement in
                    AchievementRow(achievement: achievement)
                }
            }
        }
    }
    
    private var suggestedActivities: [String] {
        [
            "Create your first meet",
            "Attend a car meet",
            "Create and share a route",
            "Complete your profile",
            "Add friends to your network"
        ]
    }
    
    private func activityIcon(for activity: String) -> String {
        switch activity {
        case "Create your first meet":
            return "calendar.badge.plus"
        case "Attend a car meet":
            return "person.2.fill"
        case "Create and share a route":
            return "map.fill"
        case "Complete your profile":
            return "person.fill.checkmark"
        case "Add friends to your network":
            return "person.badge.plus.fill"
        default:
            return "star.fill"
        }
    }
    
    private func loadUserAchievements() {
        guard let userId = authManager.currentUser?.id else { return }
        
        Task {
            await viewModel.loadUserAchievements(userId: userId)
            // Simulate achievement earning for testing purposes
            // This would be removed in production and handled by real user activities
            #if DEBUG
            if !ProcessInfo.processInfo.arguments.contains("TESTING_NO_ACHIEVEMENTS") {
                simulateAchievementEarning()
            }
            #endif
        }
    }
    
    // For demonstration/test purposes only
    private func simulateAchievementEarning() {
        // Only show achievement earning overlay in preview mode or if specifically testing
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" ||
              ProcessInfo.processInfo.arguments.contains("TESTING_ACHIEVEMENTS") else {
            return
        }
        
        // Create a mock achievement that might have been earned
        let mockAchievement = Achievement(
            id: UUID().uuidString,
            type: .profileComplete,
            title: "Identity Established",
            description: "Completed your profile with all information",
            icon: "person.fill.checkmark",
            earnedAt: Date()
        )
        
        // Show the achievement earned overlay with animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring()) {
                self.newlyEarnedAchievement = mockAchievement
                self.showProgressOverlay = true
            }
        }
    }
}

struct AchievementRow: View {
    let achievement: Achievement
    
    var body: some View {
        HStack(spacing: 15) {
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
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.headline)
                
                Text(achievement.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Earned: \(achievement.earnedAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 5)
    }
}

struct AchievementEarnedView: View {
    let achievement: Achievement
    let onDismiss: () -> Void
    
    @State private var showContent = false
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            // Achievement card
            VStack(spacing: 20) {
                // Trophy icon with animation
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.orange, .yellow]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: .yellow.opacity(0.5), radius: showContent ? 20 : 0)
                    
                    Image(systemName: achievement.icon)
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 2)
                }
                .scaleEffect(showContent ? 1.0 : 0.5)
                
                // Achievement text
                VStack(spacing: 8) {
                    Text("Achievement Unlocked!")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Text(achievement.title)
                        .font(.title3.bold())
                        .foregroundColor(.yellow)
                        .padding(.bottom, 4)
                    
                    Text(achievement.description)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                }
                .opacity(showContent ? 1.0 : 0)
                .offset(y: showContent ? 0 : 20)
                
                // Dismiss button
                Button(action: dismiss) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [.blue, .purple]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                        )
                }
                .padding(.top, 10)
                .opacity(showContent ? 1.0 : 0)
                .offset(y: showContent ? 0 : 20)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemGray6).opacity(0.9))
                    .shadow(radius: 20)
            )
            .padding(.horizontal, 30)
        }
        .onAppear {
            // Start the animation when view appears
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                showContent = true
            }
        }
    }
    
    private func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            showContent = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

// MARK: - Previews
#Preview {
    AchievementsView()
        .environmentObject(AuthManager())
} 
import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingDatabaseCleanup = false
    @ObservedObject var meetViewModel: MeetViewModel
    
    var body: some View {
        NavigationView {
            List {
                // Account Section
                Section("Account") {
                    NavigationLink {
                        ProfileView(viewModel: meetViewModel)
                    } label: {
                        Label("Profile", systemImage: "person.circle")
                    }
                    
                    Button(role: .destructive) {
                        Task {
                            await viewModel.signOut()
                            dismiss()
                        }
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
                
                // Preferences Section
                Section("Preferences") {
                    Toggle("Enable Notifications", isOn: $viewModel.notificationsEnabled)
                    Toggle("Dark Mode", isOn: $viewModel.darkModeEnabled)
                    Toggle("Location Services", isOn: $viewModel.locationServicesEnabled)
                }
                
                // Premium Section
                Section("Premium") {
                    if viewModel.isPremium {
                        Label("Premium Member", systemImage: "star.fill")
                            .foregroundColor(.yellow)
                    } else {
                        Button {
                            viewModel.showingPremiumUpgrade = true
                        } label: {
                            Label("Upgrade to Premium", systemImage: "star")
                        }
                    }
                }
                
                // About Section
                Section("About") {
                    NavigationLink {
                        Text("Version 1.0.0")
                    } label: {
                        Label("Version", systemImage: "info.circle")
                    }
                    
                    Link(destination: URL(string: "https://meetspot.app/privacy")!) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                    
                    Link(destination: URL(string: "https://meetspot.app/terms")!) {
                        Label("Terms of Service", systemImage: "doc.text")
                    }
                }
                
                // Admin Section
                Section("Admin") {
                    Button {
                        showingDatabaseCleanup = true
                    } label: {
                        Label("Database Cleanup", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingPremiumUpgrade) {
                PremiumUpgradeView()
            }
            .sheet(isPresented: $showingDatabaseCleanup) {
                DatabaseCleanupView()
            }
        }
    }
}

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var notificationsEnabled = true
    @Published var darkModeEnabled = false
    @Published var locationServicesEnabled = true
    @Published var isPremium = false
    @Published var showingPremiumUpgrade = false
    
    private let userService = UserService.shared
    
    init() {
        Task {
            await loadUserSettings()
        }
    }
    
    func loadUserSettings() async {
        do {
            if let userId = try await userService.currentUserId {
                let user = try await userService.fetchUser(id: userId)
                isPremium = user.isPremium
            }
        } catch {
            print("Error loading user settings: \(error)")
        }
    }
    
    func signOut() async {
        do {
            try await userService.signOut()
        } catch {
            print("Error signing out: \(error)")
        }
    }
}

struct PremiumUpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.yellow)
                
                Text("Upgrade to Premium")
                    .font(.title)
                    .bold()
                
                VStack(alignment: .leading, spacing: 15) {
                    FeatureRow(icon: "map.fill", text: "Advanced Location Features")
                    FeatureRow(icon: "photo.fill", text: "Unlimited Vehicle Photos")
                    FeatureRow(icon: "bell.fill", text: "Priority Notifications")
                    FeatureRow(icon: "person.2.fill", text: "Exclusive Meetups")
                }
                .padding()
                
                Button {
                    // Handle premium upgrade
                } label: {
                    Text("Upgrade Now")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Premium")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(text)
        }
    }
}

#Preview {
    SettingsView(meetViewModel: MeetViewModel())
} 

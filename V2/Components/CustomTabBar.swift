import SwiftUI

enum Tab: Int {
    case discover
    case vehicles
    case profile
    case settings
    
    var icon: String {
        switch self {
        case .discover: return "map.fill"
        case .vehicles: return "car.fill"
        case .profile: return "person.fill"
        case .settings: return "gear"
        }
    }
    
    var title: String {
        switch self {
        case .discover: return "Discover"
        case .vehicles: return "Vehicles"
        case .profile: return "Profile"
        case .settings: return "Settings"
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab: Tab = .discover
    @StateObject private var discoverViewModel = DiscoverViewModel()
    @StateObject private var meetViewModel = MeetViewModel()
    
    var body: some View {
        ZStack {
            // Background gradient for entire app
            DesignSystem.Colors.backgroundGradient
                .ignoresSafeArea()
            
            // Standard iOS TabView with default styling
            TabView(selection: $selectedTab) {
                DiscoverView(viewModel: discoverViewModel)
                    .tabItem {
                        Label(Tab.discover.title, systemImage: Tab.discover.icon)
                    }
                    .tag(Tab.discover)
                
                VehiclesView()
                    .tabItem {
                        Label(Tab.vehicles.title, systemImage: Tab.vehicles.icon)
                    }
                    .tag(Tab.vehicles)
                
                ProfileView(viewModel: meetViewModel)
                    .tabItem {
                        Label(Tab.profile.title, systemImage: Tab.profile.icon)
                    }
                    .tag(Tab.profile)
                
                SettingsView(meetViewModel: meetViewModel)
                    .tabItem {
                        Label(Tab.settings.title, systemImage: Tab.settings.icon)
                    }
                    .tag(Tab.settings)
            }
            // No custom styling or modifications to the TabView
        }
        .onAppear {
            // Preload data
            Task {
                do {
                    await discoverViewModel.fetchMeets()
                    try await meetViewModel.fetchMeets()
                } catch {
                    print("Error in preloading tab content: \(error)")
                }
            }
        }
    }
}

#Preview {
    MainTabView()
} 
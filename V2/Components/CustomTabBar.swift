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
    @StateObject private var vehicleViewModel = VehicleViewModel()
    @State private var showingVehicleOnboarding = false
    
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
                
                // Only show the actual VehiclesView if the user has vehicles
                Group {
                    if !vehicleViewModel.vehicles.isEmpty {
                        VehiclesView()
                    } else {
                        // Show a placeholder view that will trigger onboarding
                        VehicleOnboardingPlaceholder(showOnboarding: $showingVehicleOnboarding)
                    }
                }
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
            .sheet(isPresented: $showingVehicleOnboarding) {
                VehicleOnboardingView { newVehicle in
                    Task {
                        do {
                            try await vehicleViewModel.createVehicle(newVehicle)
                            await vehicleViewModel.fetchVehicles()
                        } catch {
                            print("Error creating vehicle: \(error)")
                        }
                    }
                }
                .environmentObject(AuthManager())
            }
        }
        .onAppear {
            // Preload data
            Task {
                do {
                    await discoverViewModel.fetchMeets()
                    try await meetViewModel.fetchMeets()
                    await vehicleViewModel.fetchVehicles()
                } catch {
                    print("Error in preloading tab content: \(error)")
                }
            }
        }
        .onChange(of: selectedTab) { _, newTab in
            if newTab == .vehicles && vehicleViewModel.vehicles.isEmpty {
                showingVehicleOnboarding = true
            }
        }
    }
}

// A simple placeholder view that displays nothing and automatically triggers onboarding
struct VehicleOnboardingPlaceholder: View {
    @Binding var showOnboarding: Bool
    
    var body: some View {
        ZStack {
            AnimatedGradientBackground()
            VStack {
                // Nothing visible here since we'll immediately show the onboarding
            }
        }
        .onAppear {
            // Small delay to ensure the tab transition completes before showing sheet
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showOnboarding = true
            }
        }
    }
}

#Preview {
    MainTabView()
} 
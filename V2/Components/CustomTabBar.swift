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

struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    @Namespace private var namespace
    
    var body: some View {
        HStack {
            ForEach([Tab.discover, .vehicles, .profile, .settings], id: \.self) { tab in
                VStack(spacing: 4) {
                    Image(systemName: tab.icon)
                        .font(.system(size: 20))
                    
                    Text(tab.title)
                        .font(.caption2)
                }
                .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.5))
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    ZStack {
                        if selectedTab == tab {
                            DesignSystem.Colors.accentGradient
                                .clipShape(Capsule())
                                .matchedGeometryEffect(id: "tab", in: namespace)
                        }
                    }
                )
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .padding(.horizontal)
        .padding(.bottom, 8)
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
            
            // Content
            VStack(spacing: 0) {
                TabView(selection: $selectedTab) {
                    DiscoverView(viewModel: discoverViewModel)
                        .tag(Tab.discover)
                    
                    VehiclesView()
                        .tag(Tab.vehicles)
                    
                    ProfileView(viewModel: meetViewModel)
                        .tag(Tab.profile)
                    
                    SettingsView(meetViewModel: meetViewModel)
                        .tag(Tab.settings)
                }
                
                CustomTabBar(selectedTab: $selectedTab)
            }
        }
    }
}

#Preview {
    MainTabView()
} 
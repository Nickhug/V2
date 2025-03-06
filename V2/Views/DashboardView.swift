import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = MeetViewModel()
    @StateObject private var routeViewModel = RouteViewModel()
    @EnvironmentObject private var authManager: AuthManager
    @SceneStorage("selectedTab") private var selectedTab = "home" // Persist tab selection
    
    var body: some View {
        ZStack {
            // Replace static background with animated gradient
            AnimatedGradientBackground()
            
            Group {
                if authManager.isAuthenticated {
                    TabView(selection: $selectedTab) {
                        HomeView()
                            .tabItem {
                                Label("Home", systemImage: "house.fill")
                            }
                            .tag("home")
                        
                        ExploreView(viewModel: viewModel)
                            .tabItem {
                                Label("Explore", systemImage: "magnifyingglass")
                            }
                            .tag("explore")
                        
                        RoutesView()
                            .environmentObject(routeViewModel)
                            .tabItem {
                                Label("Routes", systemImage: "map.fill")
                            }
                            .tag("routes")
                        
                        ProfileView(viewModel: viewModel)
                            .tabItem {
                                Label("Profile", systemImage: "person.fill")
                            }
                            .tag("profile")
                    }
                    .tint(.white)
                } else {
                    LoginView()
                }
            }
        }
        .environmentObject(viewModel)
        .environmentObject(routeViewModel)
    }
}

// Enhanced components
struct TrendingMeetCard: View {
    let meet: Meet
    @ObservedObject var viewModel: MeetViewModel
    
    var body: some View {
        NavigationLink(destination: MeetDetailView(meet: meet, viewModel: viewModel)) {
            cardContent
        }
    }
    
    // Break down the complex view into smaller components
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            cardImageSection
            cardInfoSection
        }
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
    
    private var cardImageSection: some View {
        ZStack(alignment: .topTrailing) {
            // Image with overlay
            cardImage
            
            // Type pill
            typePill
        }
    }
    
    private var cardImage: some View {
        let imageView = AsyncImageView(imageName: meet.coverImage)
            .aspectRatio(contentMode: .fill)
            .frame(width: 180, height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        
        let gradientOverlay = LinearGradient(
            gradient: Gradient(colors: [.clear, .black.opacity(0.7)]),
            startPoint: .center,
            endPoint: .bottom
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        
        return imageView.overlay(gradientOverlay)
    }
    
    private var typePill: some View {
        Text(meet.type.rawValue)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(meet.type.color.opacity(0.8))
            .clipShape(Capsule())
            .foregroundColor(.white)
            .padding(8)
    }
    
    private var cardInfoSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(meet.title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .lineLimit(1)
            
            locationInfo
            attendeeInfo
        }
        .padding(10)
    }
    
    private var locationInfo: some View {
        HStack {
            Image(systemName: "mappin.circle.fill")
                .foregroundColor(.white.opacity(0.7))
            Text(meet.address)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(1)
        }
    }
    
    private var attendeeInfo: some View {
        HStack {
            ForEach(0..<min(3, meet.attendees.count), id: \.self) { i in
                attendeeCircle(for: i)
            }
            
            if meet.attendees.count > 3 {
                Text("+\(meet.attendees.count - 3)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .offset(x: -CGFloat(3 * 10))
            }
        }
        .padding(.leading, 30)
    }
    
    private func attendeeCircle(for index: Int) -> some View {
        Circle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: 22, height: 22)
            .overlay(
                Text(String(meet.attendees[index].profile.name.prefix(1)))
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            )
            .offset(x: -CGFloat(index * 10))
    }
}

extension Theme {
    static let rsvpButtonBackground = Color(red: 0.5, green: 0.3, blue: 0.9) // Purple color
    static let rsvpButtonAttendingBackground = Color(red: 0.3, green: 0.7, blue: 0.4) // Green color
    static let rsvpButtonShadow = Color.black.opacity(0.2)
}

struct RSVPButton: View {
    let meet: Meet
    @ObservedObject var viewModel: MeetViewModel
    @State private var isAttending = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        Button {
            Task {
                isLoading = true
                do {
                    if isAttending {
                        try await viewModel.leaveMeet(meet)
                    } else {
                        await viewModel.attendMeet(meet)
                    }
                    isAttending.toggle()
                } catch {
                    errorMessage = error.localizedDescription
                }
                isLoading = false
            }
        } label: {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: isAttending ? "checkmark.circle.fill" : "plus.circle.fill")
                        .font(.system(size: 18))
                }
                Text(isAttending ? "Attending" : "RSVP")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(isAttending ? Theme.rsvpButtonAttendingBackground : Theme.rsvpButtonBackground)
            .foregroundColor(.white)
            .cornerRadius(22)
            .shadow(color: Theme.rsvpButtonShadow, radius: 5, y: 2)
        }
        .disabled(isLoading)
        .onAppear {
            Task {
                isAttending = viewModel.isAttending(meet)
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
    }
}

struct EnhancedFeaturedMeetCard: View {
    let meet: Meet
    @ObservedObject var viewModel: MeetViewModel
    
    var body: some View {
        NavigationLink(destination: MeetDetailView(meet: meet, viewModel: viewModel)) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .bottomLeading) {
                    AsyncImageView(imageName: meet.coverImage)
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 220)
                        .clipped()
                        .overlay(
                            LinearGradient(
                                gradient: Gradient(colors: [.clear, .black.opacity(0.8)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(meet.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.white)
                            Text(meet.locationName)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .font(.subheadline)
                        
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.white)
                            Text(meet.formattedDate)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .font(.subheadline)
                    }
                    .padding()
                }
                
                VStack(spacing: 16) {
                    Text(meet.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .padding(.horizontal)
                    
                    RSVPButton(meet: meet, viewModel: viewModel)
                        .padding(.horizontal)
                        .padding(.bottom)
                }
                .padding(.vertical)
                .background(Color(.systemBackground))
                .cornerRadius(15)
            }
            .background(Color(.systemBackground))
            .cornerRadius(15)
            .shadow(radius: 5)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EnhancedMeetCard: View {
    let meet: Meet
    @ObservedObject var viewModel: MeetViewModel
    
    var body: some View {
        NavigationLink(destination: MeetDetailView(meet: meet, viewModel: viewModel)) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .top) {
                    AsyncImageView(imageName: meet.coverImage)
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 150)
                        .clipShape(UnevenRoundedRectangle(cornerRadii: .init(
                            topLeading: 16, bottomLeading: 0, bottomTrailing: 0, topTrailing: 16
                        )))
                    
                    VStack {
                        Spacer()
                        HStack {
                            Text(formatDistance(for: meet))
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.7))
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                            
                            Spacer()
                            
                            Text(meet.type.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(meet.type.color)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                        .padding(10)
                    }
                    .frame(height: 150)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text(meet.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.white.opacity(0.7))
                        Text(meet.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.callout)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    HStack {
                        Image(systemName: "person.3.fill")
                            .foregroundColor(.white.opacity(0.7))
                        Text("\(meet.attendees.count) attending")
                            .font(.callout)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Spacer()
                        
                        // Host Avatar
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Text("H")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            )
                    }
                }
                .padding()
            }
            .background(Color.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
        }
    }
    
    // Helper to format distance
    private func formatDistance(for meet: Meet) -> String {
        // This would use actual location data in a real app
        return "\(Int.random(in: 1...15)) mi away"
    }
}

struct EnhancedUpcomingMeetRow: View {
    let meet: Meet
    @ObservedObject var viewModel: MeetViewModel
    
    var body: some View {
        NavigationLink(destination: MeetDetailView(meet: meet, viewModel: viewModel)) {
            HStack(spacing: 15) {
                // Date callout
                VStack(spacing: 2) {
                    Text(formattedDay(from: meet.date))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(formattedMonth(from: meet.date))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(width: 50)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(
                            colors: [meet.type.color.opacity(0.5), meet.type.color.opacity(0.2)],
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                )
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(meet.title)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack {
                        Image(systemName: "clock.fill")
                            .font(.caption2)
                        Text(formattedTime(from: meet.date))
                            .font(.subheadline)
                    }
                    .foregroundColor(.white.opacity(0.7))
                    
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.white.opacity(0.7))
                        Text(meet.address)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Button {
                    // Navigation to calendar or details
                } label: {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.07))
            )
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
    
    // Helper methods to format date components
    private func formattedDay(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter.string(from: date)
    }
    
    private func formattedMonth(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }
    
    private func formattedTime(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Preview
#Preview {
    DashboardView()
} 

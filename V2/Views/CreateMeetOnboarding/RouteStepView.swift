import SwiftUI
import MapKit

struct RouteStepView: View {
    @ObservedObject var onboardingState: CreateMeetOnboardingState
    @ObservedObject var viewModel: MeetViewModel
    @State private var animateElements = false
    @State private var routes: [Route] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            // Background decoration
            Circle()
                .fill(MeetSpotColors.pink500.opacity(0.1))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: 150, y: -200)
            
            Circle()
                .fill(MeetSpotColors.purple900.opacity(0.1))
                .frame(width: 250, height: 250)
                .blur(radius: 60)
                .offset(x: -150, y: 250)
                
            // Main content
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add a Route")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Select an existing route or create a new one")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Image(systemName: CreateMeetStep.route.systemIcon)
                        .font(.system(size: 40))
                        .foregroundColor(MeetSpotColors.pink500)
                        .opacity(animateElements ? 1 : 0)
                        .rotationEffect(.degrees(animateElements ? 0 : -30))
                        .offset(y: animateElements ? 0 : -10)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: animateElements)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Note that route is optional
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(MeetSpotColors.pink500)
                    
                    Text("Adding a route is optional. You can skip this step if you don't want to include a route.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Material.ultraThinMaterial)
                )
                .padding(.horizontal)
                .opacity(animateElements ? 1 : 0)
                .offset(y: animateElements ? 0 : 20)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3), value: animateElements)
                
                // Content area
                if isLoading {
                    // Loading state
                    VStack(spacing: 20) {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.5)
                        
                        Text("Loading routes...")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Material.ultraThinMaterial)
                            .backgroundStyle(Color.black.opacity(0.3))
                    )
                    .mediumShadow()
                    .padding(.horizontal)
                    .opacity(animateElements ? 1 : 0)
                    .offset(y: animateElements ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3), value: animateElements)
                } else if let error = errorMessage {
                    // Error state
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("Failed to load routes")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                        
                        Button {
                            loadRoutes()
                        } label: {
                            Text("Try Again")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 12)
                                .background(MeetSpotColors.pink500)
                                .cornerRadius(12)
                        }
                    }
                    .padding(30)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Material.ultraThinMaterial)
                            .backgroundStyle(Color.black.opacity(0.3))
                    )
                    .mediumShadow()
                    .padding(.horizontal)
                    .opacity(animateElements ? 1 : 0)
                    .offset(y: animateElements ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3), value: animateElements)
                } else if routes.isEmpty {
                    // No routes state
                    VStack(spacing: 20) {
                        Image(systemName: "map.fill")
                            .font(.system(size: 50))
                            .foregroundColor(MeetSpotColors.pink500.opacity(0.7))
                        
                        Text("No Routes Available")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("You don't have any routes yet. Create a new route to share with your meet attendees.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button {
                            onboardingState.showRouteCreator = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Create New Route")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [MeetSpotColors.pink500, MeetSpotColors.purple900]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .pronouncedShadow()
                        }
                    }
                    .padding(30)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Material.ultraThinMaterial)
                            .backgroundStyle(Color.black.opacity(0.3))
                    )
                    .mediumShadow()
                    .padding(.horizontal)
                    .opacity(animateElements ? 1 : 0)
                    .offset(y: animateElements ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3), value: animateElements)
                } else {
                    // Routes list
                    ScrollView {
                        VStack(spacing: 16) {
                            // Create new route button
                            Button {
                                onboardingState.showRouteCreator = true
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                    
                                    Text("Create New Route")
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.subheadline)
                                }
                                .foregroundColor(.white)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(MeetSpotColors.pink500.opacity(0.2))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(MeetSpotColors.pink500.opacity(0.5), lineWidth: 1)
                                        )
                                )
                            }
                            .padding(.horizontal)
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                                .padding(.horizontal)
                            
                            // Routes list
                            ForEach(routes) { route in
                                RouteCard(
                                    route: route,
                                    isSelected: onboardingState.selectedRoute?.id == route.id,
                                    onSelect: {
                                        withAnimation(.spring()) {
                                            onboardingState.selectedRoute = route
                                        }
                                    }
                                )
                                .padding(.horizontal)
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(.vertical)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Material.ultraThinMaterial)
                            .backgroundStyle(Color.black.opacity(0.3))
                    )
                    .mediumShadow()
                    .padding(.horizontal)
                    .opacity(animateElements ? 1 : 0)
                    .offset(y: animateElements ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3), value: animateElements)
                }
                
                // Selected route display
                if let selectedRoute = onboardingState.selectedRoute {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Selected Route")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack {
                            Image(systemName: "map.fill")
                                .foregroundColor(MeetSpotColors.pink500)
                            
                            Text(selectedRoute.title)
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            if let distance = selectedRoute.formattedDistance {
                                Text(distance)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Button {
                                withAnimation(.spring()) {
                                    onboardingState.selectedRoute = nil
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Material.ultraThinMaterial)
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                Spacer()
            }
        }
        .onAppear {
            withAnimation {
                animateElements = true
            }
            loadRoutes()
        }
        .sheet(isPresented: $onboardingState.showRouteCreator) {
            // This would show your route creation view
            Text("Route Creator would go here")
                .onDisappear {
                    // Reload routes when route creator is dismissed
                    loadRoutes()
                }
        }
    }
    
    // Load user's routes
    private func loadRoutes() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Mock loading for now - in a real app, you'd fetch from your service
                try await Task.sleep(for: .seconds(1))
                
                // Get routes from viewModel - assuming your viewModel has a method to fetch routes
                // routes = try await viewModel.getRoutes()
                
                // For demo purposes, using mock data
                routes = [
                    Route(
                        id: "1",
                        creatorId: "user123",
                        title: "Mountain Pass",
                        description: "A scenic route through the mountains",
                        routeData: RouteData(
                            coordinates: [
                                Coordinate(latitude: 37.7749, longitude: -122.4194),
                                Coordinate(latitude: 37.8086, longitude: -122.4095)
                            ]
                        ),
                        distance: 12.5,
                        estimatedTime: 45,
                        difficulty: .moderate
                    ),
                    Route(
                        id: "2",
                        creatorId: "user123",
                        title: "Coastal Drive",
                        description: "Beautiful seaside highway route",
                        routeData: RouteData(
                            coordinates: [
                                Coordinate(latitude: 37.7749, longitude: -122.4194),
                                Coordinate(latitude: 37.8283, longitude: -122.4814)
                            ]
                        ),
                        distance: 25.3,
                        estimatedTime: 60,
                        difficulty: .easy
                    ),
                    Route(
                        id: "3",
                        creatorId: "user123",
                        title: "Downtown Loop",
                        description: "A quick loop around downtown",
                        routeData: RouteData(
                            coordinates: [
                                Coordinate(latitude: 37.7749, longitude: -122.4194),
                                Coordinate(latitude: 37.7899, longitude: -122.4000)
                            ]
                        ),
                        distance: 5.2,
                        estimatedTime: 20,
                        difficulty: .easy
                    )
                ]
                
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}

// Preview
struct RouteStepView_Previews: PreviewProvider {
    static var previews: some View {
        RouteStepView(
            onboardingState: CreateMeetOnboardingState(),
            viewModel: MeetViewModel()
        )
        .preferredColorScheme(.dark)
    }
} 
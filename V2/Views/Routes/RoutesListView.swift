import SwiftUI
import MapKit
import CoreLocation

struct RoutesListView: View {
    @StateObject private var viewModel = RouteViewModel()
    @State private var showingRouteEditor = false
    @State private var showingRouteDetail = false
    @State private var selectedRoute: Route?
    @State private var isPresentingDeleteConfirm = false
    
    var meetId: String?
    var editable: Bool = true
    
    var body: some View {
        ZStack {
            VStack {
                if editable {
                    HStack {
                        Spacer()
                        
                        Button {
                            showingRouteEditor = true
                        } label: {
                            HStack {
                                Image(systemName: "plus")
                                Text("Create Route")
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(DesignSystem.Colors.accentGradient)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                        }
                        .padding(.trailing)
                        .padding(.bottom, 4)
                    }
                }
                
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if getRoutes().isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(getRoutes()) { route in
                                RouteCard(route: route)
                                    .onTapGesture {
                                        selectedRoute = route
                                        showingRouteDetail = true
                                    }
                                    .contextMenu {
                                        if editable {
                                            Button {
                                                selectedRoute = route
                                                showingRouteEditor = true
                                            } label: {
                                                Label("Edit", systemImage: "pencil")
                                            }
                                            
                                            Button(role: .destructive) {
                                                selectedRoute = route
                                                isPresentingDeleteConfirm = true
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                        
                                        Button {
                                            // Share route (e.g., via a URL or text)
                                            shareRoute(route)
                                        } label: {
                                            Label("Share", systemImage: "square.and.arrow.up")
                                        }
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            
            if let errorMessage = viewModel.errorMessage {
                VStack {
                    Text("Error loading routes")
                        .font(.headline)
                    
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Try Again") {
                        loadRoutes()
                    }
                    .padding(.top)
                }
                .padding()
                .modifier(DesignSystem.GlassCard())
                .padding()
            }
        }
        .navigationTitle(meetId != nil ? "Meet Routes" : "My Routes")
        .sheet(isPresented: $showingRouteEditor) {
            RouteEditorView(
                meetId: meetId,
                onRouteSaved: { route in
                    // Refresh routes after saving
                    loadRoutes()
                },
                existingRoute: selectedRoute
            )
            .environmentObject(AuthManager())
            .onDisappear {
                selectedRoute = nil
            }
        }
        .sheet(isPresented: $showingRouteDetail) {
            if let route = selectedRoute {
                RouteDetailView(route: route)
            }
        }
        .alert("Delete Route?", isPresented: $isPresentingDeleteConfirm) {
            Button("Delete", role: .destructive) {
                if let route = selectedRoute {
                    deleteRoute(route)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this route? This action cannot be undone.")
        }
        .onAppear {
            loadRoutes()
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "map")
                .font(.system(size: 70))
                .foregroundColor(.secondary)
            
            Text(meetId != nil ? "No Routes Found" : "You haven't created any routes yet")
                .font(.headline)
            
            Text(meetId != nil ? "This meet doesn't have any routes attached." : "Create a route to get started planning your drives.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if editable {
                Button {
                    showingRouteEditor = true
                } label: {
                    Text(meetId != nil ? "Add Route to Meet" : "Create Your First Route")
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(DesignSystem.Colors.accentGradient)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.top)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func loadRoutes() {
        Task {
            if let meetId = meetId {
                await viewModel.fetchMeetRoutes(meetId: meetId)
            } else {
                await viewModel.fetchUserRoutes()
            }
        }
    }
    
    private func getRoutes() -> [Route] {
        if meetId != nil {
            return viewModel.meetRoutes
        } else {
            return viewModel.userRoutes
        }
    }
    
    private func deleteRoute(_ route: Route) {
        Task {
            let success = await viewModel.deleteRoute(id: route.id)
            if success {
                selectedRoute = nil
            }
        }
    }
    
    private func shareRoute(_ route: Route) {
        // Create a simple text representation of the route
        let shareText = """
        Check out this route: \(route.title)
        
        Distance: \(String(format: "%.1f", route.distance)) km
        Estimated time: \(route.estimatedTime) minutes
        Difficulty: \(route.difficulty.rawValue.capitalized)
        
        \(route.description)
        """
        
        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            activityVC.popoverPresentationController?.sourceView = rootViewController.view
            rootViewController.present(activityVC, animated: true, completion: nil)
        }
    }
}

struct RouteCard: View {
    var route: Route
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(route.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                Label {
                    Text("\(String(format: "%.1f", route.distance)) km")
                } icon: {
                    Image(systemName: "speedometer")
                        .foregroundColor(.blue)
                }
                .font(.subheadline)
            }
            
            if !route.description.isEmpty {
                Text(route.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack {
                Label {
                    Text("\(route.estimatedTime) min")
                } icon: {
                    Image(systemName: "clock")
                        .foregroundColor(.orange)
                }
                .font(.caption)
                
                Spacer()
                
                Label {
                    Text(route.difficulty.rawValue.capitalized)
                } icon: {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.purple)
                }
                .font(.caption)
                
                Spacer()
                
                Label {
                    Text("\(route.routeData.waypoints.count) waypoints")
                } icon: {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.red)
                }
                .font(.caption)
            }
            
            // Small preview map
            if !route.routeData.coordinates.isEmpty {
                RouteMapPreview(route: route)
                    .frame(height: 120)
                    .cornerRadius(8)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .fill(Theme.Colors.surface.opacity(0.3))
                .background(.ultraThinMaterial)
        )
    }
}

struct RouteMapPreview: View {
    var route: Route
    
    @State private var region: MKCoordinateRegion
    
    init(route: Route) {
        self.route = route
        let coordinates = route.routeData.coordinates
        
        // Set initial region
        if let firstCoord = coordinates.first {
            _region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: firstCoord.latitude, longitude: firstCoord.longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            ))
        } else {
            // Default region if no coordinates
            _region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            ))
        }
        
        // Calculate appropriate region to fit all coordinates
        if coordinates.count > 1 {
            var minLat = coordinates[0].latitude
            var maxLat = coordinates[0].latitude
            var minLon = coordinates[0].longitude
            var maxLon = coordinates[0].longitude
            
            for coordinate in coordinates {
                minLat = min(minLat, coordinate.latitude)
                maxLat = max(maxLat, coordinate.latitude)
                minLon = min(minLon, coordinate.longitude)
                maxLon = max(maxLon, coordinate.longitude)
            }
            
            let center = CLLocationCoordinate2D(
                latitude: (minLat + maxLat) / 2,
                longitude: (minLon + maxLon) / 2
            )
            
            let span = MKCoordinateSpan(
                latitudeDelta: (maxLat - minLat) * 1.5,
                longitudeDelta: (maxLon - minLon) * 1.5
            )
            
            _region = State(initialValue: MKCoordinateRegion(center: center, span: span))
        }
    }
    
    var body: some View {
        Map {
            // Draw route line
            MapPolyline(coordinates: route.routeData.coordinates.map { $0.clCoordinate })
                .stroke(Color.accentColor, lineWidth: 3)
            
            // Draw start and end points if they exist
            if let startWaypoint = route.routeData.waypoints.first(where: { $0.type == .start }) {
                Marker("Start", coordinate: startWaypoint.coordinate.clCoordinate)
                    .tint(.green)
            }
            
            if let endWaypoint = route.routeData.waypoints.first(where: { $0.type == .end }) {
                Marker("End", coordinate: endWaypoint.coordinate.clCoordinate)
                    .tint(.red)
            }
        }
        .mapStyle(.standard)
        .mapControls {
            MapCompass()
        }
    }
}

struct RouteDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = RouteViewModel()
    
    var route: Route
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                RouteMapView(viewModel: viewModel, route: route)
                    .edgesIgnoringSafeArea(.top)
            }
            .navigationTitle(route.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                    }
                }
            }
            .onAppear {
                viewModel.selectedRoute = route
            }
        }
    }
} 
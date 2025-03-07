import SwiftUI
import MapKit
import CoreLocation

struct RoutesListView: View {
    @EnvironmentObject private var viewModel: RouteViewModel
    @State private var showingRouteEditor = false
    @State private var showingRouteDetail = false
    @State private var selectedRoute: Route?
    @State private var isPresentingDeleteConfirm = false
    
    var routes: [Route]? = nil
    var meetId: String?
    var editable: Bool = true
    
    // Use the provided routes or fall back to the appropriate routes from the viewModel
    private var displayedRoutes: [Route] {
        if let routes = routes {
            return routes
        } else if let meetId = meetId, !meetId.isEmpty {
            return viewModel.meetRoutes
        } else if editable {
            return viewModel.userRoutes
        } else {
            return viewModel.routes
        }
    }
    
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
                            .background(
                                Capsule()
                                    .fill(MeetSpotColors.accentGradient)
                            )
                            .foregroundColor(.white)
                        }
                        .padding(.trailing)
                    }
                    .padding(.vertical, 8)
                }
                
                if displayedRoutes.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "map")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text(editable ? "You haven't created any routes yet" : "No routes available")
                            .font(.headline)
                        
                        if editable {
                            Button {
                                showingRouteEditor = true
                            } label: {
                                Text("Create Your First Route")
                                    .padding()
                                    .background(MeetSpotColors.accentGradient)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding()
                } else {
                    List {
                        ForEach(displayedRoutes) { route in
                            RouteRow(route: route)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedRoute = route
                                    showingRouteDetail = true
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    if editable {
                                        Button(role: .destructive) {
                                            selectedRoute = route
                                            isPresentingDeleteConfirm = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                        
                                        Button {
                                            viewModel.startEditingRoute(route)
                                            showingRouteEditor = true
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        .tint(.blue)
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
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
    
    private func loadRoutes() {
        Task {
            if let meetId = meetId {
                await viewModel.fetchMeetRoutes(meetId: meetId)
            } else {
                await viewModel.fetchUserRoutes()
            }
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

struct RouteRow: View {
    let route: Route
    
    var body: some View {
        HStack(spacing: 16) {
            // Route thumbnail/icon
            ZStack {
                Circle()
                    .fill(MeetSpotColors.accentGradient)
                    .frame(width: 50, height: 50)
                
                Image(systemName: "map.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
            
            // Route details
            VStack(alignment: .leading, spacing: 4) {
                Text(route.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(route.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack(spacing: 12) {
                    Label("\(String(format: "%.1f", route.distance)) km", systemImage: "arrow.triangle.swap")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label("\(route.estimatedTime) min", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label(route.difficulty.rawValue.capitalized, systemImage: "chart.bar.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
} 
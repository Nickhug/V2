import SwiftUI
import MapKit

struct RouteMapView: View {
    @ObservedObject var viewModel: RouteViewModel
    var route: Route?
    var isEditable: Bool
    @State private var cameraPosition: MapCameraPosition
    @State private var initialLocationSet = false
    
    init(viewModel: RouteViewModel, route: Route? = nil, isEditable: Bool = false) {
        self.viewModel = viewModel
        self.route = route
        self.isEditable = isEditable
        
        // Initialize with the viewModel's current mapRegion
        self._cameraPosition = State(initialValue: .region(viewModel.mapRegion))
    }
    
    var body: some View {
        MapReader { proxy in
            mapView(with: proxy)
        }
    }
    
    @ViewBuilder
    private func mapView(with proxy: MapProxy) -> some View {
        Map(position: $cameraPosition) {
            // User location
            UserAnnotation()
                .tint(.blue)
            
            // Route polylines
            mapPolylines
            
            // Waypoints
            mapWaypoints
        }
        .mapStyle(.standard)
        .mapControls {
            MapUserLocationButton()
                .mapControlVisibility(.visible)
            MapCompass()
                .mapControlVisibility(.visible)
            MapScaleView()
                .mapControlVisibility(.visible)
        }
        .onAppear {
            setupView(proxy: proxy)
        }
        .onChange(of: viewModel.locationManager.location) { _, newLocation in
            if let location = newLocation, !initialLocationSet, isEditable {
                print("RouteMapView - Got first location, updating camera: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                initialLocationSet = true
                DispatchQueue.main.async {
                    cameraPosition = .region(MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    ))
                }
            }
        }
        .overlay {
            routeInfoCard
        }
    }
    
    private func setupView(proxy: MapProxy) {
        print("RouteMapView - onAppear")
        viewModel.mapProxy = proxy
        cameraPosition = .region(viewModel.mapRegion)
        
        // Set up region change handler
        viewModel.onMapRegionChange = { [weak viewModel] newRegion in
            print("RouteMapView - mapRegion changed, updating camera position")
            if let viewModel = viewModel {
                cameraPosition = .region(viewModel.mapRegion)
            }
        }
        
        // Request location update if needed and we're in edit mode
        if viewModel.locationManager.location == nil && isEditable {
            print("RouteMapView - Requesting initial location")
            viewModel.locationManager.forceLocationUpdate()
        }
    }
    
    @ViewBuilder
    private var routeInfoCard: some View {
        if !isEditable, let route = route {
            VStack {
                Spacer()
                MapRouteInfoCard(
                    icon: "map",
                    title: route.title,
                    value: route.formattedDistance ?? "N/A"
                )
                .padding()
            }
        }
    }
    
    private var mapPolylines: some MapContent {
        let overlays = getRouteOverlays()
        
        if !overlays.isEmpty, let overlay = overlays.first {
            // Create an MKPolyline for the coordinates
            let mkPolyline = MKPolyline(coordinates: overlay.coordinates, count: overlay.coordinates.count)
            return MapPolyline(mkPolyline)
                .stroke(Color.accentColor, lineWidth: 4)
        }
        
        // Return an empty polyline if no coordinates
        return MapPolyline(MKPolyline())
            .stroke(Color.accentColor, lineWidth: 4)
    }
    
    private var mapWaypoints: some MapContent {
        // Always return a ForEach, but with an empty array if there are no waypoints
        let waypoints = getWaypoints()
        // Limit to maximum 20 waypoints to avoid compiler complexity issues
        let limitedWaypoints = Array(waypoints.prefix(20))
        
        return ForEach(limitedWaypoints.isEmpty ? [] : limitedWaypoints) { waypoint in
            Annotation(
                waypoint.title,
                coordinate: waypoint.coordinate.clCoordinate
            ) {
                WaypointMarkerView(
                    waypoint: waypoint,
                    isDraggable: isEditable,
                    mapRegion: viewModel.mapRegion
                ) { newLocation in
                    if isEditable {
                        if let index = viewModel.waypoints.firstIndex(where: { $0.id == waypoint.id }) {
                            var updatedWaypoint = waypoint
                            updatedWaypoint.coordinate = Coordinate(from: newLocation)
                            viewModel.waypoints[index] = updatedWaypoint
                        }
                    }
                }
            }
        }
    }
    
    private func getWaypoints() -> [Waypoint] {
        if let route = route, !isEditable {
            return route.routeData.waypoints
        }
        return viewModel.waypoints
    }
    
    private func getRouteOverlays() -> [RouteOverlay] {
        if let route = route, !isEditable {
            return [RouteOverlay(id: route.id, coordinates: route.routeData.coordinates.map { $0.clCoordinate })]
        } else if !viewModel.routeCoordinates.isEmpty {
            return [RouteOverlay(id: "draft", coordinates: viewModel.routeCoordinates)]
        }
        return []
    }
    
    private func extractRegion(from position: MapCameraPosition) -> MKCoordinateRegion? {
        let mirror = Mirror(reflecting: position)
        for child in mirror.children {
            if let region = child.value as? MKCoordinateRegion {
                return region
            }
        }
        return nil
    }
}

struct RouteOverlay: Identifiable {
    let id: String
    let coordinates: [CLLocationCoordinate2D]
}

struct RoutePolylineView: Shape {
    var coordinates: [CLLocationCoordinate2D]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard coordinates.count > 1 else { return path }
        
        let points = coordinates.map { coordinate -> CGPoint in
            let latitude = (coordinate.latitude - coordinates[0].latitude) / 0.1
            let longitude = (coordinate.longitude - coordinates[0].longitude) / 0.1
            
            let x = rect.width * CGFloat(longitude) + rect.midX
            let y = rect.height * CGFloat(latitude) + rect.midY
            
            return CGPoint(x: x, y: y)
        }
        
        path.move(to: points[0])
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        
        return path
    }
}

struct WaypointMarkerView: View {
    var waypoint: Waypoint
    var isDraggable: Bool
    var mapRegion: MKCoordinateRegion
    var onDragEnded: (CLLocationCoordinate2D) -> Void
    
    @State private var dragOffset: CGSize = .zero
    @State private var position: CGPoint = .zero
    @State private var showDetails = false
    
    var body: some View {
        VStack(spacing: 0) {
            markerCircle
            
            if waypoint.type == .start || waypoint.type == .end {
                markerLabel
            }
        }
        .sheet(isPresented: $showDetails) {
            WaypointDetailSheet(waypoint: waypoint, isEditable: isDraggable)
                .environmentObject(AuthManager())
        }
    }
    
    private var markerCircle: some View {
        ZStack {
            Circle()
                .fill(waypoint.type.displayColor)
                .frame(width: 30, height: 30)
            
            Image(systemName: waypoint.type.systemIconName)
                .foregroundColor(.white)
                .font(.system(size: 14, weight: .bold))
        }
        .shadow(radius: 2)
        .offset(dragOffset)
        .gesture(isDraggable ? simpleDragGesture : nil)
        .onTapGesture {
            showDetails.toggle()
        }
    }
    
    private var markerLabel: some View {
        Text(waypoint.title)
            .font(.caption)
            .fontWeight(.bold)
            .padding(4)
            .background(.ultraThinMaterial)
            .cornerRadius(4)
    }
    
    // Simplified drag gesture
    private var simpleDragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
            }
            .onEnded { value in
                // Basic calculation without complex math
                if value.translation != .zero {
                    calculateNewCoordinate(from: value.translation)
                }
                dragOffset = .zero
            }
    }
    
    private func calculateNewCoordinate(from translation: CGSize) {
        // Get screen size for relative calculations
        let screenSize = UIScreen.main.bounds.size
        
        // Calculate offsets based on screen size and map span
        let latOffset = (translation.height / screenSize.height) * mapRegion.span.latitudeDelta
        let lonOffset = (translation.width / screenSize.width) * mapRegion.span.longitudeDelta
        
        // Apply offset to current coordinate
        let newLat = waypoint.coordinate.latitude - latOffset
        let newLon = waypoint.coordinate.longitude + lonOffset
        
        // Send new coordinate to callback
        onDragEnded(CLLocationCoordinate2D(latitude: newLat, longitude: newLon))
    }
}

struct WaypointDetailSheet: View {
    var waypoint: Waypoint
    var isEditable: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                Theme.Colors.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.Spacing.large) {
                        // Header with icon
                        waypointHeaderView
                        
                        // Details card
                        waypointDetailsCard
                        
                        // Coordinates and information card
                        coordinatesCard
                        
                        // Action buttons (only for editable mode)
                        if isEditable {
                            actionButtons
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Waypoint Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.accent)
                }
            }
        }
    }
    
    private var waypointHeaderView: some View {
        VStack(spacing: Theme.Spacing.medium) {
            // Icon with colored background
            ZStack {
                Circle()
                    .fill(waypoint.type.displayColor)
                    .frame(width: 80, height: 80)
                    .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius * 0.5)
                
                Image(systemName: waypoint.type.systemIconName)
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.white)
            }
            
            // Title
            Text(waypoint.title)
                .font(Theme.Typography.heading2)
                .foregroundColor(Theme.Colors.text)
                .multilineTextAlignment(.center)
            
            // Type badge
            Text(waypoint.type.rawValue.capitalized)
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(waypoint.type.displayColor.opacity(0.2))
                .foregroundColor(waypoint.type.displayColor)
                .clipShape(Capsule())
        }
    }
    
    private var waypointDetailsCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(Theme.Colors.accent)
                Text("Details")
                    .font(Theme.Typography.heading3)
                    .foregroundColor(Theme.Colors.text)
            }
            
            VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                detailRow(icon: "mappin.and.ellipse", title: "Title", value: waypoint.title)
                
                if let subtitle = waypoint.subtitle {
                    detailRow(icon: "text.alignleft", title: "Description", value: subtitle)
                }
                
                detailRow(icon: "tag.fill", title: "Type", value: waypoint.type.defaultTitle)
            }
            .padding()
            .background(Theme.cardBackground)
            .cornerRadius(Theme.CornerRadius.medium)
            .shadow(color: Theme.shadowColor.opacity(0.1), radius: Theme.shadowRadius * 0.5)
        }
    }
    
    private var coordinatesCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(Theme.Colors.accent)
                Text("Coordinates")
                    .font(Theme.Typography.heading3)
                    .foregroundColor(Theme.Colors.text)
            }
            
            VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                coordinateRow(title: "Latitude", value: waypoint.coordinate.latitude)
                coordinateRow(title: "Longitude", value: waypoint.coordinate.longitude)
            }
            .padding()
            .background(Theme.cardBackground)
            .cornerRadius(Theme.CornerRadius.medium)
            .shadow(color: Theme.shadowColor.opacity(0.1), radius: Theme.shadowRadius * 0.5)
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: Theme.Spacing.medium) {
            Button(action: {
                // Copy coordinates to clipboard
                let coordinateString = "(\(waypoint.coordinate.latitude), \(waypoint.coordinate.longitude))"
                UIPasteboard.general.string = coordinateString
                // In a real app, we'd show a success message here
            }) {
                HStack {
                    Image(systemName: "doc.on.doc")
                    Text("Copy Coordinates")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Theme.Colors.surface)
                .foregroundColor(Theme.Colors.text)
                .cornerRadius(Theme.CornerRadius.medium)
            }
            
            Button(action: {
                // This would be linked to external map apps
                let url = URL(string: "https://maps.apple.com/?ll=\(waypoint.coordinate.latitude),\(waypoint.coordinate.longitude)")
                if let url = url, UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Image(systemName: "map")
                    Text("Open in Maps")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Theme.Colors.accentGradient)
                .foregroundColor(.white)
                .cornerRadius(Theme.CornerRadius.medium)
            }
        }
    }
    
    private func detailRow(icon: String, title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.small) {
            Image(systemName: icon)
                .foregroundColor(Theme.Colors.accent)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(Theme.Colors.textSecondary)
                
                Text(value)
                    .font(.body)
                    .foregroundColor(Theme.Colors.text)
            }
        }
    }
    
    private func coordinateRow(title: String, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(Theme.Colors.textSecondary)
            
            HStack {
                Text(String(format: "%.6f", value))
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(Theme.Colors.text)
                
                Spacer()
                
                Button(action: {
                    // Copy single coordinate to clipboard
                    UIPasteboard.general.string = String(format: "%.6f", value)
                    // In a real app, we'd show a success message here
                }) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(Theme.Colors.accent)
                }
            }
            .padding(10)
            .background(Theme.Colors.surface.opacity(0.5))
            .cornerRadius(Theme.CornerRadius.small)
        }
    }
}

// Renamed to avoid conflict with RouteEditorView.RouteInfoCard
struct MapRouteInfoCard: View {
    var icon: String
    var title: String
    var value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                
                Text(title)
                    .font(.headline)
            }
            
            Text(value)
                .font(.subheadline)
        }
        .padding()
        .modifier(DesignSystem.GlassCard())
    }
}

// Helper struct for empty map content
struct EmptyMapContent: MapContent {
    var body: some MapContent {
        // Empty implementation
    }
} 
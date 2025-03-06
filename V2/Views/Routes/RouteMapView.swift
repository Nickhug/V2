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
    
    var body: some View {
        NavigationView {
            Form {
                waypointDetailsSection
            }
            .navigationTitle("Waypoint Info")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var waypointDetailsSection: some View {
        Section(header: Text("Waypoint Details")) {
            LabeledContent("Title", value: waypoint.title)
            
            if let subtitle = waypoint.subtitle {
                LabeledContent("Subtitle", value: subtitle)
            }
            
            LabeledContent("Type", value: waypoint.type.rawValue.capitalized)
            
            LabeledContent("Coordinates") {
                coordinatesView
            }
        }
    }
    
    private var coordinatesView: some View {
        VStack(alignment: .leading) {
            Text("Lat: \(waypoint.coordinate.latitude, specifier: "%.6f")")
            Text("Lon: \(waypoint.coordinate.longitude, specifier: "%.6f")")
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
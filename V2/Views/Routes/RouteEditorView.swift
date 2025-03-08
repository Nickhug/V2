import SwiftUI
import MapKit

// MARK: - Route Editor View

struct RouteEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = RouteViewModel()
    @EnvironmentObject private var authManager: AuthManager
    
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var difficulty: RouteDifficulty = .moderate
    @State private var showingDiscardAlert = false
    @State private var isLoading = false
    @State private var error: NSError? = nil
    @State private var showSuccess = false
    @State private var saved = false
    @State private var showingRouteForm = false
    
    // Tool selection state
    @State private var selectedTool: WaypointTool = .route
    @State private var showToolbar = false
    @State private var initialLocationSet = false
    @State private var lastLocationRequestTime: Date = Date(timeIntervalSince1970: 0)
    
    // Route editor is always in edit mode
    private let isEditable: Bool = true
    
    var meetId: String?
    var onRouteSaved: ((Route) -> Void)?
    var existingRoute: Route?
    
    // Enum for tool selection
    enum WaypointTool: String, CaseIterable {
        case route = "Route"
        case start = "Start"
        case end = "End"
        case waypoint = "Waypoint"
        case scenic = "Scenic"
        case rest = "Rest Stop"
        
        var iconName: String {
            switch self {
            case .route: return "arrow.triangle.turn.up.right.diamond.fill"
            case .start: return "flag.fill"
            case .end: return "flag.checkered"
            case .waypoint: return "mappin"
            case .scenic: return "camera"
            case .rest: return "cup.and.saucer"
            }
        }
        
        var waypointType: WaypointType? {
            switch self {
            case .route: return nil
            case .start: return .start
            case .end: return .end
            case .waypoint: return .regular
            case .scenic: return .scenic
            case .rest: return .rest
            }
        }
        
        var color: Color {
            switch self {
            case .route: return .blue
            case .start: return .green
            case .end: return .red
            case .waypoint: return .orange
            case .scenic: return .purple
            case .rest: return .brown
            }
        }
    }
    
    // MARK: - Throttled Location Request
    private func requestLocationIfNeeded() {
        // Only request location if at least 5 seconds have passed since the last request
        let now = Date()
        if now.timeIntervalSince(lastLocationRequestTime) >= 5.0 {
            print("RouteEditorView - Requesting location (throttled)")
            viewModel.locationManager.requestLocation()
            lastLocationRequestTime = now
        } else {
            print("RouteEditorView - Skipping location request (throttled)")
        }
    }
    
    init(meetId: String? = nil, onRouteSaved: ((Route) -> Void)? = nil, existingRoute: Route? = nil) {
        self.meetId = meetId
        self.onRouteSaved = onRouteSaved
        self.existingRoute = existingRoute
        
        if let route = existingRoute {
            _title = State(initialValue: route.title)
            _description = State(initialValue: route.description)
            _difficulty = State(initialValue: route.difficulty)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AnimatedGradientBackground()
                
                if showingRouteForm {
                    routeFormView
                } else {
                    mapView
                }
            }
            .navigationTitle(existingRoute != nil ? "Edit Route" : "Create Route")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        if title.isEmpty && description.isEmpty && viewModel.waypoints.isEmpty {
                            dismiss()
                        } else {
                            showingDiscardAlert = true
                        }
                    } label: {
                        Text("Cancel")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if showingRouteForm {
                        Button {
                            saveRoute()
                        } label: {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Save")
                            }
                        }
                        .disabled(isLoading || title.isEmpty || viewModel.waypoints.count < 2)
                    } else {
                        Button {
                            showToolbar.toggle()
                        } label: {
                            Image(systemName: "wrench")
                        }
                    }
                }
            }
            .alert(isPresented: $showingDiscardAlert) {
                Alert(
                    title: Text("Discard Changes?"),
                    message: Text("You have unsaved changes. Are you sure you want to discard them?"),
                    primaryButton: .destructive(Text("Discard")) {
                        dismiss()
                    },
                    secondaryButton: .cancel()
                )
            }
            .onAppear {
                print("RouteEditorView - onAppear")
                
                // Initialize the route - either existing or new
                if let existingRoute = existingRoute {
                    viewModel.startEditingRoute(existingRoute)
                } else {
                    // Start a new route - this will handle the location request
                    viewModel.startNewRoute()
                }
            }
            .onChange(of: viewModel.locationManager.location) { oldLocation, newLocation in
                // No action needed here - let RouteMapView handle centering
                if let newLocation = newLocation {
                    print("RouteEditorView - Got location update: \(newLocation.coordinate.latitude), \(newLocation.coordinate.longitude)")
                }
            }
        }
    }
    
    private var mapView: some View {
        ZStack {
            RouteMapView(viewModel: viewModel, isEditable: true)
                .ignoresSafeArea()
                .overlay(
                    ZStack {
                        // Instructions and location button at the top
                        VStack {
                            HStack {
                                // Tool indicator and instructions
                                HStack {
                                    Image(systemName: selectedTool.iconName)
                                        .foregroundColor(selectedTool.color)
                                        .padding(8)
                                        .background(Color.white.opacity(0.2))
                                        .clipShape(Circle())
                                    
                                    Text(routeInstructionsText)
                                        .font(.subheadline)
                                }
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(10)
                                .padding()
                                
                                Spacer()
                                
                                // Location button
                                Button(action: {
                                    print("RouteEditorView - Location button pressed")
                                    
                                    // ALWAYS force a location update when the user manually presses the button
                                    print("RouteEditorView - Forcing location update from button press")
                                    viewModel.locationManager.forceLocationUpdate()
                                    
                                    // Try to center immediately if location is available
                                    if let location = viewModel.locationManager.location?.coordinate {
                                        print("RouteEditorView - Setting region from button press: \(location.latitude), \(location.longitude)")
                                        viewModel.mapRegion = MKCoordinateRegion(
                                            center: location,
                                            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                                        )
                                        
                                        // Cache this location
                                        UserDefaults.standard.set(
                                            ["latitude": location.latitude, "longitude": location.longitude],
                                            forKey: "LastKnownLocation"
                                        )
                                    } else if let lastKnownLocation = UserDefaults.standard.object(forKey: "LastKnownLocation") as? [String: Double],
                                              let latitude = lastKnownLocation["latitude"],
                                              let longitude = lastKnownLocation["longitude"] {
                                        // Use cached location if available
                                        print("RouteEditorView - Using cached location for button press: \(latitude), \(longitude)")
                                        viewModel.mapRegion = MKCoordinateRegion(
                                            center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                                            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                                        )
                                    } else {
                                        print("RouteEditorView - No location available")
                                    }
                                }) {
                                    Image(systemName: "location.fill")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(width: 44, height: 44)
                                        .background(Color.blue.opacity(0.8))
                                        .cornerRadius(10)
                                }
                                .padding()
                            }
                            
                            Spacer()
                        }
                        
                        // Waypoint tool toolbar
                        if showToolbar {
                            VStack {
                                HStack {
                                    Spacer()
                                    
                                    VStack(spacing: 15) {
                                        ForEach(WaypointTool.allCases, id: \.self) { tool in
                                            Button {
                                                selectedTool = tool
                                                showToolbar = false
                                                
                                                // Reset back to route mode after a delay
                                                if tool != .route {
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                                        // Only reset if no action was taken
                                                        if selectedTool == tool {
                                                            selectedTool = .route
                                                        }
                                                    }
                                                }
                                            } label: {
                                                HStack {
                                                    Text(tool.rawValue)
                                                        .font(.subheadline)
                                                    
                                                    Spacer()
                                                    
                                                    Image(systemName: tool.iconName)
                                                        .foregroundColor(.white)
                                                }
                                                .padding(.horizontal)
                                                .padding(.vertical, 12)
                                                .frame(width: 160)
                                                .background(selectedTool == tool ? tool.color : Color.black.opacity(0.6))
                                                .cornerRadius(8)
                                            }
                                        }
                                    }
                                    .padding()
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(12)
                                    .padding()
                                }
                                
                                Spacer()
                            }
                        }
                        
                        // Bottom controls
                        VStack {
                            Spacer()
                            
                            HStack {
                                // Undo last point
                                if !viewModel.routeCoordinates.isEmpty {
                                    Button(action: {
                                        // Remove last segment
                                        if viewModel.routeCoordinates.count > 1 {
                                            viewModel.routeCoordinates.removeLast()
                                            // If the last waypoint is not start, remove it
                                            if let lastWaypoint = viewModel.waypoints.last, lastWaypoint.type != .start {
                                                viewModel.waypoints.removeLast()
                                            }
                                        }
                                    }) {
                                        Image(systemName: "arrow.uturn.backward")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .frame(width: 44, height: 44)
                                            .background(Color.orange.opacity(0.8))
                                            .cornerRadius(10)
                                    }
                                }
                                
                                Spacer()
                                
                                // Current tool indicator
                                if selectedTool != .route {
                                    Text("Tool: \(selectedTool.rawValue)")
                                        .font(.caption)
                                        .padding(8)
                                        .background(selectedTool.color.opacity(0.8))
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                                
                                Spacer()
                                
                                // Clear route
                                if !viewModel.routeCoordinates.isEmpty {
                                    Button(action: {
                                        viewModel.clearRoute()
                                        // Reset to route mode
                                        selectedTool = .route 
                                    }) {
                                        Image(systemName: "trash")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .frame(width: 44, height: 44)
                                            .background(Color.red.opacity(0.8))
                                            .cornerRadius(10)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            
                            // Action button - context dependent
                            if viewModel.routeCoordinates.isEmpty {
                                // If no route exists, show "Start Route" button
                                Button(action: {
                                    if let location = viewModel.locationManager.location?.coordinate {
                                        viewModel.startRouteAt(location)
                                        // Reset to route mode
                                        selectedTool = .route
                                    }
                                }) {
                                    Label("Start Route at My Location", systemImage: "car.fill")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.green.opacity(0.8))
                                        .cornerRadius(10)
                                }
                                .padding()
                            } else if viewModel.waypoints.contains(where: { $0.type == .start }) && 
                                     viewModel.waypoints.contains(where: { $0.type == .end }) {
                                // If route is complete, show "Continue" button
                                Button {
                                    showingRouteForm = true
                                } label: {
                                    Label("Continue to Route Details", systemImage: "arrow.right")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.blue, Color.purple]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .cornerRadius(10)
                                }
                                .padding()
                            } else if viewModel.waypoints.contains(where: { $0.type == .start }) {
                                // If only start exists, show "Complete Route" button
                                Button(action: {
                                    let centerCoordinate = viewModel.mapRegion.center
                                    viewModel.calculateRoadRoute(from: viewModel.routeCoordinates.last ?? centerCoordinate, to: centerCoordinate)
                                    
                                    // Reset to route mode
                                    selectedTool = .route
                                }) {
                                    Label("Set End Point Here", systemImage: "flag.checkered")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.red.opacity(0.8))
                                        .cornerRadius(10)
                                }
                                .padding()
                            }
                        }
                    }
                )
                .onTapGesture { location in
                    guard isEditable else { return }
                    
                    if let proxy = viewModel.mapProxy,
                       let coordinate = proxy.convert(location, from: .local) {
                        
                        // Handle based on selected tool
                        if let waypointType = selectedTool.waypointType {
                            // For specific waypoint tools
                            viewModel.addWaypoint(at: coordinate, title: waypointType.defaultTitle, type: waypointType)
                            
                            // Auto-reset to route mode
                            DispatchQueue.main.async {
                                selectedTool = .route
                            }
                        } else {
                            // For route mode
                            if viewModel.routeCoordinates.isEmpty {
                                // If no route yet, start one
                                viewModel.startRouteAt(coordinate)
                            } else if !viewModel.waypoints.contains(where: { $0.type == .end }) {
                                // If route started but not ended, add segment
                                viewModel.addRouteSegment(to: coordinate)
                            }
                        }
                    }
                }
        }
    }
    
    // Contextual instructions based on route state and selected tool
    private var routeInstructionsText: String {
        if selectedTool != .route {
            return "Tap map to place a \(selectedTool.rawValue.lowercased()) point"
        } else if viewModel.routeCoordinates.isEmpty {
            return "Tap the map to start your route"
        } else if !viewModel.waypoints.contains(where: { $0.type == .end }) {
            return "Tap the map to add waypoints or use button to end"
        } else {
            return "Your route is complete. Review and continue"
        }
    }
    
    private var routeFormView: some View {
        ScrollView {
            VStack(spacing: 20) {
                routeDetailsForm
                routeInfoCards
            }
            .padding()
        }
    }
    
    private var routeDetailsForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ROUTE DETAILS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                titleField
                descriptionField
                difficultyPicker
            }
        }
        .padding(.vertical)
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private var titleField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Title")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            TextField("", text: $title)
                .font(.headline)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .viewPlaceholder(when: title.isEmpty) {
                    Text("Enter route title")
                        .foregroundColor(.gray.opacity(0.7))
                        .font(.headline)
                        .padding(.leading)
                }
        }
        .padding(.horizontal)
    }
    
    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Description")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $description)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                
                if description.isEmpty {
                    Text("Describe your route...")
                        .foregroundColor(.gray.opacity(0.7))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var difficultyPicker: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Difficulty")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Picker("Difficulty", selection: $difficulty) {
                ForEach(RouteDifficulty.allCases, id: \.self) { difficulty in
                    Text(difficulty.rawValue)
                        .tag(difficulty)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
        }
        .padding(.horizontal)
    }
    
    private var routeInfoCards: some View {
        HStack(spacing: 12) {
            RouteInfoCard(
                icon: "ruler",
                title: "Distance",
                value: formattedDistance
            )
            
            RouteInfoCard(
                icon: "clock",
                title: "Est. Time",
                value: formattedEstimatedTime
            )
            
            RouteInfoCard(
                icon: "mappin.and.ellipse",
                title: "Waypoints",
                value: "\(viewModel.waypoints.count)"
            )
        }
        .padding(.horizontal)
    }
    
    private var formattedDistance: String {
        var totalDistance: Double = 0
        let coordinates = viewModel.routeCoordinates
        
        if coordinates.count > 1 {
            for i in 0..<(coordinates.count - 1) {
                let coord1 = CLLocation(
                    latitude: coordinates[i].latitude,
                    longitude: coordinates[i].longitude
                )
                let coord2 = CLLocation(
                    latitude: coordinates[i+1].latitude,
                    longitude: coordinates[i+1].longitude
                )
                totalDistance += coord1.distance(from: coord2) / 1000 // Convert to km
            }
        }
        
        if totalDistance >= 1.0 {
            return String(format: "%.1f km", totalDistance)
        } else {
            let meters = Int(totalDistance * 1000)
            return "\(meters) m"
        }
    }
    
    private var formattedEstimatedTime: String {
        var totalDistance: Double = 0
        let coordinates = viewModel.routeCoordinates
        
        if coordinates.count > 1 {
            for i in 0..<(coordinates.count - 1) {
                let coord1 = CLLocation(
                    latitude: coordinates[i].latitude,
                    longitude: coordinates[i].longitude
                )
                let coord2 = CLLocation(
                    latitude: coordinates[i+1].latitude,
                    longitude: coordinates[i+1].longitude
                )
                totalDistance += coord1.distance(from: coord2) / 1000 // Convert to km
            }
        }
        
        // Estimate time (using average speed of 30 km/h)
        let averageSpeedKmPerHour: Double = 30
        let estimatedTime = Int((totalDistance / averageSpeedKmPerHour) * 60) // Convert to minutes
        
        return "\(estimatedTime) min"
    }
    
    private func saveRoute() {
        isLoading = true
        
        // Convert coordinates to RouteData format
        let coordinates = viewModel.routeCoordinates.map { Coordinate(from: $0) }
        let routeData = RouteData(coordinates: coordinates, waypoints: viewModel.waypoints)
        
        // Calculate distance and estimated time
        var totalDistance: Double = 0
        if coordinates.count > 1 {
            for i in 0..<(coordinates.count - 1) {
                let coord1 = CLLocation(
                    latitude: coordinates[i].latitude,
                    longitude: coordinates[i].longitude
                )
                let coord2 = CLLocation(
                    latitude: coordinates[i+1].latitude,
                    longitude: coordinates[i+1].longitude
                )
                totalDistance += coord1.distance(from: coord2) / 1000 // Convert to km
            }
        }
        
        // Estimate time (using average speed of 30 km/h)
        let averageSpeedKmPerHour: Double = 30
        let estimatedTime = Int((totalDistance / averageSpeedKmPerHour) * 60) // Convert to minutes
        
        let route = Route(
            id: existingRoute?.id ?? UUID().uuidString,
            meetId: meetId,
            creatorId: existingRoute?.creatorId ?? "", // This will be set by the viewModel
            title: title,
            description: description,
            routeData: routeData,
            distance: totalDistance,
            estimatedTime: estimatedTime,
            difficulty: difficulty,
            createdAt: existingRoute?.createdAt ?? Date(),
            updatedAt: Date()
        )
        
        Task {
            let savedRoute: Route?
            if existingRoute != nil {
                savedRoute = await viewModel.updateRoute(route)
            } else {
                savedRoute = await viewModel.createRoute(
                    title: title,
                    description: description,
                    difficulty: difficulty,
                    meetId: meetId
                )
            }
            
            if let savedRoute = savedRoute {
                await MainActor.run {
                    saved = true
                    showSuccess = true
                    isLoading = false
                    onRouteSaved?(savedRoute)
                }
            } else {
                await MainActor.run {
                    self.error = NSError(domain: "RouteEditor", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to save route"])
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Supporting View Components
struct RouteInfoCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(value)
                .font(.headline)
                .foregroundColor(.white)
        }
        .frame(minWidth: 90, maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Route Difficulty Enum
// Removed duplicate RouteDifficulty enum, using the one from Models/Route.swift instead 
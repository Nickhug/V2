import Foundation
import MapKit
import Combine
import SwiftUI

@MainActor
class RouteViewModel: ObservableObject {
    private let supabaseService = SupabaseService.shared
    
    @Published var routes: [Route] = []
    @Published var userRoutes: [Route] = []
    @Published var meetRoutes: [Route] = []
    @Published var selectedRoute: Route?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // For route editing
    @Published var draftRoute: Route?
    @Published var routeCoordinates: [CLLocationCoordinate2D] = []
    @Published var waypoints: [Waypoint] = []
    @Published var isEditingRoute = false
    @Published var locationManager: LocationManager = {
        let manager = LocationManager()
        // Initialize with a past time to ensure first request goes through
        manager.lastRequestTime = Date(timeIntervalSince1970: 0)
        return manager
    }()
    
    // Add a callback for map region changes to avoid SwiftUI Equatable issues
    var onMapRegionChange: ((MKCoordinateRegion) -> Void)?
    
    @Published var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    ) {
        didSet {
            // Call the callback when mapRegion changes
            onMapRegionChange?(mapRegion)
        }
    }
    
    // Reference to map proxy for coordinate conversion
    var mapProxy: MapProxy?
    
    // Internal tracking of last location request to prevent duplicate requests
    private var lastLocationRequestTimestamp: Date = Date(timeIntervalSince1970: 0)
    
    // Add these properties to the RouteViewModel class
    @Published var searchQuery: String = ""
    
    // Returns routes filtered by searchQuery and difficulty
    var filteredUserRoutes: [Route] {
        if searchQuery.isEmpty {
            return userRoutes
        }
        
        return userRoutes.filter { route in
            route.title.localizedCaseInsensitiveContains(searchQuery) ||
            route.description.localizedCaseInsensitiveContains(searchQuery) ||
            route.creator.localizedCaseInsensitiveContains(searchQuery) ||
            route.difficultyString.localizedCaseInsensitiveContains(searchQuery)
        }
    }
    
    var filteredRoutes: [Route] {
        if searchQuery.isEmpty {
            return routes
        }
        
        return routes.filter { route in
            route.title.localizedCaseInsensitiveContains(searchQuery) ||
            route.description.localizedCaseInsensitiveContains(searchQuery) ||
            route.creator.localizedCaseInsensitiveContains(searchQuery) ||
            route.difficultyString.localizedCaseInsensitiveContains(searchQuery)
        }
    }
    
    var filteredMeetRoutes: [Route] {
        if searchQuery.isEmpty {
            return meetRoutes
        }
        
        return meetRoutes.filter { route in
            route.title.localizedCaseInsensitiveContains(searchQuery) ||
            route.description.localizedCaseInsensitiveContains(searchQuery) ||
            route.creator.localizedCaseInsensitiveContains(searchQuery) ||
            route.difficultyString.localizedCaseInsensitiveContains(searchQuery)
        }
    }
    
    // Fetch all routes
    func fetchRoutes() async {
        isLoading = true
        errorMessage = nil
        
        do {
            routes = try await supabaseService.fetchRoutes()
        } catch {
            errorMessage = "Failed to load routes: \(error.localizedDescription)"
            print("Error fetching routes: \(error)")
        }
        
        isLoading = false
    }
    
    // Fetch routes created by the current user
    func fetchUserRoutes() async {
        isLoading = true
        errorMessage = nil
        
        do {
            userRoutes = try await supabaseService.fetchRoutesByCreator()
        } catch {
            errorMessage = "Failed to load your routes: \(error.localizedDescription)"
            print("Error fetching user routes: \(error)")
        }
        
        isLoading = false
    }
    
    // Fetch routes for a specific meet
    func fetchMeetRoutes(meetId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            meetRoutes = try await supabaseService.fetchRoutesByMeet(meetId: meetId)
        } catch {
            errorMessage = "Failed to load meet routes: \(error.localizedDescription)"
            print("Error fetching meet routes: \(error)")
        }
        
        isLoading = false
    }
    
    // Fetch a single route by ID
    func fetchRoute(id: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            selectedRoute = try await supabaseService.fetchRoute(id: id)
            
            // Set the map region to show the route
            if let route = selectedRoute, !route.routeData.coordinates.isEmpty {
                updateMapRegion(for: route)
            }
        } catch {
            errorMessage = "Failed to load route: \(error.localizedDescription)"
            print("Error fetching route: \(error)")
        }
        
        isLoading = false
    }
    
    // Create a new route
    func createRoute(title: String, description: String, difficulty: RouteDifficulty, meetId: String? = nil) async -> Route? {
        guard let userId = try? await supabaseService.client.auth.session.user.id.uuidString else {
            errorMessage = "You must be logged in to create a route"
            return nil
        }
        
        isLoading = true
        errorMessage = nil
        
        // Convert the current editing coordinates to the Route model format
        let coordinates = routeCoordinates.map { Coordinate(from: $0) }
        let routeData = RouteData(coordinates: coordinates, waypoints: waypoints)
        
        var newRoute = Route(
            meetId: meetId,
            creatorId: userId,
            title: title,
            description: description,
            routeData: routeData,
            difficulty: difficulty
        )
        
        // Calculate distance and estimated time
        newRoute.calculateRouteDetails()
        
        do {
            let createdRoute = try await supabaseService.createRoute(newRoute)
            routes.append(createdRoute)
            userRoutes.append(createdRoute)
            if meetId != nil {
                meetRoutes.append(createdRoute)
            }
            isLoading = false
            return createdRoute
        } catch {
            errorMessage = "Failed to create route: \(error.localizedDescription)"
            print("Error creating route: \(error)")
            isLoading = false
            return nil
        }
    }
    
    // Update an existing route
    func updateRoute(_ route: Route) async -> Route? {
        isLoading = true
        errorMessage = nil
        
        var updatedRoute = route
        updatedRoute.updatedAt = Date()
        
        do {
            let result = try await supabaseService.updateRoute(updatedRoute)
            
            // Update local lists
            if let index = routes.firstIndex(where: { $0.id == result.id }) {
                routes[index] = result
            }
            
            if let index = userRoutes.firstIndex(where: { $0.id == result.id }) {
                userRoutes[index] = result
            }
            
            if let index = meetRoutes.firstIndex(where: { $0.id == result.id }) {
                meetRoutes[index] = result
            }
            
            if selectedRoute?.id == result.id {
                selectedRoute = result
            }
            
            isLoading = false
            return result
        } catch {
            errorMessage = "Failed to update route: \(error.localizedDescription)"
            print("Error updating route: \(error)")
            isLoading = false
            return nil
        }
    }
    
    // Delete a route
    func deleteRoute(id: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await supabaseService.deleteRoute(id: id)
            
            // Remove from local lists
            routes.removeAll { $0.id == id }
            userRoutes.removeAll { $0.id == id }
            meetRoutes.removeAll { $0.id == id }
            
            if selectedRoute?.id == id {
                selectedRoute = nil
            }
            
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to delete route: \(error.localizedDescription)"
            print("Error deleting route: \(error)")
            isLoading = false
            return false
        }
    }
    
    // Start editing a new route
    func startNewRoute() {
        print("RouteViewModel - startNewRoute called")
        
        // Reset route data
        routeCoordinates = []
        waypoints = []
        isEditingRoute = true
        
        // Check for location and set region directly
        if let location = locationManager.location?.coordinate {
            print("RouteViewModel - Using existing location in startNewRoute: \(location.latitude), \(location.longitude)")
            mapRegion = MKCoordinateRegion(
                center: location,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            
            // Cache this for future use
            UserDefaults.standard.set(
                ["latitude": location.latitude, "longitude": location.longitude],
                forKey: "LastKnownLocation"
            )
        } else if let lastKnownLocation = UserDefaults.standard.object(forKey: "LastKnownLocation") as? [String: Double],
                  let latitude = lastKnownLocation["latitude"],
                  let longitude = lastKnownLocation["longitude"] {
            
            print("RouteViewModel - Using cached location in startNewRoute: \(latitude), \(longitude)")
            mapRegion = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        } else {
            // Default to San Francisco if no location is available
            print("RouteViewModel - No location available, defaulting to San Francisco")
            mapRegion = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
        
        // Always request a fresh location when starting a new route
        print("RouteViewModel - Forcing a location update in startNewRoute")
        locationManager.forceLocationUpdate()
    }
    
    // Start editing an existing route
    func startEditingRoute(_ route: Route) {
        routeCoordinates = route.routeData.coordinates.map { $0.clCoordinate }
        waypoints = route.routeData.waypoints
        isEditingRoute = true
        
        updateMapRegion(for: route)
    }
    
    // Update map region to fit all coordinates
    func updateMapRegion(for route: Route? = nil) {
        let coordinates = route?.routeData.coordinates.map { $0.clCoordinate } ?? routeCoordinates
        
        guard !coordinates.isEmpty else { return }
        
        if coordinates.count == 1 {
            mapRegion = MKCoordinateRegion(
                center: coordinates[0],
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
            return
        }
        
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
            latitudeDelta: (maxLat - minLat) * 1.2,
            longitudeDelta: (maxLon - minLon) * 1.2
        )
        
        mapRegion = MKCoordinateRegion(center: center, span: span)
    }
    
    // Add coordinate to the route
    func addCoordinate(_ coordinate: CLLocationCoordinate2D) {
        routeCoordinates.append(coordinate)
        
        // If this is the first point, automatically add a start waypoint
        if routeCoordinates.count == 1 && !waypoints.contains(where: { $0.type == .start }) {
            let startWaypoint = Waypoint(
                id: UUID().uuidString,
                coordinate: Coordinate(from: coordinate),
                title: "Start",
                type: .start
            )
            waypoints.append(startWaypoint)
        }
        
        // If we have at least 2 points and no end waypoint, consider adding an end waypoint
        if routeCoordinates.count > 1 && !waypoints.contains(where: { $0.type == .end }) {
            let endWaypoint = Waypoint(
                id: UUID().uuidString,
                coordinate: Coordinate(from: coordinate),
                title: "End",
                type: .end
            )
            waypoints.append(endWaypoint)
        }
    }
    
    // Add a specific waypoint type
    func addWaypoint(type: WaypointType) {
        guard !routeCoordinates.isEmpty else { return }
        
        // Use the most recently added coordinate for the waypoint
        let coordinate = routeCoordinates.last!
        
        // If we already have a waypoint of this type, remove it
        waypoints.removeAll { $0.type == type }
        
        // Create a new waypoint
        let waypoint = Waypoint(
            id: UUID().uuidString,
            coordinate: Coordinate(from: coordinate),
            title: type.defaultTitle,
            type: type
        )
        
        waypoints.append(waypoint)
    }
    
    // Add a waypoint at a specific coordinate with title and type
    func addWaypoint(at coordinate: CLLocationCoordinate2D, title: String, type: WaypointType) {
        // If we already have a waypoint of this unique type (like start/end), remove it
        if type == .start || type == .end {
            waypoints.removeAll { $0.type == type }
        }
        
        // Create the new waypoint
        let waypoint = Waypoint(
            id: UUID().uuidString,
            coordinate: Coordinate(from: coordinate),
            title: title,
            type: type
        )
        
        waypoints.append(waypoint)
        
        // Also add the coordinate to the route if it's not already included
        if !routeCoordinates.contains(where: { 
            abs($0.latitude - coordinate.latitude) < 0.00001 && 
            abs($0.longitude - coordinate.longitude) < 0.00001 
        }) {
            routeCoordinates.append(coordinate)
        }
    }
    
    // Clear all route data
    func clearRoute() {
        routeCoordinates = []
        waypoints = []
    }
    
    // Remove a waypoint
    func removeWaypoint(_ waypoint: Waypoint) {
        waypoints.removeAll { $0.id == waypoint.id }
    }
    
    // Set map region to user's location
    func setRegionToUserLocation() {
        print("RouteViewModel - setRegionToUserLocation called")
        
        // Check if we already have a location before requesting again
        if let location = locationManager.location?.coordinate {
            print("RouteViewModel - Using immediate location in setRegionToUserLocation: \(location.latitude), \(location.longitude)")
            // We already have a location, just use it
            mapRegion = MKCoordinateRegion(
                center: location,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            
            // Cache this for future use
            UserDefaults.standard.set(
                ["latitude": location.latitude, "longitude": location.longitude],
                forKey: "LastKnownLocation"
            )
        } else {
            // Fall back to cached location if available
            if let lastKnownLocation = UserDefaults.standard.object(forKey: "LastKnownLocation") as? [String: Double],
                   let latitude = lastKnownLocation["latitude"],
                   let longitude = lastKnownLocation["longitude"] {
                
                print("RouteViewModel - Using cached location: \(latitude), \(longitude)")
                mapRegion = MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            }
            
            // Always request a fresh location when this method is explicitly called
            print("RouteViewModel - Forcing location update in setRegionToUserLocation")
            locationManager.forceLocationUpdate()
        }
    }
    
    // MARK: - Road-Snapped Route Methods
    
    // Calculate a road-based route between points
    func calculateRoadRoute(from sourceCoordinate: CLLocationCoordinate2D, to destinationCoordinate: CLLocationCoordinate2D) {
        let sourcePlacemark = MKPlacemark(coordinate: sourceCoordinate)
        let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate)
        
        let sourceItem = MKMapItem(placemark: sourcePlacemark)
        let destinationItem = MKMapItem(placemark: destinationPlacemark)
        
        let directionRequest = MKDirections.Request()
        directionRequest.source = sourceItem
        directionRequest.destination = destinationItem
        directionRequest.transportType = .automobile
        
        let directions = MKDirections(request: directionRequest)
        directions.calculate { [weak self] response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error calculating directions: \(error.localizedDescription)")
                return
            }
            
            if let route = response?.routes.first {
                // Extract route points
                let roadPoints = route.polyline.points()
                let pointCount = route.polyline.pointCount
                
                var newCoordinates: [CLLocationCoordinate2D] = []
                for i in 0..<pointCount {
                    let mapPoint = roadPoints[i]
                    let coordinate = mapPoint.coordinate
                    newCoordinates.append(coordinate)
                }
                
                // Add these coordinates to our route
                if self.routeCoordinates.isEmpty {
                    self.routeCoordinates = newCoordinates
                } else {
                    // Remove the last coordinate if it's very close to the first one of the new segment
                    // to avoid duplication
                    if let lastCoord = self.routeCoordinates.last,
                       let firstNewCoord = newCoordinates.first {
                        let lastLocation = CLLocation(latitude: lastCoord.latitude, longitude: lastCoord.longitude)
                        let firstNewLocation = CLLocation(latitude: firstNewCoord.latitude, longitude: firstNewCoord.longitude)
                        
                        if lastLocation.distance(from: firstNewLocation) < 10 { // Less than 10 meters
                            self.routeCoordinates.removeLast()
                        }
                    }
                    
                    self.routeCoordinates.append(contentsOf: newCoordinates)
                }
                
                // Update the endpoints as waypoints if this is the start or end of the route
                if self.waypoints.isEmpty {
                    // This is the start - add a start waypoint
                    let startWaypoint = Waypoint(
                        id: UUID().uuidString,
                        coordinate: Coordinate(from: newCoordinates.first ?? sourceCoordinate),
                        title: "Start",
                        type: .start
                    )
                    self.waypoints.append(startWaypoint)
                }
                
                // Add the end point as a waypoint if requested
                if self.waypoints.count == 1 && !self.waypoints.contains(where: { $0.type == .end }) {
                    // Add an end waypoint at the destination
                    let endWaypoint = Waypoint(
                        id: UUID().uuidString,
                        coordinate: Coordinate(from: newCoordinates.last ?? destinationCoordinate),
                        title: "End",
                        type: .end
                    )
                    self.waypoints.append(endWaypoint)
                } else if self.waypoints.count > 1 && !newCoordinates.isEmpty {
                    // Add a regular waypoint at significant turns
                    let lastCoord = newCoordinates.last ?? destinationCoordinate
                    
                    // Only add waypoint if we don't already have one very close to this location
                    let shouldAddWaypoint = !self.waypoints.contains { waypoint in
                        let waypointLocation = CLLocation(
                            latitude: waypoint.coordinate.latitude,
                            longitude: waypoint.coordinate.longitude
                        )
                        let newLocation = CLLocation(
                            latitude: lastCoord.latitude,
                            longitude: lastCoord.longitude
                        )
                        return waypointLocation.distance(from: newLocation) < 50 // Within 50 meters
                    }
                    
                    if shouldAddWaypoint {
                        let waypoint = Waypoint(
                            id: UUID().uuidString,
                            coordinate: Coordinate(from: lastCoord),
                            title: "Waypoint \(self.waypoints.count - 1)", // -1 to account for start
                            type: .regular
                        )
                        self.waypoints.append(waypoint)
                    }
                }
                
                // Update the map region to show the entire route
                self.updateMapRegion()
            }
        }
    }
    
    // Add a new segment to the route
    func addRouteSegment(to coordinate: CLLocationCoordinate2D) {
        if let lastCoordinate = routeCoordinates.last {
            // Calculate road route between last point and new point
            calculateRoadRoute(from: lastCoordinate, to: coordinate)
        } else if let userLocation = locationManager.location?.coordinate {
            // If this is the first point, start from user's location
            calculateRoadRoute(from: userLocation, to: coordinate)
        } else {
            // Fallback if no location available
            addCoordinate(coordinate)
        }
    }
    
    // Start a new route at the given coordinate
    func startRouteAt(_ coordinate: CLLocationCoordinate2D) {
        clearRoute()
        
        // Add starting point
        routeCoordinates.append(coordinate)
        
        // Add a start waypoint
        let startWaypoint = Waypoint(
            id: UUID().uuidString,
            coordinate: Coordinate(from: coordinate),
            title: "Start",
            type: .start
        )
        waypoints.append(startWaypoint)
        
        // Update map region
        mapRegion = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }
}

extension WaypointType {
    var systemIconName: String {
        switch self {
        case .start: return "flag.fill"
        case .end: return "flag.checkered"
        case .regular: return "mappin"
        case .scenic: return "camera"
        case .rest: return "cup.and.saucer"
        case .checkpoint: return "checkmark.circle.fill"
        case .fuel: return "fuelpump.fill"
        case .food: return "fork.knife"
        }
    }
    
    // Renamed from 'color' to 'displayColor' to avoid conflict
    var displayColor: Color {
        switch self {
        case .start: return Color(hex: "#4CAF50") // Green
        case .end: return Color(hex: "#F44336")   // Red
        case .regular: return Color(hex: "#2196F3") // Blue
        case .scenic: return Color(hex: "#9C27B0") // Purple
        case .rest: return Color(hex: "#795548")  // Brown
        case .checkpoint: return Color(hex: "#FF9800") // Orange
        case .fuel: return Color(hex: "#FFEB3B") // Yellow
        case .food: return Color(hex: "#FF5722") // Deep Orange
        }
    }
    
    var hexColor: String {
        switch self {
        case .start: return "#4CAF50" // Green
        case .end: return "#F44336"   // Red
        case .regular: return "#2196F3" // Blue
        case .scenic: return "#9C27B0" // Purple
        case .rest: return "#795548"  // Brown
        case .checkpoint: return "#FF9800" // Orange
        case .fuel: return "#FFEB3B" // Yellow
        case .food: return "#FF5722" // Deep Orange
        }
    }
} 
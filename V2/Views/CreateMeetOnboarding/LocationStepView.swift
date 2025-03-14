import SwiftUI
import MapKit
import CoreLocation

struct LocationStepView: View {
    @ObservedObject var onboardingState: CreateMeetOnboardingState
    @StateObject private var locationManager: LocationManager = LocationManager()
    @State private var animateElements = false
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var isMapVisible = false
    
    // Add a namespace for view identification and animation control
    @Namespace private var mapTransition
    
    // Track if this view is actively being shown
    @State private var isActive = false
    
    // Track if we're in the process of transitioning out
    @State private var isTransitioningOut = false
    
    // Key for distinguishing map instances
    @State private var mapKey = UUID()
    
    var body: some View {
        ZStack {
            // Background decoration
            Circle()
                .fill(MeetSpotColors.pink500.opacity(0.1))
                .frame(width: 250, height: 250)
                .blur(radius: 70)
                .offset(x: -150, y: -200)
            
            Circle()
                .fill(MeetSpotColors.purple900.opacity(0.1))
                .frame(width: 250, height: 250)
                .blur(radius: 70)
                .offset(x: 150, y: 250)
                
            // Main content
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Choose Location")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Select where your meet will take place")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Image(systemName: CreateMeetStep.location.systemIcon)
                        .font(.system(size: 40))
                        .foregroundColor(MeetSpotColors.pink500)
                        .opacity(animateElements ? 1 : 0)
                        .rotationEffect(.degrees(animateElements ? 0 : -30))
                        .offset(y: animateElements ? 0 : -10)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.7).delay(0.2),
                            value: animateElements
                        )
                }
                .padding()
                .padding(.top, 10)
                
                // Search bar
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(isSearching ? MeetSpotColors.pink500 : .white.opacity(0.5))
                        
                        TextField("Search for a location", text: $searchText)
                            .foregroundColor(.white)
                            .autocorrectionDisabled()
                            .onSubmit {
                                searchLocation()
                            }
                            .overlay(
                                Button(action: {
                                    searchText = ""
                                    searchResults = []
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white.opacity(0.5))
                                        .opacity(searchText.isEmpty ? 0 : 1)
                                }
                                .padding(.trailing, 8),
                                alignment: .trailing
                            )
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Material.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        isSearching ? MeetSpotColors.pink500 : Color.white.opacity(0.1),
                                        lineWidth: isSearching ? 2 : 1
                                    )
                            )
                    )
                    .padding(.horizontal)
                    .onChange(of: searchText) { _, newValue in
                        if newValue.count > 2 {
                            searchLocation()
                        }
                    }
                    .onTapGesture {
                        isSearching = true
                    }
                    
                    // Search results list
                    if !searchResults.isEmpty {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(searchResults, id: \.self) { item in
                                    Button {
                                        // Select this location
                                        onboardingState.selectedLocation = item.placemark.coordinate
                                        onboardingState.address = formatAddress(from: item.placemark)
                                        region = MKCoordinateRegion(
                                            center: item.placemark.coordinate,
                                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                        )
                                        
                                        // Hide search results and keyboard
                                        searchResults = []
                                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                        isSearching = false
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(item.name ?? "Unknown Location")
                                                    .font(.headline)
                                                    .foregroundColor(.white)
                                                Text(formatAddress(from: item.placemark))
                                                    .font(.subheadline)
                                                    .foregroundColor(.white.opacity(0.7))
                                                    .lineLimit(1)
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: "arrow.forward.circle.fill")
                                                .foregroundColor(MeetSpotColors.pink500)
                                        }
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Material.ultraThinMaterial)
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                            .padding(.bottom, 16)
                        }
                        .frame(maxHeight: 300)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                
                // Map view with improved Metal resource management and tap handling
                ZStack {
                    // Only render the Map when this step is active and map is visible and not transitioning out
                    if isMapVisible && isActive && !isTransitioningOut {
                        // Using MapReader for proper coordinate conversion
                        MapReader { mapProxy in
                            Map(position: mapPositionBinding()) {
                                // Show user location
                                if locationManager.location != nil {
                                    UserAnnotation()
                                }
                                
                                // Show selected location
                                if let selectedLocation = onboardingState.selectedLocation {
                                    Marker("Selected Location", coordinate: selectedLocation)
                                        .tint(MeetSpotColors.pink500)
                                }
                            }
                            .id("map-view-\(mapKey)") // Use dynamic key for force recreation on reappearance
                            .mapStyle(.standard(elevation: .flat)) // Use flat to reduce GPU load
                            .mapControls {
                                MapUserLocationButton()
                                MapCompass()
                                MapScaleView()
                            }
                            .onTapGesture { screenPosition in
                                // Use MapProxy's convert method to accurately get the coordinate from the screen position
                                if let coordinate = mapProxy.convert(screenPosition, from: .local) {
                                    // Log for debugging
                                    let tapID = UUID().uuidString
                                    print("Map tapped at screen position: \(screenPosition), converted to coordinate: \(coordinate.latitude), \(coordinate.longitude), ID: \(tapID)")
                                    
                                    // Ensure coordinate is valid
                                    guard coordinate.latitude.isFinite && coordinate.longitude.isFinite,
                                          CLLocationCoordinate2DIsValid(coordinate) else {
                                        print("Invalid coordinate after conversion: \(coordinate)")
                                        return
                                    }
                                    
                                    // Set selected location with animation to provide visual feedback
                                    withAnimation {
                                        onboardingState.selectedLocation = coordinate
                                    }
                                    
                                    // Get address from coordinates
                                    reverseGeocode(coordinate)
                                    
                                    // Close search if open
                                    searchResults = []
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                    isSearching = false
                                } else {
                                    print("Failed to convert screen position to coordinate")
                                }
                            }
                            .allowsHitTesting(isActive && !isTransitioningOut) // Disable hit testing when transitioning
                        }
                        .background(Color.black.opacity(0.1)) // Add a background to help Metal context
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        // Add a transition that doesn't involve opacity changes (which can cause Metal issues)
                        .transition(.asymmetric(
                            insertion: .opacity.animation(.easeIn(duration: 0.3)),
                            removal: .identity
                        ))
                        // Add a matching ID for the namespace to help with transitions
                        .matchedGeometryEffect(id: "mapContainer", in: mapTransition)
                    } else {
                        // Show a placeholder when the map isn't loaded yet or is being removed
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Material.ultraThinMaterial)
                            .overlay(
                                VStack {
                                    ProgressView()
                                        .tint(.white)
                                    Text(isTransitioningOut ? "Unloading map..." : "Loading map...")
                                        .foregroundColor(.white.opacity(0.8))
                                        .font(.subheadline)
                                        .padding(.top, 8)
                                }
                            )
                            // Make sure placeholder has same frame as the map for smooth transition
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            // Add a matching ID for the namespace to help with transitions
                            .matchedGeometryEffect(id: "mapContainer", in: mapTransition)
                    }
                    
                    // Current location button
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button {
                                if let location = locationManager.location {
                                    region = MKCoordinateRegion(
                                        center: location.coordinate,
                                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                    )
                                } else {
                                    locationManager.requestLocation()
                                }
                            } label: {
                                Image(systemName: "location.fill")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(
                                        Circle()
                                            .fill(MeetSpotColors.pink500)
                                    )
                            }
                            .subtleShadow()
                            .padding(16)
                            .opacity(isMapVisible && !isTransitioningOut ? 1 : 0)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal)
                .opacity(animateElements ? 1 : 0)
                .offset(y: animateElements ? 0 : 20)
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.8).delay(0.3),
                    value: animateElements
                )
                
                // Selected location display
                if let _ = onboardingState.selectedLocation, !onboardingState.address.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Selected Location")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(MeetSpotColors.pink500)
                            
                            Text(onboardingState.address)
                                .foregroundColor(.white)
                                .lineLimit(2)
                            
                            Spacer()
                            
                            Button {
                                onboardingState.selectedLocation = nil
                                onboardingState.address = ""
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
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onChange(of: locationManager.location) { _, newLocation in
            if let newLocation = newLocation, region.center.latitude == 37.7749 {
                // Only set the region to user location if it's still at default coordinates
                region = MKCoordinateRegion(
                    center: newLocation.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            }
        }
        .animation(.spring(response: 0.3), value: searchResults.isEmpty)
        .animation(.spring(response: 0.3), value: onboardingState.selectedLocation != nil)
        .onAppear {
            // Set active status
            isActive = true
            isTransitioningOut = false
            mapKey = UUID() // Generate a new map instance key
            
            // Start animations
            withAnimation {
                animateElements = true
            }
            
            // Request location permissions immediately
            locationManager.requestLocation()
            
            // Delay loading the map until animations are complete and this view is fully visible
            // Using a longer delay to ensure the view is fully rendered before attempting to load the map
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if isActive && !isTransitioningOut { // Only show map if view is still active
                    isMapVisible = true
                }
            }
        }
        .onDisappear {
            // Start unloading sequence - first mark as transitioning out
            handleViewExit()
        }
        // Add a task to pre-emptively cleanup when the view is about to disappear (SwiftUI lifetime events)
        .task {
            // This task naturally cancels when the view disappears
            // Wait for cancellation, which happens automatically when view disappears
        }
    }
    
    // Handle view exit with a multi-step cleanup process
    private func handleViewExit() {
        // Step 1: Mark as transitioning out immediately
        isTransitioningOut = true
        isActive = false
        
        // Immediately start a cleanup task for immediate actions
        Task { @MainActor in
            // Force an immediate run loop execution to allow SwiftUI to process the state change
            try? await Task.sleep(for: .milliseconds(16)) // One frame at 60 FPS
            
            // Step 2: Wait a frame to let any transitions start, then begin hiding the map
            // The longer delay here helps ensure Metal completes its work before resource removal
            try? await Task.sleep(for: .milliseconds(300))
            if isTransitioningOut {
                isMapVisible = false
            }
            
            // Step 3: Final cleanup after the map has been hidden
            try? await Task.sleep(for: .milliseconds(500))
            // Ensure we're completely cleaned up
            isMapVisible = false
        }
    }
    
    // Create the binding separately to avoid pattern matching issues
    private func mapPositionBinding() -> Binding<MapCameraPosition> {
        return Binding(
            get: { 
                return MapCameraPosition.region(region) 
            },
            set: { newPosition in
                if let newRegion = newPosition.extractRegion() {
                    region = newRegion
                }
            }
        )
    }
    
    // MARK: - Helper methods
    
    // Search for locations
    private func searchLocation() {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let error = error {
                print("Error searching for \(searchText): \(error.localizedDescription)")
                return
            }
            
            if let response = response {
                searchResults = response.mapItems
            }
        }
    }
    
    // Get address from coordinates
    private func reverseGeocode(_ coordinate: CLLocationCoordinate2D) {
        // Validate coordinate is valid for geocoding
        guard CLLocationCoordinate2DIsValid(coordinate) else {
            print("Invalid coordinate for geocoding: \(coordinate)")
            // Set a default address
            DispatchQueue.main.async {
                self.onboardingState.address = "Location selected"
            }
            return
        }
        
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        // Add timeout and error handling
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Reverse geocoding error: \(error.localizedDescription)")
                    // Still provide a fallback address
                    self.onboardingState.address = "Location at \(String(format: "%.4f", coordinate.latitude)), \(String(format: "%.4f", coordinate.longitude))"
                    return
                }
                
                if let placemark = placemarks?.first {
                    self.onboardingState.address = self.formatAddress(from: placemark)
                } else {
                    // No placemarks found, provide coordinates as fallback
                    self.onboardingState.address = "Location at \(String(format: "%.4f", coordinate.latitude)), \(String(format: "%.4f", coordinate.longitude))"
                }
            }
        }
    }
    
    // Format address from placemark
    private func formatAddress(from placemark: CLPlacemark) -> String {
        var components: [String] = []
        
        if let thoroughfare = placemark.thoroughfare {
            components.append(thoroughfare)
        }
        
        if let subThoroughfare = placemark.subThoroughfare {
            // Insert at beginning if available
            if !components.isEmpty {
                components[0] = subThoroughfare + " " + components[0]
            } else {
                components.append(subThoroughfare)
            }
        }
        
        if let locality = placemark.locality {
            components.append(locality)
        }
        
        if let administrativeArea = placemark.administrativeArea {
            components.append(administrativeArea)
        }
        
        if let postalCode = placemark.postalCode {
            components.append(postalCode)
        }
        
        return components.joined(separator: ", ")
    }
}

// MARK: - Extensions

// Extension on MapCameraPosition to safely extract region
extension MapCameraPosition {
    func extractRegion() -> MKCoordinateRegion? {
        // Skip pattern matching entirely and use reflection directly
        // This avoids all 'let' binding pattern issues in expressions
        let mirror = Mirror(reflecting: self)
        
        // Look for an associated value named "region"
        for child in mirror.children {
            if child.label == "region", let region = child.value as? MKCoordinateRegion {
                return region
            }
        }
        return nil
    }
}

// Preview
struct LocationStepView_Previews: PreviewProvider {
    static var previews: some View {
        LocationStepView(onboardingState: CreateMeetOnboardingState())
            .preferredColorScheme(.dark)
    }
} 
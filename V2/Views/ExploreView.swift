import SwiftUI
import MapKit
import CoreLocation

struct ExploreView: View {
    @ObservedObject var viewModel: MeetViewModel
    @StateObject private var locationManager = LocationManager()
    @State private var cameraPosition = MapCameraPosition.region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    ))
    @State private var selectedMeet: Meet?
    @State private var showFullDetails = false
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var isShowingMap = false
    @State private var initialLocationSet = false
    @State private var showingCreateMeet = false
    @State private var showSearchResults = false
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            // Replace static background with animated gradient
            AnimatedGradientBackground()
            
            VStack(spacing: 0) {
                // Custom Header
                customHeader
                    .background(Color.black.opacity(0.2))
                    .mediumShadow()
                
                // Content Stack
                ZStack {
                    if showSearchResults && !viewModel.searchQuery.isEmpty {
                        // Location search results view
                        searchResultsView
                    } else {
                        // Map content
                        mapView
                        
                        // Preview Card
                        meetPreviewCardView
                    }
                    
                    // Floating Action Button for Create
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                showingCreateMeet = true
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 50)
                                    .background(MeetSpotColors.accentGradient)
                                    .clipShape(Circle())
                                    .pronouncedShadow()
                            }
                            .padding(.trailing, 16)
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingCreateMeet) {
                CreateMeetOnboardingView(viewModel: viewModel)
            }
            .sheet(isPresented: $showFullDetails) {
                if let meet = selectedMeet {
                    NavigationView {
                        MeetFullDetails(meet: meet, viewModel: viewModel)
                            .background(MeetSpotColors.backgroundGradient)
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button("Done") {
                                        showFullDetails = false
                                    }
                                    .foregroundColor(.white)
                                }
                            }
                    }
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
        .edgesIgnoringSafeArea(.bottom)
        .onAppear {
            // Force immediate refresh when view appears
            Task {
                await forceRefreshMapData()
            }
        }
    }
    
    // Search results view to display filtered locations and meets
    private var searchResultsView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Section: Locations
                LocationsSearchResultsSection(
                    viewModel: viewModel,
                    isLoading: viewModel.isLoading,
                    locations: _viewModel.wrappedValue.filteredLocations,
                    onLocationSelected: { location in
                        // Update map to show the selected location
                        let newRegion = MKCoordinateRegion(
                            center: CLLocationCoordinate2D(
                                latitude: location.latitude,
                                longitude: location.longitude
                            ),
                            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                        )
                        cameraPosition = .region(newRegion)
                        showSearchResults = false
                    }
                )
                
                // Section: Meets
                MeetsSearchResultsSection(
                    meets: viewModel.filteredMeets,
                    onMeetSelected: { meet in
                        selectedMeet = meet
                        showSearchResults = false
                        
                        // Update map to show the selected meet
                        let newRegion = MKCoordinateRegion(
                            center: meet.location,
                            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                        )
                        cameraPosition = .region(newRegion)
                    }
                )
            }
            .padding(.bottom, 30)
        }
        .background(AnimatedGradientBackground())
    }

    // MARK: - Computed Properties
    
    private var customHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: {
                    // Toggle between map and list view
                    withAnimation {
                        isShowingMap.toggle()
                    }
                }) {
                    Image(systemName: isShowingMap ? "list.bullet" : "map")
                        .font(.title3)
                        .foregroundColor(MeetSpotColors.pink500)
                }
                
                Text("Explore Meets")
                    .font(MeetSpotStyle.Typography.heading2)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Search button - removed as we now have a search bar
            }
            .padding(.horizontal)
            
            // Add Modern Search bar
            SearchBar(
                text: $viewModel.searchQuery,
                placeholder: "Search locations or meets...",
                onSearch: {
                    // Perform search on submit
                    Task {
                        await viewModel.searchLocations(query: viewModel.searchQuery)
                    }
                    showSearchResults = true
                },
                onTextChange: { newValue in
                    // Show search results when typing
                    Task {
                        await viewModel.searchLocations(query: newValue)
                    }
                    showSearchResults = !newValue.isEmpty
                }
            )
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }
}

// MARK: - MapAnnotationView
private struct MapAnnotationView: View {
    let meet: Meet
    let isSelected: Bool
    let onTap: () -> Void
    
    private var circleFill: AnyShapeStyle {
        isSelected ? AnyShapeStyle(MeetSpotColors.secondaryGradient) : AnyShapeStyle(Color.white)
    }
    
    private var circleStroke: AnyShapeStyle {
        isSelected ? AnyShapeStyle(Color.white) : AnyShapeStyle(MeetSpotColors.purple900)
    }
    
    private var triangleFill: AnyShapeStyle {
        isSelected ? AnyShapeStyle(MeetSpotColors.pink500) : AnyShapeStyle(Color.white)
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                Circle()
                    .fill(circleFill)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .stroke(circleStroke, lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                
                Triangle()
                    .fill(triangleFill)
                    .frame(width: 16, height: 8)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - MapControlsView
private struct MapControlsView: View {
    var body: some View {
        MapCompass()
            .mapControlVisibility(.visible)
        MapScaleView()
            .mapControlVisibility(.visible)
    }
}

// MARK: - ExploreView+MapComponents
private extension ExploreView {
    var mapView: some View {
        Map(position: $cameraPosition) {
            // Show user location if available
            if locationManager.location != nil {
                UserAnnotation()
                    .tint(MeetSpotColors.pink500)
            }
            
            ForEach(viewModel.meets) { meet in
                Annotation(meet.title, coordinate: meet.location) {
                    MapAnnotationView(
                        meet: meet,
                        isSelected: selectedMeet?.id == meet.id,
                        onTap: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedMeet = meet
                            }
                        }
                    )
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .overlay(mapOverlayGradient)
        .ignoresSafeArea(edges: .bottom)
        .mapControls {
            MapUserLocationButton()
                .mapControlVisibility(.visible)
            MapCompass()
                .mapControlVisibility(.visible)
            MapScaleView()
                .mapControlVisibility(.visible)
            MapPitchToggle()
                .mapControlVisibility(.visible)
        }
        .onTapGesture(perform: handleMapTap)
        .onAppear(perform: setupInitialLocation)
        .onChange(of: locationManager.location) { _, newLocation in
            if let newLocation = newLocation, !initialLocationSet {
                initialLocationSet = true
                updateRegionForLocation(newLocation)
            }
        }
    }
    
    var mapOverlayGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.clear,
                Color.black.opacity(0.1),
                Color.black.opacity(0.2)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
    
    private func forceRefreshMapData() async {
        // Force refresh of meet data to ensure pins appear
        isLoading = true
        await viewModel.forceRefreshAll()
        
        // If needed, set initial location from first meet
        if locationManager.location == nil && viewModel.meets.count > 0 {
            let firstMeet = viewModel.meets[0]
            let coordinates = CLLocationCoordinate2D(
                latitude: firstMeet.location.latitude,
                longitude: firstMeet.location.longitude
            )
            
            withAnimation {
                cameraPosition = .region(MKCoordinateRegion(
                    center: coordinates,
                    span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                ))
                print("📍 Set map to first meet location: \(coordinates.latitude), \(coordinates.longitude)")
            }
        }
        
        print("🗺️ Map refreshed with \(viewModel.meets.count) meets")
        isLoading = false
    }
}

// MARK: - ExploreView+PreviewCard
private extension ExploreView {
    var meetPreviewCardView: some View {
        Group {
            if let meet = selectedMeet {
                VStack {
                    Spacer()
                    
                    MeetSpotUI.Cards.meetCard {
                        VStack(spacing: 0) {
                            // Handle for dragging
                            RoundedRectangle(cornerRadius: 2.5)
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 36, height: 5)
                                .padding(.vertical, 8)
                            
                            // Meet preview content
                            previewContent(for: meet)
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            if value.translation.height > 50 {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedMeet = nil
                                }
                            }
                        }
                )
            }
        }
    }
    
    func previewContent(for meet: Meet) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title and type
            HStack {
                MeetSpotType.subtitle(meet.title)
                
                Spacer()
                
                MeetSpotUI.Badges.status(meet.type.rawValue.capitalized)
            }
            
            // Location
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(MeetSpotColors.pink500)
                MeetSpotType.caption(meet.address)
            }
            
            // Date and capacity
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(MeetSpotColors.pink500)
                MeetSpotType.caption(meet.formattedDate)
                
                Spacer()
                
                Image(systemName: "person.3.fill")
                    .foregroundColor(MeetSpotColors.pink500)
                MeetSpotType.caption("\(meet.attendees.count)/\(meet.capacity)")
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button {
                    showFullDetails = true
                } label: {
                    MeetSpotUI.Buttons.primary("View Details")
                }
                
                Button {
                    // Handle share action
                } label: {
                    MeetSpotUI.Buttons.secondary("Share")
                }
            }
        }
        .padding()
    }
}

// MARK: - Helper Methods
private extension ExploreView {
    func handleMapTap(_ location: CGPoint) {
        if selectedMeet != nil {
            withAnimation(.spring(response: 0.3)) {
                selectedMeet = nil
            }
        }
    }
    
    func setupInitialLocation() {
        locationManager.requestLocation()
        if let location = locationManager.location {
            if !initialLocationSet {
                initialLocationSet = true
                updateRegionForLocation(location)
            }
        }
    }
    
    func updateRegionForLocation(_ location: CLLocation) {
        let region = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        cameraPosition = .region(region)
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// Location Manager to handle user location
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus?
    @Published var locationError: Error?
    private var locationTimer: Timer?
    @Published var lastRequestTime: Date = Date(timeIntervalSince1970: 0)
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        print("LocationManager initialized")
        
        // Check initial authorization status
        let status = locationManager.authorizationStatus
        print("Initial authorization status: \(status.rawValue)")
        authorizationStatus = status
        
        // If already authorized, try to get location immediately
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    func requestLocation() {
        // Throttle requests to prevent excessive polling
        let now = Date()
        if now.timeIntervalSince(lastRequestTime) < 3.0 {
            print("⚠️ LocationManager - THROTTLING LOCATION REQUEST - too soon after previous request")
            return
        }
        
        lastRequestTime = now
        print("LocationManager - requestLocation called")
        locationManager.requestWhenInUseAuthorization()
        
        // Reset any previous errors
        locationError = nil
        
        // Reset any existing timer
        locationTimer?.invalidate()
        
        // Set a timeout for location requests
        locationTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
            // If we haven't got a location after 10 seconds, stop trying to prevent battery drain
            if self?.location == nil {
                self?.locationManager.stopUpdatingLocation()
                print("⚠️ Location request timed out after 10 seconds")
            }
        }
        
        // Check for authorization before starting updates
        let status = locationManager.authorizationStatus
        print("Current authorization status when requesting location: \(status.rawValue)")
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            print("Authorization granted, starting location updates")
            // Stop any existing updates first to ensure a fresh start
            locationManager.stopUpdatingLocation()
            locationManager.startUpdatingLocation()
        } else {
            print("LocationManager - Not authorized: \(status.rawValue)")
        }
    }
    
    // Force a location update even if we recently requested one
    func forceLocationUpdate() {
        print("LocationManager - FORCING location update (bypassing throttle)")
        lastRequestTime = Date(timeIntervalSince1970: 0) // Reset the time to force an update
        requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Update on the main thread to ensure UI updates properly
        DispatchQueue.main.async {
            if let location = locations.last {
                // Only update if the location is reasonably accurate
                if location.horizontalAccuracy >= 0 && location.horizontalAccuracy <= 100 {
                    print("LocationManager - Got location: \(location.coordinate.latitude), \(location.coordinate.longitude) with accuracy: \(location.horizontalAccuracy)")
                    self.location = location
                    self.locationError = nil
                    
                    // Stop updating location to save battery - we have what we need
                    self.locationManager.stopUpdatingLocation()
                } else {
                    print("LocationManager - Received inaccurate location: \(location.horizontalAccuracy) meters")
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.locationError = error
            // If we get a location error, still try to continue with the last known location if available
            print("LocationManager - Location error: \(error.localizedDescription)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("LocationManager - Authorization status changed to: \(status.rawValue)")
        authorizationStatus = status
        
        // If authorization changed to authorized, request location again
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            print("LocationManager - Now authorized, starting location updates")
            locationManager.startUpdatingLocation()
        } else {
            print("LocationManager - Not authorized: \(status.rawValue)")
        }
    }
}

// NOTE: Helper extension and shape for cornerRadius have been moved to ViewExtensions.swift

// Extracted marker view for better performance
struct MarkerView: View {
    let meet: Meet
    let isSelected: Bool
    
    @State private var isPressed = false
    @State private var showDetails = false
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0
    
    var body: some View {
        VStack(spacing: 4) {
            // Animated marker icon
            Theme.Icons.mapAnnotationIcon(for: meet.type, isPremium: meet.isPremium)
                .scaleEffect(scale)
                .rotationEffect(.degrees(rotation))
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: scale)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: rotation)
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        scale = 1.2
                        rotation = 360
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            scale = 1.0
                            rotation = 0
                        }
                    }
                }
            
            // Animated title
            if isSelected {
                Text(meet.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.7))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Theme.Colors.accent.opacity(0.5), lineWidth: 1)
                            )
                    )
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    .fixedSize(horizontal: true, vertical: true)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
    }
}

// Preview Card (compact view)
struct MeetPreviewCard: View {
    let meet: Meet
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(meet.title)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text(meet.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Quick Details
            HStack(spacing: 20) {
                Label(meet.address, systemImage: "location.fill")
                    .lineLimit(1)
                    .font(.subheadline)
                
                Label("\(meet.attendees.count) attending", systemImage: "person.3.fill")
                    .font(.subheadline)
            }
        }
        .foregroundColor(.white)
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(20)
        .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius)
    }
}

struct ReplyView: View {
    let comment: MeetComment
    let meet: Meet
    let viewModel: MeetViewModel
    @Binding var replyText: String
    @Environment(\.dismiss) private var dismiss
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Reply to \(viewModel.users.first { $0.id == comment.userId }?.profile.name ?? "comment")", text: $replyText)
                }
                
                Section {
                    Button("Send Reply") {
                        Task {
                            do {
                                try await viewModel.addReply(replyText, to: comment, in: meet)
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                        }
                    }
                    .disabled(replyText.isEmpty)
                }
            }
            .navigationTitle("Reply")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
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
}

// MARK: - Custom View Modifiers
struct GlassmorphicCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(MeetSpotColors.backgroundGradient)
            .background(.ultraThinMaterial)
            .cornerRadius(MeetSpotStyle.Radius.medium)
            .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 10)
    }
}

struct PrimaryButton: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, MeetSpotStyle.Spacing.large)
            .padding(.vertical, MeetSpotStyle.Spacing.medium)
            .background(MeetSpotColors.primaryGradient)
            .cornerRadius(MeetSpotStyle.Radius.large)
            .shadow(radius: 10)
    }
}

extension View {
    func glassmorphicCard() -> some View {
        modifier(GlassmorphicCard())
    }
    
    func primaryButton() -> some View {
        modifier(PrimaryButton())
    }
}

// MARK: - Search Results Components
private struct LocationsSearchResultsSection: View {
    let viewModel: MeetViewModel
    let isLoading: Bool
    let locations: [Location]
    let onLocationSelected: (Location) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Locations")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                    Spacer()
                }
                .padding()
            } else if locations.isEmpty {
                Text("No locations found")
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(locations) { location in
                    LocationSearchResultRow(location: location, onTap: {
                        onLocationSelected(location)
                    })
                }
            }
        }
        .padding(.top)
    }
}

private struct LocationSearchResultRow: View {
    let location: Location
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .font(.title2)
                    .foregroundColor(MeetSpotColors.pink500)
                
                VStack(alignment: .leading) {
                    Text(location.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(location.address)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Material.ultraThinMaterial)
            )
            .padding(.horizontal)
        }
    }
}

private struct MeetsSearchResultsSection: View {
    let meets: [Meet]
    let onMeetSelected: (Meet) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Meets")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            if meets.isEmpty {
                Text("No meets found")
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(meets) { meet in
                    MeetSearchResultRow(meet: meet, onTap: {
                        onMeetSelected(meet)
                    })
                }
            }
        }
        .padding(.top)
    }
}

private struct MeetSearchResultRow: View {
    let meet: Meet
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "car.fill")
                    .font(.title2)
                    .foregroundColor(MeetSpotColors.pink500)
                
                VStack(alignment: .leading) {
                    Text(meet.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(meet.locationName)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Material.ultraThinMaterial)
            )
            .padding(.horizontal)
        }
    }
} 

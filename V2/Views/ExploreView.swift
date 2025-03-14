import SwiftUI
import MapKit
import CoreLocation

struct ExploreView: View {
    @ObservedObject var viewModel: MeetViewModel
    @StateObject private var routeViewModel = RouteViewModel()
    @StateObject private var locationManager: LocationManager = LocationManager()
    @State private var cameraPosition = MapCameraPosition.region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    ))
    @State private var selectedMeet: Meet?
    @State private var showFullDetails = false
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var isShowingMap = true
    @State private var initialLocationSet = false
    @State private var showingCreateMeet = false
    @State private var showSearchResults = false
    @State private var isLoading = false
    @State private var showingRouteView = false
    @State private var mapIsTilted = false
    
    // Add a property to handle tab selection changes
    @State private var selectedTab: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Map or list content
                if isShowingMap {
                    mapView
                } else {
                    ZStack {
                        AnimatedGradientBackground()
                        
                        // Search results or list content
                        if showSearchResults {
                            searchResultsView
                        } else {
                            // Scrollable content with meets
                            ScrollView {
                                meetListContent
                            }
                        }
                    }
                }
                
                // Floating header
                VStack {
                    // Search and toggle controls
                    searchAndToggleBar
                    
                    // Floating action buttons (Create meet, Feed)
                    if !showSearchResults {
                        VStack {
                            Spacer()
                            
                            // Action buttons at the bottom 
                            HStack(spacing: 16) {
                                Spacer()
                                
                                // Feed button - changed from Routes button
                                Button {
                                    // Show route view instead of changing tabs
                                    showingRouteView = true
                                } label: {
                                    Image(systemName: "map.fill")
                                        .font(.system(size: 24))
                                        .frame(width: 56, height: 56)
                                        .background(Circle().fill(Color.white))
                                        .foregroundColor(.black)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.black, lineWidth: 1.5)
                                        )
                                        .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
                                }
                                
                                // Create meet button
                                Button {
                                    showingCreateMeet = true
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.system(size: 24))
                                        .frame(width: 56, height: 56)
                                        .background(Circle().fill(Color.white))
                                        .foregroundColor(.black)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.black, lineWidth: 1.5)
                                        )
                                        .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
                                }
                            }
                            .padding(.trailing, 16)
                            .padding(.bottom, 32) // Add padding to lift them above the bottom tab bar
                        }
                    }
                }
                
                // Selected meet preview card
                meetPreviewCardView
            }
            .environmentObject(locationManager)
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarHidden(true)
            .sheet(isPresented: $showingCreateMeet) {
                CreateMeetOnboardingView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingRouteView) {
                RoutesView()
            }
            .sheet(isPresented: $showFullDetails) {
                if let meet = selectedMeet {
                    NavigationView {
                        MeetDetailView(meet: meet, viewModel: viewModel)
                            .navigationBarTitleDisplayMode(.inline)
                            .navigationBarItems(trailing: Button("Done") { showFullDetails = false })
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
        .navigationViewStyle(.stack)
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
                        .foregroundColor(Color.white)
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
    
    // Computed properties for dynamic styling
    private var circleFill: Color {
        isSelected ? MeetSpotColors.purple900 : .white
    }
    
    private var circleStroke: Color {
        isSelected ? .white : MeetSpotColors.purple900
    }
    
    private var iconColor: Color {
        isSelected ? .white : MeetSpotColors.purple900
    }
    
    private var iconName: String {
        switch meet.vehicleType {
        case .car:
            return "car.fill"
        case .bike:
            return "motorcycle"
        case .both, .mixed:
            return "car.2"
        }
    }
    
    var body: some View {
        Button(action: {
            print("Annotation tapped directly for meet: \(meet.title)")
            onTap()
        }) {
            VStack(spacing: 0) {
                // Main icon circle
                ZStack {
                    Circle()
                        .fill(circleFill)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .stroke(circleStroke, lineWidth: 2)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    
                    // Vehicle type icon
                    Image(systemName: iconName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(iconColor)
                }
                
                // Location marker triangle
                Triangle()
                    .fill(isSelected ? AnyShapeStyle(MeetSpotColors.purple900) : AnyShapeStyle(Color.white))
                    .frame(width: 16, height: 8)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                
                // Add premium indicator if needed
                if meet.isPremium && isSelected {
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 10, height: 10)
                        .overlay(
                            Image(systemName: "star.fill")
                                .font(.system(size: 6, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .offset(x: 12, y: -24)
                }
            }
        }
        .buttonStyle(PlainButtonStyle()) // Prevents default button styling
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
                    .tint(MeetSpotColors.purple900)
            }
            
            ForEach(viewModel.meets) { meet in
                Annotation(meet.title, coordinate: meet.location) {
                    MapAnnotationView(
                        meet: meet,
                        isSelected: selectedMeet?.id == meet.id,
                        onTap: {
                            print("MapAnnotationView tap received for meet: \(meet.title)")
                            if selectedMeet?.id == meet.id {
                                // If already selected, show full details directly
                                print("Already selected, showing detail sheet directly")
                                showFullDetails = true
                            } else {
                                // Otherwise just select the meet
                                selectMeet(meet)
                            }
                        }
                    )
                }
                .annotationTitles(.hidden) // Hide the default title popup
                .tag(meet.id) // Add a tag to help with identification
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            // Use built-in MapKit controls for compass and scale
            MapCompass()
            MapScaleView()
                .padding([.bottom], 50)
        }
        .overlay(mapOverlayGradient)
        .overlay(
            // Custom positioned map controls to prevent header overlap
            VStack(spacing: 12) {
                // Add a spacer to push controls below the header
                Spacer()
                    .frame(height: 160)
                
                // User location button
                Button {
                    if let location = locationManager.location {
                        updateRegionForLocation(location)
                    } else {
                        locationManager.requestLocation()
                    }
                } label: {
                    Image(systemName: "location.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.black)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color.white))
                        .overlay(
                            Circle()
                                .stroke(Color.black, lineWidth: 1.5)
                        )
                        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                }
                
                // 3D toggle button
                Button {
                    // Toggle map elevation
                    if mapIsTilted {
                        cameraPosition = .camera(MapCamera(
                            centerCoordinate: cameraPosition.camera?.centerCoordinate ?? CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                            distance: cameraPosition.camera?.distance ?? 1000,
                            heading: cameraPosition.camera?.heading ?? 0,
                            pitch: 0 // Flat
                        ))
                    } else {
                        cameraPosition = .camera(MapCamera(
                            centerCoordinate: cameraPosition.camera?.centerCoordinate ?? CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                            distance: cameraPosition.camera?.distance ?? 1000,
                            heading: cameraPosition.camera?.heading ?? 0,
                            pitch: 60 // Tilted
                        ))
                    }
                    mapIsTilted.toggle()
                } label: {
                    Image(systemName: mapIsTilted ? "view.2d" : "view.3d")
                        .font(.system(size: 16))
                        .foregroundColor(.black)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color.white))
                        .overlay(
                            Circle()
                                .stroke(Color.black, lineWidth: 1.5)
                        )
                        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                }
            }
            .padding(.trailing, 16)
            .padding(.top, 16),
            alignment: .topTrailing
        )
        .ignoresSafeArea(edges: .bottom)
        .onTapGesture {
            // Only handle taps on the map background, not on annotations
            handleMapTap(CGPoint(x: 0, y: 0))
        }
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
            startPoint: UnitPoint.top,
            endPoint: UnitPoint.bottom
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
                                .fill(Color.white.opacity(0.5))
                                .frame(width: 36, height: 5)
                                .padding(.vertical, 8)
                            
                            // Meet preview content
                            previewContent(for: meet)
                        }
                    }
                    .transition(
                        AnyTransition.move(edge: .bottom).combined(with: .opacity)
                    )
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
                    .foregroundColor(.white)
                MeetSpotType.caption(meet.address)
            }
            
            // Date and capacity
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.white)
                MeetSpotType.caption(meet.formattedDate)
                
                Spacer()
                
                Image(systemName: "person.3.fill")
                    .foregroundColor(.white)
                MeetSpotType.caption("\(meet.attendees.count)/\(meet.capacity)")
            }
            
            // Status indicator
            HStack {
                Image(systemName: meet.status.icon)
                    .foregroundColor(.white)
                MeetSpotType.caption(meet.status.displayName)
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button {
                    print("View Details tapped for meet: \(meet.id), status: \(meet.status.rawValue)")
                    // Force sheet to present regardless of other conditions
                    DispatchQueue.main.async {
                        showFullDetails = true
                    }
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
        // Only dismiss selected meet if one is currently selected
        // This avoids interfering with annotation taps
        if selectedMeet != nil {
            print("Background map tapped, dismissing selected meet")
            withAnimation(.spring(response: 0.3)) {
                selectedMeet = nil
            }
        }
    }
    
    // New function to handle meet selection consistently
    func selectMeet(_ meet: Meet, showDetailSheet: Bool = false) {
        print("Selecting meet: \(meet.title), ID: \(meet.id), status: \(meet.status.rawValue)")
        
        // Ensure selections are always on main thread
        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.3)) {
                selectedMeet = meet
            }
            
            // If showDetailSheet is true, present the sheet after a tiny delay to ensure state is updated
            if showDetailSheet {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    print("Opening detail sheet for meet: \(meet.id)")
                    showFullDetails = true
                }
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
            .foregroundColor(.black)
            .padding(.horizontal, MeetSpotStyle.Spacing.large)
            .padding(.vertical, MeetSpotStyle.Spacing.medium)
            .background(Color.white)
            .cornerRadius(MeetSpotStyle.Radius.large)
            .overlay(
                RoundedRectangle(cornerRadius: MeetSpotStyle.Radius.large)
                    .stroke(Color.black, lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
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
                    .foregroundColor(MeetSpotColors.purple900)
                
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
                    .foregroundColor(Color.white)
                
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

// MARK: - Missing Components
private extension ExploreView {
    // Extracted list content for displaying meets
    var meetListContent: some View {
        VStack(spacing: 16) {
            ForEach(viewModel.meets) { meet in
                Button {
                    print("List item tapped for meet: \(meet.title)")
                    selectMeet(meet, showDetailSheet: true)
                } label: {
                    MeetCardRow(meet: meet)
                        .padding(.horizontal)
                }
            }
            .padding(.bottom, 4)
            
            if viewModel.isLoading {
                ProgressView()
                    .tint(.white)
                    .padding()
            }
            
            // Safe area spacer
            Spacer().frame(height: 100)
        }
        .padding(.top)
    }
    
    // Search bar and view toggle controls
    var searchAndToggleBar: some View {
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
                        .foregroundColor(Color.white)
                }
                
                Text("Explore Meets")
                    .font(MeetSpotStyle.Typography.heading2)
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 20) // Increased top padding
            
            // Search bar
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
            .padding(.vertical, 12) // Added vertical padding
        }
        .background(
            // Stronger background for the header area
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.7),
                            Color.black.opacity(0.4),
                            Color.black.opacity(0.1)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 150) // Increased height
                .ignoresSafeArea(edges: .top)
        )
    }
}

// Helper component for meet list items
private struct MeetCardRow: View {
    let meet: Meet
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(meet.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(meet.locationName)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(MeetSpotColors.purple900)
                    Text(meet.formattedDate)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    Image(systemName: "person.3.fill")
                        .foregroundColor(MeetSpotColors.purple900)
                    Text("\(meet.attendees.count)/\(meet.capacity)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.6))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
        )
    }
}


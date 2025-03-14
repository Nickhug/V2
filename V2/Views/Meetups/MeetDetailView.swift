import SwiftUI
import MapKit

struct MeetDetailView: View {
    @ObservedObject var viewModel: MeetViewModel
    @StateObject private var routeViewModel = RouteViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab = 0
    @State private var showingJoinSheet = false
    @State private var showingRouteEditor = false
    @State private var selectedVehicle: Vehicle?
    @State private var mapRegion: MKCoordinateRegion
    @State private var cameraPosition: MapCameraPosition
    @State private var scrollOffset: CGFloat = 0
    @State private var animateCover: Bool = false
    @State private var showFullDescription: Bool = false
    @State private var newComment: String = ""
    @State private var coverScale: CGFloat = 1.0
    @State private var showShareSheet = false
    @State private var headerOpacity: Double = 0
    
    let meet: Meet
    private let tabTitles = ["Overview", "Attendees", "Discussion"]
    
    init(meet: Meet, viewModel: MeetViewModel) {
        self.viewModel = viewModel
        self.meet = meet
        
        // Initialize map region centered on the meet location
        let region = MKCoordinateRegion(
            center: meet.location,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        
        _mapRegion = State(initialValue: region)
        _cameraPosition = State(initialValue: .region(region))
    }
    
    // Private helper to fetch comments
    private func fetchMeetComments() async {
        do {
            // Direct fetch from Supabase service
            let comments = try await SupabaseService.shared.fetchComments(meetId: meet.id)
            
            // Update on main thread
            await MainActor.run {
                viewModel.comments = comments
                
                // Update meet's comments if needed
                if let meetIndex = viewModel.meets.firstIndex(where: { $0.id == meet.id }) {
                    var updatedMeet = viewModel.meets[meetIndex]
                    updatedMeet.comments = comments
                    viewModel.meets[meetIndex] = updatedMeet
                }
            }
        } catch {
            print("Error fetching comments: \(error)")
        }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background
            Color.black
                .ignoresSafeArea()
            
            // ScrollView for the entire content
        ScrollView {
                GeometryReader { proxy in
                    let offset = proxy.frame(in: .named("scroll")).minY
                    Color.clear.preference(key: ScrollOffsetKey.self, value: offset)
                }
                .frame(height: 0)
                
                ZStack(alignment: .top) {
                    // Parallax Hero Image
                    GeometryReader { geo in
                        let scrollY = geo.frame(in: .global).minY
                        
                        ZStack(alignment: .bottom) {
                            // Cover image with parallax
                            AsyncImageView(imageName: meet.coverImage)
                                .aspectRatio(contentMode: .fill)
                                .frame(width: UIScreen.main.bounds.width)
                                .frame(height: 400 + max(0, -scrollY))
                                .clipped()
                                .offset(y: min(0, scrollY / 2))
                                .scaleEffect(max(coverScale, 1.0))
                            
                            // Dark gradient overlay
                            LinearGradient(
                                colors: [
                                    .clear,
                                    .black.opacity(0.3),
                                    .black.opacity(0.8),
                                    .black
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 400)
                            
                            // Meet info overlay
                            VStack(alignment: .leading, spacing: 8) {
                                // Meet status badge
                                Text(meet.status.displayName)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(meet.status.color.opacity(0.2))
                                    .foregroundColor(meet.status.color)
                                    .clipShape(Capsule())
                                
                                // Title with animation
                                Text(meet.title)
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                                    .shadow(color: Color.black.opacity(0.5), radius: 4, x: 0, y: 2)
                                    .opacity(animateCover ? 1 : 0)
                                    .offset(y: animateCover ? 0 : 20)
                                
                                // Date and location indicators
                                HStack {
                                    // Date pill
                                    HStack(spacing: 4) {
                                        Image(systemName: "calendar")
                                            .font(.caption)
                                        Text(meet.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.15))
                                    .clipShape(Capsule())
                                    
                                    // Location pill
                                    HStack(spacing: 4) {
                                        Image(systemName: "mappin")
                                            .font(.caption)
                                        Text(meet.locationName)
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.15))
                                    .clipShape(Capsule())
                                }
                                .foregroundColor(.white)
                                .opacity(animateCover ? 1 : 0)
                                .offset(y: animateCover ? 0 : 20)
                                
                                // Vehicle and route types
                                HStack {
                                    // Vehicle type
                                    Text(meet.vehicleType.rawValue)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.white.opacity(0.15))
                                        .foregroundColor(.white)
                                        .clipShape(Capsule())
                                    
                                    // Route type
                                    Text(meet.routeType.rawValue)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.white.opacity(0.15))
                                .foregroundColor(.white)
                                        .clipShape(Capsule())
                                }
                                .opacity(animateCover ? 1 : 0)
                                .offset(y: animateCover ? 0 : 20)
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 24)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(height: 400)
                    }
                    .frame(height: 400)
                    
                    VStack(spacing: 0) {
                        // Empty space to offset content
                        Color.clear
                            .frame(height: 380)
                        
                        // Content container with modernized rounded corners
                        VStack(spacing: 0) {
                            // Custom tab bar with smooth animations
                            HStack(spacing: 0) {
                                ForEach(0..<tabTitles.count, id: \.self) { index in
                                    Button(action: {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                            selectedTab = index
                                        }
                                    }) {
                                        VStack(spacing: 8) {
                                            Text(tabTitles[index])
                                                .fontWeight(selectedTab == index ? .bold : .medium)
                                                .foregroundColor(selectedTab == index ? .white : .white.opacity(0.6))
                                            
                                            // Animated indicator
                                            Rectangle()
                                                .fill(selectedTab == index ? MeetSpotColors.purple900 : Color.clear)
                                                .frame(height: 3)
                                                .cornerRadius(3)
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 16)
                            .padding(.bottom, 8)
                            .background(Color.black.opacity(0.7))
                            
                            // Tab content
                            TabView(selection: $selectedTab) {
                                // OVERVIEW TAB
                                overviewTab
                                    .tag(0)
                                
                                // ATTENDEES TAB
                                attendeesTab
                                    .tag(1)
                                
                                // DISCUSSION TAB
                                discussionTab
                                    .tag(2)
                            }
                            .tabViewStyle(.page(indexDisplayMode: .never))
                            .frame(minHeight: UIScreen.main.bounds.height * 0.7)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 32)
                                .fill(Color.black)
                                .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: -5)
                        )
                        .offset(y: -20)
                    }
                }
            }
            .ignoresSafeArea()
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetKey.self) { value in
                scrollOffset = value
                
                // Animate cover image based on scroll
                withAnimation(.easeOut(duration: 0.2)) {
                    // Scale effect for pull-to-refresh feeling
                    coverScale = value > 0 ? 1 + (value / 500) : 1.0
                    
                    // Control header opacity based on scroll
                    headerOpacity = value < -80 ? 1.0 : 0.0
                }
            }
            
            // Floating header that appears on scroll with blurred background
            if headerOpacity > 0 {
                floatingHeader
                    .opacity(headerOpacity)
                    .transition(.opacity)
            }
            
            // Navigation controls overlay
            HStack {
                // Back button
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                // Action buttons
                if let currentUser = viewModel.currentUser {
                    HStack(spacing: 12) {
                        if meet.creatorId == currentUser.id {
                            // Edit button for creator
                            Button(action: {
                                showingRouteEditor = true
                            }) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Color.black.opacity(0.3))
                                    .clipShape(Circle())
                            }
                        } else {
                            // Join button for non-creators
                            Button(action: {
                                showingJoinSheet = true
                            }) {
                                Text(viewModel.isAttending(meet) ? "Joined" : "Join")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(viewModel.isAttending(meet) ? .black : .white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(viewModel.isAttending(meet) ? Color.white : Color.black.opacity(0.3))
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white, lineWidth: viewModel.isAttending(meet) ? 0 : 1)
                                    )
                            }
                        }
                        
                        // Share button
                        Button(action: {
                            showShareSheet = true
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .zIndex(10)
        }
        .sheet(isPresented: $showingJoinSheet) {
            JoinMeetView(meet: meet, viewModel: viewModel)
        }
            .sheet(isPresented: $showingRouteEditor) {
                RouteEditorView(
                    meetId: meet.id,
                    onRouteSaved: nil,
                    existingRoute: routeViewModel.meetRoutes.first(where: { $0.id == meet.primaryRouteId })
                )
            }
        .sheet(isPresented: $showShareSheet) {
            // Share sheet with activity items for the meet URL
            let meetShareText = "Check out this meet: \(meet.title)"
            let activityItems: [Any] = [meetShareText]
            ActivityViewController(activityItems: activityItems)
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: 
            Button(action: {
                dismiss()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .foregroundColor(.white)
            }
        )
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if let currentUser = viewModel.currentUser, meet.creatorId == currentUser.id {
                    Menu {
                        Button(action: {
                            showingRouteEditor = true
                        }) {
                            Label("Edit Route", systemImage: "map")
                        }
                        
                        ForEach(MeetStatus.allCases) { status in
                            if status != meet.status {
                                Button(action: {
                                    Task {
                                        try? await viewModel.updateMeetStatus(meetId: meet.id, status: status)
                                    }
                                }) {
                                    Label("Mark as \(status.displayName)", systemImage: status.icon)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.white)
                    }
                }
            }
        }
            .task {
                // Fetch participants and comments for this meet
                await viewModel.fetchParticipants(meetId: meet.id)
                
                // Use the helper method instead of direct viewModel call
                await fetchMeetComments()
                
                // Fetch routes for this meet
                await routeViewModel.fetchMeetRoutes(meetId: meet.id)
                
                // Set the selected route if there's a primary route
                if let primaryRouteId = meet.primaryRouteId,
                   let primaryRoute = routeViewModel.meetRoutes.first(where: { $0.id == primaryRouteId }) {
                    routeViewModel.selectedRoute = primaryRoute
                }
            
            // Animate cover image
            withAnimation(.easeOut(duration: 0.8)) {
                animateCover = true
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Floating Header View
    
    private var floatingHeader: some View {
        VStack(spacing: 0) {
            // Blurred background
            ZStack {
                // Blurred background
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
                
                // Content
                        HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                    Text(meet.title)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if let currentUser = viewModel.currentUser {
                        if meet.creatorId != currentUser.id {
                            Button(action: {
                                showingJoinSheet = true
                            }) {
                                Text(viewModel.isAttending(meet) ? "Joined" : "Join")
                                .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(viewModel.isAttending(meet) ? .black : .white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(viewModel.isAttending(meet) ? Color.white : Color.white.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .frame(height: 44)
            .ignoresSafeArea(edges: .top)
        }
    }
    
    // MARK: - Tab Views
    
    var overviewTab: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Description section
                VStack(alignment: .leading, spacing: 12) {
                    Text("About")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(meet.description)
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(showFullDescription ? nil : 3)
                        .onTapGesture {
                            withAnimation(.spring()) {
                                showFullDescription.toggle()
                            }
                        }
                    
                    if !showFullDescription && meet.description.count > 150 {
                        Button("Show more") {
                            withAnimation(.spring()) {
                                showFullDescription = true
                            }
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(MeetSpotColors.purple900)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                )
                
                // Location Map
                VStack(alignment: .leading, spacing: 12) {
                    Text("Location")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Map(position: $cameraPosition) {
                        Marker("\(meet.title)", coordinate: meet.location)
                            .tint(MeetSpotColors.purple900)
                    }
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    
                    // Address text with icon
                            HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(MeetSpotColors.purple900)
                        
                        Text(meet.address)
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    // Directions button
                                Button {
                        // Open in Maps
                        let url = URL(string: "maps://?daddr=\(meet.location.latitude),\(meet.location.longitude)")
                        if let url = url, UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                                } label: {
                        HStack {
                            Image(systemName: "arrow.triangle.turn.up.right.diamond")
                            Text("Get Directions")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(MeetSpotColors.purple900.opacity(0.2))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(MeetSpotColors.purple900.opacity(0.5), lineWidth: 1)
                        )
                    }
                    .padding(.top, 8)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                )
                
                // Rules section
                if !meet.rules.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Rules")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(meet.rules, id: \.self) { rule in
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(MeetSpotColors.purple900)
                                        .font(.system(size: 16))
                                    
                                    Text(rule)
                                        .font(.system(size: 16))
                                        .foregroundColor(.white.opacity(0.8))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.05))
                    )
                }
                
                // Creator controls
                if let currentUser = viewModel.currentUser, meet.creatorId == currentUser.id {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Manage Meet")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("As the creator, you can change the status of this meet:")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                        
                        // Status buttons with improved styling
                        HStack(spacing: 12) {
                            ForEach(MeetStatus.allCases) { status in
                                if status != meet.status {
                Button {
                                        Task {
                                            try? await viewModel.updateMeetStatus(meetId: meet.id, status: status)
                                        }
                } label: {
                                        Text(status.displayName)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(status.color.opacity(0.2))
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(status.color.opacity(0.5), lineWidth: 1)
                                            )
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.05))
                    )
                }
                
                Spacer(minLength: 60)
            }
            .padding()
        }
    }
    
    var attendeesTab: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Header with count and capacity visualization
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Attendees")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("\(meet.attendees.count)/\(meet.capacity)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    // Colored progress bar
                    ProgressView(value: Double(meet.attendees.count), total: Double(meet.capacity))
                        .progressViewStyle(LinearProgressViewStyle(tint: MeetSpotColors.purple900))
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .frame(height: 8)
                }
                    .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                )
                
                // Attendees grid with improved styling
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 16)], spacing: 16) {
                    ForEach(meet.attendees) { attendee in
                        VStack(spacing: 8) {
                            // Avatar with animated loading and placeholder
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(width: 80, height: 80)
                                
                                AsyncImageView(
                                    imageName: attendee.profile.avatar,
                                    avatarUrl: attendee.profile.avatarUrl
                                )
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(MeetSpotColors.purple900.opacity(0.5), lineWidth: 2)
                                )
                                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            
                            Text(attendee.profile.name)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            // Vehicle info if available
                            if let vehicle = attendee.vehicles.first {
                                Text("\(vehicle.make) \(vehicle.model)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.6))
                                    .lineLimit(1)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                    }
                }
                
                // Empty state with improved visuals
                if meet.attendees.isEmpty {
                    VStack {
                        Spacer()
                        
                        Image(systemName: "person.3")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.3))
                            .padding(.bottom, 16)
                        
                        Text("No attendees yet")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("Be the first to join!")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.5))
                        
                        // Join button
                        if let currentUser = viewModel.currentUser, meet.creatorId != currentUser.id {
                Button {
                                showingJoinSheet = true
                            } label: {
                                Text("Join Now")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white)
                                    )
                            }
                            .padding(.top, 20)
                        }
                        
                        Spacer()
                    }
                    .frame(height: 300)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.05))
                    )
                }
                
                Spacer(minLength: 60)
            }
            .padding()
        }
    }
    
    var discussionTab: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                Text("Discussion")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal)
                
                // Comment input with modern styling
                HStack(spacing: 12) {
                    TextField("Add a comment...", text: $newComment)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.05))
                        )
                        .foregroundColor(.white)
                    
                    Button {
                        Task {
                            do {
                                try await viewModel.addComment(newComment, to: meet)
                                newComment = ""
                        } catch {
                                print("Error adding comment: \(error)")
                            }
                    }
                } label: {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.white)
                            .padding(12)
                            .background(
                                Circle()
                                    .fill(newComment.isEmpty ? Color.white.opacity(0.1) : MeetSpotColors.purple900)
                                    .shadow(color: newComment.isEmpty ? Color.clear : MeetSpotColors.purple900.opacity(0.3), radius: 5, x: 0, y: 2)
                            )
                            .foregroundColor(newComment.isEmpty ? .white.opacity(0.5) : .white)
                    }
                    .disabled(newComment.isEmpty)
                }
                .padding(.horizontal)
                
                // Comments section
                VStack(spacing: 16) {
                    if meet.comments.isEmpty {
                        VStack {
                            Spacer()
                            
                            Image(systemName: "bubble.right")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.3))
                                .padding(.bottom, 16)
                            
                            Text("No comments yet")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text("Start the conversation!")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.5))
                            
                            Spacer()
                        }
                        .frame(height: 300)
                .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.05))
                        )
                        .padding(.horizontal)
                    } else {
                        ForEach(meet.comments) { comment in
                            CommentCard(
                                comment: comment,
                                meet: meet,
                                viewModel: viewModel,
                                onDelete: {
                                    Task {
                                        do {
                                            try await viewModel.deleteComment(comment, from: meet)
                                        } catch {
                                            print("Error deleting comment: \(error)")
                                        }
                                    }
                                }
                            )
                            .padding(.horizontal)
                        }
                    }
                }
                
                Spacer(minLength: 60)
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Supporting Views

struct CommentCard: View {
    let comment: MeetComment
    let meet: Meet
    let viewModel: MeetViewModel
    let onDelete: () -> Void
    
    @State private var showActions: Bool = false
    @State private var isLiked: Bool = false
    
    var user: User? {
        viewModel.users.first { $0.id == comment.userId }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Author info
        HStack {
                AsyncImageView(
                    imageName: user?.profile.avatar ?? "",
                    avatarUrl: user?.profile.avatarUrl
                )
                .aspectRatio(contentMode: .fill)
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
                )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(user?.profile.name ?? "Unknown")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text(comment.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Button {
                    withAnimation(.spring()) {
                        showActions.toggle()
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.8))
                        .rotationEffect(.degrees(showActions ? 90 : 0))
                        .padding(8)
                        .background(showActions ? Color.white.opacity(0.1) : Color.clear)
                        .clipShape(Circle())
                }
            }
            
            // Comment text
            Text(comment.text)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
            
            // Actions
            HStack(spacing: 20) {
                Button {
                    Task {
                        do {
                            try await viewModel.likeComment(comment, in: meet)
                            withAnimation(.spring()) {
                                isLiked.toggle()
                            }
                        } catch {
                            print("Error liking comment: \(error)")
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: comment.likes > 0 ? "heart.fill" : "heart")
                            .font(.system(size: 16))
                        Text("\(comment.likes)")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(comment.likes > 0 ? MeetSpotColors.purple900 : .white.opacity(0.6))
                }
                
                if !comment.replies.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.right")
                            .font(.system(size: 16))
                        Text("\(comment.replies.count)")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.white.opacity(0.6))
                }
            }
            
            // Action menu
            if showActions {
                HStack {
                    Button {
                        // Reply action
                    } label: {
                        Label("Reply", systemImage: "arrowshape.turn.up.left")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
            }
            
            Spacer()
                    
                    if let currentUser = viewModel.currentUser, comment.userId == currentUser.id {
                        Button {
                            onDelete()
                        } label: {
                            Label("Delete", systemImage: "trash")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding(.vertical, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Replies
            if !comment.replies.isEmpty {
                ForEach(comment.replies) { reply in
                    CommentCard(
                        comment: reply,
                        meet: meet,
                        viewModel: viewModel,
                        onDelete: onDelete
                    )
                    .padding(.leading, 40)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Supporting Types

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Activity View Controller for Sharing

struct ActivityViewController: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewController>) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityViewController>) {}
} 

import SwiftUI
import MapKit

struct MeetDetailView: View {
    @ObservedObject var viewModel: MeetViewModel
    @StateObject private var routeViewModel = RouteViewModel()
    
    @State private var selectedTab = 0
    @State private var showingJoinSheet = false
    @State private var showingRouteEditor = false
    @State private var selectedVehicle: Vehicle?
    @State private var mapRegion: MKCoordinateRegion
    @State private var cameraPosition: MapCameraPosition
    
    let meet: Meet
    
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
            // Direct fetch from Supabase service to avoid any potential method signature conflicts
            let comments = try await SupabaseService.shared.fetchComments(meetId: meet.id)
            
            // Update viewModel comments collection
            await MainActor.run {
                viewModel.comments = comments
                
                // Also update the meet's comments if needed
                if let index = viewModel.meets.firstIndex(where: { $0.id == meet.id }) {
                    var updatedMeet = viewModel.meets[index]
                    updatedMeet.comments = comments
                    viewModel.meets[index] = updatedMeet
                }
            }
        } catch {
            print("Error fetching comments: \(error)")
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Meet map
                ZStack(alignment: .bottomTrailing) {
                    Map(position: $cameraPosition) {
                        Annotation("Meet Location", coordinate: meet.location) {
                            VStack {
                                Image(systemName: "flag.checkered.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.red)
                                
                                Text(meet.title)
                                    .font(.caption)
                                    .padding(5)
                                    .background(Color.white.opacity(0.8))
                                    .cornerRadius(5)
                            }
                        }
                    }
                    .frame(height: 200)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    HStack {
                        Button {
                            if let primaryRoute = routeViewModel.meetRoutes.first(where: { $0.id == meet.primaryRouteId }) {
                                routeViewModel.selectedRoute = primaryRoute
                                showingRouteEditor = true
                            }
                        } label: {
                            Label("View Route", systemImage: "map")
                                .padding(8)
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .disabled(meet.primaryRouteId == nil)
                        
                        Button {
                            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: meet.location))
                            mapItem.name = meet.title
                            mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
                        } label: {
                            Label("Directions", systemImage: "arrow.triangle.turn.up.right.diamond")
                                .padding(8)
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                }
                
                // Status section
                VStack {
                    HStack {
                        Text("Event Status")
                            .font(.headline)
                        
                        Spacer()
                        
                        AnimatedStatusBadge(status: meet.status)
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(meet.status.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if meet.status == .upcoming {
                            Text("This meet will start on \(meet.date.formatted(date: .long, time: .shortened))")
                                .font(.subheadline)
                        } else if meet.status == .active {
                            Text("This meet started on \(meet.date.formatted(date: .long, time: .shortened)) and is currently active")
                                .font(.subheadline)
                        } else if meet.status == .completed {
                            Text("This meet took place on \(meet.date.formatted(date: .long, time: .shortened))")
                                .font(.subheadline)
                        } else if meet.status == .canceled {
                            Text("This meet was scheduled for \(meet.date.formatted(date: .long, time: .shortened))")
                                .font(.subheadline)
                        }
                        
                        // If user is creator, show status management controls
                        if meet.creatorId == viewModel.currentUser?.id {
                            VStack(alignment: .leading, spacing: 8) {
                                Divider()
                                
                                Text("Manage Status")
                                    .font(.subheadline.bold())
                                
                                HStack {
                                    ForEach(MeetStatus.allCases) { status in
                                        if status != meet.status {
                                            Button {
                                                Task {
                                                    try? await viewModel.updateMeetStatus(meetId: meet.id, status: status)
                                                }
                                            } label: {
                                                Text(status.displayName)
                                                    .font(.caption)
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 5)
                                                    .background(status.color.opacity(0.2))
                                                    .foregroundColor(status.color)
                                                    .cornerRadius(8)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Meet details
                VStack(alignment: .leading, spacing: 16) {
                    Text(meet.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    HStack {
                        StatusBadge(status: meet.status)
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Date and time
                    HStack(spacing: 20) {
                        VStack(alignment: .leading) {
                            Text("Date")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(meet.date, style: .date)
                                .font(.headline)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Time")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(meet.date, style: .time)
                                .font(.headline)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Location
                    VStack(alignment: .leading) {
                        Text("Location")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(meet.address)
                            .font(.headline)
                    }
                    .padding(.horizontal)
                    
                    // Vehicle type
                    VStack(alignment: .leading) {
                        Text("Vehicle Type")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(meet.vehicleType.rawValue)
                            .font(.headline)
                    }
                    .padding(.horizontal)
                    
                    // Route type
                    VStack(alignment: .leading) {
                        Text("Route Type")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(meet.routeType.rawValue)
                            .font(.headline)
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Description
                    Text("About")
                        .font(.headline)
                        .padding(.horizontal)
                    Text(meet.description)
                        .padding(.horizontal)
                    
                    if meet.status == .active {
                        Button {
                            // TODO: Implement check-in functionality
                        } label: {
                            HStack {
                                Spacer()
                                Label("Check In", systemImage: "checkmark.circle.fill")
                                    .padding()
                                    .background(Color.accentColor)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                Spacer()
                            }
                        }
                        .padding()
                    }
                    
                    // Tabs for participants, comments, and routes
                    VStack {
                        Picker("", selection: $selectedTab) {
                            Text("Participants").tag(0)
                            Text("Comments").tag(1)
                            Text("Routes").tag(2)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        
                        TabView(selection: $selectedTab) {
                            ParticipantsView(viewModel: viewModel, meetId: meet.id)
                                .tag(0)
                            
                            MeetCommentsView(meet: meet, comments: $viewModel.comments)
                                .tag(1)
                            
                            RoutesListView(meetId: meet.id)
                                .tag(2)
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                        .frame(height: 300)
                    }
                    
                    // Join button
                    Button {
                        showingJoinSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.plus")
                            Text("Join Meet")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(meet.status.allowsInteraction ? DesignSystem.Colors.accentGradient : LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!meet.status.allowsInteraction)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .sheet(isPresented: $showingJoinSheet) {
                        JoinMeetView(meet: meet, viewModel: viewModel)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingRouteEditor) {
                RouteEditorView(
                    meetId: meet.id,
                    onRouteSaved: nil,
                    existingRoute: routeViewModel.meetRoutes.first(where: { $0.id == meet.primaryRouteId })
                )
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
            }
        }
    }
}

struct ParticipantsView: View {
    @ObservedObject var viewModel: MeetViewModel
    var meetId: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Participants (\(viewModel.participants.count))")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView {
                LazyVStack(alignment: .leading) {
                    ForEach(viewModel.participants, id: \.userId) { participant in
                        HStack {
                            Circle()
                                .fill(Color.gray)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text(String(participant.userId.uuidString.prefix(2)))
                                        .foregroundColor(.white)
                                )
                            
                            VStack(alignment: .leading) {
                                Text("User \(participant.userId.uuidString.prefix(8))")
                                    .font(.subheadline)
                                Text("Joined \(participant.joinedAt, style: .date)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("Vehicle \(participant.vehicleId.uuidString.prefix(4))")
                                .font(.caption)
                                .padding(4)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(4)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
}

struct MeetCommentsView: View {
    let meet: Meet
    @Binding var comments: [MeetComment]
    @State private var newComment = ""
    
    var body: some View {
        VStack {
            Text("Comments (\(comments.count))")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView {
                LazyVStack(alignment: .leading) {
                    ForEach(comments) { comment in
                        VStack(alignment: .leading) {
                            HStack {
                                Circle()
                                    .fill(Color.gray)
                                    .frame(width: 30, height: 30)
                                
                                Text("User \(comment.userId.prefix(8))")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                
                                Spacer()
                                
                                Text(comment.timestamp, style: .time)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(comment.text)
                                .padding(.leading, 40)
                            
                            HStack {
                                Spacer()
                                Button {
                                    // TODO: Implement like functionality
                                } label: {
                                    Label("\(comment.likes)", systemImage: "heart")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal)
                    }
                }
            }
            
            HStack {
                TextField("Add a comment...", text: $newComment)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button {
                    // TODO: Implement add comment functionality
                } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.accentColor)
                }
            }
            .padding()
        }
    }
}

struct JoinMeetView: View {
    @ObservedObject var viewModel: MeetViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedVehicle: Vehicle?
    @State private var isJoining = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    let meet: Meet
    
    init(meet: Meet, viewModel: MeetViewModel) {
        self.meet = meet
        self.viewModel = viewModel
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Select a vehicle to join with")
                    .font(.headline)
                    .padding()
                
                ScrollView {
                    LazyVStack {
                        ForEach(viewModel.currentUser?.vehicles ?? []) { vehicle in
                            VehicleSelectionRow(vehicle: vehicle, isSelected: selectedVehicle?.id == vehicle.id) {
                                selectedVehicle = vehicle
                            }
                        }
                    }
                    .padding()
                }
                
                Button {
                    Task {
                        isJoining = true
                        do {
                            try await viewModel.joinMeet(meet)
                            presentationMode.wrappedValue.dismiss()
                        } catch {
                            alertMessage = "Failed to join meet. Please try again."
                            showAlert = true
                        }
                        isJoining = false
                    }
                } label: {
                    if isJoining {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Join Meet")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedVehicle == nil ? Color.gray : Color.accentColor)
                .cornerRadius(10)
                .padding()
                .disabled(selectedVehicle == nil || isJoining)
            }
            .navigationTitle("Join Meet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

struct VehicleSelectionRow: View {
    let vehicle: Vehicle
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            // Image section
            let iconName = vehicle.type == .car ? "car.fill" : "bicycle"
            
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 40, height: 40)
                .background(Color.accentColor.opacity(0.1))
            
            VStack(alignment: .leading) {
                Text("\(vehicle.make) \(vehicle.model)")
                    .font(.headline)
                
                // Break up the complex expression
                let vehicleDetails = "\(vehicle.year) • \(vehicle.type.rawValue.capitalized)"
                Text(vehicleDetails)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
            }
        }
        .padding()
        
        // Break up the complex background modifier
        .background(backgroundFill)
        .overlay(selectionStroke)
        .onTapGesture {
            onTap()
        }
    }
    
    // Extract complex views into computed properties
    private var backgroundFill: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.gray.opacity(0.1))
    }
    
    private var selectionStroke: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
    }
} 
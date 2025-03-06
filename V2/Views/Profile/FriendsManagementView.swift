import SwiftUI

struct FriendsManagementView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var searchText = ""
    @State private var showingAddFriend = false
    @State private var showingPendingRequests = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var friends: [User] = []
    @State private var pendingRequests: [FriendRequestViewModel] = []
    
    var body: some View {
        NavigationView {
            List {
                // Search Bar
                Section {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search Friends", text: $searchText)
                            .autocapitalization(.none)
                    }
                }
                
                // Friend Requests
                Section {
                    Button {
                        showingPendingRequests = true
                    } label: {
                        HStack {
                            Image(systemName: "person.badge.plus")
                                .foregroundColor(.blue)
                                .frame(width: 32, height: 32)
                            
                            Text("Friend Requests")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if !pendingRequests.isEmpty {
                                Text("\(pendingRequests.count)")
                                    .foregroundColor(.white)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.red)
                                    .clipShape(Capsule())
                            }
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    
                    Button {
                        showingAddFriend = true
                    } label: {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .foregroundColor(.blue)
                                .frame(width: 32, height: 32)
                            
                            Text("Add Friend")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                }
                
                // Friends List
                if !friends.isEmpty {
                    Section(header: Text("Your Friends")) {
                        ForEach(filteredFriends) { friend in
                            NavigationLink(destination: FriendProfileView(user: friend)) {
                                HStack(spacing: 16) {
                                    // Profile Image
                                    if let avatarUrl = friend.profile.avatarUrl, !avatarUrl.isEmpty {
                                        AsyncImage(url: URL(string: avatarUrl)) { image in
                                            image
                                                .resizable()
                                                .scaledToFill()
                                        } placeholder: {
                                            Image(systemName: "person.circle.fill")
                                                .resizable()
                                                .foregroundColor(.secondary)
                                        }
                                        .frame(width: 50, height: 50)
                                        .clipShape(Circle())
                                    } else if !friend.profile.avatar.isEmpty {
                                        // Fallback to legacy avatar field
                                        AsyncImage(url: URL(string: friend.profile.avatar)) { image in
                                            image
                                                .resizable()
                                                .scaledToFill()
                                        } placeholder: {
                                            Image(systemName: "person.circle.fill")
                                                .resizable()
                                                .foregroundColor(.secondary)
                                        }
                                        .frame(width: 50, height: 50)
                                        .clipShape(Circle())
                                    } else {
                                        Image(systemName: "person.circle.fill")
                                            .resizable()
                                            .frame(width: 50, height: 50)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(friend.profile.name)
                                            .font(.headline)
                                        
                                        Text(friend.profile.location.address)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                } else if !isLoading {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: "person.3.sequence.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                                .padding()
                            
                            Text("No Friends Yet")
                                .font(.headline)
                            
                            Text("Add friends to see their meets and vehicles.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .padding(.bottom)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Friends")
            .refreshable {
                await loadFriends()
                await loadPendingRequests()
            }
            .overlay {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                }
            }
            .alert(isPresented: .constant(errorMessage != nil)) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage ?? "Unknown error"),
                    dismissButton: .default(Text("OK")) {
                        errorMessage = nil
                    }
                )
            }
            .sheet(isPresented: $showingAddFriend) {
                AddFriendView { success in
                    if success {
                        Task {
                            await loadPendingRequests()
                        }
                    }
                }
            }
            .sheet(isPresented: $showingPendingRequests) {
                FriendRequestsView(requests: pendingRequests) { success in
                    if success {
                        Task {
                            await loadFriends()
                            await loadPendingRequests()
                        }
                    }
                }
            }
            .onAppear {
                Task {
                    await loadFriends()
                    await loadPendingRequests()
                }
            }
        }
    }
    
    private var filteredFriends: [User] {
        if searchText.isEmpty {
            return friends
        } else {
            return friends.filter { friend in
                friend.profile.name.localizedCaseInsensitiveContains(searchText) ||
                friend.email.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func loadFriends() async {
        guard let currentUser = authManager.currentUser else { return }
        
        isLoading = true
        
        let friendIds = currentUser.friends
        var loadedFriends: [User] = []
        
        for friendId in friendIds {
            if let friend = try? await UserService.shared.fetchUser(id: friendId) {
                loadedFriends.append(friend)
            }
        }
        
        self.friends = loadedFriends
        isLoading = false
    }
    
    private func loadPendingRequests() async {
        isLoading = true
        
        // Remove the unreachable catch block and directly set mock data
        // For now, we'll use mock data
        self.pendingRequests = []
        
        isLoading = false
    }
}

struct AddFriendView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    let onComplete: (Bool) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Add by Email")) {
                    TextField("Email Address", text: $email)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .disabled(isLoading)
                    
                    Button {
                        Task {
                            await sendFriendRequest()
                        }
                    } label: {
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Send Request")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(email.isEmpty || isLoading)
                    .buttonStyle(.bordered)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
                
                if let success = successMessage {
                    Section {
                        Text(success)
                            .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle("Add Friend")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                        onComplete(successMessage != nil)
                    }
                }
            }
        }
    }
    
    private func sendFriendRequest() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            // Here you'd call your API to send the friend request
            // For now, we'll simulate a successful request
            try await Task.sleep(nanoseconds: 1_000_000_000)
            successMessage = "Friend request sent to \(email)"
        } catch {
            errorMessage = "Failed to send request: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

struct FriendRequestsView: View {
    let requests: [FriendRequestViewModel]
    let onComplete: (Bool) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            List {
                if requests.isEmpty {
                    Section {
                        VStack(spacing: 16) {
                            Image(systemName: "person.crop.circle.badge.checkmark")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                                .padding()
                            
                            Text("No Pending Requests")
                                .font(.headline)
                            
                            Text("You don't have any pending friend requests at the moment.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                } else {
                    Section(header: Text("Pending Requests")) {
                        ForEach(requests) { request in
                            HStack {
                                // Profile Image
                                if let avatarUrl = request.sender.profile.avatarUrl, !avatarUrl.isEmpty {
                                    AsyncImage(url: URL(string: avatarUrl)) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    } placeholder: {
                                        Image(systemName: "person.circle.fill")
                                            .resizable()
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                                } else if !request.sender.profile.avatar.isEmpty {
                                    // Fallback to legacy avatar field
                                    AsyncImage(url: URL(string: request.sender.profile.avatar)) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    } placeholder: {
                                        Image(systemName: "person.circle.fill")
                                            .resizable()
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .frame(width: 50, height: 50)
                                        .foregroundColor(.secondary)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(request.sender.profile.name)
                                        .font(.headline)
                                    
                                    Text(request.formattedTimestamp)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                HStack(spacing: 8) {
                                    Button {
                                        Task {
                                            await handleRequest(request, accept: true)
                                        }
                                    } label: {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.title2)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Button {
                                        Task {
                                            await handleRequest(request, accept: false)
                                        }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                            .font(.title2)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 4)
                            .disabled(isLoading)
                        }
                    }
                }
            }
            .navigationTitle("Friend Requests")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                        onComplete(true)
                    }
                }
            }
            .overlay {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                }
            }
        }
    }
    
    private func handleRequest(_ request: FriendRequestViewModel, accept: Bool) async {
        isLoading = true
        
        // Simulate a delay without try/catch since there's no real API call yet
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Additional processing would go here
        print("Handled friend request (accept: \(accept))")
        
        isLoading = false
    }
}

struct FriendProfileView: View {
    let user: User
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Profile Header
                ZStack(alignment: .bottom) {
                    // Background
                    LinearGradient(
                        gradient: Gradient(colors: [.blue.opacity(0.8), .purple.opacity(0.8)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 200)
                    
                    // Profile Image and Name
                    VStack {
                        if let avatarUrl = user.profile.avatarUrl, !avatarUrl.isEmpty {
                            AsyncImage(url: URL(string: avatarUrl)) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .foregroundColor(.white)
                            }
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 3))
                        } else if !user.profile.avatar.isEmpty {
                            // Fallback to legacy avatar field
                            AsyncImage(url: URL(string: user.profile.avatar)) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .foregroundColor(.white)
                            }
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 3))
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 120)
                                .foregroundColor(.white)
                        }
                        
                        Text(user.profile.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .offset(y: 60)
                }
                .padding(.bottom, 60)
                
                // Friend Details
                VStack(spacing: 20) {
                    // Bio
                    if !user.profile.bio.isEmpty {
                        ProfileSection(title: "About") {
                            Text(user.profile.bio)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Location
                    if !user.profile.location.address.isEmpty {
                        ProfileSection(title: "Location") {
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.blue)
                                Text(user.profile.location.address)
                            }
                            .font(.body)
                            .foregroundColor(.secondary)
                        }
                    }
                    
                    // Vehicles
                    if !user.vehicles.isEmpty && user.preferences.privacySettings.showVehicles {
                        ProfileSection(title: "Vehicles") {
                            ForEach(user.vehicles) { vehicle in
                                VehicleCard(vehicle: vehicle, user: user)
                            }
                        }
                    }
                    
                    // Social Media
                    if user.preferences.privacySettings.showSocial &&
                       (user.profile.social?.instagram.isEmpty == false ||
                        user.profile.social?.facebook.isEmpty == false ||
                        user.profile.social?.twitter.isEmpty == false) {
                        ProfileSection(title: "Social Media") {
                            VStack(alignment: .leading, spacing: 12) {
                                if user.profile.social?.instagram.isEmpty == false {
                                    SocialMediaRow(platform: "Instagram", username: user.profile.social?.instagram ?? "", icon: "camera.fill")
                                }
                                
                                if user.profile.social?.facebook.isEmpty == false {
                                    SocialMediaRow(platform: "Facebook", username: user.profile.social?.facebook ?? "", icon: "f.square.fill")
                                }
                                
                                if user.profile.social?.twitter.isEmpty == false {
                                    SocialMediaRow(platform: "Twitter", username: user.profile.social?.twitter ?? "", icon: "message.fill")
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle(user.profile.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SocialMediaRow: View {
    let platform: String
    let username: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text("\(platform): \(username)")
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }
}

struct FriendRequestViewModel: Identifiable {
    let id: UUID
    let senderId: String
    let receiverId: String
    let status: String
    let timestamp: Date
    let sender: User
    
    var formattedTimestamp: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

struct ProfileSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            content
                .padding(.leading, 4)
            
            Divider()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }
}

#Preview {
    FriendsManagementView()
        .environmentObject(AuthManager())
}

#Preview {
    AddFriendView { _ in }
}

#Preview {
    let mockUser = User(
        id: "123",
        email: "friend@example.com",
        profile: User.Profile(
            name: "John Doe",
            avatar: "",
            bio: "Car enthusiast from California",
            location: User.Profile.Location(latitude: 0, longitude: 0, address: "San Francisco, CA"),
            joinDate: Date(),
            social: User.Profile.Social(instagram: "johndoe", facebook: "johndoefb", twitter: "johndoetwt")
        ),
        vehicles: [
            Vehicle(
                id: "v1",
                userId: "user1",
                make: "BMW",
                model: "M3",
                year: 2022,
                type: .car,
                modifications: ["Custom exhaust", "Lowered suspension"],
                photos: [],
                createdAt: Date(),
                updatedAt: Date()
            )
        ],
        friends: [],
        isPremium: false,
        achievements: [],
        preferences: User.Preferences.defaultPreferences
    )
    
    FriendProfileView(user: mockUser)
} 

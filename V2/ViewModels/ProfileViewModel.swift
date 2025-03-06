import SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showingImagePicker = false
    @Published var showingAddVehicle = false
    @Published var showingSettings = false
    @Published var profileImage: UIImage?
    
    private let userService = UserService.shared
    private let authManager: AuthManager
    private let imageUploadService = ImageUploadService.shared
    
    init(authManager: AuthManager) {
        self.authManager = authManager
        loadProfileImage()
    }
    
    func loadProfileImage() {
        // Try to load from avatarUrl first, then fall back to legacy avatar field
        guard let user = authManager.currentUser else { return }
        
        let avatarUrlString: String?
        
        if let url = user.profile.avatarUrl, !url.isEmpty {
            avatarUrlString = url
        } else if !user.profile.avatar.isEmpty {
            avatarUrlString = user.profile.avatar
        } else {
            return
        }
        
        guard let urlString = avatarUrlString, let url = URL(string: urlString) else { return }
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        self.profileImage = image
                    }
                }
            } catch {
                print("Error loading profile image: \(error)")
            }
        }
    }
    
    func updateProfile(_ profile: User.Profile) async {
        isLoading = true
        
        var updatedUser = authManager.currentUser!
        updatedUser.profile = profile
        await authManager.updateProfile(updatedUser)
        loadProfileImage()
        
        isLoading = false
    }
    
    func uploadProfileImage(_ image: UIImage) async {
        isLoading = true
        
        do {
            guard let userId = authManager.currentUser?.id else {
                throw NSError(domain: "ProfileViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "User ID not available"])
            }
            
            let avatarUrl = try await imageUploadService.uploadAvatar(image, userId: userId)
            
            var updatedUser = authManager.currentUser!
            updatedUser.profile.avatarUrl = avatarUrl
            await authManager.updateProfile(updatedUser)
            self.profileImage = image
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func addVehicle(_ vehicle: Vehicle) async {
        isLoading = true
        
        var updatedUser = authManager.currentUser!
        updatedUser.vehicles.append(vehicle)
        await authManager.updateProfile(updatedUser)
        
        isLoading = false
    }
    
    func deleteVehicle(at indexSet: IndexSet) async {
        isLoading = true
        
        var updatedUser = authManager.currentUser!
        updatedUser.vehicles.remove(atOffsets: indexSet)
        await authManager.updateProfile(updatedUser)
        
        isLoading = false
    }
    
    func signOut() async {
        isLoading = true
        await authManager.signOut()
        isLoading = false
    }
} 
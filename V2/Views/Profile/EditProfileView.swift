import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthManager
    @State private var name: String = ""
    @State private var bio: String = ""
    @State private var location: String = ""
    @State private var instagram: String = ""
    @State private var facebook: String = ""
    @State private var twitter: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    // Avatar selection states
    @State private var selectedImage: UIImage?
    @State private var isShowingPhotoPicker = false
    @State private var isUploadingAvatar = false
    
    var body: some View {
        NavigationView {
            Form {
                // Avatar Section
                Section {
                    VStack {
                        ZStack {
                            // Avatar display
                            if let selectedImage = selectedImage {
                                Image(uiImage: selectedImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                    .shadow(radius: 7)
                            } else if let user = authManager.currentUser, let avatarUrl = user.profile.avatarUrl, !avatarUrl.isEmpty {
                                AsyncImage(url: URL(string: avatarUrl)) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    ProgressView()
                                }
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                .shadow(radius: 7)
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 120, height: 120)
                                    .foregroundColor(.gray)
                                    .shadow(radius: 7)
                            }
                            
                            // Edit button overlay
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        isShowingPhotoPicker = true
                                    }) {
                                        Image(systemName: "pencil.circle.fill")
                                            .font(.system(size: 30))
                                            .foregroundColor(.blue)
                                            .background(Color.white)
                                            .clipShape(Circle())
                                            .shadow(radius: 2)
                                    }
                                    .disabled(isUploadingAvatar)
                                    .sheet(isPresented: $isShowingPhotoPicker) {
                                        PhotoPicker(image: $selectedImage) { image in
                                            // Handle successful image selection
                                            uploadAvatar(image)
                                        }
                                    }
                                }
                            }
                            .frame(width: 120, height: 120)
                            
                            // Upload indicator
                            if isUploadingAvatar {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .frame(width: 120, height: 120)
                                    .background(Color.black.opacity(0.4))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.vertical)
                        
                        Text("Tap to change profile picture")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                Section(header: Text("Profile Information")) {
                    EditProfileField(title: "Name", text: $name, icon: "person.fill")
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bio")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $bio)
                            .frame(height: 100)
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                    }
                    
                    EditProfileField(title: "Location", text: $location, icon: "location.fill")
                }
                
                Section(header: Text("Social Media")) {
                    EditProfileField(title: "Instagram", text: $instagram, icon: "camera.fill")
                    EditProfileField(title: "Facebook", text: $facebook, icon: "f.square.fill")
                    EditProfileField(title: "Twitter", text: $twitter, icon: "bird.fill")
                }
                
                Section {
                    Button(action: saveProfile) {
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Save Changes")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(isLoading)
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
            .navigationTitle("Edit Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadUserData()
            }
        }
    }
    
    private func loadUserData() {
        guard let user = authManager.currentUser else { return }
        
        name = user.profile.name
        bio = user.profile.bio
        location = user.profile.location.address
        instagram = user.profile.social?.instagram ?? ""
        facebook = user.profile.social?.facebook ?? ""
        twitter = user.profile.social?.twitter ?? ""
    }
    
    private func uploadAvatar(_ image: UIImage) {
        guard let userId = authManager.currentUser?.id else { return }
        
        isUploadingAvatar = true
        
        Task {
            do {
                let avatarUrl = try await ImageUploadService.shared.uploadAvatar(image, userId: userId)
                
                // Save to user profile
                if var user = authManager.currentUser {
                    user.profile.avatarUrl = avatarUrl
                    await authManager.updateProfile(user)
                    
                    await MainActor.run {
                        isUploadingAvatar = false
                        successMessage = "Profile picture updated!"
                    }
                }
            } catch {
                print("Error uploading avatar: \(error)")
                
                await MainActor.run {
                    isUploadingAvatar = false
                    errorMessage = "Failed to upload profile picture. Please try again."
                }
            }
        }
    }
    
    private func saveProfile() {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        guard var user = authManager.currentUser else {
            isLoading = false
            errorMessage = "User data not available"
            return
        }
        
        // Update user profile data
        user.profile.name = name
        user.profile.bio = bio
        user.profile.location.address = location
        
        // Update social media links
        var social = user.profile.social ?? User.Profile.Social.empty
        social.instagram = instagram
        social.facebook = facebook
        social.twitter = twitter
        user.profile.social = social
        
        // Save to database
        Task {
            await authManager.updateProfile(user)
            
            await MainActor.run {
                successMessage = "Profile updated successfully"
                isLoading = false
            }
        }
    }
}

struct EditProfileField: View {
    let title: String
    @Binding var text: String
    let icon: String
    var isMultiline: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                if isMultiline {
                    TextEditor(text: $text)
                        .frame(height: 100)
                } else {
                    TextField(title, text: $text)
                }
            }
        }
    }
}

#Preview {
    EditProfileView()
        .environmentObject(AuthManager())
} 
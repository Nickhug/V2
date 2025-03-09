import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthManager
    @State private var name: String = ""
    @State private var bio: String = ""
    @State private var location: String = ""
    @State private var statusMessage: String = ""
    @State private var instagram: String = ""
    @State private var facebook: String = ""
    @State private var twitter: String = ""
    @State private var isLoading = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var showingSuccessToast = false
    @State private var activeSection: ProfileSection = .basic
    
    // Avatar selection states
    @State private var selectedImage: UIImage?
    @State private var isShowingPhotoPicker = false
    @State private var isUploadingAvatar = false
    
    // Form validation
    @State private var isFormValid = false
    
    enum ProfileSection: String, CaseIterable {
        case basic = "Basic Info"
        case social = "Social Media"
        case preferences = "Preferences"
    }
    
    var body: some View {
        ZStack {
            // Background
            AnimatedGradientBackground()
            
            // Main content
            VStack(spacing: 0) {
                // Header with close button
                headerView
                
                // Scrollable content
                ScrollView {
                    VStack(spacing: MeetSpotStyle.Spacing.large) {
                        // Avatar section
                        avatarSection
                            .padding(.top, MeetSpotStyle.Spacing.large)
                        
                        // Section tabs
                        sectionTabs
                        
                        // Form sections
                        formSection
                            .padding(.horizontal, MeetSpotStyle.Spacing.medium)
                            .padding(.bottom, MeetSpotStyle.Spacing.large)
                    }
                }
                
                // Save button at bottom
                saveButton
                    .padding()
            }
            
            // Loading overlay
            if isLoading {
                loadingOverlay
            }
            
            // Success toast
            if showingSuccessToast {
                successToast
            }
        }
        .onAppear {
            loadUserData()
            validateForm()
        }
        .onChange(of: name) { validateForm() }
        .onChange(of: bio) { validateForm() }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            // Title
            Text("Edit Profile")
                .font(MeetSpotStyle.Typography.heading2)
                .foregroundColor(.white)
            
            Spacer()
            
            // Close button
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.title3)
                    .foregroundColor(.black)
                    .padding(12)
                    .background(
                        Circle()
                            .fill(Color.white)
                            .overlay(
                                Circle()
                                    .stroke(Color.black, lineWidth: 1.5)
                            )
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 1)
            }
        }
        .padding()
        .background(Color.black.opacity(0.2))
    }
    
    // MARK: - Avatar Section
    private var avatarSection: some View {
        VStack(spacing: MeetSpotStyle.Spacing.medium) {
            ZStack {
                // Avatar display
                if let selectedImage = selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .mediumShadow()
                } else if let user = authManager.currentUser, let avatarUrl = user.profile.avatarUrl, !avatarUrl.isEmpty {
                    AsyncImage(url: URL(string: avatarUrl)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        ProgressView()
                            .tint(.white)
                    }
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .mediumShadow()
                } else {
                    Circle()
                        .fill(MeetSpotColors.accentGradient)
                        .frame(width: 120, height: 120)
                        .overlay(
                            Text(String(name.prefix(1).uppercased()))
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .mediumShadow()
                }
                
                // Edit button overlay
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            isShowingPhotoPicker = true
                        }) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(MeetSpotColors.accentGradient)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 1))
                                .subtleShadow()
                        }
                        .disabled(isUploadingAvatar)
                        .offset(x: 10, y: 10)
                    }
                }
                .frame(width: 110, height: 110)
                
                // Upload indicator
                if isUploadingAvatar {
                    Circle()
                        .fill(Color.black.opacity(0.6))
                        .frame(width: 120, height: 120)
                        .overlay(
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(1.5)
                        )
                }
            }
            
            Text(authManager.currentUser?.email ?? "")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
        .sheet(isPresented: $isShowingPhotoPicker) {
            PhotoPicker(image: $selectedImage) { image in
                uploadAvatar(image)
            }
        }
    }
    
    // MARK: - Section Tabs
    private var sectionTabs: some View {
        HStack(spacing: 0) {
            ForEach(ProfileSection.allCases, id: \.self) { section in
                Button(action: {
                    withAnimation {
                        activeSection = section
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(section.rawValue)
                            .font(.subheadline)
                            .fontWeight(activeSection == section ? .semibold : .regular)
                            .foregroundColor(activeSection == section ? .white : .white.opacity(0.6))
                        
                        Rectangle()
                            .fill(activeSection == section ? Color.black : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.1))
    }
    
    // MARK: - Form Sections
    private var formSection: some View {
        VStack(spacing: MeetSpotStyle.Spacing.large) {
            switch activeSection {
            case .basic:
                basicInfoSection
            case .social:
                socialMediaSection
            case .preferences:
                preferencesSection
            }
        }
    }
    
    private var basicInfoSection: some View {
        VStack(spacing: MeetSpotStyle.Spacing.medium) {
            ModernTextField(
                title: "Name",
                text: $name,
                icon: "person.fill",
                placeholder: "Your full name"
            )
            
            ModernTextField(
                title: "Status Message",
                text: $statusMessage,
                icon: "quote.bubble.fill",
                placeholder: "What's on your mind?"
            )
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "text.alignleft")
                        .foregroundColor(MeetSpotColors.pink500)
                    
                    Text("Bio")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                TextEditor(text: $bio)
                    .foregroundColor(.white)
                    .frame(height: 100)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: MeetSpotStyle.Radius.medium)
                            .fill(Material.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: MeetSpotStyle.Radius.medium)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .mediumShadow()
            }
            
            ModernTextField(
                title: "Location",
                text: $location,
                icon: "location.fill",
                placeholder: "Your city or location"
            )
        }
    }
    
    private var socialMediaSection: some View {
        VStack(spacing: MeetSpotStyle.Spacing.medium) {
            ModernTextField(
                title: "Instagram",
                text: $instagram,
                icon: "camera.fill",
                placeholder: "Your Instagram handle"
            )
            
            ModernTextField(
                title: "Facebook",
                text: $facebook,
                icon: "f.square.fill",
                placeholder: "Your Facebook profile"
            )
            
            ModernTextField(
                title: "Twitter",
                text: $twitter,
                icon: "bird.fill",
                placeholder: "Your Twitter handle"
            )
            
            // Social media preview
            previewCard
        }
    }
    
    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Profile Preview")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                    } else if let user = authManager.currentUser, let avatarUrl = user.profile.avatarUrl, !avatarUrl.isEmpty {
                        AsyncImage(url: URL(string: avatarUrl)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            ProgressView()
                                .tint(.white)
                        }
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(MeetSpotColors.accentGradient)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Text(String(name.prefix(1).uppercased()))
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(name.isEmpty ? "Your Name" : name)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(statusMessage.isEmpty ? "Your status message" : statusMessage)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    if !instagram.isEmpty {
                        socialRow(icon: "camera.fill", platform: "Instagram", handle: instagram)
                    }
                    
                    if !facebook.isEmpty {
                        socialRow(icon: "f.square.fill", platform: "Facebook", handle: facebook)
                    }
                    
                    if !twitter.isEmpty {
                        socialRow(icon: "bird.fill", platform: "Twitter", handle: twitter)
                    }
                    
                    if instagram.isEmpty && facebook.isEmpty && twitter.isEmpty {
                        Text("Add your social media profiles to see them here")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.top, 8)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: MeetSpotStyle.Radius.medium)
                    .fill(Material.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: MeetSpotStyle.Radius.medium)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .mediumShadow()
        }
        .padding(.top, 8)
    }
    
    private func socialRow(icon: String, platform: String, handle: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.black)
                .frame(width: 20)
            
            Text(platform)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 70, alignment: .leading)
            
            Text(handle)
                .font(.caption)
                .foregroundColor(.white)
                .lineLimit(1)
        }
    }
    
    private var preferencesSection: some View {
        VStack(spacing: MeetSpotStyle.Spacing.large) {
            // Preferences would go here in a future implementation
            // For now, showing a placeholder
            
            VStack(alignment: .center, spacing: 16) {
                Image(systemName: "gear")
                    .font(.system(size: 48))
                    .foregroundColor(.black)
                
                Text("Preferences Coming Soon")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Advanced preferences and settings will be available in a future update.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
        }
    }
    
    // MARK: - Save Button
    private var saveButton: some View {
        Button(action: saveProfile) {
            HStack {
                if isSaving {
                    ProgressView()
                        .tint(.black)
                        .padding(.trailing, 10)
                }
                
                Text("Save Changes")
                    .font(.headline)
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                isFormValid 
                ? Color.white
                : Color.white.opacity(0.5)
            )
            .cornerRadius(MeetSpotStyle.Radius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: MeetSpotStyle.Radius.medium)
                    .stroke(Color.black, lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 1)
        }
        .disabled(!isFormValid || isSaving)
    }
    
    // MARK: - Loading Overlay
    private var loadingOverlay: some View {
        Color.black.opacity(0.7)
            .ignoresSafeArea()
            .overlay(
                VStack(spacing: 20) {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(2)
                    
                    Text("Loading...")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            )
    }
    
    // MARK: - Success Toast
    private var successToast: some View {
        VStack {
            Spacer()
            
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                
                Text("Profile updated successfully")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: MeetSpotStyle.Radius.medium)
                    .fill(Material.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: MeetSpotStyle.Radius.medium)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .mediumShadow()
            .padding()
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    // MARK: - Private Methods
    private func loadUserData() {
        isLoading = true
        
        guard let user = authManager.currentUser else {
            isLoading = false
            errorMessage = "User data not available"
            return
        }
        
        name = user.profile.name
        bio = user.profile.bio
        location = user.profile.location.address
        statusMessage = user.profile.statusMessage ?? ""
        instagram = user.profile.social?.instagram ?? ""
        facebook = user.profile.social?.facebook ?? ""
        twitter = user.profile.social?.twitter ?? ""
        
        isLoading = false
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
                        showSuccessToast("Profile picture updated!")
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
    
    private func validateForm() {
        isFormValid = !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func saveProfile() {
        guard isFormValid else { return }
        
        isSaving = true
        errorMessage = nil
        
        guard var user = authManager.currentUser else {
            isSaving = false
            errorMessage = "User data not available"
            return
        }
        
        // Update user profile data
        user.profile.name = name
        user.profile.bio = bio
        user.profile.location.address = location
        user.profile.statusMessage = statusMessage
        
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
                isSaving = false
                showSuccessToast("Profile updated successfully")
            }
        }
    }
    
    private func showSuccessToast(_ message: String) {
        successMessage = message
        withAnimation {
            showingSuccessToast = true
        }
        
        // Hide toast after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                showingSuccessToast = false
            }
        }
    }
}

// MARK: - Supporting Views
struct ModernTextField: View {
    let title: String
    @Binding var text: String
    let icon: String
    var placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(MeetSpotColors.pink500)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            TextField("", text: $text)
                .foregroundColor(.white)
                .viewPlaceholder(when: text.isEmpty) {
                    Text(placeholder)
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: MeetSpotStyle.Radius.medium)
                        .fill(Material.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: MeetSpotStyle.Radius.medium)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
                .mediumShadow()
        }
    }
}

struct EditProfileView_Previews: PreviewProvider {
    static var previews: some View {
        EditProfileView()
            .environmentObject(AuthManager())
    }
} 
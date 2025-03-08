import SwiftUI
import Foundation
import PhotosUI

@MainActor
class AuthViewModel: ObservableObject {
    // Auth state properties
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showError = false
    @Published var currentView: AuthViewType = .welcome
    
    // Login form
    @Published var loginEmail = ""
    @Published var loginPassword = ""
    @Published var rememberMe = true
    
    // Signup form
    @Published var signupEmail = ""
    @Published var signupPassword = ""
    @Published var confirmPassword = ""
    
    // Onboarding
    @Published var onboardingState = OnboardingState()
    @Published var selectedImage: PhotosPickerItem?
    @Published var isOnboardingComplete = false
    
    // Dependencies
    private let authManager: AuthManager
    
    // Default initializer that handles the @MainActor context properly
    init() {
        self.authManager = AuthManager()
    }
    
    // Initializer with dependency injection
    init(authManager: AuthManager) {
        self.authManager = authManager
    }
    
    // MARK: - Navigation
    
    func showLogin() {
        withAnimation {
            currentView = .login
        }
    }
    
    func showSignup() {
        withAnimation {
            currentView = .signup
        }
    }
    
    func showForgotPassword() {
        withAnimation {
            currentView = .forgotPassword
        }
    }
    
    // MARK: - Authentication
    
    func login() async {
        isLoading = true
        
        // Reset error state
        error = nil
        
        do {
            await authManager.logIn(loginEmail, loginPassword)
            
            // Check if there was an error in the auth manager
            if let authError = authManager.error {
                error = authError
                showError = true
            }
        }
        
        isLoading = false
    }
    
    func signUp() async {
        isLoading = true
        error = nil
        
        do {
            await authManager.signUp(signupEmail, signupPassword, onboardingState.name)
            
            // Check if there was an error in the auth manager
            if let authError = authManager.error {
                error = authError
                showError = true
            } else {
                // Success - move to onboarding
                withAnimation {
                    currentView = .onboarding
                }
            }
        }
        
        isLoading = false
    }
    
    func signOut() async {
        isLoading = true
        
        do {
            // Use authManager to sign out instead of directly accessing supabase
            try await authManager.signOut()
        } catch {
            self.error = error
            showError = true
        }
        
        isLoading = false
    }
    
    // MARK: - Form Validation
    
    private func validateLoginForm() -> Bool {
        guard !loginEmail.isEmpty else {
            error = NSError(domain: "auth", code: 1, userInfo: [NSLocalizedDescriptionKey: "Email is required"])
            showError = true
            return false
        }
        
        guard !loginPassword.isEmpty else {
            error = NSError(domain: "auth", code: 2, userInfo: [NSLocalizedDescriptionKey: "Password is required"])
            showError = true
            return false
        }
        
        return true
    }
    
    private func validateSignupForm() -> Bool {
        guard !signupEmail.isEmpty else {
            error = NSError(domain: "auth", code: 1, userInfo: [NSLocalizedDescriptionKey: "Email is required"])
            showError = true
            return false
        }
        
        guard !signupPassword.isEmpty else {
            error = NSError(domain: "auth", code: 2, userInfo: [NSLocalizedDescriptionKey: "Password is required"])
            showError = true
            return false
        }
        
        guard signupPassword == confirmPassword else {
            error = NSError(domain: "auth", code: 3, userInfo: [NSLocalizedDescriptionKey: "Passwords do not match"])
            showError = true
            return false
        }
        
        // Email validation
        guard signupEmail.contains("@") && signupEmail.contains(".") else {
            error = NSError(domain: "auth", code: 4, userInfo: [NSLocalizedDescriptionKey: "Please enter a valid email"])
            showError = true
            return false
        }
        
        // Password strength validation
        guard signupPassword.count >= 8 else {
            error = NSError(domain: "auth", code: 5, userInfo: [NSLocalizedDescriptionKey: "Password must be at least 8 characters"])
            showError = true
            return false
        }
        
        return true
    }
    
    // MARK: - Onboarding
    
    func completeOnboarding() async {
        guard let userId = authManager.currentUser?.id else {
            error = NSError(domain: "auth", code: 100, userInfo: [NSLocalizedDescriptionKey: "User ID not found"])
            showError = true
            return
        }
        
        onboardingState.isLoading = true
        
        do {
            // Create user profile
            let profile = onboardingState.createUserProfile(for: userId)
            
            // Update user in database
            if onboardingState.avatar != nil {
                // TODO: Upload avatar image to storage
                // This would be implemented with Supabase storage
            }
            
            // Fix User.Preferences initialization with proper structure
            let notificationPrefs = User.Preferences.NotificationPreferences(
                newMeets: onboardingState.preferences.notificationsEnabled,
                meetUpdates: onboardingState.preferences.notificationsEnabled,
                friendRequests: onboardingState.preferences.notificationsEnabled,
                comments: onboardingState.preferences.notificationsEnabled
            )
            
            let privacySettings = User.Preferences.PrivacySettings(
                showVehicles: true,
                showLocation: onboardingState.preferences.locationSharingEnabled,
                showSocial: true
            )
            
            // Update user preferences
            let user = User(
                id: userId,
                email: signupEmail,
                profile: profile,
                vehicles: [],
                friends: [],
                isPremium: false,
                achievements: [],
                preferences: User.Preferences(
                    darkMode: onboardingState.preferences.darkModeEnabled,
                    notifications: notificationPrefs,
                    privacySettings: privacySettings
                ),
                upcomingMeets: nil
            )
            
            // Use authManager to update user instead of directly accessing supabase
            try await authManager.updateUserProfile(user)
            
            // Update current user in AuthManager
            authManager.currentUser = user
            
            // Mark onboarding as complete
            isOnboardingComplete = true
            currentView = .complete
        } catch {
            onboardingState.errorMessage = error.localizedDescription
            onboardingState.showError = true
        }
        
        onboardingState.isLoading = false
    }
    
    func handlePhotoSelection() async {
        guard let selectedItem = selectedImage else { return }
        
        do {
            if let data = try await selectedItem.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                let resizedImage = await resizeImage(image, targetSize: CGSize(width: 400, height: 400))
                onboardingState.avatar = resizedImage
            }
        } catch {
            onboardingState.errorMessage = "Failed to load image: \(error.localizedDescription)"
            onboardingState.showError = true
        }
    }
    
    private func resizeImage(_ image: UIImage, targetSize: CGSize) async -> UIImage {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let size = image.size
                let widthRatio  = targetSize.width  / size.width
                let heightRatio = targetSize.height / size.height
                let ratio = min(widthRatio, heightRatio)
                let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
                
                let format = UIGraphicsImageRendererFormat()
                format.scale = 1
                
                let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
                let resizedImage = renderer.image { context in
                    image.draw(in: CGRect(origin: .zero, size: newSize))
                }
                
                continuation.resume(returning: resizedImage)
            }
        }
    }
}

// View types for auth flow
enum AuthViewType {
    case welcome
    case login
    case signup
    case forgotPassword
    case onboarding
    case complete
} 
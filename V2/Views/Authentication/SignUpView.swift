import SwiftUI
import PhotosUI

@available(iOS 16.0, *)
struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var name = ""
    @State private var bio = ""
    @State private var location = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var currentStep = 0
    
    // Photo selection states
    @State private var selectedImage: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var isUploadingAvatar = false
    
    var body: some View {
        ZStack {
            // Replace static background with animated gradient
            AnimatedGradientBackground()
            
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Progress bar
                    ProgressView(value: Double(currentStep) / 2.0)
                        .tint(.white)
                        .padding()
                    
                    // Content
                    TabView(selection: $currentStep) {
                        // Step 1: Account Setup
                        accountSetupView
                            .tag(0)
                        
                        // Step 2: Profile Setup
                        profileSetupView
                            .tag(1)
                        
                        // Step 3: Final Setup
                        finalSetupView
                            .tag(2)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut, value: currentStep)
                    
                    // Navigation buttons
                    navigationButtons
                }
            }
        }
    }
    
    private var accountSetupView: some View {
        VStack(spacing: 24) {
            Text("Create Your Account")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.top, 40)
            
            VStack(spacing: 20) {
                // Email input
                FloatingTextField(
                    placeholder: "Email",
                    icon: "envelope.fill",
                    text: $email
                )
                
                // Password input
                FloatingTextField(
                    placeholder: "Password",
                    icon: "lock.fill",
                    text: $password,
                    isSecure: true
                )
                
                // Confirm Password input
                FloatingTextField(
                    placeholder: "Confirm Password",
                    icon: "lock.shield.fill",
                    text: $confirmPassword,
                    isSecure: true
                )
                
                // Password requirements
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password must contain:")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    HStack(spacing: 5) {
                        Image(systemName: password.count >= 8 ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(password.count >= 8 ? .green : .white.opacity(0.5))
                        
                        Text("At least 8 characters")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    HStack(spacing: 5) {
                        Image(systemName: password.rangeOfCharacter(from: .decimalDigits) != nil ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(password.rangeOfCharacter(from: .decimalDigits) != nil ? .green : .white.opacity(0.5))
                        
                        Text("At least 1 number")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal)
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
    
    private var profileSetupView: some View {
        VStack(spacing: 24) {
            Text("Your Profile")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.top, 40)
            
            // Profile Image Selection
            PhotosPicker(selection: $selectedImage, matching: .images) {
                VStack {
                    if let profileImage = profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 4))
                    } else {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "person.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                            
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.blue)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                }
                            }
                            .frame(width: 110, height: 110)
                        }
                    }
                    
                    Text("Add Profile Picture")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.top, 8)
                }
            }
            .onChange(of: selectedImage) { oldValue, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            profileImage = image
                        }
                    }
                }
            }
            
            VStack(spacing: 20) {
                // Name input
                FloatingTextField(
                    placeholder: "Full Name",
                    icon: "person.fill",
                    text: $name
                )
                
                // Bio input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bio (Optional)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                    
                    TextEditor(text: $bio)
                        .frame(height: 100)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .foregroundColor(.white)
                }
                .padding(.horizontal)
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
    
    private var finalSetupView: some View {
        VStack(spacing: 24) {
            Text("Almost Done!")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.top, 40)
            
            VStack(spacing: 20) {
                // Location input
                FloatingTextField(
                    placeholder: "Location (Optional)",
                    icon: "location.fill",
                    text: $location
                )
                
                // Additional setup info
                VStack(spacing: 16) {
                    setupInfoRow(icon: "bell.fill", title: "Notifications", description: "Stay updated with meets and messages")
                    setupInfoRow(icon: "car.fill", title: "Vehicle Setup", description: "Add your vehicles after signup")
                    setupInfoRow(icon: "person.2.fill", title: "Find Friends", description: "Connect with other enthusiasts")
                }
                .padding(.top)
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
    
    private func setupInfoRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var navigationButtons: some View {
        HStack(spacing: 20) {
            if currentStep > 0 {
                Button {
                    withAnimation {
                        currentStep -= 1
                    }
                } label: {
                    Text("Back")
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(width: 100)
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                }
            }
            
            Button {
                if currentStep < 2 {
                    withAnimation {
                        currentStep += 1
                    }
                } else {
                    createAccount()
                }
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                    }
                    Text(currentStep == 2 ? "Create Account" : "Next")
                        .fontWeight(.bold)
                }
                .foregroundColor(.black)
                .frame(maxWidth: currentStep == 0 ? .infinity : 100)
                .padding()
                .background(isStepValid ? Color.white : Color.white.opacity(0.5))
                .cornerRadius(12)
            }
            .disabled(!isStepValid || isLoading)
        }
        .padding()
    }
    
    private var isStepValid: Bool {
        switch currentStep {
        case 0:
            return !email.isEmpty && 
                   !password.isEmpty && 
                   password == confirmPassword && 
                   password.count >= 8 && 
                   email.contains("@") &&
                   password.rangeOfCharacter(from: .decimalDigits) != nil
        case 1:
            return !name.isEmpty
        case 2:
            return true
        default:
            return false
        }
    }
    
    private func createAccount() {
        isLoading = true
        errorMessage = nil
        
        Task {
            await authManager.signUp(email, password, name)
            dismiss()
            
            isLoading = false
        }
    }
}

#Preview {
    SignUpView()
        .environmentObject(AuthManager())
} 
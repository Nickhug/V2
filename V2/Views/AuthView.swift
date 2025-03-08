import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var confirmPassword = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Replace static background with animated gradient
                AnimatedGradientBackground()
                
                // Content
                ScrollView {
                    VStack(spacing: MeetSpotStyle.Spacing.large) {
                        // Logo and Title
                        VStack(spacing: MeetSpotStyle.Spacing.medium) {
                            Image("app-logo") // Make sure to add this to assets
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                            
                            Text("MeetSpot")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text(showSignUp ? "Create your account" : "Welcome back")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.top, 60)
                        
                        // Form Fields
                        VStack(spacing: MeetSpotStyle.Spacing.medium) {
                            if showSignUp {
                                AuthTextField(
                                    text: $name,
                                    placeholder: "Full Name",
                                    icon: "person.fill"
                                )
                            }
                            
                            AuthTextField(
                                text: $email,
                                placeholder: "Email",
                                icon: "envelope.fill"
                            )
                            
                            AuthTextField(
                                text: $password,
                                placeholder: "Password",
                                icon: "lock.fill",
                                isSecure: true
                            )
                            
                            if showSignUp {
                                AuthTextField(
                                    text: $confirmPassword,
                                    placeholder: "Confirm Password",
                                    icon: "lock.fill",
                                    isSecure: true
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        // Action Button
                        Button(action: handleAuthAction) {
                            HStack {
                                Text(showSignUp ? "Create Account" : "Sign In")
                                
                                if authManager.isLoading {
                                    // Simple Circle-based spinner animation
                                    Circle()
                                        .trim(from: 0, to: 0.7)
                                        .stroke(Color.white, lineWidth: 2)
                                        .frame(width: 20, height: 20)
                                        .rotationEffect(Angle(degrees: 270))
                                        .rotationEffect(Angle(degrees: authManager.isLoading ? 360 : 0))
                                        .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false), value: authManager.isLoading)
                                        .padding(.leading, 8)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .primaryButton()
                        .padding(.horizontal)
                        .disabled(authManager.isLoading)
                        
                        // Toggle Auth Mode
                        Button(action: { showSignUp.toggle() }) {
                            Text(showSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                                .foregroundColor(.white)
                                .underline()
                        }
                        .padding(.top, MeetSpotStyle.Spacing.small)
                    }
                    .padding()
                }
            }
            .alert("Error", isPresented: Binding(
                get: { authManager.error != nil },
                set: { if !$0 { authManager.error = nil } }
            )) {
                Button("OK") {}
            } message: {
                Text(authManager.error?.localizedDescription ?? "An error occurred")
            }
        }
    }
    
    private func handleAuthAction() {
        Task {
            if showSignUp {
                await authManager.signUp(email, password, name)
            } else {
                await authManager.logIn(email, password)
            }
        }
    }
}

struct AuthTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    var isSecure: Bool = false
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 24)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .textContentType(.password)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .foregroundColor(.white)
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(MeetSpotStyle.Radius.medium)
    }
} 
import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @EnvironmentObject private var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var rememberMe = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingSignUp = false
    @State private var showingForgotPassword = false
    
    var body: some View {
        ZStack {
            // Replace static background with animated gradient
            AnimatedGradientBackground()
            
            ScrollView {
                VStack(spacing: Theme.Spacing.extraLarge) {
                    // Logo and Welcome
                    VStack(spacing: Theme.Spacing.medium) {
                        Image("app-logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .shadow(color: Theme.Colors.accent.opacity(0.3),
                                  radius: Theme.shadowRadius,
                                  x: 0, y: 8)
                        
                        Text("Welcome Back")
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)
                        
                        Text("Sign in to continue")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.top, 48)
                    
                    // Login Form with glass effect
                    VStack(spacing: Theme.Spacing.large) {
                        FloatingTextField(
                            placeholder: "Email",
                            icon: "envelope",
                            text: $email
                        )
                        
                        FloatingTextField(
                            placeholder: "Password",
                            icon: "lock",
                            text: $password,
                            isSecure: true
                        )
                        
                        // Forgot Password Link
                        HStack {
                            Spacer()
                            Button {
                                showingForgotPassword = true
                            } label: {
                                Text("Forgot Password?")
                                    .font(.footnote)
                                    .foregroundColor(Theme.Colors.accent)
                            }
                        }
                        
                        // Error Message
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundColor(Theme.Colors.error)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        // Login Button
                        Button {
                            Task {
                                await login()
                            }
                        } label: {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .tint(Theme.Colors.text)
                                }
                                Text("Sign In")
                                    .font(.headline)
                                    .foregroundColor(Theme.Colors.text)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.Colors.accent)
                            .cornerRadius(Theme.CornerRadius.medium)
                        }
                        .disabled(isLoading)
                    }
                    .padding(Theme.Spacing.large)
                    .background(.ultraThinMaterial) // Glass effect
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                    .padding(.horizontal)
                    
                    // Social Login
                    VStack(spacing: Theme.Spacing.medium) {
                        Text("Or continue with")
                            .font(.footnote)
                            .foregroundColor(Theme.Colors.textSecondary)
                        
                        HStack(spacing: Theme.Spacing.large) {
                            SocialLoginButton(
                                iconName: "apple.logo",
                                color: Theme.Colors.surface
                            ) {
                                viewModel.signInWithApple()
                            }
                            
                            SocialLoginButton(
                                iconName: "g.circle.fill",
                                color: Theme.Colors.surface
                            ) {
                                viewModel.signInWithGoogle()
                            }
                        }
                    }
                    
                    // Sign Up Link
                    HStack(spacing: Theme.Spacing.small) {
                        Text("Don't have an account?")
                            .font(.footnote)
                            .foregroundColor(Theme.Colors.textSecondary)
                        
                        Button {
                            showingSignUp = true
                        } label: {
                            Text("Sign Up")
                                .font(.footnote)
                                .foregroundColor(Theme.Colors.accent)
                        }
                    }
                    .padding(.bottom, 48) // Using fixed value instead of huge
                }
                .padding()
            }
        }
        // No background color needed as the AnimatedGradientBackground is provided by ContentView
        .sheet(isPresented: $showingSignUp) {
            if #available(iOS 16.0, *) {
                SignUpView()
            }
        }
        .sheet(isPresented: $showingForgotPassword) {
            ForgotPasswordView()
        }
    }
    
    private func login() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let _ = try await Task { @MainActor in
                try await SupabaseService.shared.signIn(email: email, password: password)
            }.value
            await MainActor.run {
                isLoading = false
                authManager.isAuthenticated = true
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
}

struct SocialLoginButton: View {
    let iconName: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(Theme.Colors.text)
                .frame(width: 60, height: 60)
                .background(color)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Theme.Colors.textSecondary.opacity(0.1), lineWidth: 1)
                )
                .shadow(
                    color: Theme.shadowColor,
                    radius: Theme.shadowRadius * 0.5,
                    x: 0,
                    y: 4
                )
        }
    }
}

@MainActor
class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var error: Error?
    
    private let supabase: SupabaseService
    private let userService: UserService
    
    init(supabase: SupabaseService = .shared, userService: UserService = .shared) {
        self.supabase = supabase
        self.userService = userService
    }
    
    func signIn() async {
        isLoading = true
        error = nil
        
        do {
            let _ = try await supabase.signIn(email: email, password: password)
            // Handle successful sign in
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func signInWithApple() {
        // Implement Apple sign in
    }
    
    func signInWithGoogle() {
        // Implement Google sign in
    }
}

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Reset Password")) {
                    TextField("Email Address", text: $email)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .disabled(isLoading)
                    
                    Button {
                        resetPassword()
                    } label: {
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Send Reset Link")
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
                
                Section {
                    Button("Back to Login") {
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Forgot Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func resetPassword() {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if email.isEmpty || !email.contains("@") {
                errorMessage = "Please enter a valid email address"
            } else {
                successMessage = "Password reset link sent to \(email)"
            }
            isLoading = false
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager())
}

#Preview {
    ForgotPasswordView()
} 
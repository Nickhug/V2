import SwiftUI
import PhotosUI

@available(iOS 16.0, *)
struct SignUpView: View {
    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusField: FocusField?
    @State private var animateForm = false
    @State private var isLoading = false
    
    // Move enum declaration out of the struct so it can be accessed by SignUpScrollContent
    enum FocusField {
        case email, password, confirmPassword, name
    }
    
    // Create a binding that bridges between FocusState and regular Binding
    private var focusFieldBinding: Binding<FocusField?> {
        Binding(
            get: { self.focusField },
            set: { self.focusField = $0 }
        )
    }
    
    var body: some View {
        ZStack {
            // Background
            AnimatedGradientBackground()
            
            // Content
            SignUpScrollContent(
                viewModel: viewModel,
                focusField: focusFieldBinding,
                animateForm: $animateForm,
                isLoading: $isLoading
            )
        }
        .alert(isPresented: $viewModel.showError) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.error?.localizedDescription ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            // Animate form elements
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                animateForm = true
            }
            
            // Set initial focus to email field after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                focusField = .email
            }
        }
        // Add tap gesture to dismiss keyboard
        .onTapGesture {
            // Dismiss keyboard when tapping outside of input fields
            focusField = nil
        }
    }
}

// Helper struct to break down the complex view
struct SignUpScrollContent: View {
    @ObservedObject var viewModel: AuthViewModel
    @Binding var focusField: SignUpView.FocusField?
    @Binding var animateForm: Bool
    @Binding var isLoading: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header with back button
                headerView
                
                // Header text
                titleView
                
                // Sign Up Form
                signUpFormView
                
                // Social sign up options
                socialLoginView
            }
            .padding(.horizontal)
        }
    }
    
    private var headerView: some View {
        HStack {
            Button(action: {
                withAnimation {
                    viewModel.currentView = .welcome
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 20)
    }
    
    private var titleView: some View {
        VStack(spacing: 16) {
            Text("Create Account")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("Join the community")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.bottom, 12)
    }
    
    private var signUpFormView: some View {
        VStack(spacing: 20) {
            // Email field
            emailFieldView
            
            // Name field
            nameFieldView
            
            // Password field
            passwordFieldView
            
            // Password requirements
            PasswordRequirementsView(password: viewModel.signupPassword)
                .opacity(animateForm ? 1 : 0)
                .offset(y: animateForm ? 0 : 20)
            
            // Confirm Password field
            confirmPasswordFieldView
            
            // Sign Up button
            signUpButtonView
        }
        .padding(.horizontal, 24)
    }
    
    private var emailFieldView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Email")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .padding(.leading, 4)
            
            HStack {
                Image(systemName: "envelope.fill")
                    .foregroundColor(focusField == .email ? MeetSpotColors.pink500 : .white.opacity(0.5))
                    .font(.system(size: 20))
                    .frame(width: 36)
                
                TextField("", text: $viewModel.signupEmail)
                    .viewPlaceholder(when: viewModel.signupEmail.isEmpty) {
                        Text("Enter your email").foregroundColor(.white.opacity(0.3))
                    }
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .onTapGesture {
                        focusField = .email
                    }
                    .foregroundColor(.white)
                    .submitLabel(.next)
                    .onSubmit {
                        focusField = .name
                    }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Material.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        focusField == .email ? MeetSpotColors.pink500 : Color.white.opacity(0.1),
                        lineWidth: focusField == .email ? 1.5 : 1
                    )
            )
        }
        .opacity(animateForm ? 1 : 0)
        .offset(y: animateForm ? 0 : 20)
    }
    
    private var nameFieldView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Full Name")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .padding(.leading, 4)
            
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(focusField == .name ? MeetSpotColors.pink500 : .white.opacity(0.5))
                    .font(.system(size: 20))
                    .frame(width: 36)
                
                TextField("", text: $viewModel.onboardingState.name)
                    .viewPlaceholder(when: viewModel.onboardingState.name.isEmpty) {
                        Text("Enter your full name").foregroundColor(.white.opacity(0.3))
                    }
                    .autocapitalization(.words)
                    .disableAutocorrection(false)
                    .onTapGesture {
                        focusField = .name
                    }
                    .foregroundColor(.white)
                    .submitLabel(.next)
                    .onSubmit {
                        focusField = .password
                    }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Material.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        focusField == .name ? MeetSpotColors.pink500 : Color.white.opacity(0.1),
                        lineWidth: focusField == .name ? 1.5 : 1
                    )
            )
        }
        .opacity(animateForm ? 1 : 0)
        .offset(y: animateForm ? 0 : 20)
    }
    
    private var passwordFieldView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Password")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .padding(.leading, 4)
            
            GenericPasswordField<SignUpView.FocusField>(
                text: $viewModel.signupPassword,
                placeholder: "Enter your password",
                isFocused: focusField == .password,
                onSubmit: {
                    focusField = .confirmPassword
                },
                onFocusChange: { isFocused in
                    if isFocused {
                        focusField = .password
                    }
                }
            )
        }
        .opacity(animateForm ? 1 : 0)
        .offset(y: animateForm ? 0 : 20)
    }
    
    private var confirmPasswordFieldView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Confirm Password")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .padding(.leading, 4)
            
            GenericPasswordField<SignUpView.FocusField>(
                text: $viewModel.confirmPassword,
                placeholder: "Confirm your password",
                isFocused: focusField == .confirmPassword,
                onSubmit: {
                    focusField = nil
                },
                onFocusChange: { isFocused in
                    if isFocused {
                        focusField = .confirmPassword
                    }
                }
            )
        }
        .opacity(animateForm ? 1 : 0)
        .offset(y: animateForm ? 0 : 20)
    }
    
    private var signUpButtonView: some View {
        Button(action: {
            isLoading = true
            Task {
                await viewModel.signUp()
                isLoading = false
            }
        }) {
            HStack {
                if isLoading {
                    // Simple Circle-based spinner animation
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: 20, height: 20)
                        .rotationEffect(Angle(degrees: 270))
                        .rotationEffect(Angle(degrees: isLoading ? 360 : 0))
                        .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false), value: isLoading)
                        .padding(.trailing, 8)
                }
                
                Text("Create Account")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [MeetSpotColors.pink500, MeetSpotColors.purple900]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: MeetSpotColors.pink500.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .disabled(isLoading || viewModel.signupEmail.isEmpty || viewModel.signupPassword.isEmpty || viewModel.confirmPassword.isEmpty || viewModel.onboardingState.name.isEmpty)
        .opacity((isLoading || viewModel.signupEmail.isEmpty || viewModel.signupPassword.isEmpty || viewModel.confirmPassword.isEmpty || viewModel.onboardingState.name.isEmpty) ? 0.7 : 1)
        .opacity(animateForm ? 1 : 0)
        .offset(y: animateForm ? 0 : 20)
        .padding(.top, 8)
    }
    
    private var socialLoginView: some View {
        VStack(spacing: 24) {
            // Divider with "or"
            HStack {
                Line()
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    .frame(height: 1)
                
                Text("or continue with")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 10)
                
                Line()
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    .frame(height: 1)
            }
            .padding(.horizontal)
            .opacity(animateForm ? 1 : 0)
            
            // Social login buttons
            HStack(spacing: 20) {
                SocialLoginButton(iconName: "apple.logo", color: .white, action: {})
                SocialLoginButton(iconName: "envelope.fill", color: .white, action: {})
                SocialLoginButton(iconName: "g.circle.fill", color: .white, action: {})
            }
            .opacity(animateForm ? 1 : 0)
            
            // Sign In link
            HStack {
                Text("Already have an account?")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.subheadline)
                
                Button(action: {
                    viewModel.showLogin()
                }) {
                    Text("Sign In")
                        .font(.subheadline.bold())
                        .foregroundColor(MeetSpotColors.pink500)
                }
            }
            .padding(.top, 8)
            .opacity(animateForm ? 1 : 0)
        }
        .padding(.top, 20)
        .padding(.bottom, 40)
    }
}

struct PasswordRequirementsView: View {
    let password: String
    
    private var hasMinimumLength: Bool {
        password.count >= 8
    }
    
    private var hasUppercase: Bool {
        password.contains(where: { $0.isUppercase })
    }
    
    private var hasNumber: Bool {
        password.contains(where: { $0.isNumber })
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            PasswordRequirementRow(
                text: "At least 8 characters",
                isMet: hasMinimumLength
            )
            
            PasswordRequirementRow(
                text: "Contains uppercase letter",
                isMet: hasUppercase
            )
            
            PasswordRequirementRow(
                text: "Contains number",
                isMet: hasNumber
            )
        }
        .padding(.leading, 40)
        .padding(.top, 4)
    }
}

struct PasswordRequirementRow: View {
    let text: String
    let isMet: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isMet ? MeetSpotColors.pink500 : .white.opacity(0.4))
                .font(.system(size: 14))
            
            Text(text)
                .font(.caption)
                .foregroundColor(isMet ? .white.opacity(0.8) : .white.opacity(0.4))
        }
    }
}

#Preview {
    SignUpView(viewModel: AuthViewModel())
} 
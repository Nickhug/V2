import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusField: FocusField?
    @State private var animateForm = false
    
    // For visual effects
    @State private var isLoading = false
    @State private var animateGradient = false
    
    enum FocusField {
        case email, password
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
            ScrollView {
                VStack(spacing: 32) {
                    // Header with back button
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
                    
                    // Header text & logo
                    VStack(spacing: 24) {
                        Image("app-logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .shadow(color: MeetSpotColors.pink500.opacity(0.5), radius: 10, x: 0, y: 5)
                        
                        VStack(spacing: 8) {
                            Text("Welcome Back")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("Sign in to continue")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(.bottom, 20)
                    
                    // Login Form
                    VStack(spacing: 24) {
                        // Email field
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
                                
                                TextField("", text: $viewModel.loginEmail)
                                    .viewPlaceholder(when: viewModel.loginEmail.isEmpty) {
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
                                        focusField == .email ? MeetSpotColors.pink500 : Color.white.opacity(0.1),
                                        lineWidth: focusField == .email ? 1.5 : 1
                                    )
                            )
                        }
                        .opacity(animateForm ? 1 : 0)
                        .offset(y: animateForm ? 0 : 20)
                        
                        // Password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.leading, 4)
                            
                            GenericPasswordField<LoginView.FocusField>(
                                text: $viewModel.loginPassword,
                                placeholder: "Enter your password",
                                isFocused: focusField == .password,
                                onSubmit: {
                                    focusField = nil
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
                        
                        // Remember me & forgot password
                        HStack {
                            Toggle("Remember me", isOn: $viewModel.rememberMe)
                                .toggleStyle(CheckboxToggleStyle())
                                .foregroundColor(.white.opacity(0.8))
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Button(action: {
                                viewModel.showForgotPassword()
                            }) {
                                Text("Forgot Password?")
                                    .font(.subheadline)
                                    .foregroundColor(MeetSpotColors.pink500)
                                    .underline()
                            }
                        }
                        .padding(.horizontal, 4)
                        .opacity(animateForm ? 1 : 0)
                        .offset(y: animateForm ? 0 : 20)
                        
                        // Login button
                        Button(action: {
                            isLoading = true
                            Task {
                                await viewModel.login()
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
                                
                                Text("Sign In")
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
                        .disabled(isLoading || viewModel.loginEmail.isEmpty || viewModel.loginPassword.isEmpty)
                        .opacity((isLoading || viewModel.loginEmail.isEmpty || viewModel.loginPassword.isEmpty) ? 0.7 : 1)
                        .opacity(animateForm ? 1 : 0)
                        .offset(y: animateForm ? 0 : 20)
                    }
                    .padding(.horizontal, 24)
                    
                    // Social login options
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
                        
                        // Sign up link
                        HStack {
                            Text("Don't have an account?")
                                .foregroundColor(.white.opacity(0.7))
                                .font(.subheadline)
                            
                            Button(action: {
                                viewModel.showSignup()
                            }) {
                                Text("Sign Up")
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
                .padding(.horizontal)
            }
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

// MARK: - Supporting Views

struct PasswordField: View {
    @Binding var text: String
    var placeholder: String
    var isFocused: Bool
    var onFocusChange: (LoginView.FocusField?) -> Void
    var currentField: LoginView.FocusField
    
    @State private var isSecured: Bool = true
    
    init(text: Binding<String>, 
         placeholder: String, 
         isFocused: Bool, 
         focusState: FocusState<LoginView.FocusField?>.Binding, 
         currentField: LoginView.FocusField) {
        self._text = text
        self.placeholder = placeholder
        self.isFocused = isFocused
        self.onFocusChange = { newValue in
            focusState.wrappedValue = newValue
        }
        self.currentField = currentField
    }
    
    var body: some View {
        HStack {
            Image(systemName: "lock.fill")
                .foregroundColor(isFocused ? MeetSpotColors.pink500 : .white.opacity(0.5))
                .font(.system(size: 20))
                .frame(width: 36)
            
            Group {
                if isSecured {
                    SecureField("", text: $text)
                        .viewPlaceholder(when: text.isEmpty) {
                            Text(placeholder).foregroundColor(.white.opacity(0.3))
                        }
                        .submitLabel(.go)
                        .onSubmit {
                            onFocusChange(nil)
                        }
                } else {
                    TextField("", text: $text)
                        .viewPlaceholder(when: text.isEmpty) {
                            Text(placeholder).foregroundColor(.white.opacity(0.3))
                        }
                        .submitLabel(.go)
                        .onSubmit {
                            onFocusChange(nil)
                        }
                }
            }
            .foregroundColor(.white)
            .onTapGesture {
                onFocusChange(currentField)
            }
            .autocapitalization(.none)
            .disableAutocorrection(true)
            
            Button(action: {
                isSecured.toggle()
            }) {
                Image(systemName: isSecured ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.white.opacity(0.5))
                    .font(.system(size: 16))
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
                    isFocused ? MeetSpotColors.pink500 : Color.white.opacity(0.1),
                    lineWidth: isFocused ? 1.5 : 1
                )
        )
    }
}

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(configuration.isOn ? MeetSpotColors.pink500 : .white.opacity(0.6))
                .font(.system(size: 20))
                .onTapGesture {
                    configuration.isOn.toggle()
                }
            
            configuration.label
        }
    }
}

struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        return path
    }
}

struct SocialLoginButton: View {
    let iconName: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(.black)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(Material.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.2)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

#Preview {
    LoginView(viewModel: AuthViewModel())
} 
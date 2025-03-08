import SwiftUI

struct ForgotPasswordView: View {
    @ObservedObject var viewModel: AuthViewModel
    @State private var email = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isSuccess = false
    @State private var animateElements = false
    @FocusState private var isEmailFocused: Bool
    
    var body: some View {
        ZStack {
            // Background
            AnimatedGradientBackground()
            
            // Content
            VStack(spacing: 32) {
                // Header with back button
                HStack {
                    Button(action: {
                        withAnimation {
                            viewModel.currentView = .login
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
                .padding(.top, 20)
                .padding(.horizontal, 24)
                
                if isSuccess {
                    // Success state
                    VStack(spacing: 24) {
                        // Animation
                        LottieView(name: "email-sent", loopMode: .playOnce)
                            .frame(width: 200, height: 200)
                            .scaleEffect(animateElements ? 1 : 0.5)
                            .opacity(animateElements ? 1 : 0)
                        
                        // Success text
                        VStack(spacing: 16) {
                            Text("Check Your Email")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text("We've sent password reset instructions to:\n\(email)")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : 20)
                        
                        // Back to login button
                        Button(action: {
                            withAnimation {
                                viewModel.currentView = .login
                            }
                        }) {
                            Text("Back to Login")
                                .font(.headline)
                                .foregroundColor(.white)
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
                        .padding(.top, 16)
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : 20)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 40)
                } else {
                    // Request reset state
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 48))
                                .foregroundColor(MeetSpotColors.pink500)
                                .opacity(animateElements ? 1 : 0)
                                .scaleEffect(animateElements ? 1 : 0.8)
                            
                            Text("Reset Password")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .opacity(animateElements ? 1 : 0)
                            
                            Text("Enter your email address and we'll send you instructions to reset your password.")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                                .opacity(animateElements ? 1 : 0)
                        }
                        .padding(.top, 40)
                        
                        // Email field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.leading, 4)
                                .opacity(animateElements ? 1 : 0)
                            
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(isEmailFocused ? MeetSpotColors.pink500 : .white.opacity(0.5))
                                    .font(.system(size: 20))
                                    .frame(width: 36)
                                
                                TextField("", text: $email)
                                    .viewPlaceholder(when: email.isEmpty) {
                                        Text("Enter your email").foregroundColor(.white.opacity(0.3))
                                    }
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .focused($isEmailFocused)
                                    .foregroundColor(.white)
                                    .submitLabel(.go)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Material.ultraThinMaterial)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        isEmailFocused ? MeetSpotColors.pink500 : Color.white.opacity(0.1),
                                        lineWidth: isEmailFocused ? 1.5 : 1
                                    )
                            )
                            .opacity(animateElements ? 1 : 0)
                            .offset(y: animateElements ? 0 : 20)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        
                        // Error message
                        if let error = errorMessage {
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(Color.red.opacity(0.8))
                                .padding(.horizontal, 24)
                                .opacity(animateElements ? 1 : 0)
                        }
                        
                        // Send reset button
                        Button(action: {
                            sendResetLink()
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .padding(.trailing, 8)
                                }
                                
                                Text("Send Reset Link")
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
                        .disabled(isLoading || email.isEmpty)
                        .opacity((isLoading || email.isEmpty) ? 0.7 : 1)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : 20)
                    }
                }
                
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                animateElements = true
            }
        }
    }
    
    private func sendResetLink() {
        // Validate email
        guard !email.isEmpty, email.contains("@"), email.contains(".") else {
            errorMessage = "Please enter a valid email address"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false
            
            // Show success state with animation
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isSuccess = true
                animateElements = false
                
                // Animate success elements after a brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        animateElements = true
                    }
                }
            }
        }
    }
}

// Simple Lottie View wrapper
struct LottieView: View {
    let name: String
    let loopMode: LoopMode
    
    enum LoopMode {
        case loop, playOnce
    }
    
    var body: some View {
        // Note: This is a placeholder. In a real implementation, you would use Lottie's AnimationView
        // Since we don't have Lottie integration here, we'll use a simple animation placeholder
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.1))
            
            Image(systemName: "envelope.badge.fill")
                .font(.system(size: 70))
                .foregroundColor(MeetSpotColors.pink500)
        }
    }
}

#Preview {
    ForgotPasswordView(viewModel: AuthViewModel())
} 
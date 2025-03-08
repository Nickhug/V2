import SwiftUI

struct AuthFlowView: View {
    @StateObject private var viewModel = AuthViewModel()
    @EnvironmentObject private var authManager: AuthManager
    
    var body: some View {
        ZStack {
            // Background
            AnimatedGradientBackground()
            
            // Content views based on the current auth state
            switch viewModel.currentView {
            case .welcome:
                WelcomeView(viewModel: viewModel)
                    .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .leading)))
                
            case .login:
                LoginView(viewModel: viewModel)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                
            case .signup:
                SignUpView(viewModel: viewModel)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                
            case .forgotPassword:
                ForgotPasswordView(viewModel: viewModel)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                
            case .onboarding:
                OnboardingView(viewModel: viewModel)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                
            case .complete:
                CompletionView()
                    .transition(.asymmetric(insertion: .opacity, removal: .opacity))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.currentView)
        .onChange(of: viewModel.isOnboardingComplete) { _, newValue in
            if newValue {
                authManager.isAuthenticated = true
            }
        }
    }
}

// Success completion view before transitioning to main app
struct CompletionView: View {
    @State private var scale: CGFloat = 0.7
    @State private var opacity: Double = 0
    @EnvironmentObject private var authManager: AuthManager
    
    var body: some View {
        ZStack {
            AnimatedGradientBackground()
            
            VStack(spacing: 24) {
                Circle()
                    .fill(MeetSpotColors.pink500.opacity(0.2))
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .fill(MeetSpotColors.pink500.opacity(0.5))
                            .frame(width: 90, height: 90)
                    )
                    .overlay(
                        Circle()
                            .fill(MeetSpotColors.pink500)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    )
                    .scaleEffect(scale)
                    .opacity(opacity)
                
                Text("Welcome to MeetSpot!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(opacity)
                
                Text("Your account has been successfully created.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2)) {
                scale = 1.0
                opacity = 1.0
            }
            
            // Automatically transition to main app after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation {
                    authManager.isAuthenticated = true
                }
            }
        }
    }
}

#Preview {
    AuthFlowView()
        .environmentObject(AuthManager())
} 
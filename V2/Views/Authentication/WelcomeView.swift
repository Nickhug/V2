import SwiftUI

struct WelcomeView: View {
    @ObservedObject var viewModel: AuthViewModel
    @State private var animateBackground = false
    @State private var animateLogo = false
    @State private var animateTitle = false
    @State private var animateSubtitle = false
    @State private var animateButtons = false
    
    // For parallax effect
    @State private var xOffset: CGFloat = 0
    @State private var yOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Animated background
                AnimatedGradientBackground()
                
                // Content container with slight parallax
                VStack(spacing: 32) {
                    // App logo with animation
                    VStack(spacing: 24) {
                        Image("app-logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .shadow(color: MeetSpotColors.pink500.opacity(0.6), radius: 15, x: 0, y: 8)
                            .offset(x: xOffset * 5, y: yOffset * 5)
                            .opacity(animateLogo ? 1 : 0)
                            .scaleEffect(animateLogo ? 1 : 0.7)
                        
                        // Title with glow effect
                        Text("MeetSpot")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: MeetSpotColors.pink500.opacity(0.8), radius: 10, x: 0, y: 0)
                            .offset(x: xOffset * 3, y: yOffset * 3)
                            .opacity(animateTitle ? 1 : 0)
                            .scaleEffect(animateTitle ? 1 : 0.8)
                        
                        // Subtitle with animation
                        Text("Drive. Connect. Experience.")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .offset(x: xOffset * 2, y: yOffset * 2)
                            .opacity(animateSubtitle ? 1 : 0)
                            .padding(.top, 8)
                    }
                    .padding(.top, 60)
                    
                    Spacer()
                    
                    // Feature highlights with glass cards
                    VStack(spacing: 16) {
                        FeatureCard(icon: "car.fill", title: "Discover Meets", description: "Find and join car meets around you.", delay: 0.1)
                        
                        FeatureCard(icon: "map.fill", title: "Explore Routes", description: "Share and discover exciting driving routes.", delay: 0.2)
                        
                        FeatureCard(icon: "person.2.fill", title: "Connect", description: "Connect with other automotive enthusiasts.", delay: 0.3)
                    }
                    .offset(x: xOffset * -2, y: yOffset * -2)
                    .opacity(animateSubtitle ? 1 : 0)
                    .transition(.opacity)
                    
                    Spacer()
                    
                    // Buttons
                    VStack(spacing: 16) {
                        // Get Started button with gradient
                        Button(action: {
                            viewModel.showSignup()
                        }) {
                            Text("Get Started")
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
                                .shadow(color: MeetSpotColors.pink500.opacity(0.5), radius: 10, x: 0, y: 5)
                        }
                        
                        // Login button with glass style
                        Button(action: {
                            viewModel.showLogin()
                        }) {
                            Text("I already have an account")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(.ultraThinMaterial)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.bottom, 48)
                    .padding(.horizontal, 24)
                    .opacity(animateButtons ? 1 : 0)
                    .offset(y: animateButtons ? 0 : 30)
                }
                .padding(.horizontal, 24)
            }
            .edgesIgnoringSafeArea(.all)
            .preferredColorScheme(.dark)
            .onAppear {
                startAnimations()
                
                // Add parallax effect based on device motion
                startParallaxEffect()
            }
        }
    }
    
    private func startAnimations() {
        // Sequence animations
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7, blendDuration: 0).delay(0.2)) {
            animateLogo = true
        }
        
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7, blendDuration: 0).delay(0.7)) {
            animateTitle = true
        }
        
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7, blendDuration: 0).delay(1.0)) {
            animateSubtitle = true
        }
        
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7, blendDuration: 0).delay(1.3)) {
            animateButtons = true
        }
    }
    
    private func startParallaxEffect() {
        // Simple animation to simulate device motion for parallax
        withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
            xOffset = 5
            yOffset = 3
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) {
                xOffset = -5
                yOffset = -3
            }
        }
    }
}

// Glass-style feature card component
private struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let delay: Double
    
    @State private var isHovered = false
    
    init(icon: String, title: String, description: String, delay: Double = 0.0) {
        self.icon = icon
        self.title = title
        self.description = description
        self.delay = delay
    }
    
    var body: some View {
        HStack(spacing: 20) {
            // Animated icon
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [MeetSpotColors.pink500, MeetSpotColors.purple900]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: MeetSpotColors.pink500.opacity(0.3), radius: 8, x: 0, y: 4)
            
            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .white.opacity(0.5),
                            .clear,
                            .clear,
                            .white.opacity(0.2)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 10)
        .scaleEffect(isHovered ? 1.02 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onTapGesture {
            withAnimation {
                isHovered.toggle()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation {
                        isHovered = false
                    }
                }
            }
        }
    }
}

#Preview {
    WelcomeView(viewModel: AuthViewModel())
} 
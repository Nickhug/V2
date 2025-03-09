import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var isLoading = true
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Add animated gradient background at the root level
            ModernGradientBackground()
            
            if isLoading {
                LoadingView()
                    .transition(.opacity)
            } else {
                Group {
                    if authManager.isAuthenticated {
                        DashboardView()
                    } else {
                        AuthFlowView()
                    }
                }
                .transition(.opacity)
            }
        }
        .task {
            // Check session on app launch
            await authManager.checkAndRestoreSession()
            
            // Simulate a brief splash screen
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            withAnimation(.easeInOut(duration: 0.5)) {
                isLoading = false
            }
        }
    }
}

// Loading/splash screen
struct LoadingView: View {
    // Animation states
    @State private var pulsate = false
    @State private var isRotating = false
    @State private var animationPhase = 0
    
    var body: some View {
        VStack {
            Image("app-logo")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .shadow(color: MeetSpotColors.pink500.opacity(0.6), radius: 15, x: 0, y: 8)
                .scaleEffect(pulsate ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulsate)
            
            Text("MeetSpot")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.top, 16)
            
            // Improved Circle loading spinner with continuous animation
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(Color.white, lineWidth: 3)
                .frame(width: 30, height: 30)
                .rotationEffect(Angle(degrees: 270))
                .rotationEffect(Angle(degrees: isRotating ? 360 : 0))
                .animation(
                    Animation.linear(duration: 1.0)
                        .repeatForever(autoreverses: false), 
                    value: isRotating
                )
                .padding(.top, 32)
        }
        .onAppear {
            // Trigger animations with a small delay between them
            pulsate = true
            
            // Ensure the rotation animation starts and continues
            isRotating = true
        }
    }
}

// Add a standalone preview for LoadingView to better test the animation
struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            ModernGradientBackground()
            LoadingView()
        }
        .previewDisplayName("Loading Screen")
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
}
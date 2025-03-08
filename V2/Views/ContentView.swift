import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var isLoading = true
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Add animated gradient background at the root level
            AnimatedGradientBackground()
            
            if isLoading {
                LoadingView()
            } else {
                Group {
                    if authManager.isAuthenticated {
                        DashboardView()
                    } else {
                        AuthFlowView()
                    }
                }
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
    @State private var pulsate = false
    @State private var rotation = 0.0
    
    var body: some View {
        VStack {
            Image("app-logo")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .shadow(color: MeetSpotColors.pink500.opacity(0.6), radius: 15, x: 0, y: 8)
                .scaleEffect(pulsate ? 1.05 : 1.0)
            
            Text("MeetSpot")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.top, 16)
            
            // Basic Circle loading spinner instead of ProgressView to avoid UIKit adapter
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(Color.white, lineWidth: 3)
                .frame(width: 30, height: 30)
                .rotationEffect(Angle(degrees: 270))
                .rotationEffect(Angle(degrees: rotation))
                .padding(.top, 32)
        }
        .onAppear {
            // Start the pulsing animation
            withAnimation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulsate = true
            }
            
            // Start the loading spinner animation
            withAnimation(Animation.linear(duration: 1).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
}
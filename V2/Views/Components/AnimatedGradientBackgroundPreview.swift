import SwiftUI

struct AnimatedGradientBackgroundPreview: View {
    var body: some View {
        ZStack {
            // Main animated gradient background
            AnimatedGradientBackground()
                .overlay(
                    VStack(spacing: 30) {
                        Text("MeetSpot")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Drive. Connect. Experience.")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Spacer().frame(height: 50)
                        
                        // Glass card with animated gradient background
                        GlassGradientBackground {
                            VStack(spacing: 20) {
                                Text("Welcome Back")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text("Sign in to continue")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Button(action: {}) {
                                    Text("Sign In")
                                        .fontWeight(.semibold)
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 40)
                                        .background(
                                            Capsule()
                                                .fill(Color.white)
                                        )
                                        .foregroundColor(.black)
                                }
                                .padding(.top, 10)
                            }
                            .padding(30)
                            .frame(width: 300)
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 80)
                )
        }
    }
}

// Custom Demo View for comparing different variations
struct GradientComparisonView: View {
    var body: some View {
        TabView {
            // Original version (shown for comparison only)
            VStack {
                Text("Original Animation")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 50)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                // This simulates the old implementation for comparison
                LinearGradient(colors: [
                    Color.black,
                    Color(white: 0.15),
                    Color(white: 0.3),
                    Color(white: 0.15),
                    Color.black
                ], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .edgesIgnoringSafeArea(.all)
            )
            .tabItem {
                Label("Original", systemImage: "1.circle")
            }
            
            // New version
            AnimatedGradientBackground()
                .overlay(
                    Text("New Animation")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 50)
                )
                .tabItem {
                    Label("New", systemImage: "2.circle")
                }
            
            // Custom version
            AnimatedGradientBackgroundCustom(
                colors: [Color.black, Color(white: 0.2), Color(white: 0.1)],
                speed: 8.0,
                autoReverse: true
            )
            .overlay(
                Text("Custom Animation")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 50)
            )
            .tabItem {
                Label("Custom", systemImage: "3.circle")
            }
        }
        .tint(.white)
    }
}

// Preview
struct AnimatedGradientBackgroundPreview_Previews: PreviewProvider {
    static var previews: some View {
        AnimatedGradientBackgroundPreview()
            .previewDisplayName("Login Screen")
        
        GradientComparisonView()
            .previewDisplayName("Comparison View")
    }
} 
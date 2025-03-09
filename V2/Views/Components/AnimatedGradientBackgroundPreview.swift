import SwiftUI

struct AnimatedGradientBackgroundPreview: View {
    var body: some View {
        ZStack {
            // Uses ModernGradientBackground via the compatibility wrapper
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
                        
                        // Glass card with modern gradient background
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
                        
                        if #available(iOS 18.0, *) {
                            Text("Unpatterned MeshGradient with Dynamic Color Variation")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.bottom, 10)
                        } else {
                            Text("Enhanced Multi-Color Fallback Gradient")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.bottom, 10)
                        }
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
            // Fallback gradient (shown for comparison)
            VStack {
                Text("Multi-Color Fallback")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 50)
                
                Text("(Enhanced Color Palette)")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                FallbackGradientBackground()
            )
            .tabItem {
                Label("Fallback", systemImage: "1.circle")
            }
            
            // ModernGradientBackground (version-aware implementation)
            ModernGradientBackground()
                .overlay(
                    VStack {
                        Text("Unpatterned Gradient")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.top, 50)
                        
                        if #available(iOS 18.0, *) {
                            Text("(Random Color Distribution with 12 Colors)")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.7))
                        } else {
                            Text("(Enhanced Multi-Color Fallback)")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                    }
                )
                .tabItem {
                    Label("Random", systemImage: "2.circle")
                }
            
            // Custom version with even more color variety
            AnimatedGradientBackgroundCustom(
                colors: [
                    // Rich dark colors expanded palette
                    Color(red: 0.03, green: 0.03, blue: 0.09),  // Deep blue-black
                    Color(red: 0.06, green: 0.02, blue: 0.14),  // Rich purple
                    Color(red: 0.02, green: 0.05, blue: 0.13),  // Deep blue
                    Color(red: 0.08, green: 0.04, blue: 0.16),  // Midnight purple
                    Color(red: 0.04, green: 0.08, blue: 0.14),  // Teal blue
                    Color(red: 0.10, green: 0.05, blue: 0.12),  // Dark magenta
                    Color(red: 0.07, green: 0.03, blue: 0.11),  // Deep purple
                    Color(red: 0.09, green: 0.03, blue: 0.08),  // Burgundy
                    Color(red: 0.04, green: 0.06, blue: 0.15),  // Navy blue
                    Color(red: 0.08, green: 0.02, blue: 0.10),  // Berry purple
                ],
                speed: 0.3,
                autoReverse: true
            )
            .overlay(
                VStack {
                    Text("Dynamic Colors")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 50)
                    
                    if #available(iOS 18.0, *) {
                        Text("(Evolving Non-Repeating Color Pattern)")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.7))
                    } else {
                        Text("(Enhanced Linear Gradient)")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                }
            )
            .tabItem {
                Label("Dynamic", systemImage: "3.circle")
            }
            
            // Mesh Gradient on Text (iOS 18+ only)
            if #available(iOS 18.0, *) {
                VStack {
                    Text("MeshGradient as Style")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(
                            MeshGradient(width: 3, height: 3, points: [
                                SIMD2<Float>(0.0, 0.0), SIMD2<Float>(0.5, 0.0), SIMD2<Float>(1.0, 0.0),
                                SIMD2<Float>(0.0, 0.5), SIMD2<Float>(0.5, 0.5), SIMD2<Float>(1.0, 0.5),
                                SIMD2<Float>(0.0, 1.0), SIMD2<Float>(0.5, 1.0), SIMD2<Float>(1.0, 1.0)
                            ], colors: [
                                Color(red: 0.122, green: 0.078, blue: 0.149),  // Premium purple accent
                                Color(red: 0.090, green: 0.063, blue: 0.137),  // Premium violet
                                Color(red: 0.075, green: 0.051, blue: 0.102),  // Dark aubergine
                                Color(red: 0.063, green: 0.047, blue: 0.078),  // Premium dark charcoal-purple
                                Color(red: 0.043, green: 0.071, blue: 0.125),  // Midnight blue
                                Color(red: 0.055, green: 0.082, blue: 0.133),  // Sapphire blue
                                Color(red: 0.098, green: 0.059, blue: 0.114),  // Muted burgundy
                                Color(red: 0.133, green: 0.086, blue: 0.161),  // Luxury violet
                                Color(red: 0.071, green: 0.094, blue: 0.137)   // Steel blue accent
                            ],
                            background: Color(red: 0.035, green: 0.039, blue: 0.067))
                        )
                        .padding(.top, 50)
                    
                    Spacer()
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 100))
                        .foregroundStyle(
                            MeshGradient(width: 3, height: 3, points: [
                                SIMD2<Float>(0.0, 0.0), SIMD2<Float>(0.5, 0.0), SIMD2<Float>(1.0, 0.0),
                                SIMD2<Float>(0.0, 0.5), SIMD2<Float>(0.5, 0.5), SIMD2<Float>(1.0, 0.5),
                                SIMD2<Float>(0.0, 1.0), SIMD2<Float>(0.5, 1.0), SIMD2<Float>(1.0, 1.0)
                            ], colors: [
                                Color(red: 0.06, green: 0.02, blue: 0.14),
                                Color(red: 0.10, green: 0.05, blue: 0.12),
                                Color(red: 0.04, green: 0.08, blue: 0.14),
                                Color(red: 0.03, green: 0.03, blue: 0.09),
                                Color(red: 0.08, green: 0.04, blue: 0.16),
                                Color(red: 0.07, green: 0.03, blue: 0.11),
                                Color(red: 0.09, green: 0.02, blue: 0.10),
                                Color(red: 0.04, green: 0.06, blue: 0.12),
                                Color(red: 0.02, green: 0.05, blue: 0.13)
                            ],
                            background: Color(red: 0.02, green: 0.03, blue: 0.09))
                        )
                    
                    Spacer()
                }
                .background(Color(red: 0.02, green: 0.03, blue: 0.09))
                .tabItem {
                    Label("Styled", systemImage: "4.circle")
                }
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
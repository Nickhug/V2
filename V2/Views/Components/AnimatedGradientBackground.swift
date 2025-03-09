import SwiftUI
import Foundation

/// A modern gradient background that uses MeshGradient on iOS 18+ with fallback for earlier versions
/// This is a compatibility wrapper to maintain backward compatibility with existing code
public struct AnimatedGradientBackground: View {
    // Maintaining compatibility with existing implementation
    @State private var animationPhase: Double = 0.0
    @State private var isVisible: Bool = false
    @State private var isPaused: Bool = false
    
    // Environment awareness
    @Environment(\.scenePhase) private var scenePhase
    
    public var body: some View {
        // Use the modern gradient implementation
        ModernGradientBackground()
    }
    
    public init() {}
}

// A customizable version with color parameters - maintaining compatibility
public struct AnimatedGradientBackgroundCustom: View {
    private let colors: [Color]
    private let speed: Double
    private let autoReverse: Bool
    
    public var body: some View {
        if #available(iOS 18.0, *) {
            // Use the new implementation for iOS 18+
            CustomMeshGradientBackground(
                colors: colors,
                speed: speed
            )
        } else {
            // Simplified version for compatibility with earlier iOS versions
            LinearGradient(
                colors: colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }
    
    public init(colors: [Color] = [
        // Premium color palette with sophisticated dark tones
        Color(red: 0.035, green: 0.039, blue: 0.067),  // Rich dark background
        Color(red: 0.063, green: 0.047, blue: 0.078),  // Premium dark charcoal-purple
        Color(red: 0.075, green: 0.051, blue: 0.102),  // Dark aubergine 
        Color(red: 0.090, green: 0.063, blue: 0.137),  // Premium violet
        Color(red: 0.043, green: 0.071, blue: 0.125),  // Midnight blue
        Color(red: 0.122, green: 0.078, blue: 0.149),  // Premium purple accent
        Color(red: 0.035, green: 0.039, blue: 0.067),  // Rich dark background
    ], 
                speed: Double = 1.0,
                autoReverse: Bool = false) {
        self.colors = colors
        self.speed = speed
        self.autoReverse = autoReverse
    }
}

// Glass effect container with animated gradient background - maintaining compatibility
struct GlassGradientBackground<Content: View>: View {
    private let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        // Use the new implementation
        GlassMeshGradientBackground(content: { content })
    }
}

// Extension for conditional view modifiers - maintaining compatibility
extension View {
    @ViewBuilder
    func ifGradientView<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    func withGlassGradient() -> some View {
        // Use the new implementation
        self.withGlassMeshGradient()
    }
    
    func withAnimatedGradient() -> some View {
        // Use the new implementation
        self.withModernGradient()
    }
}

// Preview provider
struct AnimatedGradientBackground_Previews: PreviewProvider {
    static var previews: some View {
        AnimatedGradientBackground()
    }
} 
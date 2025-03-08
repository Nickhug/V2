import SwiftUI
import Foundation

/// A minimal, monochromatic animated gradient background with subtle movement
public struct AnimatedGradientBackground: View {
    // Animation phases for subtle movement
    @State private var phase1: Double = 0.0
    @State private var phase2: Double = 0.0
    
    // Extremely subtle color palette - barely visible gradations from black to dark gray
    private let colors: [Color] = [
        Color.black,                          // Pure black
        Color(white: 0.03),                   // Nearly black
        Color(white: 0.05),                   // Extremely dark gray
        Color(white: 0.07),                   // Very dark gray
        Color(white: 0.09),                   // Dark gray with minimal visibility
        Color(red: 0.04, green: 0.04, blue: 0.06) // Very dark with slight blue tint
    ]
    
    // Animation state
    @State private var isAnimating: Bool = false
    @State private var isVisible: Bool = false
    @State private var isPaused: Bool = false
    
    // Environment awareness
    @Environment(\.scenePhase) private var scenePhase
    
    public var body: some View {
        ZStack {
            // Pure black background base
            Color.black.ignoresSafeArea()
            
            // Subtle gradient animation layers
            TimelineView(.animation(minimumInterval: 0.2, paused: !isVisible || scenePhase != .active || isPaused)) { _ in
                gradientLayers
            }
            .compositingGroup()
            .allowsHitTesting(false)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            // Handle app backgrounding/foregrounding
            if newPhase != .active && isAnimating {
                isPaused = true
            } else if newPhase == .active && isVisible {
                isPaused = false
                if !isAnimating {
                    startAnimation()
                }
            }
        }
        .onAppear {
            isVisible = true
            setupNotificationObservers()
            
            // Start animation with minimal delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isPaused = false
                startAnimation()
            }
        }
        .onDisappear {
            isVisible = false
            isPaused = true
            removeNotificationObservers()
        }
    }
    
    // Simplified gradient layers with minimal movement
    private var gradientLayers: some View {
        ZStack {
            // First gradient layer - horizontal flow
            GeometryReader { geometry in
                LinearGradient(
                    gradient: Gradient(colors: [
                        colors[0],
                        colors[1],
                        colors[2],
                        colors[1],
                        colors[0]
                    ]),
                    startPoint: UnitPoint(
                        x: 0.3 + 0.07 * sin(phase1 * 0.2),
                        y: 0.3 + 0.07 * cos(phase2 * 0.2)
                    ),
                    endPoint: UnitPoint(
                        x: 0.7 + 0.07 * sin(phase2 * 0.2),
                        y: 0.7 + 0.07 * cos(phase1 * 0.2)
                    )
                )
                .opacity(0.8)
                .ignoresSafeArea()
            }
            
            // Second gradient layer - diagonal flow
            GeometryReader { geometry in
                LinearGradient(
                    gradient: Gradient(colors: [
                        colors[0],
                        colors[3],
                        colors[5],
                        colors[3],
                        colors[0]
                    ]),
                    startPoint: UnitPoint(
                        x: 0.2 + 0.05 * sin(phase2 * 0.15),
                        y: 0.8 + 0.05 * cos(phase1 * 0.15)
                    ),
                    endPoint: UnitPoint(
                        x: 0.8 + 0.05 * sin(phase1 * 0.15),
                        y: 0.2 + 0.05 * cos(phase2 * 0.15)
                    )
                )
                .opacity(0.6)
                .blendMode(.plusLighter)
                .ignoresSafeArea()
            }
        }
    }
    
    // Start the subtle animation
    private func startAnimation() {
        isAnimating = true
        
        // Use slow, gentle animations for subtle movement
        withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
            phase1 = 2 * .pi
        }
        
        withAnimation(.linear(duration: 45).repeatForever(autoreverses: false)) {
            phase2 = 2 * .pi
        }
    }
    
    // Setup notification observers for external control
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("PauseAnimatedBackgrounds"),
            object: nil,
            queue: .main
        ) { _ in
            self.isPaused = true
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ResumeAnimatedBackgrounds"),
            object: nil,
            queue: .main
        ) { _ in
            if self.isVisible {
                self.isPaused = false
                if !self.isAnimating {
                    self.startAnimation()
                }
            }
        }
    }
    
    // Clean up observers
    private func removeNotificationObservers() {
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name("PauseAnimatedBackgrounds"),
            object: nil
        )
        
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name("ResumeAnimatedBackgrounds"),
            object: nil
        )
    }
    
    // Public methods for external control
    public func pauseAnimations() {
        isPaused = true
    }
    
    public func resumeAnimations() {
        if isVisible {
            isPaused = false
            if !isAnimating {
                startAnimation()
            }
        }
    }
    
    public init() {}
}

// Simple glass effect container that uses the animated background
struct GlassGradientBackground<Content: View>: View {
    private let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            AnimatedGradientBackground()
            
            content
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 5)
        }
    }
}

// Extension to easily apply animated gradient background to any view
extension View {
    func withAnimatedGradient() -> some View {
        ZStack {
            AnimatedGradientBackground()
            self
        }
    }
    
    func withGlassGradient() -> some View {
        GlassGradientBackground {
            self
        }
    }
}

// Extension for conditional view modifiers specific to gradient components
extension View {
    @ViewBuilder
    func ifGradientView<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// Preview provider
struct AnimatedGradientBackground_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AnimatedGradientBackground()
                .previewDisplayName("Monochromatic Gradient")
            
            GlassGradientBackground {
                VStack(spacing: 20) {
                    Text("Glass Card")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("With subtle monochromatic background")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding()
                .frame(width: 300, height: 200)
            }
            .previewDisplayName("Glass Card")
            
            // Custom version with slightly different monochromatic scheme
            AnimatedGradientBackgroundCustom(
                colors: [
                    Color.black,             // Pure black base
                    Color(white: 0.02),      // Nearly black
                    Color(white: 0.04),      // Very dark gray
                    Color(white: 0.06),      // Dark gray
                    Color(white: 0.08),      // Medium-dark gray
                    Color(white: 0.10)       // Medium gray
                ],
                speed: 1.2
            )
            .previewDisplayName("Custom Monochrome")
        }
    }
}

// A customizable version with color parameters
public struct AnimatedGradientBackgroundCustom: View {
    // Multiple phases for more complex, less predictable movement
    @State private var phase1: Double = 0.0
    @State private var phase2: Double = 0.0
    @State private var phase3: Double = 0.0
    
    // Flag to track if this view is visible (to pause animations when offscreen)
    @State private var isVisible: Bool = false
    
    private let colors: [Color]
    private let speed: Double
    private let autoReverse: Bool
    
    @Environment(\.scenePhase) private var scenePhase
    
    public var body: some View {
        ZStack {
            // Start with a solid color background
            colors[0]
                .ignoresSafeArea()
            
            TimelineView(.animation(minimumInterval: 0.5, paused: !isVisible || scenePhase != .active)) { _ in
                GeometryReader { geometry in
                    // First gradient - extremely large and subtle
                    LinearGradient(
                        gradient: Gradient(colors: [
                            colors[0],
                            colors.count > 1 ? colors[1] : colors[0],
                            colors.count > 2 ? colors[2] : colors[0],
                            colors[0]
                        ]),
                        startPoint: UnitPoint(
                            x: 0.4 + 0.05 * sin(phase1 * 0.5),
                            y: 0.4 + 0.05 * sin(phase2 * 0.4)
                        ),
                        endPoint: UnitPoint(
                            x: 0.6 + 0.05 * cos(phase3 * 0.3),
                            y: 0.6 + 0.05 * cos(phase1 * 0.45)
                        )
                    )
                    .opacity(0.7)
                    .ignoresSafeArea()
                }
            }
        }
        .onAppear {
            isVisible = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                startAnimation()
            }
        }
        .onDisappear {
            isVisible = false
        }
        // Essential for performance
        .drawingGroup(opaque: false)
    }
    
    private func startAnimation() {
        // Calculate actual durations based on speed
        let baseDuration1 = 180.0 / speed
        let baseDuration2 = 210.0 / speed
        let baseDuration3 = 240.0 / speed
        
        withAnimation(.linear(duration: baseDuration1).repeatForever(autoreverses: autoReverse)) {
            phase1 = 2 * .pi
        }
        
        withAnimation(.linear(duration: baseDuration2).repeatForever(autoreverses: autoReverse)) {
            phase2 = 2 * .pi
        }
        
        withAnimation(.linear(duration: baseDuration3).repeatForever(autoreverses: autoReverse)) {
            phase3 = 2 * .pi
        }
    }
    
    public init(colors: [Color] = [
        Color.black,             // Pure black base
        Color(white: 0.02),      // Nearly black
        Color(white: 0.04),      // Very dark gray
        Color(white: 0.06),      // Dark gray
        Color(white: 0.08),      // Medium-dark gray
        Color(white: 0.10)       // Medium gray
    ], 
                speed: Double = 1.0,
                autoReverse: Bool = false) {
        self.colors = colors
        self.speed = speed
        self.autoReverse = autoReverse
    }
} 
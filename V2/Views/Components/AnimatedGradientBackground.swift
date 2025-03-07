import SwiftUI
import Foundation

/// A fluid, monochromatic animated gradient background with smooth transitions
public struct AnimatedGradientBackground: View {
    // Multiple phases for organic movement
    @State private var phase1: Double = 0.0
    @State private var phase2: Double = 0.0
    @State private var phase3: Double = 0.0
    
    // Monochromatic color palette with subtle variations
    private let colors: [Color] = [
        Color(white: 0.02),      // Nearly black
        Color(white: 0.04),      // Very dark gray
        Color(white: 0.06),      // Dark gray
        Color(white: 0.08),      // Medium-dark gray
        Color(white: 0.1),       // Medium gray
        Color(white: 0.13)       // Light-medium gray
    ]
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base layer - dark background
                Color.black
                
                // First gradient layer
                LinearGradient(
                    gradient: Gradient(colors: [
                        colors[0],
                        colors[1],
                        colors[2]
                    ]),
                    startPoint: UnitPoint(
                        x: 0.2 + 0.1 * sin(phase1 * 0.5),
                        y: 0.2 + 0.1 * cos(phase1 * 0.7)
                    ),
                    endPoint: UnitPoint(
                        x: 0.8 + 0.1 * sin(phase2 * 0.6),
                        y: 0.8 + 0.1 * cos(phase2 * 0.4)
                    )
                )
                .opacity(0.7)
                
                // Second gradient layer
                RadialGradient(
                    gradient: Gradient(colors: [
                        colors[3].opacity(0.6),
                        colors[2].opacity(0.3),
                        Color.clear
                    ]),
                    center: UnitPoint(
                        x: 0.7 + 0.15 * sin(phase2 * 0.3 + phase3 * 0.2),
                        y: 0.3 + 0.15 * cos(phase1 * 0.4 + phase2 * 0.2)
                    ),
                    startRadius: geometry.size.width * 0.1,
                    endRadius: max(geometry.size.width, geometry.size.height) * 0.8
                )
                .opacity(0.7)
                
                // Third gradient - different pattern and timing
                RadialGradient(
                    gradient: Gradient(colors: [
                        colors[4].opacity(0.5),
                        colors[3].opacity(0.3),
                        Color.clear
                    ]),
                    center: UnitPoint(
                        x: 0.3 + 0.15 * sin(phase3 * 0.5 - phase2 * 0.2),
                        y: 0.7 + 0.15 * cos(phase1 * 0.3 - phase3 * 0.3)
                    ),
                    startRadius: geometry.size.width * 0.05,
                    endRadius: max(geometry.size.width, geometry.size.height) * 0.7
                )
                .opacity(0.5)
                
                // Highlight layer
                RadialGradient(
                    gradient: Gradient(colors: [
                        colors[5].opacity(0.4),
                        Color.clear
                    ]),
                    center: UnitPoint(
                        x: 0.5 + 0.2 * cos(phase1 * 0.2) * sin(phase2 * 0.3),
                        y: 0.5 + 0.2 * sin(phase3 * 0.3) * cos(phase1 * 0.2)
                    ),
                    startRadius: min(geometry.size.width, geometry.size.height) * 0.1,
                    endRadius: max(geometry.size.width, geometry.size.height) * 0.6
                )
                .opacity(0.4)
            }
        }
        .ignoresSafeArea(.all)
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Smooth animations with different durations for organic feel
        withAnimation(.easeInOut(duration: 25).repeatForever(autoreverses: false)) {
            phase1 = 2 * .pi
        }
        
        withAnimation(.easeInOut(duration: 30).repeatForever(autoreverses: false)) {
            phase2 = 2 * .pi
        }
        
        withAnimation(.easeInOut(duration: 35).repeatForever(autoreverses: false)) {
            phase3 = 2 * .pi
        }
    }
    
    public init() {}
}

/// A shape that creates an organic blob form
struct Blob: Shape {
    let position: CGPoint
    let size: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        // Create an organic blob using multiple control points
        let points = 6
        var lastPoint = CGPoint(
            x: center.x + radius * cos(0),
            y: center.y + radius * sin(0)
        )
        path.move(to: lastPoint)
        
        for i in 1...points {
            let angle = 2 * .pi / Double(points) * Double(i)
            
            // Add some randomness to the radius for each point to create blob shape
            let randomRadius = radius * (0.8 + CGFloat.random(in: 0...0.4))
            
            // Calculate point position - use Foundation.cos/sin explicitly
            let pointX = center.x + randomRadius * CGFloat(Foundation.cos(angle))
            let pointY = center.y + randomRadius * CGFloat(Foundation.sin(angle))
            let point = CGPoint(x: pointX, y: pointY)
            
            // Break up control point calculations
            let controlOffset1X = (point.x - lastPoint.x) / 3 + CGFloat.random(in: -10...10)
            let controlOffset1Y = (point.y - lastPoint.y) / 3 + CGFloat.random(in: -10...10)
            let control1 = CGPoint(
                x: lastPoint.x + controlOffset1X,
                y: lastPoint.y + controlOffset1Y
            )
            
            let controlOffset2X = 2 * (point.x - lastPoint.x) / 3 + CGFloat.random(in: -10...10)
            let controlOffset2Y = 2 * (point.y - lastPoint.y) / 3 + CGFloat.random(in: -10...10)
            let control2 = CGPoint(
                x: lastPoint.x + controlOffset2X,
                y: lastPoint.y + controlOffset2Y
            )
            
            path.addCurve(to: point, control1: control1, control2: control2)
            lastPoint = point
        }
        
        path.closeSubpath()
        return path
    }
}

// A specialized version that adds glass-morphism effect to the content
struct GlassGradientBackground<Content: View>: View {
    private let content: Content
    var opacity: Double = 0.7
    
    init(opacity: Double = 0.7, @ViewBuilder content: () -> Content) {
        self.opacity = opacity
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            // Base gradient
            AnimatedGradientBackground()
            
            // Glass container
            content
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
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

// A customizable version with color parameters
public struct AnimatedGradientBackgroundCustom: View {
    // Multiple phases for more complex, less predictable movement
    @State private var phase1: Double = 0.0
    @State private var phase2: Double = 0.0
    @State private var phase3: Double = 0.0
    
    private let colors: [Color]
    private let speed: Double
    private let autoReverse: Bool
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base layer - solid background
                colors[0]
                
                // First gradient - extremely large and subtle
                LinearGradient(
                    gradient: Gradient(colors: [
                        colors[0],
                        colors.count > 1 ? colors[1] : colors[0],
                        colors.count > 2 ? colors[2] : colors[0],
                        colors[0]
                    ]),
                    startPoint: UnitPoint(
                        x: 0.4 + 0.05 * sin(phase1) * cos(phase2 * 0.8),
                        y: 0.4 + 0.05 * sin(phase2) * cos(phase3 * 0.7)
                    ),
                    endPoint: UnitPoint(
                        x: 0.6 + 0.05 * cos(phase3) * sin(phase1 * 0.6),
                        y: 0.6 + 0.05 * cos(phase1) * sin(phase2 * 0.9)
                    )
                )
                .opacity(0.6)
                
                // Second gradient - different movement pattern
                RadialGradient(
                    gradient: Gradient(colors: [
                        colors.count > 3 ? colors[3].opacity(0.3) : colors[0].opacity(0.3),
                        colors.count > 1 ? colors[1].opacity(0.1) : colors[0].opacity(0.1),
                        Color.clear
                    ]),
                    center: UnitPoint(
                        x: 0.3 + 0.07 * sin(phase1 * 0.7 + phase3 * 0.3),
                        y: 0.7 + 0.07 * cos(phase2 * 0.6 + phase1 * 0.2)
                    ),
                    startRadius: geometry.size.width * 0.1,
                    endRadius: max(geometry.size.width, geometry.size.height) * 1.2
                )
                .opacity(0.5)
                
                // Third gradient - different pattern and timing
                RadialGradient(
                    gradient: Gradient(colors: [
                        colors.count > 4 ? colors[4].opacity(0.2) : colors[0].opacity(0.2),
                        colors.count > 2 ? colors[2].opacity(0.1) : colors[0].opacity(0.1),
                        Color.clear
                    ]),
                    center: UnitPoint(
                        x: 0.7 + 0.08 * sin(phase3 * 0.8 - phase2 * 0.3),
                        y: 0.3 + 0.08 * cos(phase1 * 0.5 - phase3 * 0.4)
                    ),
                    startRadius: geometry.size.width * 0.2,
                    endRadius: max(geometry.size.width, geometry.size.height) * 1.5
                )
                .opacity(0.4)
                
                // Subtle light areas
                RadialGradient(
                    gradient: Gradient(colors: [
                        colors.count > 5 ? colors[5].opacity(0.15) : colors[0].opacity(0.15),
                        Color.clear
                    ]),
                    center: UnitPoint(
                        x: 0.5 + 0.1 * cos(phase1 * 0.3) * sin(phase2 * 0.4),
                        y: 0.5 + 0.1 * sin(phase3 * 0.4) * cos(phase1 * 0.3)
                    ),
                    startRadius: min(geometry.size.width, geometry.size.height) * 0.3,
                    endRadius: max(geometry.size.width, geometry.size.height) * 1.8
                )
                .opacity(0.3)
            }
        }
        .ignoresSafeArea(.all)
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Calculate actual durations based on speed
        let baseDuration1 = 60.0 / speed
        let baseDuration2 = 75.0 / speed
        let baseDuration3 = 90.0 / speed
        
        withAnimation(.easeInOut(duration: baseDuration1).repeatForever(autoreverses: autoReverse)) {
            phase1 = 2 * .pi
        }
        
        withAnimation(.easeInOut(duration: baseDuration2).repeatForever(autoreverses: autoReverse)) {
            phase2 = 2 * .pi
        }
        
        withAnimation(.easeInOut(duration: baseDuration3).repeatForever(autoreverses: autoReverse)) {
            phase3 = 2 * .pi
        }
    }
    
    public init(colors: [Color] = [
        Color(white: 0.02),      // Nearly black
        Color(white: 0.04),      // Very dark gray
        Color(white: 0.06),      // Dark gray
        Color(white: 0.08),      // Medium-dark gray
        Color(white: 0.1),       // Medium gray
        Color(white: 0.13)       // Light-medium gray
    ], 
                speed: Double = 1.0,
                autoReverse: Bool = false) {
        self.colors = colors
        self.speed = speed
        self.autoReverse = autoReverse
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
                    Color(white: 0.01),   // Nearly black
                    Color(white: 0.03),   // Very dark gray
                    Color(white: 0.05),   // Dark gray
                    Color(white: 0.07),   // Medium-dark gray
                    Color(white: 0.09),   // Medium gray
                    Color(white: 0.12)    // Light-medium gray
                ],
                speed: 1.2
            )
            .previewDisplayName("Custom Monochrome")
        }
    }
} 
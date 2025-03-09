import SwiftUI
import Foundation

/// A sophisticated dark-themed mesh gradient background with subtle animation
@available(iOS 18.0, *)
public struct MeshGradientBackground: View {
    // Animation state
    @State private var animationPhase: Double = 0.0
    @State private var isVisible: Bool = false
    
    // Premium color palette - sophisticated dark theme with rich accents
    private let colors: [Color] = [
        Color(red: 0.063, green: 0.047, blue: 0.078),  // Premium dark charcoal-purple
        Color(red: 0.031, green: 0.047, blue: 0.094),  // Dark navy blue
        Color(red: 0.075, green: 0.051, blue: 0.102),  // Dark aubergine
        Color(red: 0.043, green: 0.071, blue: 0.125),  // Midnight blue
        Color(red: 0.090, green: 0.063, blue: 0.137),  // Premium violet
        Color(red: 0.047, green: 0.059, blue: 0.114),  // Deep blue-slate
        Color(red: 0.082, green: 0.043, blue: 0.094),  // Rich plum
        Color(red: 0.039, green: 0.078, blue: 0.118),  // Deep teal-navy
        Color(red: 0.098, green: 0.059, blue: 0.114),  // Muted burgundy
        Color(red: 0.122, green: 0.078, blue: 0.149),  // Premium purple accent
        Color(red: 0.055, green: 0.082, blue: 0.133),  // Sapphire blue
        Color(red: 0.133, green: 0.086, blue: 0.161),  // Luxury violet
        Color(red: 0.055, green: 0.047, blue: 0.090),  // Deep indigo
        Color(red: 0.071, green: 0.094, blue: 0.137)   // Steel blue accent
    ]
    
    // Environment awareness for app state
    @Environment(\.scenePhase) private var scenePhase
    
    public var body: some View {
        TimelineView(.animation(minimumInterval: 0.1, paused: false)) { timeline in
            // Calculate animation values based on time with slower frequencies
            let time = timeline.date.timeIntervalSince1970
            
            // Slower wave patterns for more subtle movement (reduced frequencies)
            let wave1 = sin(time * 0.05) * 0.15  // Much slower frequency
            let wave2 = cos(time * 0.03) * 0.12  // Even slower
            let wave3 = sin(time * 0.04 + 0.5) * 0.13
            let wave4 = cos(time * 0.06 + 1.3) * 0.14
            
            // Extend mesh beyond screen bounds to eliminate edge indentation
            MeshGradient(
                width: 5,
                height: 5,
                locations: .points([
                    // Row 1 - extend beyond top edge (-0.05 on y-axis)
                    SIMD2<Float>(-0.05, -0.05),  // Extended top-left beyond screen
                    SIMD2<Float>(0.25 + Float(wave1 * 0.03), Float(-0.05 + wave2 * 0.05)),
                    SIMD2<Float>(0.5 + Float(wave3 * 0.03), Float(-0.05 + wave4 * 0.04)),
                    SIMD2<Float>(0.75 - Float(wave2 * 0.03), Float(-0.05 - wave1 * 0.05)),
                    SIMD2<Float>(1.05, -0.05),  // Extended top-right beyond screen
                    
                    // Row 2 - extend slightly left and right (-0.05 and 1.05 on x-axis)
                    SIMD2<Float>(-0.05 + Float(wave2 * 0.08), 0.25 + Float(wave3 * 0.05)),
                    SIMD2<Float>(0.27 + Float(wave4 * 0.06), 0.23 + Float(wave1 * 0.04)),
                    SIMD2<Float>(0.5 + Float(wave1 * 0.07), 0.24 - Float(wave2 * 0.03)),
                    SIMD2<Float>(0.73 - Float(wave3 * 0.06), 0.23 + Float(wave4 * 0.04)),
                    SIMD2<Float>(1.05 - Float(wave4 * 0.08), 0.25 - Float(wave2 * 0.05)),
                    
                    // Row 3 - center area with extended sides
                    SIMD2<Float>(-0.05 - Float(wave3 * 0.07), 0.5 + Float(wave2 * 0.06)),
                    SIMD2<Float>(0.27 + Float(wave1 * 0.05), 0.5 - Float(wave4 * 0.04)),
                    SIMD2<Float>(0.5 + Float(wave2 * 0.08), 0.5 + Float(wave1 * 0.05)),
                    SIMD2<Float>(0.73 - Float(wave4 * 0.05), 0.5 - Float(wave3 * 0.04)),
                    SIMD2<Float>(1.05 + Float(wave3 * 0.07), 0.5 + Float(wave2 * 0.06)),
                    
                    // Row 4 - extend slightly left and right
                    SIMD2<Float>(-0.05 + Float(wave4 * 0.08), 0.75 - Float(wave1 * 0.05)),
                    SIMD2<Float>(0.27 - Float(wave2 * 0.06), 0.77 + Float(wave3 * 0.04)),
                    SIMD2<Float>(0.5 + Float(wave3 * 0.07), 0.76 - Float(wave4 * 0.03)),
                    SIMD2<Float>(0.73 + Float(wave1 * 0.06), 0.77 + Float(wave2 * 0.04)),
                    SIMD2<Float>(1.05 - Float(wave4 * 0.08), 0.75 - Float(wave1 * 0.05)),
                    
                    // Row 5 - extend beyond bottom edge (1.05 on y-axis)
                    SIMD2<Float>(-0.05, 1.05),  // Extended bottom-left beyond screen
                    SIMD2<Float>(0.25 + Float(wave3 * 0.03), 1.05 - Float(wave1 * 0.05)),
                    SIMD2<Float>(0.5 - Float(wave2 * 0.03), 1.05 + Float(wave4 * 0.04)),
                    SIMD2<Float>(0.75 + Float(wave1 * 0.03), 1.05 - Float(wave3 * 0.05)),
                    SIMD2<Float>(1.05, 1.05)    // Extended bottom-right beyond screen
                ]),
                colors: .colors(createVariedColorMatrix(time)), // Use dynamic color distribution
                background: Color(red: 0.035, green: 0.039, blue: 0.067), // Rich dark background
                smoothsColors: true
            )
            .opacity(isVisible ? 1.0 : 0.0)
            .edgesIgnoringSafeArea([.all]) // Ensure ALL edges ignore safe area
            .onAppear {
                withAnimation(.easeIn(duration: 0.5)) {
                    isVisible = true
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                withAnimation(.easeInOut(duration: 0.5)) {
                    isVisible = (newPhase == .active)
                }
            }
        }
        .edgesIgnoringSafeArea([.all]) // Add at TimelineView level too
    }
    
    // Generate a varied, non-patterned color distribution
    private func createVariedColorMatrix(_ time: TimeInterval) -> [Color] {
        // Multiple time-varying parameters for more organic, non-repeating pattern
        let t1 = sin(time * 0.011) * 0.5 + 0.5
        let t2 = cos(time * 0.017) * 0.5 + 0.5
        let t3 = sin(time * 0.013 + 0.7) * 0.5 + 0.5
        let t4 = cos(time * 0.019 + 1.3) * 0.5 + 0.5
        let t5 = sin(time * 0.015 + 2.1) * 0.5 + 0.5
        let t6 = cos(time * 0.012 + 0.9) * 0.5 + 0.5
        
        // Create array of varied offsets based on time
        let timeOffsets = [
            t1 * 7, t2 * 5, t3 * 6, t4 * 4, t5 * 8, 
            t6 * 3, t1 * 6, t2 * 7, t3 * 4, t4 * 9,
            t5 * 5, t6 * 8, t1 * 4, t2 * 6, t3 * 7,
            t4 * 5, t5 * 9, t6 * 4, t1 * 8, t2 * 3,
            t3 * 9, t4 * 6, t5 * 4, t6 * 7, t1 * 5
        ]
        
        // Dynamic primes for creating non-repeating patterns
        let primes = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37]
        let colorCount = colors.count
        
        // Create a completely varied matrix without any obvious pattern
        var resultColors: [Color] = []
        
        for i in 0..<25 {
            // Use multiple parameters to determine color selection
            let primeIndex = i % primes.count
            let prime = primes[primeIndex]
            
            // Dynamic indirection calculation
            let timeValue = timeOffsets[i]
            let offset = Int(timeValue * Double(prime))
            
            // Apply a different combination of calculations for each point
            let dynamicIndex: Int
            
            if i % 5 == 0 { // Points on left edge
                dynamicIndex = (i * 2 + offset + Int(t1 * 5)) % colorCount
            } else if i % 5 == 4 { // Points on right edge
                dynamicIndex = ((i + 7) * 3 + offset + Int(t2 * 4)) % colorCount
            } else if i < 5 { // Points on top row
                dynamicIndex = ((i + 11) + offset + Int(t3 * 6)) % colorCount
            } else if i >= 20 { // Points on bottom row
                dynamicIndex = ((i + 13) * 2 + offset + Int(t4 * 3)) % colorCount
            } else if i % 2 == 0 { // Even indices in the middle
                dynamicIndex = ((i * i + 3) + offset + Int(t5 * 7)) % colorCount
            } else { // Odd indices in the middle
                dynamicIndex = ((i * 3 + 5) + offset + Int(t6 * 5)) % colorCount
            }
            
            // Get the color at the calculated index
            resultColors.append(colors[dynamicIndex])
        }
        
        return resultColors
    }
    
    public init() {}
}

/// A fallback gradient for iOS versions before 18.0
public struct FallbackGradientBackground: View {
    public var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.035, green: 0.039, blue: 0.067),  // Rich dark background
                Color(red: 0.063, green: 0.047, blue: 0.078),  // Premium dark charcoal-purple
                Color(red: 0.075, green: 0.051, blue: 0.102),  // Dark aubergine
                Color(red: 0.047, green: 0.059, blue: 0.114),  // Deep blue-slate
                Color(red: 0.090, green: 0.063, blue: 0.137),  // Premium violet
                Color(red: 0.039, green: 0.078, blue: 0.118),  // Deep teal-navy
                Color(red: 0.122, green: 0.078, blue: 0.149),  // Premium purple accent
                Color(red: 0.035, green: 0.039, blue: 0.067)   // Rich dark background (repeated)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .edgesIgnoringSafeArea([.all]) // More explicit than ignoresSafeArea()
    }
    
    public init() {}
}

/// A version-aware gradient background that uses MeshGradient on iOS 18+ 
/// and falls back to LinearGradient on earlier versions
public struct ModernGradientBackground: View {
    public var body: some View {
        if #available(iOS 18.0, *) {
            MeshGradientBackground()
        } else {
            FallbackGradientBackground()
        }
    }
    
    public init() {}
}

// A customizable version with color parameters
@available(iOS 18.0, *)
public struct CustomMeshGradientBackground: View {
    private let colors: [Color]
    private let speed: Double
    
    public var body: some View {
        TimelineView(.animation(minimumInterval: 0.1, paused: false)) { timeline in
            let time = timeline.date.timeIntervalSince1970 * speed
            
            // Much slower wave patterns for more fluid, subtle movement
            let wave1 = sin(time * 0.1) * 0.2
            let wave2 = cos(time * 0.07) * 0.15
            let wave3 = sin(time * 0.08 + 1.1) * 0.18
            let wave4 = cos(time * 0.09 - 0.7) * 0.12
            
            // Extend mesh beyond screen bounds to eliminate edge indentation
            MeshGradient(
                width: 5,
                height: 5,
                locations: .points([
                    // Row 1 - extend beyond top edge
                    SIMD2<Float>(-0.05, -0.05),  // Extended top-left
                    SIMD2<Float>(0.25 + Float(wave1 * 0.05), Float(-0.05 + wave2 * 0.03)),
                    SIMD2<Float>(0.5 + Float(wave3 * 0.04), Float(-0.05 + wave4 * 0.04)),
                    SIMD2<Float>(0.75 - Float(wave2 * 0.05), Float(-0.05 - wave1 * 0.03)),
                    SIMD2<Float>(1.05, -0.05),  // Extended top-right
                    
                    // Row 2 - extend slightly beyond sides
                    SIMD2<Float>(-0.05 + Float(wave2 * 0.08), 0.25 + Float(wave3 * 0.05)),
                    SIMD2<Float>(0.27 + Float(wave4 * 0.06), 0.23 + Float(wave1 * 0.04)),
                    SIMD2<Float>(0.5 + Float(wave1 * 0.07), 0.24 - Float(wave2 * 0.03)),
                    SIMD2<Float>(0.73 - Float(wave3 * 0.06), 0.23 + Float(wave4 * 0.04)),
                    SIMD2<Float>(1.05 - Float(wave4 * 0.08), 0.25 - Float(wave2 * 0.05)),
                    
                    // Row 3 - extend slightly beyond sides
                    SIMD2<Float>(-0.05 - Float(wave3 * 0.07), 0.5 + Float(wave2 * 0.06)),
                    SIMD2<Float>(0.27 + Float(wave1 * 0.05), 0.5 - Float(wave4 * 0.04)),
                    SIMD2<Float>(0.5 + Float(wave2 * 0.08), 0.5 + Float(wave1 * 0.05)),
                    SIMD2<Float>(0.73 - Float(wave4 * 0.05), 0.5 - Float(wave3 * 0.04)),
                    SIMD2<Float>(1.05 + Float(wave3 * 0.07), 0.5 + Float(wave2 * 0.06)),
                    
                    // Row 4 - extend slightly beyond sides
                    SIMD2<Float>(-0.05 + Float(wave4 * 0.08), 0.75 - Float(wave1 * 0.05)),
                    SIMD2<Float>(0.27 - Float(wave2 * 0.06), 0.77 + Float(wave3 * 0.04)),
                    SIMD2<Float>(0.5 + Float(wave3 * 0.07), 0.76 - Float(wave4 * 0.03)),
                    SIMD2<Float>(0.73 + Float(wave1 * 0.06), 0.77 + Float(wave2 * 0.04)),
                    SIMD2<Float>(1.05 - Float(wave4 * 0.08), 0.75 - Float(wave1 * 0.05)),
                    
                    // Row 5 - extend beyond bottom edge
                    SIMD2<Float>(-0.05, 1.05),  // Extended bottom-left
                    SIMD2<Float>(0.25 + Float(wave3 * 0.03), 1.05 - Float(wave1 * 0.05)),
                    SIMD2<Float>(0.5 - Float(wave2 * 0.03), 1.05 + Float(wave4 * 0.04)),
                    SIMD2<Float>(0.75 + Float(wave1 * 0.03), 1.05 - Float(wave3 * 0.05)),
                    SIMD2<Float>(1.05, 1.05)    // Extended bottom-right
                ]),
                colors: .colors(createRandomColorMatrix(time, colors)),
                background: Color(red: 0.02, green: 0.03, blue: 0.09), // Slightly tinted background
                smoothsColors: true
            )
            .edgesIgnoringSafeArea([.all]) // More explicit than ignoresSafeArea()
        }
        .edgesIgnoringSafeArea([.all])
    }
    
    // Helper method to create a varied, non-patterned color distribution
    private func createRandomColorMatrix(_ time: TimeInterval, _ colors: [Color]) -> [Color] {
        // Get the count of available colors
        let count = colors.count
        
        // Generate multiple time-based parameters for more organic variation
        let t1 = sin(time * 0.011) * 0.5 + 0.5
        let t2 = cos(time * 0.017) * 0.5 + 0.5
        let t3 = sin(time * 0.013 + 0.7) * 0.5 + 0.5
        let t4 = cos(time * 0.019 + 1.3) * 0.5 + 0.5
        let t5 = sin(time * 0.015 + 2.1) * 0.5 + 0.5
        let t6 = cos(time * 0.012 + 0.9) * 0.5 + 0.5
        
        // Prime numbers for non-repeating patterns
        let primes = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37]
        
        // Generate varied offsets with different oscillation frequencies
        let offsets = [
            Int(t1 * 7) + Int(t5 * 3),  Int(t2 * 5) + Int(t6 * 4),  Int(t3 * 6) + Int(t1 * 2),  Int(t4 * 4) + Int(t2 * 5),  Int(t5 * 8) + Int(t3 * 1),
            Int(t6 * 5) + Int(t4 * 3),  Int(t1 * 6) + Int(t5 * 5),  Int(t2 * 7) + Int(t6 * 2),  Int(t3 * 4) + Int(t1 * 6),  Int(t4 * 9) + Int(t2 * 1),
            Int(t5 * 3) + Int(t3 * 7),  Int(t6 * 8) + Int(t4 * 2),  Int(t1 * 4) + Int(t5 * 6),  Int(t2 * 6) + Int(t6 * 3),  Int(t3 * 7) + Int(t1 * 4),
            Int(t4 * 5) + Int(t2 * 7),  Int(t5 * 9) + Int(t3 * 2),  Int(t6 * 4) + Int(t4 * 5),  Int(t1 * 8) + Int(t5 * 1),  Int(t2 * 3) + Int(t6 * 6),
            Int(t3 * 9) + Int(t1 * 2),  Int(t4 * 6) + Int(t2 * 4),  Int(t5 * 4) + Int(t3 * 5),  Int(t6 * 7) + Int(t4 * 3),  Int(t1 * 5) + Int(t5 * 4)
        ]
        
        // Create varied color matrix using different calculations for different positions
        var resultColors: [Color] = []
        
        for i in 0..<25 {
            let primeIndex = i % primes.count
            let prime = primes[primeIndex]
            let positionFactor = (i * prime) % count
            
            // Combine position, offset, and time-based factors for true variety
            let dynamicIndex = (positionFactor + offsets[i] + i) % count
            resultColors.append(colors[dynamicIndex])
        }
        
        return resultColors
    }
    
    public init(colors: [Color] = [
        // Premium elegant color palette
        Color(red: 0.063, green: 0.047, blue: 0.078),  // Premium dark charcoal-purple
        Color(red: 0.031, green: 0.047, blue: 0.094),  // Dark navy blue
        Color(red: 0.075, green: 0.051, blue: 0.102),  // Dark aubergine
        Color(red: 0.043, green: 0.071, blue: 0.125),  // Midnight blue
        Color(red: 0.090, green: 0.063, blue: 0.137),  // Premium violet
        Color(red: 0.047, green: 0.059, blue: 0.114),  // Deep blue-slate
        Color(red: 0.082, green: 0.043, blue: 0.094),  // Rich plum
        Color(red: 0.039, green: 0.078, blue: 0.118),  // Deep teal-navy
        Color(red: 0.098, green: 0.059, blue: 0.114),  // Muted burgundy
        Color(red: 0.122, green: 0.078, blue: 0.149),  // Premium purple accent
        Color(red: 0.055, green: 0.082, blue: 0.133),  // Sapphire blue
        Color(red: 0.133, green: 0.086, blue: 0.161),  // Luxury violet
        Color(red: 0.055, green: 0.047, blue: 0.090),  // Deep indigo
        Color(red: 0.071, green: 0.094, blue: 0.137)   // Steel blue accent
    ], 
             speed: Double = 0.2) { // Reduced default speed
        self.colors = colors
        self.speed = speed
    }
}

// Glass effect container with mesh gradient background
public struct GlassMeshGradientBackground<Content: View>: View {
    private let content: Content
    
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    public var body: some View {
        ZStack {
            ModernGradientBackground()
            
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

// Extension for conditional view modifiers specific to gradient components
extension View {
    public func withGlassMeshGradient() -> some View {
        ZStack {
            ModernGradientBackground()
            self
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        }
    }
    
    public func withModernGradient() -> some View {
        ZStack {
            ModernGradientBackground()
            self
        }
    }
}

// Preview provider
struct MeshGradientBackground_Previews: PreviewProvider {
    static var previews: some View {
        ModernGradientBackground()
    }
} 
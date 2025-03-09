import SwiftUI
import Foundation
import UIKit

/// A sophisticated mesh gradient background with subtle animation
/// Uses the new iOS 18+ MeshGradient API with proper fallback for earlier versions
@available(iOS 18.0, *)
public struct MeshGradientBackground: View {
    // Animation state
    @State private var animationPhase: Double = 0.0
    @State private var isPaused: Bool = false
    @State private var colorPhase: Double = 0.0
    @State private var randomOffsets: [CGFloat] = Array(repeating: 0.0, count: 9)
    @State private var lastColorShiftTime: Date = Date()
    @State private var colorIndexMap: [Int] = [0, 1, 2, 3, 4, 5, 6, 7, 8]
    
    // Color palette - blue tones from https://coolors.co/palette/03045e-023e8a-0077b6-0096c7-00b4d8-48cae4-90e0ef-ade8f4-caf0f8
    private let colors: [Color] = [
        Color(red: 0.012, green: 0.016, blue: 0.369),  // Dark navy - 03045E
        Color(red: 0.008, green: 0.243, blue: 0.541),  // Navy blue - 023E8A
        Color(red: 0.000, green: 0.467, blue: 0.714),  // Strong blue - 0077B6
        Color(red: 0.000, green: 0.588, blue: 0.780),  // Bright blue - 0096C7
        Color(red: 0.000, green: 0.706, blue: 0.847),  // Cyan blue - 00B4D8
        Color(red: 0.282, green: 0.792, blue: 0.894),  // Light cyan - 48CAE4
        Color(red: 0.565, green: 0.878, blue: 0.937),  // Pale cyan - 90E0EF
        Color(red: 0.678, green: 0.910, blue: 0.957),  // Very pale cyan - ADE8F4
        Color(red: 0.792, green: 0.941, blue: 0.973),  // Almost white cyan - CAF0F8
        
        // Derived accent colors
        Color(red: 0.008, green: 0.243, blue: 0.541, opacity: 0.7),  // Navy blue with opacity - 023E8A
        Color(red: 0.012, green: 0.016, blue: 0.369, opacity: 0.8),  // Dark navy with opacity - 03045E
        Color(red: 0.565, green: 0.878, blue: 0.937, opacity: 0.9)   // Pale cyan with opacity - 90E0EF
    ]
    
    // Environment awareness for app state
    @Environment(\.scenePhase) private var scenePhase
    
    // Timer for random color shuffling
    private let colorShuffleTimer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    
    public var body: some View {
        TimelineView(.animation(minimumInterval: 0.05, paused: isPaused)) { timeline in
            let time = timeline.date.timeIntervalSince1970
            
            // Create more organic movement with combined waves of different frequencies
            let points = createDynamicPoints(time: time)
            
            // Get the current color arrangement with continuous hue animation
            let currentColors = animatedColors(for: timeline.date)
            
            MeshGradient(
                width: 3,
                height: 3,
                points: points,
                colors: currentColors,
                background: Color(red: 0.000, green: 0.467, blue: 0.714), // Strong blue background - 0077B6
                smoothsColors: true
            )
            .blur(radius: 6)
            .opacity(scenePhase == .active ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.5), value: scenePhase == .active)
            .ignoresSafeArea(.all)
        }
        .onAppear {
            // Initialize with random offsets
            for i in 0..<randomOffsets.count {
                randomOffsets[i] = CGFloat.random(in: -0.1...0.1)
            }
            // Initialize with random color mapping
            colorIndexMap = Array(0..<9).shuffled()
        }
        .onReceive(colorShuffleTimer) { time in
            // Only shuffle color positions every 8-12 seconds for larger changes
            if time.timeIntervalSince(lastColorShiftTime) > Double.random(in: 8...12) {
                withAnimation(.easeInOut(duration: 3.0)) {
                    shuffleColors()
                }
                lastColorShiftTime = time
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PauseAnimatedBackgrounds"))) { _ in
            isPaused = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ResumeAnimatedBackgrounds"))) { _ in
            isPaused = false
        }
    }
    
    /// Creates dynamic points with organic movement
    private func createDynamicPoints(time: TimeInterval) -> [SIMD2<Float>] {
        // Base movement patterns
        let wave1 = sin(time * 0.02) * 0.05
        let wave2 = cos(time * 0.015) * 0.05
        let wave3 = sin(time * 0.01 + 1.1) * 0.05
        let wave4 = cos(time * 0.017 - 0.7) * 0.05
        
        // Create more complex movement by combining waves
        let complexWave1 = sin(time * 0.023) * cos(time * 0.031) * 0.03
        let complexWave2 = cos(time * 0.019) * sin(time * 0.027) * 0.04
        
        // Extend beyond boundaries - use values outside the 0.0-1.0 range
        // This creates a visually larger gradient that extends past the view edges
        return [
            // Row 1 - extended beyond top-left and top edges
            SIMD2<Float>(-0.2 + Float(randomOffsets[0] + sin(time * 0.03) * 0.03), 
                         -0.2 + Float(randomOffsets[0] + cos(time * 0.025) * 0.03)),
            SIMD2<Float>(0.5 + Float(wave1 + complexWave1 + randomOffsets[1]), 
                         -0.2 + Float(sin(time * 0.022) * 0.04 + randomOffsets[1])),
            SIMD2<Float>(1.2 + Float(randomOffsets[2] + sin(time * 0.028) * 0.03), 
                         -0.2 + Float(randomOffsets[2] + cos(time * 0.024) * 0.03)),
            
            // Row 2 - extended beyond left and right edges
            SIMD2<Float>(-0.2 + Float(sin(time * 0.018) * 0.04 + randomOffsets[3]),
                          0.5 + Float(wave3 + complexWave2 + randomOffsets[3])),
            SIMD2<Float>(0.5 + Float(wave2 + sin(time * 0.021) * cos(time * 0.019) * 0.06 + randomOffsets[4]),
                          0.5 + Float(wave4 + sin(time * 0.025) * 0.07 + randomOffsets[4])),
            SIMD2<Float>(1.2 + Float(sin(time * 0.023) * 0.04 + randomOffsets[5]),
                          0.5 + Float(-wave1 + cos(time * 0.02) * 0.05 + randomOffsets[5])),
            
            // Row 3 - extended beyond bottom-left, bottom and bottom-right edges
            SIMD2<Float>(-0.2 + Float(randomOffsets[6] + sin(time * 0.026) * 0.03),
                          1.2 + Float(randomOffsets[6] + cos(time * 0.022) * 0.03)),
            SIMD2<Float>(0.5 + Float(-wave3 + complexWave1 + randomOffsets[7]),
                          1.2 + Float(sin(time * 0.024) * 0.04 + randomOffsets[7])),
            SIMD2<Float>(1.2 + Float(randomOffsets[8] + sin(time * 0.027) * 0.03),
                          1.2 + Float(randomOffsets[8] + cos(time * 0.023) * 0.03))
        ]
    }
    
    /// Continuously animate colors by shifting hues over time
    private func animatedColors(for date: Date) -> [Color] {
        let phase = CGFloat(date.timeIntervalSince1970)
        
        // Get base colors from our arrangement
        let baseColors = getBaseColors()
        
        // Apply continuous color shifting
        return baseColors.enumerated().map { index, color in
            // Different hue shift patterns for each color creates interesting dynamics
            let hueShift = sin(phase * 0.3 + Double(index) * 0.2) * 0.05
            return shiftHue(of: color, by: hueShift)
        }
    }
    
    /// Shift the hue of a color by a given amount
    private func shiftHue(of color: Color, by amount: Double) -> Color {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        // Convert to UIColor to access HSB components
        UIColor(color).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        // Apply hue shift
        hue += CGFloat(amount)
        // Keep hue in valid range (0 to 1)
        hue = hue.truncatingRemainder(dividingBy: 1.0)
        if hue < 0 {
            hue += 1
        }
        
        // Create new color with shifted hue
        return Color(hue: Double(hue), saturation: Double(saturation), brightness: Double(brightness), opacity: Double(alpha))
    }
    
    /// Shuffle the color mapping for a smooth transition
    private func shuffleColors() {
        // Create a new shuffled arrangement but retain some colors for continuity
        var newMapping = colorIndexMap
        
        // Swap a few random positions (2-4 swaps)
        let swapCount = Int.random(in: 2...4)
        for _ in 0..<swapCount {
            let i = Int.random(in: 0..<colorIndexMap.count)
            let j = Int.random(in: 0..<colorIndexMap.count)
            if i != j {
                newMapping.swapAt(i, j)
            }
        }
        
        colorIndexMap = newMapping
    }
    
    /// Get base colors arrangement based on the colorIndexMap
    private func getBaseColors() -> [Color] {
        // Strategic arrangement with darker blues at edges and lighter blues in center
        let baseColors: [Color] = [
            colors[0],  colors[4], colors[0],  // Top row - dark navy at corners, cyan blue in middle
            colors[1],  colors[6], colors[1],  // Middle row - navy blue at sides, pale cyan in center
            colors[0],  colors[4], colors[0]   // Bottom row - dark navy at corners, cyan blue in middle
        ]
        
        var arrangedColors: [Color] = Array(repeating: .clear, count: 9)
        
        // Map the colors according to our current index mapping
        for i in 0..<colorIndexMap.count {
            arrangedColors[i] = baseColors[colorIndexMap[i]]
        }
        
        return arrangedColors
    }
    
    public init() {}
}

/// A fallback gradient for iOS versions before 18.0
public struct FallbackGradientBackground: View {
    @State private var isPaused: Bool = false
    @State private var animationOffset: CGFloat = 0
    @State private var animationPhase: Double = 0
    @State private var colorPhase: Double = 0
    @State private var lastColorShiftTime: Date = Date()
    
    // Base colors for animation - using the new blue palette
    private let baseColors: [Color] = [
        Color(red: 0.012, green: 0.016, blue: 0.369),  // Dark navy - 03045E
        Color(red: 0.008, green: 0.243, blue: 0.541),  // Navy blue - 023E8A
        Color(red: 0.000, green: 0.467, blue: 0.714),  // Strong blue - 0077B6
        Color(red: 0.000, green: 0.588, blue: 0.780),  // Bright blue - 0096C7
        Color(red: 0.000, green: 0.706, blue: 0.847),  // Cyan blue - 00B4D8
        Color(red: 0.282, green: 0.792, blue: 0.894),  // Light cyan - 48CAE4
        Color(red: 0.565, green: 0.878, blue: 0.937),  // Pale cyan - 90E0EF
        Color(red: 0.792, green: 0.941, blue: 0.973)   // Almost white cyan - CAF0F8
    ]
    
    // Environment awareness
    @Environment(\.scenePhase) private var scenePhase
    
    public var body: some View {
        TimelineView(.animation(minimumInterval: 0.05, paused: isPaused)) { timeline in
            let time = timeline.date.timeIntervalSince1970
            let animatedColors = getAnimatedColors(for: timeline.date)
            
            ZStack {
                // Base gradient with slow movement - soft pastels
                LinearGradient(
                    gradient: Gradient(colors: [
                        animatedColors[0],
                        animatedColors[1],
                        animatedColors[2],
                        animatedColors[3]
                    ]),
                    startPoint: UnitPoint(x: 0, y: 0 + animationOffset),
                    endPoint: UnitPoint(x: 1, y: 1 + animationOffset)
                )
                
                // Second gradient with counter movement - deeper pastel accents
                LinearGradient(
                    gradient: Gradient(colors: [
                        animatedColors[4].opacity(0.15),
                        animatedColors[5].opacity(0.15),
                        animatedColors[6].opacity(0.12),
                        animatedColors[7].opacity(0.15)
                    ]),
                    startPoint: UnitPoint(x: 1, y: 0 - animationOffset),
                    endPoint: UnitPoint(x: 0, y: 1 - animationOffset)
                )
                .blendMode(.multiply)
                
                // Multiple pulsing radial gradients with random movement
                ForEach(0..<3, id: \.self) { index in
                    RadialGradient(
                        gradient: Gradient(colors: getRandomGradientColors(index: index, colors: animatedColors, time: time)),
                        center: getRandomCenter(index: index, time: animationPhase),
                        startRadius: 80 + getRandomRadius(index: index, phase: animationPhase, isStart: true),
                        endRadius: 250 + getRandomRadius(index: index, phase: animationPhase, isStart: false)
                    )
                    .blendMode(.multiply)
                }
                
                // Additional moving color accents
                ZStack {
                    Circle()
                        .fill(animatedColors[4].opacity(0.18))
                        .frame(width: 120 + (sin(animationPhase) * 30), height: 120 + (sin(animationPhase) * 30))
                        .position(x: UIScreen.main.bounds.width * (0.2 + sin(animationPhase * 0.3) * 0.05), 
                                y: UIScreen.main.bounds.height * (0.3 + cos(animationPhase * 0.4) * 0.05))
                        .blur(radius: 20)
                    
                    Circle()
                        .fill(animatedColors[6].opacity(0.20))
                        .frame(width: 150 + (cos(animationPhase) * 40), height: 150 + (cos(animationPhase) * 40))
                        .position(x: UIScreen.main.bounds.width * (0.7 + cos(animationPhase * 0.5) * 0.05), 
                                y: UIScreen.main.bounds.height * (0.7 + sin(animationPhase * 0.6) * 0.05))
                        .blur(radius: 25)
                    
                    // Add a third moving element
                    Circle()
                        .fill(animatedColors[7].opacity(0.15))
                        .frame(width: 180 + (sin(animationPhase * 0.7) * 35), 
                            height: 180 + (sin(animationPhase * 0.7) * 35))
                        .position(x: UIScreen.main.bounds.width * (0.4 + sin(animationPhase * 0.4) * 0.08), 
                                y: UIScreen.main.bounds.height * (0.5 + cos(animationPhase * 0.3) * 0.08))
                        .blur(radius: 30)
                }
            }
            .blur(radius: 6)
            .opacity(scenePhase == .active ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.5), value: scenePhase == .active)
            .ignoresSafeArea(.all)
        }
        .onAppear {
            if !isPaused {
                startAnimations()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PauseAnimatedBackgrounds"))) { _ in
            isPaused = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ResumeAnimatedBackgrounds"))) { _ in
            isPaused = false
            if !isPaused {
                startAnimations()
            }
        }
    }
    
    // Animate colors by shifting hues over time
    private func getAnimatedColors(for date: Date) -> [Color] {
        let phase = CGFloat(date.timeIntervalSince1970)
        
        return baseColors.enumerated().map { index, color in
            let hueShift = sin(phase * 0.2 + Double(index) * 0.3) * 0.05
            return shiftHue(of: color, by: hueShift)
        }
    }
    
    // Shift the hue of a color
    private func shiftHue(of color: Color, by amount: Double) -> Color {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        UIColor(color).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        hue += CGFloat(amount)
        hue = hue.truncatingRemainder(dividingBy: 1.0)
        if hue < 0 {
            hue += 1
        }
        
        return Color(hue: Double(hue), saturation: Double(saturation), brightness: Double(brightness), opacity: Double(alpha))
    }
    
    // Get random gradient colors for radial gradients
    private func getRandomGradientColors(index: Int, colors: [Color], time: TimeInterval) -> [Color] {
        let pastelColors = [
            colors[5].opacity(0.10 + (sin(animationPhase + Double(index)) * 0.05)),
            colors[7].opacity(0.10 + (cos(animationPhase * 0.7 + Double(index)) * 0.05)),
            colors[3].opacity(0.10 + (sin(animationPhase * 1.2 + Double(index)) * 0.05)),
            colors[0].opacity(0.0)
        ]
        
        // Use a different starting color based on the index and current phase
        let startIndex = (index + Int(animationPhase * 0.5)) % 3
        return [pastelColors[startIndex], pastelColors[3]]
    }
    
    // Get random center point that changes over time
    private func getRandomCenter(index: Int, time: Double) -> UnitPoint {
        let baseX = [0.3, 0.7, 0.5][index]
        let baseY = [0.7, 0.3, 0.5][index]
        
        let offsetX = sin(time * 0.3 + Double(index) * 0.7) * 0.2
        let offsetY = cos(time * 0.4 + Double(index) * 0.5) * 0.2
        
        return UnitPoint(x: baseX + offsetX, y: baseY + offsetY)
    }
    
    // Get random radius that changes over time
    private func getRandomRadius(index: Int, phase: Double, isStart: Bool) -> CGFloat {
        let base = isStart ? 50.0 + Double(index) * 15.0 : 150.0 + Double(index) * 50.0
        let multiplier = isStart ? 20.0 : 50.0
        let offset = sin(phase * 0.5 + Double(index) * 0.7) * multiplier
        
        return CGFloat(base + offset)
    }
    
    private func startAnimations() {
        // Multiple animations with different timing for more organic movement
        withAnimation(Animation.easeInOut(duration: 20).repeatForever(autoreverses: true)) {
            animationOffset = 0.3
        }
        
        // Faster animation phase for more dynamic movement
        withAnimation(Animation.easeInOut(duration: 15).repeatForever(autoreverses: false)) {
            animationPhase = .pi * 2
        }
        
        // Color phase animation for color transitions
        withAnimation(Animation.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
            colorPhase = 1.0
        }
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

// A customizable version with color parameters (iOS 18+)
@available(iOS 18.0, *)
public struct CustomMeshGradientBackground: View {
    private let colors: [Color]
    private let speed: Double
    private let isPaused: Bool
    
    @State private var randomOffsets: [CGFloat] = Array(repeating: 0.0, count: 9)
    @State private var colorIndexMap: [Int] = [0, 1, 2, 3, 4, 5, 6, 7, 8]
    @State private var lastColorShiftTime: Date = Date()
    
    // Timer for random color shuffling
    private let colorShuffleTimer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    
    @Environment(\.scenePhase) private var scenePhase
    
    public var body: some View {
        TimelineView(.animation(minimumInterval: 0.05, paused: isPaused)) { timeline in
            let time = timeline.date.timeIntervalSince1970 * speed
            
            // Create more organic movement with combined waves of different frequencies
            let points = createDynamicPoints(time: time)
            
            // Get current color arrangement with animated hue shifts
            let currentColors = animatedColors(for: timeline.date)
            
            MeshGradient(
                width: 3,
                height: 3,
                points: points,
                colors: currentColors,
                background: Color(red: 0.000, green: 0.467, blue: 0.714), // Strong blue background - 0077B6
                smoothsColors: true
            )
            .blur(radius: 6)
            .opacity(scenePhase == .active ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.5), value: scenePhase == .active)
            .ignoresSafeArea(.all)
        }
        .onAppear {
            // Initialize with random offsets
            for i in 0..<randomOffsets.count {
                randomOffsets[i] = CGFloat.random(in: -0.1...0.1)
            }
            // Initialize with random color mapping
            colorIndexMap = Array(0..<9).shuffled()
        }
        .onReceive(colorShuffleTimer) { time in
            // Only shuffle colors every 10-15 seconds
            if time.timeIntervalSince(lastColorShiftTime) > Double.random(in: 10...15) {
                withAnimation(.easeInOut(duration: 3.0)) {
                    shuffleColors()
                }
                lastColorShiftTime = time
            }
        }
    }
    
    /// Creates dynamic points with organic movement
    private func createDynamicPoints(time: TimeInterval) -> [SIMD2<Float>] {
        // Base movement patterns
        let wave1 = sin(time * 0.02) * 0.05
        let wave2 = cos(time * 0.015) * 0.05
        let wave3 = sin(time * 0.01 + 1.1) * 0.05
        let wave4 = cos(time * 0.017 - 0.7) * 0.05
        
        // Create more complex movement by combining waves
        let complexWave1 = sin(time * 0.023) * cos(time * 0.031) * 0.03
        let complexWave2 = cos(time * 0.019) * sin(time * 0.027) * 0.04
        
        // Extend beyond boundaries - use values outside the 0.0-1.0 range
        // This creates a visually larger gradient that extends past the view edges
        return [
            // Row 1 - extended beyond top-left and top edges
            SIMD2<Float>(-0.2 + Float(randomOffsets[0] + sin(time * 0.03) * 0.03), 
                         -0.2 + Float(randomOffsets[0] + cos(time * 0.025) * 0.03)),
            SIMD2<Float>(0.5 + Float(wave1 + complexWave1 + randomOffsets[1]), 
                         -0.2 + Float(sin(time * 0.022) * 0.04 + randomOffsets[1])),
            SIMD2<Float>(1.2 + Float(randomOffsets[2] + sin(time * 0.028) * 0.03), 
                         -0.2 + Float(randomOffsets[2] + cos(time * 0.024) * 0.03)),
            
            // Row 2 - extended beyond left and right edges
            SIMD2<Float>(-0.2 + Float(sin(time * 0.018) * 0.04 + randomOffsets[3]),
                          0.5 + Float(wave3 + complexWave2 + randomOffsets[3])),
            SIMD2<Float>(0.5 + Float(wave2 + sin(time * 0.021) * cos(time * 0.019) * 0.06 + randomOffsets[4]),
                          0.5 + Float(wave4 + sin(time * 0.025) * 0.07 + randomOffsets[4])),
            SIMD2<Float>(1.2 + Float(sin(time * 0.023) * 0.04 + randomOffsets[5]),
                          0.5 + Float(-wave1 + cos(time * 0.02) * 0.05 + randomOffsets[5])),
            
            // Row 3 - extended beyond bottom-left, bottom and bottom-right edges
            SIMD2<Float>(-0.2 + Float(randomOffsets[6] + sin(time * 0.026) * 0.03),
                          1.2 + Float(randomOffsets[6] + cos(time * 0.022) * 0.03)),
            SIMD2<Float>(0.5 + Float(-wave3 + complexWave1 + randomOffsets[7]),
                          1.2 + Float(sin(time * 0.024) * 0.04 + randomOffsets[7])),
            SIMD2<Float>(1.2 + Float(randomOffsets[8] + sin(time * 0.027) * 0.03),
                          1.2 + Float(randomOffsets[8] + cos(time * 0.023) * 0.03))
        ]
    }
    
    /// Continuously animate colors by shifting hues over time
    private func animatedColors(for date: Date) -> [Color] {
        let phase = CGFloat(date.timeIntervalSince1970 * speed)
        
        // Get base colors from our arrangement
        let baseColors = createBaseColorMatrix(colors)
        
        // Apply continuous color shifting
        return baseColors.enumerated().map { index, color in
            // Different hue shift patterns for each color creates interesting dynamics
            let hueShift = sin(phase * 0.3 + Double(index) * 0.2) * 0.07
            return shiftHue(of: color, by: hueShift)
        }
    }
    
    /// Shift the hue of a color by a given amount
    private func shiftHue(of color: Color, by amount: Double) -> Color {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        // Convert to UIColor to access HSB components
        UIColor(color).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        // Apply hue shift
        hue += CGFloat(amount)
        // Keep hue in valid range (0 to 1)
        hue = hue.truncatingRemainder(dividingBy: 1.0)
        if hue < 0 {
            hue += 1
        }
        
        // Create new color with shifted hue
        return Color(hue: Double(hue), saturation: Double(saturation), brightness: Double(brightness), opacity: Double(alpha))
    }
    
    /// Shuffle the color mapping for a smooth transition
    private func shuffleColors() {
        // Create a new shuffled arrangement but retain some colors for continuity
        var newMapping = colorIndexMap
        
        // Swap a few random positions (2-4 swaps)
        let swapCount = Int.random(in: 2...4)
        for _ in 0..<swapCount {
            let i = Int.random(in: 0..<colorIndexMap.count)
            let j = Int.random(in: 0..<colorIndexMap.count)
            if i != j {
                newMapping.swapAt(i, j)
            }
        }
        
        colorIndexMap = newMapping
    }
    
    // Strategic color placement for visual interest
    private func createBaseColorMatrix(_ colors: [Color]) -> [Color] {
        // Strategic arrangement with darker blues at edges and lighter blues in center
        let baseColors: [Color] = [
            colors[0],  colors[4], colors[0],  // Top row - dark navy at corners, cyan blue in middle
            colors[1],  colors[6], colors[1],  // Middle row - navy blue at sides, pale cyan in center
            colors[0],  colors[4], colors[0]   // Bottom row - dark navy at corners, cyan blue in middle
        ]
        
        // Apply the current color mapping
        var arrangedColors: [Color] = Array(repeating: .clear, count: 9)
        for i in 0..<colorIndexMap.count {
            arrangedColors[i] = baseColors[colorIndexMap[i]]
        }
        
        return arrangedColors
    }
    
    public init(colors: [Color] = [
        // Blue color palette from https://coolors.co/palette/03045e-023e8a-0077b6-0096c7-00b4d8-48cae4-90e0ef-ade8f4-caf0f8
        Color(red: 0.012, green: 0.016, blue: 0.369),  // Dark navy - 03045E
        Color(red: 0.008, green: 0.243, blue: 0.541),  // Navy blue - 023E8A
        Color(red: 0.000, green: 0.467, blue: 0.714),  // Strong blue - 0077B6
        Color(red: 0.000, green: 0.588, blue: 0.780),  // Bright blue - 0096C7
        Color(red: 0.000, green: 0.706, blue: 0.847),  // Cyan blue - 00B4D8
        Color(red: 0.282, green: 0.792, blue: 0.894),  // Light cyan - 48CAE4
        Color(red: 0.565, green: 0.878, blue: 0.937),  // Pale cyan - 90E0EF
        Color(red: 0.678, green: 0.910, blue: 0.957),  // Very pale cyan - ADE8F4
        Color(red: 0.792, green: 0.941, blue: 0.973),  // Almost white cyan - CAF0F8
        
        // Derived accent colors
        Color(red: 0.008, green: 0.243, blue: 0.541, opacity: 0.7),  // Navy blue with opacity - 023E8A
        Color(red: 0.012, green: 0.016, blue: 0.369, opacity: 0.8),  // Dark navy with opacity - 03045E
        Color(red: 0.565, green: 0.878, blue: 0.937, opacity: 0.9)   // Pale cyan with opacity - 90E0EF
    ], speed: Double = 0.5, isPaused: Bool = false) {
        self.colors = colors
        self.speed = speed
        self.isPaused = isPaused
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

#Preview {
    ModernGradientBackground()
} 
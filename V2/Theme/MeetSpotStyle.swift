import SwiftUI

// MARK: - Design System
struct MeetSpotStyle {
    struct Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let xlarge: CGFloat = 32
    }
    
    struct Radius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xlarge: CGFloat = 24
    }
    
    struct Typography {
        static let heading1: Font = .system(size: 28, weight: .bold)
        static let heading2: Font = .system(size: 24, weight: .bold)
        static let heading3: Font = .system(size: 20, weight: .bold)
        static let body: Font = .system(size: 16, weight: .regular)
        static let caption: Font = .system(size: 14, weight: .regular)
        static let small: Font = .system(size: 12, weight: .regular)
        
        static func heading1(_ text: String) -> some View {
            Text(text)
                .font(heading1)
                .foregroundColor(.white)
        }
        
        static func heading2(_ text: String) -> some View {
            Text(text)
                .font(heading2)
                .foregroundColor(.white)
        }
        
        static func heading3(_ text: String) -> some View {
            Text(text)
                .font(heading3)
                .foregroundColor(.white)
        }
        
        static func subtitle(_ text: String) -> some View {
            Text(text)
                .font(heading3)
                .foregroundColor(MeetSpotColors.textSecondary)
        }
        
        static func bodyText(_ text: String) -> some View {
            Text(text)
                .font(body)
                .foregroundColor(MeetSpotColors.purple200.opacity(0.8))
        }
        
        static func caption(_ text: String) -> some View {
            Text(text)
                .font(caption)
                .foregroundColor(MeetSpotColors.purple200.opacity(0.7))
        }
    }
    
    struct Animation {
        static let spring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let easeInOut = SwiftUI.Animation.easeInOut(duration: 0.3)
    }
    
    static let shadowColor = Color.black.opacity(0.25)
    static let shadowRadius: CGFloat = 10
}

// MARK: - Color Palette
struct MeetSpotColors {
    static let background = Color("Background")
    static let surface = Color.white.opacity(0.1)
    static let text = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    
    static let pink500 = Color(hex: "#FF4B93" as String)
    static let purple200 = Color(hex: "#E5D4FF" as String)
    static let purple900 = Color(hex: "#4A1D96" as String)
    
    static let primaryGradient = LinearGradient(
        colors: [Color.white, Color.white],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let secondaryGradient = LinearGradient(
        colors: [Color.white, Color.white],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let accentGradient = LinearGradient(
        colors: [Color.white, Color.white],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let backgroundGradient = LinearGradient(
        colors: [Color(hex: "#0F172A" as String), Color(hex: "#020617" as String)],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Typography
struct MeetSpotType {
    static let heading1: Font = .system(size: 28, weight: .bold)
    static let heading2: Font = .system(size: 24, weight: .bold)
    static let heading3: Font = .system(size: 20, weight: .bold)
    static let body: Font = .system(size: 16, weight: .regular)
    static let caption: Font = .system(size: 14, weight: .regular)
    static let small: Font = .system(size: 12, weight: .regular)
    
    static func title(_ text: String) -> some View {
        Text(text)
            .font(heading1)
            .foregroundColor(.white)
    }
    
    static func subtitle(_ text: String) -> some View {
        Text(text)
            .font(heading3)
            .foregroundColor(.white)
    }
    
    static func bodyText(_ text: String) -> some View {
        Text(text)
            .font(body)
            .foregroundColor(MeetSpotColors.purple200.opacity(0.8))
    }
    
    static func caption(_ text: String) -> some View {
        Text(text)
            .font(caption)
            .foregroundColor(MeetSpotColors.purple200.opacity(0.7))
    }
}

// MARK: - UI Components
struct MeetSpotUI {
    struct Cards {
        static func meetCard<Content: View>(
            @ViewBuilder content: @escaping () -> Content
        ) -> some View {
            content()
                .padding()
                .background(MeetSpotColors.primaryGradient)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        }
        
        static func profileCard<Content: View>(
            @ViewBuilder content: @escaping () -> Content
        ) -> some View {
            content()
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
    
    struct Badges {
        static func status(_ text: String) -> some View {
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.black)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black, lineWidth: 1)
                )
        }
    }
    
    struct Buttons {
        static func primary(_ text: String) -> some View {
            Text(text)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black, lineWidth: 1.5)
                )
        }
        
        static func secondary(_ text: String) -> some View {
            Text(text)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.8))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black.opacity(0.7), lineWidth: 1)
                )
        }
    }
}

// MARK: - Animation
struct MeetSpotAnimation {
    static let spring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let easeInOut = SwiftUI.Animation.easeInOut(duration: 0.3)
}

// MARK: - Shadow Styles

struct MeetSpotShadow {
    var color: Color
    var radius: CGFloat
    var x: CGFloat
    var y: CGFloat
    
    static let subtleShadow = MeetSpotShadow(
        color: .black.opacity(0.1),
        radius: 4,
        x: 0,
        y: 2
    )
    
    static let mediumShadow = MeetSpotShadow(
        color: .black.opacity(0.15),
        radius: 6,
        x: 0,
        y: 3
    )
    
    static let pronouncedShadow = MeetSpotShadow(
        color: .black.opacity(0.2),
        radius: 10,
        x: 0,
        y: 5
    )
}

// MARK: - Extensions
extension View {
    func glassEffect(cornerRadius: CGFloat = MeetSpotStyle.Radius.medium) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.white.opacity(0.1))
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Material.ultraThinMaterial)
                )
                .shadow(color: MeetSpotShadow.pronouncedShadow.color, radius: MeetSpotShadow.pronouncedShadow.radius)
        )
    }
    
    // Shadow extensions have been moved to ViewExtensions.swift
} 
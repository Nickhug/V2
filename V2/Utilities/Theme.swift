import SwiftUI

enum Theme {
    enum Colors {
        // Primary Gradients
        static let primaryGradient: LinearGradient = LinearGradient(
            gradient: Gradient(colors: [
                Color.init(hex: "2D3282"),
                Color.init(hex: "6D28D9")
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Secondary Gradients
        static let secondaryGradient: LinearGradient = LinearGradient(
            gradient: Gradient(colors: [
                Color.init(hex: "9333EA"),
                Color.init(hex: "EC4899")
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
        
        // Accent Gradients
        static let accentGradient: LinearGradient = LinearGradient(
            gradient: Gradient(colors: [
                Color.init(hex: "EC4899"),
                Color.init(hex: "8B5CF6")
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Background Gradient
        static let backgroundGradient: LinearGradient = LinearGradient(
            gradient: Gradient(colors: [
                Color.init(hex: "0F172A"),
                Color.init(hex: "1E293B")
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Solid Colors
        static let primary = Color.init(hex: "2D3282")    // Indigo 900
        static let secondary = Color.init(hex: "9333EA")   // Purple 600
        static let accent = Color.init(hex: "EC4899")      // Pink 500
        static let background = Color.init(hex: "0F172A")  // Slate 900
        static let surface = Color.init(hex: "1E293B")     // Slate 800
        static let text = Color.white
        static let textSecondary = Color.white.opacity(0.7)
        static let success = Color.init(hex: "10B981")     // Green 500
        static let error = Color.init(hex: "EF4444")       // Red 500
        static let warning = Color.init(hex: "F59E0B")     // Amber 500
        static let info = Color.init(hex: "3B82F6")        // Blue 500
    }
    
    enum Icons {
        static func mapAnnotationIcon(for type: V2MeetType, isPremium: Bool = false) -> some View {
            ZStack {
                // Background circle with gradient
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                isPremium ? Color(red: 0.95, green: 0.8, blue: 0.3) : Color(red: 0.2, green: 0.2, blue: 0.2),
                                isPremium ? Color(red: 0.9, green: 0.7, blue: 0.2) : Color(red: 0.15, green: 0.15, blue: 0.15)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                
                // Main icon
                Image(systemName: type.iconName)
                    .font(.system(size: 20, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(.white)
                
                // Premium badge
                if isPremium {
                    Circle()
                        .fill(Color(red: 0.95, green: 0.8, blue: 0.3))
                        .frame(width: 16, height: 16)
                        .overlay(
                            Image(systemName: "star.fill")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                        .offset(x: 12, y: -12)
                }
            }
        }
        
        static func vehicleIcon(for type: V2MeetType) -> String {
            switch type {
            case .car:
                return "car.fill"
            case .bike:
                return "bicycle"
            case .mixed:
                return "car.and.bicycle"
            }
        }
    }
    
    enum Typography {
        static let heading1 = Font.system(size: 28, weight: .bold)
        static let heading2 = Font.system(size: 24, weight: .bold)
        static let heading3 = Font.system(size: 20, weight: .bold)
        static let body = Font.system(size: 16, weight: .regular)
        static let caption = Font.system(size: 14, weight: .regular)
        static let small = Font.system(size: 12, weight: .regular)
        
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
                .foregroundColor(Color.init(hex: "E9D5FF").opacity(0.8))
        }
        
        static func caption(_ text: String) -> some View {
            Text(text)
                .font(caption)
                .foregroundColor(Color.init(hex: "E9D5FF").opacity(0.7))
        }
        
        static func badge(_ text: String) -> some View {
            Text(text)
                .font(.system(size: 10, weight: .medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Colors.success.opacity(0.2))
                .foregroundColor(Colors.success)
                .clipShape(Capsule())
        }
    }
    
    enum Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 32
    }
    
    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 24
    }
    
    enum Animation {
        static let spring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let easeOut = SwiftUI.Animation.easeOut(duration: 0.2)
        static let easeInOut = SwiftUI.Animation.easeInOut(duration: 0.3)
    }
    
    static let cardBackground = Colors.surface.opacity(0.3)
    static let shadowColor = Color.black.opacity(0.3)
    static let shadowRadius: CGFloat = 10
}

// MARK: - View Modifiers
extension View {
    func gradientBackground(_ gradient: LinearGradient = Theme.Colors.primaryGradient) -> some View {
        self.background(gradient)
    }
} 
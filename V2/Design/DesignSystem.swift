import SwiftUI

enum DesignSystem {
    enum Colors {
        static let backgroundGradient = LinearGradient(
            colors: [
                Color(hex: "#1a1f36"),  // Dark blue
                Color(hex: "#2d1b4e"),  // Deep purple
                Color(hex: "#3b1d61")   // Rich purple
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let accentGradient = LinearGradient(
            colors: [
                Color(hex: "#EC4899"),  // Pink
                Color(hex: "#8B5CF6")   // Purple
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        
        static let text = Color.white
        static let textSecondary = Color.white.opacity(0.8)
        static let textTertiary = Color.white.opacity(0.6)
    }
    
    enum Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 32
    }
    
    enum Typography {
        static let largeTitle = Font.system(size: 32, weight: .bold)
        static let title = Font.system(size: 24, weight: .bold)
        static let headline = Font.system(size: 20, weight: .semibold)
        static let body = Font.system(size: 16, weight: .regular)
        static let caption = Font.system(size: 14, weight: .regular)
    }
    
    struct GlassCard: ViewModifier {
        func body(content: Content) -> some View {
            content
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
    
    struct GradientButton: View {
        let title: String
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Colors.accentGradient)
                    .clipShape(Capsule())
            }
        }
    }
    
    struct AvatarView: View {
        let image: Image?
        let size: CGFloat
        
        init(image: Image? = nil, size: CGFloat = 48) {
            self.image = image
            self.size = size
        }
        
        var body: some View {
            Circle()
                .fill(Colors.accentGradient)
                .frame(width: size, height: size)
                .overlay(
                    image?
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                )
                .overlay(
                    Circle()
                        .strokeBorder(.white.opacity(0.2), lineWidth: 2)
                )
        }
    }
    
    struct StatsView: View {
        let icon: String
        let value: String
        let label: String
        
        var body: some View {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(Color(hex: "#EC4899"))
                Text(value)
                    .foregroundColor(.white.opacity(0.8))
                Text(label)
                    .foregroundColor(.white.opacity(0.6))
            }
            .font(.subheadline)
        }
    }
}

extension View {
    func glassCard() -> some View {
        modifier(DesignSystem.GlassCard())
    }
} 
import SwiftUI
import Foundation

// MARK: - Common View Extensions
extension View {
    // Placeholder for TextField
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
    
    // Corner radius modifier for specific corners
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
    
    // Various shadow styles
    func pronouncedShadow() -> some View {
        self.shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
    
    func mediumShadow() -> some View {
        self.shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
    }
    
    func subtleShadow() -> some View {
        self.shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Custom Shapes
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
} 
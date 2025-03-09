import SwiftUI
import Foundation

// MARK: - Common View Extensions
extension View {
    // MARK: - RouteViewModel Support
    
    /// Provides a shared RouteViewModel to the view hierarchy
    func withRouteViewModel() -> some View {
        self.environmentObject(RouteViewModel())
    }
    
    /// Provides a shared RouteViewModel with an existing instance
    func withRouteViewModel(_ viewModel: RouteViewModel) -> some View {
        self.environmentObject(viewModel)
    }
    
    // MARK: - Conditional Rendering
    
    @ViewBuilder
    func `if`<Transform: View>(
        _ condition: Bool,
        transform: (Self) -> Transform
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    // MARK: - UI Styling
    
    // Placeholder for TextField
    func viewPlaceholder<Content: View>(
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
    
    // Add the withoutAnimation helper to properly disable animations
    func withoutAnimation(_ action: @escaping () -> Void) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        transaction.animation = nil
        withTransaction(transaction) {
            action()
        }
    }
    
    // Conditional modifier for view transitions
    @ViewBuilder
    func ifNotInTransition<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// Helper to disable animations for a transaction
extension Transaction {
    mutating func disableAnimations() {
        self.disablesAnimations = true
        self.animation = nil
    }
}

// Helper to properly disable animations for a view
struct NoAnimationModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            // Disable all animations at the transaction level
            .transaction { transaction in
                transaction.disablesAnimations = true
                transaction.animation = nil
            }
            // Explicitly disable animations for state changes
            .animation(nil, value: UUID())
            // Remove any existing animations
            // Removing deprecated .animation(nil) call
            // Prevent animation from parent views
            .compositingGroup()
            // Additional measures to prevent animation conflicts
            .contentShape(Rectangle())
    }
}

extension View {
    // More comprehensive animation disabling
    func noAnimation() -> some View {
        self.modifier(NoAnimationModifier())
    }
    
    // Safe wrapper for environment objects to prevent animation issues
    func safeEnvironmentObject<T: ObservableObject>(_ object: T) -> some View {
        self
            .environmentObject(object)
            .transaction { transaction in
                transaction.disablesAnimations = true
            }
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

// MARK: - Navigation Bar Appearance
extension View {
    func navigationBarAppearance(backgroundColor: Color, textColor: Color) -> some View {
        self.modifier(NavigationBarAppearanceModifier(backgroundColor: backgroundColor, textColor: textColor))
    }
}

struct NavigationBarAppearanceModifier: ViewModifier {
    var backgroundColor: Color
    var textColor: Color
    
    init(backgroundColor: Color, textColor: Color) {
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        
        let coloredAppearance = UINavigationBarAppearance()
        if backgroundColor == .clear {
            coloredAppearance.configureWithTransparentBackground()
        } else {
            coloredAppearance.configureWithDefaultBackground()
            coloredAppearance.backgroundColor = UIColor(backgroundColor)
        }
        
        coloredAppearance.titleTextAttributes = [.foregroundColor: UIColor(textColor)]
        coloredAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(textColor)]
        
        UINavigationBar.appearance().standardAppearance = coloredAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = coloredAppearance
        UINavigationBar.appearance().compactAppearance = coloredAppearance
        UINavigationBar.appearance().tintColor = UIColor(textColor)
    }
    
    func body(content: Content) -> some View {
        content
    }
} 
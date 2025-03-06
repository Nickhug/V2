import SwiftUI

struct CardView<Content: View>: View {
    let content: Content
    var hasGradientOverlay: Bool = false
    var aspectRatio: CGFloat = 1.5
    var style: CardStyle = .regular
    var isInteractive: Bool = false
    
    enum CardStyle {
        case regular
        case glass
        case featured
    }
    
    init(
        style: CardStyle = .regular,
        hasGradientOverlay: Bool = false,
        aspectRatio: CGFloat = 1.5,
        isInteractive: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.hasGradientOverlay = hasGradientOverlay
        self.aspectRatio = aspectRatio
        self.style = style
        self.isInteractive = isInteractive
    }
    
    var body: some View {
        content
            .aspectRatio(aspectRatio, contentMode: .fill)
            .clipShape(RoundedRectangle(cornerRadius: style == .featured ? Theme.CornerRadius.large : Theme.CornerRadius.medium))
            .if(hasGradientOverlay) { view in
                view.overlay(
                    LinearGradient(
                        colors: [
                            Theme.Colors.surface.opacity(0.7),
                            Theme.Colors.surface.opacity(0.3)
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .clipShape(RoundedRectangle(cornerRadius: style == .featured ? Theme.CornerRadius.large : Theme.CornerRadius.medium))
                )
            }
            .if(style == .glass) { view in
                view.modifier(GlassEffect())
            }
            .if(style == .featured) { view in
                view.modifier(FeaturedEffect())
            }
            .if(style == .regular) { view in
                view.modifier(RegularEffect())
            }
            .scaleEffect(isInteractive ? 0.98 : 1)
            .animation(Theme.Animation.spring, value: isInteractive)
    }
}

private struct GlassEffect: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .fill(Theme.Colors.surface.opacity(0.4))
            )
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
            .shadow(
                color: Theme.shadowColor,
                radius: Theme.shadowRadius * 0.7,
                x: 0,
                y: 8
            )
    }
}

private struct FeaturedEffect: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                    .fill(Theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                    .stroke(Theme.Colors.accent.opacity(0.2), lineWidth: 1)
            )
            .shadow(
                color: Theme.shadowColor,
                radius: Theme.shadowRadius * 1.2,
                x: 0,
                y: 12
            )
    }
}

private struct RegularEffect: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .fill(Theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
            .shadow(
                color: Theme.shadowColor,
                radius: Theme.shadowRadius * 0.7,
                x: 0,
                y: 8
            )
    }
} 
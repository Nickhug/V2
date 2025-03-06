import SwiftUI

struct NavigationBar: View {
    enum Style {
        case large
        case compact
    }
    
    let title: String
    var subtitle: String? = nil
    var style: Style = .large
    var leadingButton: (() -> AnyView)? = nil
    var trailingButton: (() -> AnyView)? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Top bar with buttons
            HStack(spacing: Theme.Spacing.medium) {
                if let leadingButton = leadingButton {
                    leadingButton()
                }
                
                if style == .compact {
                    Text(title)
                        .font(Theme.Typography.heading3)
                        .foregroundColor(Theme.Colors.text)
                }
                
                Spacer()
                
                if let trailingButton = trailingButton {
                    trailingButton()
                }
            }
            .padding(.horizontal, Theme.Spacing.medium)
            .frame(height: 44)
            
            // Large title section
            if style == .large {
                VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                    Text(title)
                        .font(Theme.Typography.heading1)
                        .foregroundColor(Theme.Colors.text)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(Theme.Typography.body)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Theme.Spacing.medium)
                .padding(.bottom, Theme.Spacing.medium)
            }
        }
        .background(
            Theme.Colors.background
                .opacity(0.8)
                .background(.ultraThinMaterial)
        )
    }
}

// MARK: - Convenience Extensions
extension NavigationBar {
    static func backButton(action: @escaping () -> Void) -> AnyView {
        AnyView(
            Button(action: action) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Theme.Colors.text)
                    .frame(width: 32, height: 32)
                    .background(Theme.Colors.surface.opacity(0.5))
                    .clipShape(Circle())
            }
        )
    }
    
    static func iconButton(icon: String, action: @escaping () -> Void) -> AnyView {
        AnyView(
            Button(action: action) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Theme.Colors.text)
                    .frame(width: 32, height: 32)
                    .background(Theme.Colors.surface.opacity(0.5))
                    .clipShape(Circle())
            }
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        NavigationBar(
            title: "Discover",
            subtitle: "Find amazing meetups near you",
            style: .large,
            trailingButton: {
                NavigationBar.iconButton(icon: "bell.fill") {}
            }
        )
        
        NavigationBar(
            title: "Event Details",
            style: .compact,
            leadingButton: {
                NavigationBar.backButton {}
            },
            trailingButton: {
                NavigationBar.iconButton(icon: "square.and.arrow.up") {}
            }
        )
    }
    .background(Theme.Colors.background)
} 
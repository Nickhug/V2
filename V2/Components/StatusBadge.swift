import SwiftUI

/// A reusable UI component that displays the status of a meet
struct StatusBadge: View {
    let status: MeetStatus
    var size: BadgeSize = .regular
    
    enum BadgeSize {
        case small
        case regular
        case large
        
        var padding: EdgeInsets {
            switch self {
            case .small:
                return EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6)
            case .regular:
                return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
            case .large:
                return EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10)
            }
        }
        
        var fontSize: Font {
            switch self {
            case .small:
                return .caption2.bold()
            case .regular:
                return .caption.bold()
            case .large:
                return .footnote.bold()
            }
        }
        
        var cornerRadius: CGFloat {
            switch self {
            case .small:
                return 6
            case .regular:
                return 8
            case .large:
                return 10
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(size.fontSize)
            
            Text(status.displayName)
                .font(size.fontSize)
        }
        .padding(size.padding)
        .background(status.color.opacity(0.15))
        .foregroundColor(status.color)
        .cornerRadius(size.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .stroke(status.color.opacity(0.3), lineWidth: 1)
        )
    }
}

/// A variant of the StatusBadge that includes a subtle animation to indicate activity
struct AnimatedStatusBadge: View {
    let status: MeetStatus
    var size: StatusBadge.BadgeSize = .regular
    @State private var isAnimating = false
    
    var body: some View {
        StatusBadge(status: status, size: size)
            .overlay(
                status == .active ?
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
                    .offset(x: -8, y: -8)
                    .opacity(isAnimating ? 0.5 : 1.0)
                : nil
            )
            .onAppear {
                if status == .active {
                    withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                        isAnimating = true
                    }
                }
            }
    }
}

struct StatusBadge_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            Group {
                StatusBadge(status: .upcoming)
                StatusBadge(status: .active)
                StatusBadge(status: .completed)
                StatusBadge(status: .canceled)
            }
            
            Group {
                StatusBadge(status: .upcoming, size: .small)
                StatusBadge(status: .active, size: .regular)
                StatusBadge(status: .completed, size: .large)
            }
            
            AnimatedStatusBadge(status: .active)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 
import SwiftUI

struct AvatarView: View {
    let imageURL: String?
    let size: CGFloat
    var showBorder: Bool = true
    
    var body: some View {
        Group {
            if let imageURL = imageURL {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.2)
                }
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.5))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: size, height: size)
                    .background(Theme.cardBackground)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .ifAvatarView(showBorder) { view in
            view.overlay(
                Circle()
                    .strokeBorder(Theme.Colors.accent, lineWidth: 2)
            )
        }
        .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius * 0.5)
    }
}

// Extension for conditional view modifiers specific to AvatarView
extension View {
    @ViewBuilder
    func ifAvatarView<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

#Preview {
    AvatarView(imageURL: nil, size: 100)
} 
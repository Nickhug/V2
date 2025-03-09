import SwiftUI

/// A reusable loading spinner component with proper animation support
/// that works consistently in both regular views and previews.
struct LoadingSpinner: View {
    var color: Color = .white
    var lineWidth: CGFloat = 3
    var size: CGFloat = 40
    
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(color, lineWidth: lineWidth)
            .frame(width: size, height: size)
            .rotationEffect(Angle(degrees: 270))
            .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
            .animation(
                Animation.linear(duration: 1.0)
                    .repeatForever(autoreverses: false),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

#Preview {
    ZStack {
        Color.black
        VStack(spacing: 20) {
            LoadingSpinner()
            LoadingSpinner(color: .blue, lineWidth: 2, size: 30)
            LoadingSpinner(color: .green, lineWidth: 4, size: 50)
        }
    }
    .frame(width: 300, height: 300)
} 
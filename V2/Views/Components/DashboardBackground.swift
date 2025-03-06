import SwiftUI

struct DashboardBackground: View {
    var body: some View {
        ZStack {
            // Base background color
            Color.black
            
            // Gradient overlay
            LinearGradient(
                colors: [
                    Color(white: 0.1),
                    Color(white: 0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Subtle pattern
            GeometryReader { geometry in
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let spacing: CGFloat = 40
                    
                    for x in stride(from: 0, through: width, by: spacing) {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: height))
                    }
                    
                    for y in stride(from: 0, through: height, by: spacing) {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: width, y: y))
                    }
                }
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
            }
        }
        .ignoresSafeArea()
    }
} 
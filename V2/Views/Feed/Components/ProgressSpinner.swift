import SwiftUI

struct ProgressSpinner: View {
    var progress: Float
    var color: Color = .blue
    var backgroundColor: Color = .gray.opacity(0.3)
    var lineWidth: CGFloat = 4
    var size: CGFloat = 60
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(lineWidth: lineWidth)
                .opacity(0.3)
                .foregroundColor(backgroundColor)
            
            // Progress circle
            Circle()
                .trim(from: 0.0, to: CGFloat(min(progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                .foregroundColor(color)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.linear, value: progress)
            
            // Percentage text
            Text("\(Int(min(progress, 1.0) * 100))%")
                .font(.system(size: size * 0.25, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
    }
} 
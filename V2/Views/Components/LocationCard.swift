import SwiftUI

struct LocationCard: View {
    let title: String
    let imageURL: String?
    let popularityData: [CGFloat]
    let onPin: (() -> Void)?
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Image Section
            imageSection
                .overlay(alignment: .topTrailing) {
                    if let onPin = onPin {
                        Button(action: onPin) {
                            Text("Pin Location")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(Theme.Colors.text)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                        }
                        .padding(Theme.Spacing.medium)
                    }
                }
            
            // Content Section
            VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                // Title and Popular Spot Badge
                HStack {
                    Text(title)
                        .font(Theme.Typography.heading3)
                        .foregroundColor(Theme.Colors.text)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Theme.Typography.badge("Popular Spot")
                }
                
                // Popularity Chart
                popularityChart
            }
            .padding(Theme.Spacing.medium)
        }
        .background(Theme.Colors.accentGradient)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
        .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(Theme.Animation.spring, value: isPressed)
    }
    
    private var imageSection: some View {
        ZStack {
            if let imageURL = imageURL {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Theme.Colors.surface)
                        .overlay(
                            ProgressView()
                                .tint(Theme.Colors.accent)
                        )
                }
            } else {
                Rectangle()
                    .fill(Theme.Colors.primaryGradient)
            }
        }
        .frame(height: 200)
        .clipShape(
            RoundedRectangle(
                cornerRadius: Theme.CornerRadius.large,
                style: .continuous
            )
        )
    }
    
    private var popularityChart: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(popularityData, id: \.self) { value in
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Theme.Colors.accent,
                                Theme.Colors.secondary
                            ]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(height: value * 60)
            }
        }
        .frame(height: 60)
        .padding(8)
        .background(Color(hex: "9D174D").opacity(0.3))
        .cornerRadius(8)
    }
}

#Preview {
    VStack {
        LocationCard(
            title: "Coastal Highway",
            imageURL: nil,
            popularityData: [0.3, 0.5, 0.7, 0.4, 0.8, 0.6, 0.9, 0.5, 0.7, 0.4],
            onPin: {}
        )
        .padding()
        
        LocationCard(
            title: "Mountain Pass",
            imageURL: nil,
            popularityData: [0.5, 0.7, 0.3, 0.8, 0.4, 0.6, 0.2, 0.9, 0.5, 0.7],
            onPin: {}
        )
        .padding()
    }
    .background(Theme.Colors.background)
} 
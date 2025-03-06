import SwiftUI

struct VehicleCard: View {
    let vehicle: Vehicle
    let user: User
    var showOwner: Bool = false
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            // Vehicle Image
            ZStack {
                if let imageUrl = vehicle.photos.first {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ProgressView()
                    }
                } else {
                    Rectangle()
                        .fill(DesignSystem.Colors.accentGradient.opacity(0.3))
                        .overlay(
                            Image(systemName: "car.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white.opacity(0.6))
                        )
                }
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            
            // Vehicle Details
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                Text("\(vehicle.make) \(vehicle.model)")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.text)
                
                HStack {
                    DesignSystem.StatsView(
                        icon: "calendar",
                        value: vehicle.formattedYear,
                        label: ""
                    )
                    
                    Text("•")
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                    
                    DesignSystem.StatsView(
                        icon: "gear",
                        value: vehicle.type.rawValue,
                        label: ""
                    )
                    
                    if showOwner {
                        Text("•")
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                        
                        DesignSystem.StatsView(
                            icon: "person",
                            value: user.profile.name,
                            label: ""
                        )
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
} 
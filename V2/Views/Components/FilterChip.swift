import SwiftUI

struct FilterChip: View {
    let title: String
    let icon: String
    @Binding var isSelected: Bool
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button(action: {
            withAnimation(Theme.Animation.spring) {
                isSelected.toggle()
                action?()
            }
        }) {
            HStack(spacing: Theme.Spacing.small) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, Theme.Spacing.medium)
            .frame(height: 32)
            .foregroundColor(isSelected ? Theme.Colors.text : Theme.Colors.textSecondary)
            .background(
                isSelected ? Theme.Colors.accent.opacity(0.2) : Theme.Colors.surface.opacity(0.3)
            )
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(
                        isSelected ? Theme.Colors.accent : Theme.Colors.surface,
                        lineWidth: 1
                    )
            )
        }
    }
}

struct FilterChipGroup: View {
    let title: String
    @Binding var selectedFilters: Set<String>
    let filters: [(String, String)] // (title, icon)
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Text(title)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.textSecondary)
                .padding(.horizontal, Theme.Spacing.medium)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.small) {
                    ForEach(filters, id: \.0) { filter in
                        FilterChip(
                            title: filter.0,
                            icon: filter.1,
                            isSelected: .init(
                                get: { selectedFilters.contains(filter.0) },
                                set: { isSelected in
                                    if isSelected {
                                        selectedFilters.insert(filter.0)
                                    } else {
                                        selectedFilters.remove(filter.0)
                                    }
                                }
                            )
                        )
                    }
                }
                .padding(.horizontal, Theme.Spacing.medium)
            }
        }
    }
}

#Preview {
    VStack(spacing: Theme.Spacing.large) {
        // Single chips
        HStack(spacing: Theme.Spacing.medium) {
            FilterChip(
                title: "Cars",
                icon: "car.fill",
                isSelected: .constant(true)
            )
            
            FilterChip(
                title: "Bikes",
                icon: "bicycle",
                isSelected: .constant(false)
            )
        }
        
        // Filter groups
        FilterChipGroup(
            title: "Vehicle Type",
            selectedFilters: .constant(["Sports Cars", "Electric"]),
            filters: [
                ("Sports Cars", "car.fill"),
                ("SUVs", "car.side.fill"),
                ("Electric", "bolt.car.fill"),
                ("Hybrid", "leaf.fill")
            ]
        )
        
        FilterChipGroup(
            title: "Route Type",
            selectedFilters: .constant(["Mountain"]),
            filters: [
                ("Mountain", "mountain.2.fill"),
                ("Coastal", "water.waves"),
                ("City", "building.2.fill"),
                ("Scenic", "camera.fill")
            ]
        )
    }
    .padding(.vertical)
    .background(Theme.Colors.background)
} 
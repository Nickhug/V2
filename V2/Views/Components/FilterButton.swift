import SwiftUI

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    var style: FilterButtonStyle = .default
    
    enum FilterButtonStyle {
        case `default`
        case dark
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(style == .default ? (isSelected ? .white : .primary) : (isSelected ? .black : .white))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Group {
                        if style == .default {
                            if isSelected {
                                DesignSystem.Colors.accentGradient
                            } else {
                                Color(.systemGray6)
                            }
                        } else {
                            if isSelected {
                                Color.white
                            } else {
                                Color.white.opacity(0.1)
                            }
                        }
                    }
                )
                .cornerRadius(20)
        }
    }
}

#Preview {
    HStack {
        FilterButton(title: "All", isSelected: true, action: {}, style: .default)
        FilterButton(title: "Upcoming", isSelected: false, action: {}, style: .default)
        FilterButton(title: "Active", isSelected: false, action: {}, style: .dark)
        FilterButton(title: "Completed", isSelected: true, action: {}, style: .dark)
    }
    .padding()
} 
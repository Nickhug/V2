import SwiftUI

struct TabItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let selectedIcon: String
    let badgeCount: Int?
}

struct TabBar: View {
    let items: [TabItem]
    @Binding var selectedIndex: Int
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                Button(action: {
                    withAnimation(Theme.Animation.spring) {
                        selectedIndex = index
                    }
                }) {
                    VStack(spacing: 4) {
                        ZStack {
                            Image(systemName: selectedIndex == index ? item.selectedIcon : item.icon)
                                .font(.system(size: 24))
                                .foregroundColor(
                                    selectedIndex == index ? Theme.Colors.accent : Theme.Colors.textSecondary
                                )
                            
                            if let badgeCount = item.badgeCount, badgeCount > 0 {
                                Text("\(min(badgeCount, 99))")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 20, height: 20)
                                    .background(Theme.Colors.error)
                                    .clipShape(Circle())
                                    .offset(x: 10, y: -10)
                            }
                        }
                        
                        Text(item.title)
                            .font(.system(size: 12))
                            .foregroundColor(
                                selectedIndex == index ? Theme.Colors.accent : Theme.Colors.textSecondary
                            )
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.small)
        .padding(.top, Theme.Spacing.small)
        .padding(.bottom, Theme.Spacing.medium)
        .background(
            Theme.Colors.background
                .opacity(0.8)
                .background(.ultraThinMaterial)
        )
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Theme.Colors.surface),
            alignment: .top
        )
    }
}

#Preview {
    VStack {
        Spacer()
        
        TabBar(
            items: [
                TabItem(
                    title: "Discover",
                    icon: "map",
                    selectedIcon: "map.fill",
                    badgeCount: nil
                ),
                TabItem(
                    title: "Meetups",
                    icon: "car",
                    selectedIcon: "car.fill",
                    badgeCount: 3
                ),
                TabItem(
                    title: "Chat",
                    icon: "message",
                    selectedIcon: "message.fill",
                    badgeCount: 12
                ),
                TabItem(
                    title: "Profile",
                    icon: "person",
                    selectedIcon: "person.fill",
                    badgeCount: nil
                )
            ],
            selectedIndex: .constant(1)
        )
    }
    .background(Theme.Colors.background)
} 
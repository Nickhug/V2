import SwiftUI

struct NotificationsView: View {
    @StateObject var viewModel = NotificationsViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Replace static background with animated gradient
                AnimatedGradientBackground()
                
                List {
                    if viewModel.notifications.isEmpty {
                        ContentUnavailableView(
                            "No Notifications",
                            systemImage: "bell.slash",
                            description: Text("You don't have any notifications yet.")
                        )
                    } else {
                        ForEach(viewModel.notifications) { notification in
                            NotificationRow(notification: notification)
                        }
                    }
                }
                .navigationTitle("Notifications")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Mark All Read") {
                            viewModel.markAllAsRead()
                        }
                        .disabled(viewModel.notifications.isEmpty)
                    }
                }
            }
        }
    }
}

struct NotificationRow: View {
    let notification: Notification
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(notification.title)
                .font(.headline)
            Text(notification.message)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(notification.timestamp.formatted())
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct Notification: Identifiable {
    let id: String
    let title: String
    let message: String
    let timestamp: Date
    var isRead: Bool
    
    init(id: String = UUID().uuidString, title: String, message: String, timestamp: Date = Date(), isRead: Bool = false) {
        self.id = id
        self.title = title
        self.message = message
        self.timestamp = timestamp
        self.isRead = isRead
    }
}

#Preview {
    NotificationsView()
} 
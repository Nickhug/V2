import SwiftUI

struct NotificationsView: View {
    @StateObject var viewModel = NotificationsViewModel()
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Background
            AnimatedGradientBackground()
            
            VStack(spacing: 0) {
                // Content
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.notifications.isEmpty {
                    emptyStateView
                } else {
                    notificationsList
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
                    .opacity(viewModel.notifications.isEmpty ? 0.5 : 1.0)
                }
            }
            
            // Error overlay
            if let errorMessage = viewModel.errorMessage {
                VStack {
                    Spacer()
                    Text(errorMessage)
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.red.opacity(0.8))
                        )
                        .padding()
                        .onTapGesture {
                            viewModel.errorMessage = nil
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.spring(), value: errorMessage)
                .zIndex(100)
            }
        }
        .refreshable {
            viewModel.loadNotifications()
        }
    }
    
    // MARK: - Subviews
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            Text("Loading notifications...")
                .foregroundColor(.white)
                .padding(.top)
            Spacer()
        }
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Notifications",
            systemImage: "bell.slash",
            description: Text("You don't have any notifications yet.")
        )
        .foregroundColor(.white)
    }
    
    private var notificationsList: some View {
        List {
            ForEach(viewModel.notificationModels) { notification in
                EnhancedNotificationRow(notification: notification)
                    .onTapGesture {
                        if !notification.isRead {
                            viewModel.markAsRead(notification.id)
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        // Delete action
                        Button(role: .destructive) {
                            withAnimation {
                                viewModel.deleteNotification(notification.id)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        // Mark as read/unread action
                        if !notification.isRead {
                            Button {
                                viewModel.markAsRead(notification.id)
                            } label: {
                                Label("Read", systemImage: "checkmark.circle")
                            }
                            .tint(.blue)
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.1))
            }
        }
        .listStyle(.plain)
    }
}

struct EnhancedNotificationRow: View {
    let notification: NotificationModel
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon with background
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(Color.black, lineWidth: 1.5)
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 1)
                
                Image(systemName: notification.icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(notification.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Unread indicator
                    if !notification.isRead {
                        Circle()
                            .fill(MeetSpotColors.pink500)
                            .frame(width: 8, height: 8)
                    }
                }
                
                Text(notification.message)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.leading)
                
                Text(notification.relativeTime)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .opacity(notification.isRead ? 0.8 : 1.0)
    }
}

// For backward compatibility with the existing Notification struct
struct NotificationRow: View {
    let notification: Notification
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(notification.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Unread indicator
                if !notification.isRead {
                    Circle()
                        .fill(MeetSpotColors.pink500)
                        .frame(width: 8, height: 8)
                }
            }
            
            Text(notification.message)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            Text(notification.timestamp.formatted())
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.vertical, 4)
        .opacity(notification.isRead ? 0.8 : 1.0)
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
    NavigationView {
        NotificationsView()
    }
} 
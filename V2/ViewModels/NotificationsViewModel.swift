import SwiftUI
import Combine

class NotificationsViewModel: ObservableObject {
    @Published var notifications: [Notification] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    private let supabaseService = SupabaseService.shared
    
    init() {
        loadNotifications()
    }
    
    func loadNotifications() {
        isLoading = true
        
        // This is a placeholder implementation
        // Replace with actual API call when backend is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            self.notifications = [
                Notification(
                    title: "New Meet Request",
                    message: "John Doe invited you to join 'Sunday Drive'",
                    timestamp: Date().addingTimeInterval(-3600),
                    isRead: false
                ),
                Notification(
                    title: "Route Shared",
                    message: "Sarah Smith shared a new route with you",
                    timestamp: Date().addingTimeInterval(-86400),
                    isRead: true
                ),
                Notification(
                    title: "Meet Reminder",
                    message: "Your meet 'Mountain Drive' is tomorrow at 10:00 AM",
                    timestamp: Date().addingTimeInterval(-172800),
                    isRead: false
                )
            ]
            self.isLoading = false
        }
    }
    
    func markAsRead(_ notificationId: String) {
        if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
            notifications[index].isRead = true
            
            // In a real implementation, you would update this on the backend
            // supabaseService.updateNotification(id: notificationId, isRead: true)
        }
    }
    
    func markAllAsRead() {
        for index in notifications.indices {
            notifications[index].isRead = true
        }
        
        // In a real implementation, you would update this on the backend
        // supabaseService.markAllNotificationsAsRead()
    }
    
    func deleteNotification(_ notificationId: String) {
        notifications.removeAll { $0.id == notificationId }
        
        // In a real implementation, you would delete this on the backend
        // supabaseService.deleteNotification(id: notificationId)
    }
} 
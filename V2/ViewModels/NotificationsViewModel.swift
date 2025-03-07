import SwiftUI
import Combine

class NotificationsViewModel: ObservableObject {
    @Published var notifications: [Notification] = []
    @Published var notificationModels: [NotificationModel] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    private let supabaseService: SupabaseService
    
    init(supabaseService: SupabaseService = .shared) {
        self.supabaseService = supabaseService
        loadNotifications()
    }
    
    func loadNotifications() {
        isLoading = true
        
        Task { @MainActor in
            do {
                // Fetch notifications from Supabase
                let models = try await supabaseService.fetchNotifications()
                self.notificationModels = models
                
                // Convert to simpler Notification model for backward compatibility
                self.notifications = models.map { $0.toNotification() }
                
                self.isLoading = false
            } catch {
                self.errorMessage = "Failed to load notifications: \(error.localizedDescription)"
                self.isLoading = false
                
                // Fall back to dummy data if an error occurs
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
            }
        }
    }
    
    func markAsRead(_ notificationId: String) {
        // Update local state immediately for better UX
        if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
            notifications[index].isRead = true
        }
        
        if let modelIndex = notificationModels.firstIndex(where: { $0.id == notificationId }) {
            notificationModels[modelIndex].isRead = true
        }
        
        // Update on backend
        Task {
            do {
                try await supabaseService.markNotificationAsRead(notificationId)
            } catch {
                self.errorMessage = "Failed to mark notification as read: \(error.localizedDescription)"
            }
        }
    }
    
    func markAllAsRead() {
        // Update local state immediately for better UX
        for index in notifications.indices {
            notifications[index].isRead = true
        }
        
        for index in notificationModels.indices {
            notificationModels[index].isRead = true
        }
        
        // Update on backend
        Task {
            do {
                try await supabaseService.markAllNotificationsAsRead()
            } catch {
                self.errorMessage = "Failed to mark notifications as read: \(error.localizedDescription)"
            }
        }
    }
    
    func deleteNotification(_ notificationId: String) {
        // Update local state immediately for better UX
        notifications.removeAll { $0.id == notificationId }
        notificationModels.removeAll { $0.id == notificationId }
        
        // Update on backend
        Task {
            do {
                try await supabaseService.deleteNotification(notificationId)
            } catch {
                self.errorMessage = "Failed to delete notification: \(error.localizedDescription)"
                // Reload notifications to restore consistency with backend
                self.loadNotifications()
            }
        }
    }
    
    func getUnreadCount() async -> Int {
        do {
            return try await supabaseService.getUnreadNotificationsCount()
        } catch {
            print("Error getting unread count: \(error)")
            return notifications.filter { !$0.isRead }.count
        }
    }
} 
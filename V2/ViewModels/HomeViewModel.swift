import SwiftUI
import Combine
import CoreLocation
import MapKit

@MainActor
class HomeViewModel: ObservableObject {
    @Published var upcomingMeets: [Meet] = []
    @Published var recommendedMeets: [Meet] = []
    @Published var nearbyMeets: [Meet] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var unreadNotificationsCount: Int = 0
    @Published var searchQuery: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    private let supabaseService: SupabaseService
    
    // Computed properties for filtered results
    var filteredUpcomingMeets: [Meet] {
        if searchQuery.isEmpty {
            return upcomingMeets
        }
        return upcomingMeets.filter { meet in
            meet.title.localizedCaseInsensitiveContains(searchQuery) ||
            meet.description.localizedCaseInsensitiveContains(searchQuery) ||
            meet.locationName.localizedCaseInsensitiveContains(searchQuery)
        }
    }
    
    var filteredRecommendedMeets: [Meet] {
        if searchQuery.isEmpty {
            return recommendedMeets
        }
        return recommendedMeets.filter { meet in
            meet.title.localizedCaseInsensitiveContains(searchQuery) ||
            meet.description.localizedCaseInsensitiveContains(searchQuery) ||
            meet.locationName.localizedCaseInsensitiveContains(searchQuery)
        }
    }
    
    var filteredNearbyMeets: [Meet] {
        if searchQuery.isEmpty {
            return nearbyMeets
        }
        return nearbyMeets.filter { meet in
            meet.title.localizedCaseInsensitiveContains(searchQuery) ||
            meet.description.localizedCaseInsensitiveContains(searchQuery) ||
            meet.locationName.localizedCaseInsensitiveContains(searchQuery)
        }
    }
    
    init(supabaseService: SupabaseService = .shared) {
        self.supabaseService = supabaseService
        
        // Set up search debounce
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                // This helps prevent too many UI updates while typing
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        // Start fetching data
        fetchData()
        
        // Fetch notifications in a separate task
        Task {
            await fetchUnreadNotificationsCount()
        }
    }
    
    func fetchData() {
        Task {
            // Explicitly switch to main thread for UI property updates
            await MainActor.run {
                isLoading = true
            }
            
            do {
                let meets = try await supabaseService.fetchMeets()
                
                // Filter and sort meets into categories
                let currentDate = Date()
                
                // Explicitly switch to main thread for UI updates
                await MainActor.run {
                    self.upcomingMeets = meets
                        .filter { $0.date > currentDate }
                        .sorted { $0.date < $1.date }
                    
                    // For demo purposes, just assign all meets to each category
                    // In a real app, you would have more complex logic here
                    self.recommendedMeets = meets
                        .sorted { $0.attendees.count > $1.attendees.count }
                    
                    self.nearbyMeets = meets // In a real app, filter by distance to user
                    
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func refresh() async {
        // Explicitly use MainActor.run to ensure we're on the main thread
        // even if this method is called from a background context
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let meets = try await supabaseService.fetchMeets()
            
            // Filter and sort meets into categories
            let currentDate = Date()
            
            // Explicitly switch to main thread for UI updates
            await MainActor.run {
                self.upcomingMeets = meets
                    .filter { $0.date > currentDate }
                    .sorted { $0.date < $1.date }
                
                self.recommendedMeets = meets
                    .sorted { $0.attendees.count > $1.attendees.count }
                
                self.nearbyMeets = meets
                
                self.isLoading = false
            }
            
            // Also refresh the notification count
            await fetchUnreadNotificationsCount()
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func attendMeet(_ meet: Meet) {
        // Implement logic to attend a meet
    }
    
    func leaveMeet(_ meet: Meet) {
        // Implement logic to leave a meet
    }
    
    func createMeet(_ meet: Meet) async throws {
        // Fix for incorrect parameter label
        let _ = try await supabaseService.createMeet(meet)
        await refresh()
    }
    
    func fetchUnreadNotificationsCount() async {
        do {
            let count = try await supabaseService.getUnreadNotificationsCount()
            // Update directly on the main thread since we're in a @MainActor class
            self.unreadNotificationsCount = count
        } catch {
            print("Error fetching unread notification count: \(error)")
            // Keep the current count if there's an error
        }
    }
} 
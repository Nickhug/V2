import SwiftUI
import Combine
import CoreLocation
import MapKit

class HomeViewModel: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var meets: [Meet] = []
    @Published var isLoading: Bool = false
    @Published var error: Error? = nil
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadMeets()
    }
    
    func loadMeets() {
        isLoading = true
        
        // Replace this with your actual API call
        // This is a placeholder implementation
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            self.meets = [
                Meet(
                    id: "1",
                    title: "Morning Run",
                    description: "Easy run through the park",
                    date: Date(),
                    location: CLLocationCoordinate2D(latitude: 40.7829, longitude: -73.9654),
                    address: "Central Park, New York, NY",
                    type: .car,
                    coverImage: "https://example.com/central-park.jpg",
                    rules: ["No speeding", "Follow park rules"],
                    tags: ["Morning", "Park", "Cars"],
                    capacity: 20,
                    creatorId: "user1",
                    vehicleType: .car,
                    routeType: .city
                ),
                Meet(
                    id: "2",
                    title: "Hill Training",
                    description: "Hard hill repeats",
                    date: Date().addingTimeInterval(86400),
                    location: CLLocationCoordinate2D(latitude: 40.6602, longitude: -73.9790),
                    address: "Prospect Park, Brooklyn, NY",
                    type: .bike,
                    coverImage: "https://example.com/prospect-park.jpg",
                    rules: ["Helmets required", "Stay on trails"],
                    tags: ["Hills", "Training", "Bikes"],
                    capacity: 15,
                    creatorId: "user2",
                    vehicleType: .bike,
                    routeType: .mountain
                ),
                Meet(
                    id: "3",
                    title: "Trail Adventure",
                    description: "Exploring new trails",
                    date: Date().addingTimeInterval(172800),
                    location: CLLocationCoordinate2D(latitude: 40.7829, longitude: -73.9654),
                    address: "Forest Park, Queens, NY",
                    type: .mixed,
                    coverImage: "https://example.com/forest-park.jpg",
                    rules: ["Bring water", "Stay together"],
                    tags: ["Trails", "Adventure", "Mixed"],
                    capacity: 25,
                    creatorId: "user1",
                    vehicleType: .both,
                    routeType: .scenic
                )
            ]
            self.isLoading = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: workItem)
    }
    
    @MainActor
    func refresh() async {
        isLoading = true
        // Simulate a network request
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        loadMeets()
    }
    
    // Computed property for unread notifications count
    var unreadNotificationsCount: Int {
        return 3 // Placeholder value - replace with actual logic
    }
} 
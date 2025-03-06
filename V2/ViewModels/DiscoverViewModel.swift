import Foundation
import MapKit
import Combine
import Supabase
import SwiftUI

@MainActor
class DiscoverViewModel: ObservableObject {
    private let supabase = SupabaseService.shared
    private var subscriptions = Set<AnyCancellable>()
    private var meetSubscription: RealtimeChannelV2?
    
    @Published var meets: [Meet] = []
    @Published var searchText = ""
    @Published var selectedVehicleFilters: Set<String> = []
    @Published var selectedRouteFilters: Set<String> = []
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @Published var isLoading = false
    @Published var error: Error?
    
    // Default map coordinates (San Francisco)
    let defaultLatitude: Double = 37.7749
    let defaultLongitude: Double = -122.4194
    
    init() {
        setupSearchSubscription()
        setupFiltersSubscription()
        Task {
            await subscribeToMeetUpdates()
        }
    }
    
    private func setupSearchSubscription() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                Task {
                    await self?.fetchMeets()
                }
            }
            .store(in: &subscriptions)
    }
    
    private func setupFiltersSubscription() {
        Publishers.CombineLatest($selectedVehicleFilters, $selectedRouteFilters)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                Task {
                    await self?.fetchMeets()
                }
            }
            .store(in: &subscriptions)
    }
    
    private func subscribeToMeetUpdates() async {
        do {
            try await supabase.subscribeToMeetChanges { [weak self] meet in
                Task { @MainActor in
                    if let index = self?.meets.firstIndex(where: { existingMeet in
                        // Compare using string representation of IDs
                        return existingMeet.id == meet.id
                    }) {
                        self?.meets[index] = meet
                    } else {
                        self?.meets.append(meet)
                    }
                }
            }
        } catch {
            self.error = error
        }
    }
    
    func fetchMeets() async {
        isLoading = true
        // TODO: Implement actual API call
        // For now, using mock data
        await MainActor.run {
            self.meets = Meet.mockMeets
            self.isLoading = false
        }
    }
    
    func joinMeet(_ meet: Meet) async {
        do {
            _ = try await supabase.joinMeet(
                meetId: UUID(uuidString: meet.id) ?? UUID(),
                userId: UUID(), // Replace with actual user ID
                vehicleId: UUID() // Replace with actual vehicle ID
            )
        } catch {
            self.error = error
        }
    }
    
    func updateRegion(_ newRegion: MKCoordinateRegion) {
        // Only fetch if the user has moved the map significantly
        let latDiff = abs(newRegion.center.latitude - region.center.latitude)
        let lonDiff = abs(newRegion.center.longitude - region.center.longitude)
        
        if latDiff > 0.1 || lonDiff > 0.1 {
            region = newRegion
            Task {
                await fetchMeets()
            }
        }
    }
    
    func getAttendeeCount(for meet: Meet) -> Int {
        // Use the attendees array if available, otherwise fallback to random
        return meet.attendees.count > 0 ? meet.attendees.count : Int.random(in: 5...20)
    }
    
    func getOrganizerName(for meet: Meet) -> String {
        // TODO: Implement actual organizer name lookup
        return "John Doe"
    }
} 
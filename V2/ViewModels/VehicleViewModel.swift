import Foundation
import SwiftUI

@MainActor
class VehicleViewModel: ObservableObject {
    @Published var vehicles: [(Vehicle, User)] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let supabaseService = SupabaseService.shared
    
    func fetchVehicles() async {
        isLoading = true
        error = nil
        
        do {
            vehicles = try await supabaseService.fetchVehiclesWithUsers()
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func fetchVehicle(vehicleId: String) async -> (Vehicle, User)? {
        do {
            return try await supabaseService.fetchVehicleWithUser(vehicleId: vehicleId)
        } catch {
            self.error = error
            return nil
        }
    }
    
    func createVehicle(_ vehicle: Vehicle) async throws {
        isLoading = true
        error = nil
        
        do {
            _ = try await supabaseService.addVehicle(vehicle)
            await fetchVehicles() // Refresh the list
        } catch {
            self.error = error
            throw error
        }
        
        isLoading = false
    }
} 
import Foundation

// Make the enum public to ensure it's accessible from other modules
public enum VehicleType: String, Codable, CaseIterable {
    case car
    case bike
    case both
    case mixed
} 
import Foundation
import SwiftUI

enum V2MeetType: String, Codable, CaseIterable {
    case car
    case bike
    case mixed
    
    var displayName: String {
        switch self {
        case .car:
            return "Car"
        case .bike:
            return "Bike"
        case .mixed:
            return "Mixed"
        }
    }
    
    var iconName: String {
        switch self {
        case .car:
            return "car.side.fill"
        case .bike:
            return "motorcycle"
        case .mixed:
            return "car.side.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .car:
            return Color.blue
        case .bike:
            return Color.green
        case .mixed:
            return Color.purple
        }
    }
} 
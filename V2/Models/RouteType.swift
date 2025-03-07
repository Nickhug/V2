import Foundation

// Make the enum public to ensure it's accessible from other modules
public enum RouteType: String, Codable, CaseIterable {
    case mountain
    case coastal
    case city
    case scenic
} 
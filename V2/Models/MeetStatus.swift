import Foundation

// Make the enum public to ensure it's accessible from other modules
public enum MeetStatus: String, Codable {
    case upcoming
    case ongoing
    case completed
    case cancelled
} 
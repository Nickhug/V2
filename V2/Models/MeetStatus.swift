import Foundation
import SwiftUI

/// Status of a meet representing its lifecycle stage
public enum MeetStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case upcoming
    case active
    case completed
    case canceled
    
    public var id: String { rawValue }
    
    /// User-facing display name for the status
    public var displayName: String {
        switch self {
        case .upcoming:
            return "Upcoming"
        case .active:
            return "Active"
        case .completed:
            return "Completed"
        case .canceled:
            return "Canceled"
        }
    }
    
    /// Short description of what the status means
    public var description: String {
        switch self {
        case .upcoming:
            return "This meet is scheduled for the future"
        case .active:
            return "This meet is currently taking place"
        case .completed:
            return "This meet has already taken place"
        case .canceled:
            return "This meet has been canceled"
        }
    }
    
    /// Icon representing the status
    public var icon: String {
        switch self {
        case .upcoming:
            return "calendar"
        case .active:
            return "figure.wave"
        case .completed:
            return "checkmark.circle"
        case .canceled:
            return "xmark.circle"
        }
    }
    
    /// Color representing the status
    public var color: Color {
        switch self {
        case .upcoming:
            return .blue
        case .active:
            return .green
        case .completed:
            return .gray
        case .canceled:
            return .red
        }
    }
    
    /// Determines if actions related to joining or interacting with the meet should be enabled
    public var allowsInteraction: Bool {
        switch self {
        case .upcoming, .active:
            return true
        case .completed, .canceled:
            return false
        }
    }
    
    /// Determines if the meet should be scrollable in horizontal lists
    /// All meets should be scrollable regardless of status
    public var allowsScrolling: Bool {
        return true // Always allow scrolling regardless of status
    }
    
    /// Returns the status based on current date and meet date
    public static func determineStatus(meetDate: Date, isCanceled: Bool = false) -> MeetStatus {
        if isCanceled {
            return .canceled
        }
        
        let now = Date()
        
        // Add buffer times to prevent rapid status changes
        // Active: From 30 minutes before start time until 24 hours after
        let activeStartTime = meetDate.addingTimeInterval(-30 * 60) // 30 minutes before
        let activeEndTime = meetDate.addingTimeInterval(24 * 60 * 60) // 24 hours after
        
        // Add a 5-minute buffer at transitions to prevent rapid status changes
        let bufferTime: TimeInterval = 5 * 60 // 5 minutes in seconds
        
        if now < activeStartTime.addingTimeInterval(-bufferTime) {
            return .upcoming
        } else if now >= activeStartTime.addingTimeInterval(-bufferTime) && now <= activeEndTime.addingTimeInterval(bufferTime) {
            return .active
        } else {
            return .completed
        }
    }
} 
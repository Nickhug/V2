import Foundation
import SwiftUI

/// Status of a meet representing its lifecycle stage
public enum MeetStatus: String, Codable, CaseIterable, Identifiable {
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
    
    /// Returns the status based on current date and meet date
    public static func determineStatus(meetDate: Date, isCanceled: Bool = false) -> MeetStatus {
        if isCanceled {
            return .canceled
        }
        
        let now = Date()
        
        // Active: From 30 minutes before start time until 24 hours after
        let activeStartTime = meetDate.addingTimeInterval(-30 * 60) // 30 minutes before
        let activeEndTime = meetDate.addingTimeInterval(24 * 60 * 60) // 24 hours after
        
        if now < activeStartTime {
            return .upcoming
        } else if now >= activeStartTime && now <= activeEndTime {
            return .active
        } else {
            return .completed
        }
    }
} 
import Foundation

enum FriendError: LocalizedError {
    case userNotFound
    case alreadyFriends
    case requestAlreadySent
    case invalidRequest
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found"
        case .alreadyFriends:
            return "You are already friends with this user"
        case .requestAlreadySent:
            return "A friend request has already been sent"
        case .invalidRequest:
            return "Invalid friend request"
        }
    }
} 
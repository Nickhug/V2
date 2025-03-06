import Foundation

enum AuthError: LocalizedError, Equatable {
    case invalidCredentials
    case networkError
    case unknown
    case invalidSession
    case notAuthenticated
    case invalidImage
    case emailConfirmationRequired
    case userProfileNotFound
    case emailAlreadyInUse
    case databaseError
    case invalidPassword
    case emailNotConfirmed
    case userNotFound
    case userBanned
    case sessionExpired
    case tooManyRequests
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .networkError:
            return "Network error. Please check your connection"
        case .unknown:
            return "An unknown error occurred"
        case .invalidSession:
            return "Invalid session. Please sign in again"
        case .notAuthenticated:
            return "Please sign in to continue"
        case .invalidImage:
            return "Invalid image format"
        case .emailConfirmationRequired:
            return "Please confirm your email address"
        case .userProfileNotFound:
            return "User authenticated but profile not found in database"
        case .emailAlreadyInUse:
            return "This email is already registered"
        case .databaseError:
            return "Database error occurred"
        case .invalidPassword:
            return "Invalid password format"
        case .emailNotConfirmed:
            return "Email address not confirmed"
        case .userNotFound:
            return "User not found"
        case .userBanned:
            return "This account has been banned"
        case .sessionExpired:
            return "Your session has expired. Please sign in again"
        case .tooManyRequests:
            return "Too many attempts. Please try again later"
        }
    }
    
    static func == (lhs: AuthError, rhs: AuthError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidCredentials, .invalidCredentials),
             (.networkError, .networkError),
             (.unknown, .unknown),
             (.invalidSession, .invalidSession),
             (.notAuthenticated, .notAuthenticated),
             (.invalidImage, .invalidImage),
             (.emailConfirmationRequired, .emailConfirmationRequired),
             (.userProfileNotFound, .userProfileNotFound),
             (.emailAlreadyInUse, .emailAlreadyInUse),
             (.databaseError, .databaseError),
             (.invalidPassword, .invalidPassword),
             (.emailNotConfirmed, .emailNotConfirmed),
             (.userNotFound, .userNotFound),
             (.userBanned, .userBanned),
             (.sessionExpired, .sessionExpired),
             (.tooManyRequests, .tooManyRequests):
            return true
        default:
            return false
        }
    }
} 
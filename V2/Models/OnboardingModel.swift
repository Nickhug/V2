import Foundation
import SwiftUI

// Onboarding steps that define the user's journey
enum OnboardingStep: Int, CaseIterable, Identifiable {
    case welcome
    case about
    case preferences
    case complete
    
    var id: Int { self.rawValue }
    
    var title: String {
        switch self {
        case .welcome: return "Welcome"
        case .about: return "About You"
        case .preferences: return "Preferences"
        case .complete: return "Ready"
        }
    }
    
    var systemIcon: String {
        switch self {
        case .welcome: return "star.fill"
        case .about: return "person.fill"
        case .preferences: return "gearshape.fill"
        case .complete: return "checkmark.circle.fill"
        }
    }
    
    var description: String {
        switch self {
        case .welcome: return "Welcome to MeetSpot. Let's get you set up."
        case .about: return "Tell us a little about yourself."
        case .preferences: return "Set your preferences for a better experience."
        case .complete: return "You're all set to start exploring!"
        }
    }
}

// User preferences model
struct UserPreferences: Codable {
    var notificationsEnabled: Bool = true
    var locationSharingEnabled: Bool = true
    var darkModeEnabled: Bool = true
    var vehicleInterests: [VehicleType] = [.car]
    var routePreferences: [RouteType] = [.city]
}

// Manages the state of the onboarding process
class OnboardingState: ObservableObject {
    // Current step
    @Published var currentStep: OnboardingStep = .welcome
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    // User information
    @Published var name = ""
    @Published var bio = ""
    @Published var location = ""
    @Published var avatar: UIImage?
    
    // Social
    @Published var instagram = ""
    @Published var twitter = ""
    @Published var facebook = ""
    
    // Preferences
    @Published var preferences = UserPreferences()
    
    // Computed properties for navigation control
    var currentStepIndex: Int {
        currentStep.rawValue
    }
    
    var isLastStep: Bool {
        currentStep == OnboardingStep.allCases.last
    }
    
    var canContinue: Bool {
        switch currentStep {
        case .welcome:
            return true
        case .about:
            return !name.isEmpty
        case .preferences:
            return true
        case .complete:
            return true
        }
    }
    
    func moveToNextStep() {
        guard let nextIndex = OnboardingStep.allCases.firstIndex(of: currentStep)?.advanced(by: 1),
              nextIndex < OnboardingStep.allCases.count else {
            return
        }
        currentStep = OnboardingStep.allCases[nextIndex]
    }
    
    func moveToPreviousStep() {
        guard let prevIndex = OnboardingStep.allCases.firstIndex(of: currentStep)?.advanced(by: -1),
              prevIndex >= 0 else {
            return
        }
        currentStep = OnboardingStep.allCases[prevIndex]
    }
    
    // Create user profile from collected data
    func createUserProfile(for userId: String) -> User.Profile {
        let userLocation = User.Profile.Location(
            latitude: 0,
            longitude: 0,
            address: location
        )
        
        let social = User.Profile.Social(
            instagram: instagram,
            facebook: facebook,
            twitter: twitter
        )
        
        return User.Profile(
            name: name,
            avatar: avatar != nil ? "custom-avatar" : "person.circle.fill",
            bio: bio,
            location: userLocation,
            joinDate: Date(),
            social: social
        )
    }
} 
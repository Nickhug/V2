import SwiftUI
import MapKit

// Define the different steps in the create meet flow
enum CreateMeetStep: Int, CaseIterable {
    case welcome
    case basics
    case details
    case location
    case route
    case preview
    
    var title: String {
        switch self {
        case .welcome: return "Welcome"
        case .basics: return "Basic Info"
        case .details: return "Details"
        case .location: return "Location"
        case .route: return "Add Route"
        case .preview: return "Preview"
        }
    }
    
    var systemIcon: String {
        switch self {
        case .welcome: return "star.fill"
        case .basics: return "info.circle.fill"
        case .details: return "list.bullet.rectangle.fill"
        case .location: return "map.fill"
        case .route: return "mappin.and.ellipse"
        case .preview: return "checkmark.circle.fill"
        }
    }
}

// State management class for the onboarding process
class CreateMeetOnboardingState: ObservableObject {
    // Current step
    @Published var currentStep: CreateMeetStep = .welcome
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    // Basics step
    @Published var title = ""
    @Published var description = ""
    @Published var date = Date().addingTimeInterval(24 * 60 * 60) // Default to tomorrow
    @Published var meetType: V2MeetType = .car
    @Published var capacity = 50
    
    // Details step
    @Published var selectedImage: UIImage?
    @Published var showImagePicker = false
    @Published var rules: [String] = [""]
    @Published var tags: [String] = [""]
    @Published var vehicleType: VehicleType = .car
    @Published var routeType: RouteType = .city
    
    // Location step
    @Published var selectedLocation: CLLocationCoordinate2D?
    @Published var address = ""
    @Published var showLocationPicker = false
    
    // Route step
    @Published var selectedRoute: Route?
    @Published var showRouteSelector = false
    @Published var showRouteCreator = false
    
    // Computed properties for navigation control
    var currentStepIndex: Int {
        currentStep.rawValue
    }
    
    var isLastStep: Bool {
        currentStep == CreateMeetStep.allCases.last
    }
    
    var canContinue: Bool {
        switch currentStep {
        case .welcome:
            return true
        case .basics:
            return !title.isEmpty && !description.isEmpty
        case .details:
            return selectedImage != nil
        case .location:
            return selectedLocation != nil && !address.isEmpty
        case .route:
            // Route is optional, so always allow continuing
            return true
        case .preview:
            return canSubmitForm
        }
    }
    
    var canSubmitForm: Bool {
        !title.isEmpty &&
        !description.isEmpty &&
        selectedImage != nil &&
        selectedLocation != nil &&
        !address.isEmpty
    }
    
    // Navigation methods
    func moveToNextStep() {
        guard let nextStepIndex = CreateMeetStep.allCases.firstIndex(of: currentStep)?.advanced(by: 1),
              nextStepIndex < CreateMeetStep.allCases.count else {
            return
        }
        
        currentStep = CreateMeetStep.allCases[nextStepIndex]
    }
    
    func moveToPreviousStep() {
        guard let prevStepIndex = CreateMeetStep.allCases.firstIndex(of: currentStep)?.advanced(by: -1),
              prevStepIndex >= 0 else {
            return
        }
        
        currentStep = CreateMeetStep.allCases[prevStepIndex]
    }
    
    func jumpToStep(_ step: CreateMeetStep) {
        currentStep = step
    }
    
    // Helper methods for rules and tags
    func addRule() {
        rules.append("")
    }
    
    func removeRule(at index: Int) {
        guard rules.count > 1, index < rules.count else { return }
        rules.remove(at: index)
    }
    
    func addTag() {
        tags.append("")
    }
    
    func removeTag(at index: Int) {
        guard tags.count > 1, index < tags.count else { return }
        tags.remove(at: index)
    }
} 
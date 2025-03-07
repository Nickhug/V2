import SwiftUI
import PhotosUI

// Define the different steps in the add vehicle flow
enum VehicleStep: Int, CaseIterable {
    case welcome
    case basics
    case photos
    case modifications
    case preview
    
    var title: String {
        switch self {
        case .welcome: return "Welcome"
        case .basics: return "Vehicle Info"
        case .photos: return "Photos"
        case .modifications: return "Modifications"
        case .preview: return "Preview"
        }
    }
    
    var systemIcon: String {
        switch self {
        case .welcome: return "star.fill"
        case .basics: return "car.fill"
        case .photos: return "photo.fill"
        case .modifications: return "wrench.and.screwdriver.fill"
        case .preview: return "checkmark.circle.fill"
        }
    }
}

// State management class for the vehicle onboarding process
class VehicleOnboardingState: ObservableObject {
    // Current step
    @Published var currentStep: VehicleStep = .welcome
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    // Basics step
    @Published var make = ""
    @Published var model = ""
    @Published var year = Calendar.current.component(.year, from: Date())
    @Published var type: VehicleType = .car
    
    // Photos step
    @Published var selectedPhotos: [PhotosPickerItem] = []
    @Published var vehiclePhotos: [UIImage] = []
    @Published var uploadedPhotoUrls: [String] = []
    
    // Modifications step
    @Published var modifications: [String] = [""]
    
    // Computed properties for navigation control
    var currentStepIndex: Int {
        currentStep.rawValue
    }
    
    var isLastStep: Bool {
        currentStep == VehicleStep.allCases.last
    }
    
    var canContinue: Bool {
        switch currentStep {
        case .welcome:
            return true
        case .basics:
            return !make.isEmpty && !model.isEmpty
        case .photos:
            return true // Photos are optional
        case .modifications:
            return true // Modifications are optional
        case .preview:
            return canSubmitForm
        }
    }
    
    var canSubmitForm: Bool {
        // Basic requirements for vehicle creation
        return !make.isEmpty && !model.isEmpty
    }
    
    func moveToNextStep() {
        guard let nextIndex = VehicleStep.allCases.firstIndex(of: currentStep)?.advanced(by: 1),
              nextIndex < VehicleStep.allCases.count else {
            return
        }
        currentStep = VehicleStep.allCases[nextIndex]
    }
    
    func moveToPreviousStep() {
        guard let prevIndex = VehicleStep.allCases.firstIndex(of: currentStep)?.advanced(by: -1),
              prevIndex >= 0 else {
            return
        }
        currentStep = VehicleStep.allCases[prevIndex]
    }
    
    // Helper function to get modifications as an array
    func getModificationsArray() -> [String] {
        modifications.filter { !$0.isEmpty }
    }
} 
import SwiftUI
import MapKit

struct CreateMeetOnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: MeetViewModel
    @StateObject private var onboardingState = CreateMeetOnboardingState()
    
    // Screen dimensions for animations
    @State private var screenWidth = UIScreen.main.bounds.width
    @State private var step: CreateMeetStep = .welcome
    
    var body: some View {
        ZStack {
            // Replace LinearGradient with ModernGradientBackground
            ModernGradientBackground()
                .ignoresSafeArea()
            
            // Content container
            VStack(spacing: 0) {
                // Header with close button and step progress
                HStack {
                    // Back button (if not on first step)
                    if onboardingState.currentStep != .welcome {
                        Button(action: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                onboardingState.moveToPreviousStep()
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title3.weight(.semibold))
                                .foregroundColor(.black)
                                .padding(12)
                                .background(Color.white)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.black, lineWidth: 1.5)
                                )
                                .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 1)
                        }
                    }
                    
                    Spacer()
                    
                    // Close button
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title3.weight(.semibold))
                            .foregroundColor(.black)
                            .padding(12)
                            .background(Color.white)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.black, lineWidth: 1.5)
                            )
                            .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 1)
                    }
                }
                .padding(.horizontal)
                
                // Progress indicator
                CreateMeetProgressIndicator(
                    currentStep: onboardingState.currentStepIndex + 1,
                    totalSteps: CreateMeetStep.allCases.count - 1
                )
                .padding(.top)
                .padding(.bottom, 8)
                
                // Main content with step transitions
                ZStack {
                    ForEach(CreateMeetStep.allCases, id: \.self) { step in
                        if step == onboardingState.currentStep {
                            stepView(for: step)
                                .transition(
                                    .asymmetric(
                                        insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)
                                    )
                                )
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Bottom navigation
                if onboardingState.currentStep != .welcome {
                    HStack {
                        // Back button (removed as it's now in the header)
                        Spacer()
                        
                        // Next/Submit button
                        Button(action: {
                            if onboardingState.isLastStep {
                                createMeet()
                            } else {
                                validateAndContinue()
                            }
                        }) {
                            HStack {
                                Text(onboardingState.isLastStep ? "Create Meet" : "Continue")
                                    .font(.headline)
                                
                                if onboardingState.isLastStep {
                                    Image(systemName: "sparkles")
                                } else {
                                    Image(systemName: "arrow.right")
                                }
                            }
                            .foregroundColor(.black)
                            .frame(width: 160)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.black, lineWidth: 1.5)
                            )
                            .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
                        }
                        .opacity(onboardingState.canContinue ? 1.0 : 0.5)
                        .disabled(!onboardingState.canContinue)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
            
            // Loading overlay
            if onboardingState.isLoading {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
        }
        .alert(isPresented: $onboardingState.showError) {
            Alert(
                title: Text("Error"),
                message: Text(onboardingState.errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    @ViewBuilder
    func stepView(for step: CreateMeetStep) -> some View {
        switch step {
        case .welcome:
            WelcomeStepView(onboardingState: onboardingState)
        case .basics:
            BasicsStepView(onboardingState: onboardingState)
        case .details:
            DetailsStepView(onboardingState: onboardingState)
        case .location:
            LocationStepView(onboardingState: onboardingState)
        case .route:
            RouteStepView(onboardingState: onboardingState, viewModel: viewModel)
        case .preview:
            PreviewStepView(onboardingState: onboardingState)
        }
    }
    
    // Ensure we always validate the location before proceeding to the preview
    private func validateAndContinue() {
        // Check if we're on the location step
        if onboardingState.currentStep == .location {
            // Verify we have a valid location and address
            guard onboardingState.selectedLocation != nil, !onboardingState.address.isEmpty else {
                // Show an error or alert to the user
                onboardingState.errorMessage = "Please select a location on the map"
                onboardingState.showError = true
                return
            }
        }
        
        // If we're continuing to the preview step, perform additional validation
        if onboardingState.currentStep == .route {
            // Validate all required fields before showing the preview
            guard onboardingState.canSubmitForm else {
                // Show error about missing required fields
                onboardingState.errorMessage = "Please fill in all required fields before continuing"
                onboardingState.showError = true
                return
            }
        }
        
        // If all validation passes, move to the next step
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            onboardingState.moveToNextStep()
        }
    }
    
    private func createMeet() {
        // Perform final validation
        guard onboardingState.canSubmitForm else {
            onboardingState.errorMessage = "Please complete all required fields"
            onboardingState.showError = true
            return
        }
        
        onboardingState.isLoading = true
        
        Task {
            do {
                // Filter out empty rules and tags
                let filteredRules = onboardingState.rules.filter { !$0.isEmpty }
                let filteredTags = onboardingState.tags.filter { !$0.isEmpty }
                
                // Ensure we have a valid location
                guard let location = onboardingState.selectedLocation else {
                    throw NSError(domain: "CreateMeet", code: 1, userInfo: [NSLocalizedDescriptionKey: "Location is required"])
                }
                
                try await viewModel.createMeet(
                    title: onboardingState.title,
                    description: onboardingState.description,
                    date: onboardingState.date,
                    type: onboardingState.meetType,
                    location: location,
                    address: onboardingState.address,
                    rules: filteredRules,
                    tags: filteredTags,
                    coverImage: onboardingState.selectedImage!,
                    capacity: onboardingState.capacity,
                    vehicleType: onboardingState.vehicleType,
                    routeType: onboardingState.routeType,
                    primaryRouteId: onboardingState.selectedRoute?.id
                )
                
                // Success - dismiss the view
                DispatchQueue.main.async {
                    dismiss()
                }
            } catch {
                // Show error
                DispatchQueue.main.async {
                    onboardingState.errorMessage = error.localizedDescription
                    onboardingState.showError = true
                    onboardingState.isLoading = false
                }
            }
        }
    }
}

// Progress indicator view for showing current step
struct CreateMeetProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack(spacing: 16) {
            ForEach(1...totalSteps, id: \.self) { step in
                ZStack {
                    Circle()
                        .fill(step <= currentStep ? Color.white : Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                    
                    if step <= currentStep {
                        Circle()
                            .stroke(Color.black, lineWidth: 1.5)
                            .frame(width: 8, height: 8)
                    }
                }
            }
        }
    }
}

// Preview
struct CreateMeetOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        CreateMeetOnboardingView(viewModel: MeetViewModel())
    }
} 
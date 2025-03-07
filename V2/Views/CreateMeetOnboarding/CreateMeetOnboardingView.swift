import SwiftUI
import MapKit

struct CreateMeetOnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: MeetViewModel
    @StateObject private var onboardingState = CreateMeetOnboardingState()
    @State private var animateGradient = false
    
    // Screen dimensions for animations
    @State private var screenWidth = UIScreen.main.bounds.width
    @State private var step: CreateMeetStep = .welcome
    
    var body: some View {
        ZStack {
            // Animated gradient background with parallax effect
            LinearGradient(
                gradient: Gradient(colors: [
                    MeetSpotColors.purple900,
                    MeetSpotColors.pink500.opacity(0.8),
                    MeetSpotColors.purple900
                ]),
                startPoint: animateGradient ? .topLeading : .bottomLeading,
                endPoint: animateGradient ? .bottomTrailing : .topTrailing
            )
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.linear(duration: 5.0).repeatForever(autoreverses: true)) {
                    animateGradient.toggle()
                }
            }
            
            // Content container
            VStack(spacing: 0) {
                // Header
                ZStack {
                    HStack {
                        // Back button
                        if step != .welcome {
                            Button(action: {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    onboardingState.moveToPreviousStep()
                                }
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.title3.weight(.semibold))
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Material.ultraThinMaterial)
                                    .clipShape(Circle())
                                    .subtleShadow()
                            }
                        }
                        
                        Spacer()
                        
                        // Close button
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.title3.weight(.semibold))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Material.ultraThinMaterial)
                                .clipShape(Circle())
                                .subtleShadow()
                        }
                    }
                    .padding(.horizontal)
                    
                    // Progress indicator
                    ProgressIndicator(
                        currentStep: onboardingState.currentStepIndex + 1,
                        totalSteps: CreateMeetStep.allCases.count - 1
                    )
                }
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
                    VStack {
                        if onboardingState.isLastStep {
                            Button(action: {
                                createMeet()
                            }) {
                                HStack {
                                    Text("Create Meet")
                                        .font(.headline)
                                    
                                    Image(systemName: "sparkles")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [MeetSpotColors.pink500, MeetSpotColors.purple900]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(16)
                                .pronouncedShadow()
                            }
                            .disabled(!onboardingState.canSubmitForm)
                            .opacity(onboardingState.canSubmitForm ? 1.0 : 0.6)
                        } else {
                            Button(action: {
                                validateAndContinue()
                            }) {
                                HStack {
                                    Text("Continue")
                                        .font(.headline)
                                    
                                    Image(systemName: "arrow.right")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [MeetSpotColors.pink500, MeetSpotColors.purple900]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(16)
                                .pronouncedShadow()
                            }
                            .disabled(!onboardingState.canContinue)
                            .opacity(onboardingState.canContinue ? 1.0 : 0.6)
                        }
                    }
                    .padding()
                    .background(
                        Rectangle()
                            .fill(Material.ultraThinMaterial)
                            .backgroundStyle(MeetSpotColors.backgroundGradient)
                    )
                }
            }
        }
        .preferredColorScheme(.dark)
        .alert("Error", isPresented: $onboardingState.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(onboardingState.errorMessage)
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
struct ProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...totalSteps, id: \.self) { step in
                RoundedRectangle(cornerRadius: 2)
                    .fill(step <= currentStep ? Color.white : Color.white.opacity(0.3))
                    .frame(width: 24, height: 4)
                    .animation(.spring(), value: currentStep)
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
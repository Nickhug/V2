import SwiftUI
import PhotosUI

struct VehicleOnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthManager
    @StateObject private var onboardingState = VehicleOnboardingState()
    @State private var animateGradient = false
    
    // Callback when a vehicle is added
    var onVehicleAdded: (Vehicle) -> Void
    
    var body: some View {
        ZStack {
            // Update to modern mesh gradient background
            ModernGradientBackground()
                .ignoresSafeArea()
            
            // Content container
            VStack(spacing: 0) {
                // Header with close button and step progress
                HStack {
                    Spacer()
                    
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
                VehicleOnboardingProgressIndicator(
                    currentStep: onboardingState.currentStepIndex + 1,
                    totalSteps: VehicleStep.allCases.count - 1
                )
                .padding(.top)
                .padding(.bottom, 8)
                
                // Main content with step transitions
                ZStack {
                    ForEach(VehicleStep.allCases, id: \.self) { step in
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
                HStack {
                    // Back button (if not on first step)
                    if onboardingState.currentStep != .welcome {
                        Button(action: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                onboardingState.moveToPreviousStep()
                            }
                        }) {
                            Text("Back")
                                .font(.headline)
                                .foregroundColor(.black)
                                .frame(width: 120)
                                .padding(.vertical, 16)
                                .background(Color.white)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(Color.black, lineWidth: 1.5)
                                )
                                .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
                        }
                    }
                    
                    Spacer()
                    
                    // Next/Submit button
                    Button(action: {
                        if onboardingState.isLastStep {
                            addVehicle()
                        } else {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                onboardingState.moveToNextStep()
                            }
                        }
                    }) {
                        HStack {
                            Text(onboardingState.isLastStep ? "Add Vehicle" : "Next")
                                .font(.headline)
                            
                            if !onboardingState.isLastStep {
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
        .onChange(of: onboardingState.selectedPhotos) { _, newValue in
            Task {
                await handlePhotoSelection(newValue)
            }
        }
    }
    
    @ViewBuilder
    func stepView(for step: VehicleStep) -> some View {
        switch step {
        case .welcome:
            WelcomeVehicleStepView(onboardingState: onboardingState)
        case .basics:
            BasicsVehicleStepView(onboardingState: onboardingState)
        case .photos:
            PhotosVehicleStepView(onboardingState: onboardingState)
        case .modifications:
            ModificationsVehicleStepView(onboardingState: onboardingState)
        case .preview:
            PreviewVehicleStepView(onboardingState: onboardingState)
        }
    }
    
    private func addVehicle() {
        // Perform final validation
        guard onboardingState.canSubmitForm else {
            onboardingState.errorMessage = "Please complete all required fields"
            onboardingState.showError = true
            return
        }
        
        onboardingState.isLoading = true
        
        // Create vehicle object
        let vehicle = Vehicle(
            id: UUID().uuidString,
            userId: authManager.currentUser?.id,
            make: onboardingState.make,
            model: onboardingState.model,
            year: onboardingState.year,
            type: onboardingState.type,
            modifications: onboardingState.getModificationsArray(),
            photos: onboardingState.uploadedPhotoUrls,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // In a production app, we would save to the database here
        // This would be a throwing operation: await authManager.supabaseService.addVehicle(vehicle)
        
        // Call the callback
        DispatchQueue.main.async {
            onVehicleAdded(vehicle)
            dismiss()
        }
    }
    
    private func handlePhotoSelection(_ items: [PhotosPickerItem]) async {
        var images: [UIImage] = []
        var urls: [String] = []
        
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                images.append(image)
                
                // In a real app, we would upload the photo to storage and get a URL
                // let url = await authManager.supabaseService.uploadVehiclePhoto(image)
                // For demo, we'll just use a placeholder URL
                urls.append("https://example.com/photo-\(UUID().uuidString).jpg")
            }
        }
        
        await MainActor.run {
            onboardingState.vehiclePhotos = images
            onboardingState.uploadedPhotoUrls = urls
        }
    }
}

struct VehicleOnboardingProgressIndicator: View {
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

struct VehicleOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        VehicleOnboardingView { _ in }
            .environmentObject(AuthManager())
    }
} 
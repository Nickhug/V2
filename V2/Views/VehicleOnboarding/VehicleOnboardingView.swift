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
                        if onboardingState.currentStep != .welcome {
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
                        totalSteps: VehicleStep.allCases.count - 1
                    )
                }
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
                if onboardingState.currentStep != .welcome {
                    VStack {
                        if onboardingState.isLastStep {
                            Button(action: {
                                addVehicle()
                            }) {
                                HStack {
                                    Text("Add Vehicle")
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
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    onboardingState.moveToNextStep()
                                }
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
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                let resizedImage = await resizeImage(image, targetSize: CGSize(width: 800, height: 800))
                await MainActor.run {
                    onboardingState.vehiclePhotos.append(resizedImage)
                    
                    // In a real implementation, we would upload the photo and
                    // add the URL to uploadedPhotoUrls
                    // For this example, we'll simulate it with a fake URL
                    let fakeUrl = "https://example.com/vehicle/\(UUID().uuidString).jpg"
                    onboardingState.uploadedPhotoUrls.append(fakeUrl)
                }
            }
        }
    }
    
    private func resizeImage(_ image: UIImage, targetSize: CGSize) async -> UIImage {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let size = image.size
                let widthRatio  = targetSize.width  / size.width
                let heightRatio = targetSize.height / size.height
                let ratio = min(widthRatio, heightRatio)
                let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
                
                let format = UIGraphicsImageRendererFormat()
                format.scale = 1
                
                let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
                let resizedImage = renderer.image { context in
                    image.draw(in: CGRect(origin: .zero, size: newSize))
                }
                
                continuation.resume(returning: resizedImage)
            }
        }
    }
}

#Preview {
    VehicleOnboardingView { _ in }
        .environmentObject(AuthManager())
} 
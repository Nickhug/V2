import SwiftUI
import PhotosUI

@available(iOS 16.0, *)
struct AddVehicleView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthManager
    
    // Vehicle Details
    @State private var make = ""
    @State private var model = ""
    @State private var year = Calendar.current.component(.year, from: Date())
    @State private var type = VehicleType.car
    
    // Photos
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var vehiclePhotos: [UIImage] = []
    @State private var uploadedPhotoUrls: [String] = []
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0
    
    // Modifications
    @State private var modifications = ""
    
    // Flow Control
    @State private var currentStep = 0
    @State private var errorMessage: String?
    
    let onAdd: (Vehicle) -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                Theme.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress bar
                    ProgressView(value: Double(currentStep) / 2.0)
                        .tint(Theme.Colors.accent)
                        .padding()
                    
                    // Content
                    TabView(selection: $currentStep) {
                        // Step 1: Basic Details
                        basicDetailsView
                            .tag(0)
                        
                        // Step 2: Photos
                        photosView
                            .tag(1)
                        
                        // Step 3: Modifications
                        modificationsView
                            .tag(2)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut, value: currentStep)
                    
                    // Navigation buttons
                    navigationButtons
                }
            }
        }
        .onChange(of: selectedPhotos) { oldValue, newValue in
            Task {
                await handlePhotoSelection(newValue)
            }
        }
    }
    
    private var basicDetailsView: some View {
        VStack(spacing: Theme.Spacing.large) {
            Text("Tell us about your ride")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Theme.Colors.text)
                .padding(.top, 40)
            
            VStack(spacing: Theme.Spacing.large) {
                // Vehicle Type Selector
                HStack(spacing: Theme.Spacing.medium) {
                    vehicleTypeButton(VehicleType.car, icon: "car.fill", title: "Car")
                    vehicleTypeButton(VehicleType.bike, icon: "bicycle", title: "Bike")
                    vehicleTypeButton(VehicleType.mixed, icon: "car.and.bicycle", title: "Mixed")
                }
                
                // Make input
                FloatingTextField(
                    placeholder: "Make",
                    icon: "building.2.fill",
                    text: $make
                )
                
                // Model input
                FloatingTextField(
                    placeholder: "Model",
                    icon: "car.side.fill",
                    text: $model
                )
                
                // Year picker
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(Theme.Colors.text)
                        .font(.title3)
                    
                    Picker("Year", selection: $year) {
                        ForEach((1900...Calendar.current.component(.year, from: Date())).reversed(), id: \.self) { year in
                            Text(String(year))
                                .foregroundColor(Theme.Colors.text)
                                .tag(year)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 100)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                        .fill(Theme.Colors.surface.opacity(0.3))
                        .background(.ultraThinMaterial)
                )
                .shadow(color: Theme.shadowColor.opacity(0.1), radius: Theme.shadowRadius)
            }
            .padding()
            
            Spacer()
        }
    }
    
    private var photosView: some View {
        VStack(spacing: Theme.Spacing.large) {
            Text("Add Photos")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Theme.Colors.text)
                .padding(.top, 40)
            
            Text("Upload up to 5 photos of your vehicle")
                .font(.subheadline)
                .foregroundColor(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if vehiclePhotos.isEmpty {
                PhotosPicker(
                    selection: $selectedPhotos,
                    maxSelectionCount: 5,
                    matching: .images
                ) {
                    VStack(spacing: Theme.Spacing.medium) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 40))
                            .foregroundColor(Theme.Colors.accent)
                        
                        Text("Select Photos")
                            .font(.headline)
                            .foregroundColor(Theme.Colors.text)
                        
                        Text("Tap to choose photos")
                            .font(.caption)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                            .fill(Theme.Colors.surface.opacity(0.3))
                            .background(.ultraThinMaterial)
                    )
                    .shadow(color: Theme.shadowColor.opacity(0.1), radius: Theme.shadowRadius)
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Spacing.medium) {
                        ForEach(vehiclePhotos.indices, id: \.self) { index in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: vehiclePhotos[index])
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 200, height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
                                    .shadow(color: Theme.shadowColor, radius: Theme.shadowRadius)
                                
                                Button {
                                    withAnimation {
                                        vehiclePhotos.remove(at: index)
                                        if index < uploadedPhotoUrls.count {
                                            uploadedPhotoUrls.remove(at: index)
                                        }
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(Theme.Colors.text)
                                        .shadow(radius: 2)
                                }
                                .padding(8)
                            }
                        }
                        
                        if vehiclePhotos.count < 5 {
                            PhotosPicker(
                                selection: $selectedPhotos,
                                maxSelectionCount: 5 - vehiclePhotos.count,
                                matching: .images
                            ) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(Theme.Colors.accent)
                                    .frame(width: 200, height: 200)
                                    .background(
                                        RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                            .fill(Theme.Colors.surface.opacity(0.3))
                                            .background(.ultraThinMaterial)
                                    )
                                    .shadow(color: Theme.shadowColor.opacity(0.1), radius: Theme.shadowRadius)
                            }
                        }
                    }
                    .padding()
                }
            }
            
            if isUploading {
                VStack(spacing: Theme.Spacing.medium) {
                    ProgressView(value: uploadProgress)
                        .tint(Theme.Colors.accent)
                    
                    Text("Uploading photos... \(Int(uploadProgress * 100))%")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                .padding()
            }
            
            Spacer()
        }
    }
    
    private var modificationsView: some View {
        VStack(spacing: Theme.Spacing.large) {
            Text("Any modifications?")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Theme.Colors.text)
                .padding(.top, 40)
            
            Text("List your modifications, separated by commas")
                .font(.subheadline)
                .foregroundColor(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            TextEditor(text: $modifications)
                .frame(height: 150)
                .padding()
                .foregroundColor(Theme.Colors.text)
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                        .fill(Theme.Colors.surface.opacity(0.3))
                        .background(.ultraThinMaterial)
                )
                .shadow(color: Theme.shadowColor.opacity(0.1), radius: Theme.shadowRadius)
                .padding()
            
            Spacer()
        }
    }
    
    private var navigationButtons: some View {
        HStack(spacing: Theme.Spacing.large) {
            if currentStep > 0 {
                Button {
                    withAnimation {
                        currentStep -= 1
                    }
                } label: {
                    Text("Back")
                        .fontWeight(.medium)
                        .foregroundColor(Theme.Colors.text)
                        .frame(width: 100)
                        .padding()
                }
                .buttonStyle(PlainButtonStyle())
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
            }
            
            Button {
                if currentStep < 2 {
                    withAnimation {
                        currentStep += 1
                    }
                } else {
                    addVehicle()
                }
            } label: {
                Text(currentStep == 2 ? "Add Vehicle" : "Next")
                    .fontWeight(.bold)
                    .foregroundColor(Theme.Colors.text)
                    .frame(maxWidth: currentStep == 0 ? .infinity : 100)
                    .padding()
            }
            .buttonStyle(PlainButtonStyle())
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .disabled(!isStepValid)
            .opacity(isStepValid ? 1 : 0.5)
        }
        .padding()
    }
    
    private var isStepValid: Bool {
        switch currentStep {
        case 0:
            return !make.isEmpty && !model.isEmpty
        case 1:
            return true // Photos are optional
        case 2:
            return true // Modifications are optional
        default:
            return false
        }
    }
    
    private func vehicleTypeButton(_ buttonType: VehicleType, icon: String, title: String) -> some View {
        Button {
            withAnimation {
                type = buttonType
            }
        } label: {
            VStack(spacing: Theme.Spacing.small) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(type == buttonType ? Theme.Colors.text : Theme.Colors.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .fill(Theme.Colors.surface.opacity(0.3))
                    .background(.ultraThinMaterial)
            )
            .shadow(color: type == buttonType ? Theme.Colors.accent.opacity(0.3) : Theme.shadowColor.opacity(0.1),
                   radius: Theme.shadowRadius * 0.5)
        }
    }
    
    private func handlePhotoSelection(_ items: [PhotosPickerItem]) async {
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                let resizedImage = await resizeImage(image, targetSize: CGSize(width: 800, height: 800))
                await MainActor.run {
                    vehiclePhotos.append(resizedImage)
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
    
    private func addVehicle() {
        let vehicle = Vehicle(
            id: UUID().uuidString,
            userId: authManager.currentUser?.id,
            make: make,
            model: model,
            year: year,
            type: type,
            modifications: modifications.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) },
            photos: uploadedPhotoUrls,
            createdAt: Date(),
            updatedAt: Date()
        )
        onAdd(vehicle)
        dismiss()
    }
}

#Preview {
    if #available(iOS 16.0, *) {
        AddVehicleView { _ in }
            .environmentObject(AuthManager())
    } else {
        Text("Requires iOS 16.0 or later")
    }
} 
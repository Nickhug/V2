import SwiftUI
import PhotosUI
import CoreLocation

struct PostCreationView: View {
    @ObservedObject var viewModel: FeedViewModel
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var caption = ""
    @State private var selectedImages: [UIImage] = []
    @State private var selectedImagesData: [PhotosPickerItem] = []
    @State private var selectedVehicle: Vehicle?
    @State private var showingVehicleSelector = false
    @State private var location: CLLocationCoordinate2D?
    @State private var locationName = ""
    @State private var isUsingCurrentLocation = false
    @State private var showingLocationSelector = false
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    // Location manager for current location
    @StateObject private var locationManager: LocationManager = LocationManager()
    
    var body: some View {
        NavigationView {
            ZStack {
                ModernGradientBackground()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Image selection
                        imageSelection
                        
                        // Caption field
                        captionField
                        
                        // Vehicle selection button
                        vehicleSelectionButton
                        
                        // Location field
                        locationSelectionSection
                        
                        // Submit button
                        submitButton
                    }
                    .padding()
                }
                .navigationTitle("Create Post")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
                .overlay {
                    if isLoading {
                        loadingOverlay
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showingVehicleSelector) {
                VehicleSelectorView(selectedVehicle: $selectedVehicle)
            }
            .sheet(isPresented: $showingLocationSelector) {
                // Location selector view would go here
                // This could be a map view or list of locations
                // For now, we'll just use a text field
            }
        }
    }
    
    private var imageSelection: some View {
        VStack(spacing: 10) {
            if selectedImages.isEmpty {
                // Empty state
                PhotosPicker(selection: $selectedImagesData, maxSelectionCount: 5, matching: .images) {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                        
                        Text("Select Photos")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Add up to 5 photos of your vehicle")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                }
            } else {
                // Show selected images
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<selectedImages.count, id: \.self) { index in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: selectedImages[index])
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                
                                Button(action: {
                                    removeImage(at: index)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                }
                                .padding(4)
                            }
                        }
                        
                        // Add more photos button (if less than 5)
                        if selectedImages.count < 5 {
                            PhotosPicker(selection: $selectedImagesData, maxSelectionCount: 5 - selectedImages.count, matching: .images) {
                                VStack {
                                    Image(systemName: "plus")
                                        .font(.system(size: 30))
                                    Text("Add")
                                        .font(.caption)
                                }
                                .foregroundColor(.white)
                                .frame(width: 100, height: 100)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .onChange(of: selectedImagesData) { _, newValue in
            Task {
                selectedImages = []
                for item in newValue {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            selectedImages.append(image)
                        }
                    }
                }
            }
        }
    }
    
    private var captionField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Caption")
                .font(.headline)
                .foregroundColor(.white)
            
            TextEditor(text: $caption)
                .foregroundColor(.white)
                .frame(minHeight: 100)
                .padding(8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        }
    }
    
    private var vehicleSelectionButton: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Vehicle")
                .font(.headline)
                .foregroundColor(.white)
            
            Button(action: {
                showingVehicleSelector = true
            }) {
                HStack {
                    if let vehicle = selectedVehicle {
                        Text("\(vehicle.year) \(vehicle.make) \(vehicle.model)")
                            .foregroundColor(.white)
                    } else {
                        Text("Select a vehicle (optional)")
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    private var locationSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Location")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack {
                TextField("Add location (optional)", text: $locationName)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                
                Button(action: {
                    useCurrentLocation()
                }) {
                    Image(systemName: "location.fill")
                        .foregroundColor(isUsingCurrentLocation ? .blue : .white)
                        .padding(12)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
    }
    
    private var submitButton: some View {
        Button(action: {
            createPost()
        }) {
            Text("Post")
                .font(.headline)
                .foregroundColor(.black)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    submitButtonEnabled ?
                    Color.white :
                    Color.white.opacity(0.5)
                )
                .cornerRadius(10)
        }
        .disabled(!submitButtonEnabled)
        .padding(.top, 20)
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text("Creating post...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(30)
            .background(Color.black.opacity(0.7))
            .cornerRadius(16)
        }
    }
    
    private var submitButtonEnabled: Bool {
        !selectedImages.isEmpty && !caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }
    
    private func removeImage(at index: Int) {
        selectedImages.remove(at: index)
        selectedImagesData.remove(at: index)
    }
    
    private func useCurrentLocation() {
        isUsingCurrentLocation.toggle()
        
        if isUsingCurrentLocation {
            // Request location access if not already granted
            if let currentLocation = locationManager.location {
                self.location = currentLocation.coordinate
                
                // Reverse geocode to get location name
                let geocoder = CLGeocoder()
                let clLocation = currentLocation
                
                geocoder.reverseGeocodeLocation(clLocation) { placemarks, error in
                    if let error = error {
                        print("Reverse geocoding error: \(error.localizedDescription)")
                        return
                    }
                    
                    if let placemark = placemarks?.first {
                        let locationString = [
                            placemark.locality,
                            placemark.administrativeArea,
                            placemark.country
                        ]
                        .compactMap { $0 }
                        .joined(separator: ", ")
                        
                        self.locationName = locationString
                    }
                }
            }
        } else {
            self.location = nil
            self.locationName = ""
        }
    }
    
    private func createPost() {
        guard !selectedImages.isEmpty else {
            errorMessage = "Please select at least one image."
            showError = true
            return
        }
        
        guard !caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please add a caption."
            showError = true
            return
        }
        
        isLoading = true
        
        Task {
            // Create the post
            let success = await viewModel.createPost(
                caption: caption,
                images: selectedImages,
                vehicle: selectedVehicle,
                location: location,
                locationName: locationName.isEmpty ? nil : locationName
            )
            
            await MainActor.run {
                isLoading = false
                if success {
                    dismiss()
                } else {
                    errorMessage = "Failed to create post. Please try again."
                    showError = true
                }
            }
        }
    }
}

struct VehicleSelectorView: View {
    @EnvironmentObject var authManager: AuthManager
    @Binding var selectedVehicle: Vehicle?
    @Environment(\.dismiss) private var dismiss
    
    @State private var vehicles: [Vehicle] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            ZStack {
                ModernGradientBackground()
                
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else if vehicles.isEmpty {
                    emptyStateView
                } else {
                    vehicleListView
                }
            }
            .navigationTitle("Select Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadVehicles()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "car.fill")
                .font(.system(size: 50))
                .foregroundColor(.white.opacity(0.7))
            
            Text("No Vehicles Found")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text("Add a vehicle in your profile to tag it in posts.")
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    private var vehicleListView: some View {
        List {
            // None option
            Button(action: {
                selectedVehicle = nil
                dismiss()
            }) {
                HStack {
                    Text("None")
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if selectedVehicle == nil {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
            }
            .listRowBackground(Color.black.opacity(0.3))
            
            // Vehicle options
            ForEach(vehicles) { vehicle in
                Button(action: {
                    selectedVehicle = vehicle
                    dismiss()
                }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(vehicle.year) \(vehicle.make) \(vehicle.model)")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text(vehicle.type.rawValue.capitalized)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        if let selected = selectedVehicle, selected.id == vehicle.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .listRowBackground(Color.black.opacity(0.3))
            }
        }
        .listStyle(.plain)
    }
    
    private func loadVehicles() {
        Task {
            do {
                let vehicleData = try await SupabaseService.shared.fetchVehicles()
                await MainActor.run {
                    self.vehicles = vehicleData
                    self.isLoading = false
                }
            } catch {
                print("Error loading vehicles: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
} 
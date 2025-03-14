import SwiftUI
import MapKit
import PhotosUI
import UIKit

struct CreateMeetView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: MeetViewModel
    @State private var title = ""
    @State private var description = ""
    @State private var date = Date()
    @State private var type = V2MeetType.car
    @State private var capacity = 50
    @State private var address = ""
    @State private var rules: [String] = [""]
    @State private var tags: [String] = [""]
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var showLocationPicker = false
    @State private var selectedLocation: CLLocationCoordinate2D?
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case title, description, address, rule(Int), tag(Int)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Replace static background with animated gradient
                AnimatedGradientBackground()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Meet Type Selection
                        HStack(spacing: 20) {
                            MeetTypeButton(
                                type: .car,
                                isSelected: type == .car,
                                action: { type = .car }
                            )
                            
                            MeetTypeButton(
                                type: .bike,
                                isSelected: type == .bike,
                                action: { type = .bike }
                            )
                            
                            MeetTypeButton(
                                type: .mixed,
                                isSelected: type == .mixed,
                                action: { type = .mixed }
                            )
                        }
                        .padding(.horizontal)
                        
                        // Basic Information
                        VStack(spacing: 15) {
                            CustomTextField(
                                title: "Title", 
                                text: $title, 
                                icon: "textformat",
                                focused: focusedField == .title
                            )
                            .focused($focusedField, equals: .title)
                            
                            CustomTextField(
                                title: "Description", 
                                text: $description, 
                                icon: "text.quote", 
                                isMultiline: true,
                                focused: focusedField == .description
                            )
                            .focused($focusedField, equals: .description)
                            
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.blue)
                                DatePicker("Date", selection: $date, in: Date()...)
                                    .labelsHidden()
                            }
                            
                            HStack {
                                Image(systemName: "person.3.fill")
                                    .foregroundColor(.blue)
                                Stepper("Capacity: \(capacity)", value: $capacity, in: 10...1000, step: 10)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        .padding(.horizontal)
                        
                        // Location Section
                        VStack(spacing: 15) {
                            CustomTextField(
                                title: "Address", 
                                text: $address, 
                                icon: "location.fill",
                                focused: focusedField == .address
                            )
                            .focused($focusedField, equals: .address)
                            
                            Button {
                                // Dismiss keyboard if active before showing picker
                                focusedField = nil
                                showLocationPicker = true
                            } label: {
                                HStack {
                                    Image(systemName: "map.fill")
                                        .foregroundColor(.blue)
                                    Text("Pick on Map")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                            }
                            
                            if let location = selectedLocation {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Location: \(String(format: "%.4f, %.4f", location.latitude, location.longitude))")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        .padding(.horizontal)
                        
                        // Rules Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "list.bullet")
                                    .foregroundColor(.blue)
                                Text("Rules")
                                    .font(.headline)
                            }
                            
                            ForEach(rules.indices, id: \.self) { index in
                                HStack {
                                    TextField("Rule", text: $rules[index])
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .focused($focusedField, equals: .rule(index))
                                    
                                    if rules.count > 1 {
                                        Button {
                                            rules.remove(at: index)
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundColor(.red)
                                        }
                                    }
                                }
                            }
                            
                            Button {
                                rules.append("")
                            } label: {
                                Label("Add Rule", systemImage: "plus.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        .padding(.horizontal)
                        
                        // Tags Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "tag")
                                    .foregroundColor(.blue)
                                Text("Tags")
                                    .font(.headline)
                            }
                            
                            ForEach(tags.indices, id: \.self) { index in
                                HStack {
                                    TextField("Tag", text: $tags[index])
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .focused($focusedField, equals: .tag(index))
                                    
                                    if tags.count > 1 {
                                        Button {
                                            tags.remove(at: index)
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundColor(.red)
                                        }
                                    }
                                }
                            }
                            
                            Button {
                                tags.append("")
                            } label: {
                                Label("Add Tag", systemImage: "plus.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        .padding(.horizontal)
                        
                        // Cover Image Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "photo")
                                    .foregroundColor(.blue)
                                Text("Cover Image")
                                    .font(.headline)
                            }
                            
                            Button {
                                // Dismiss keyboard if active before showing picker
                                focusedField = nil
                                showImagePicker = true
                            } label: {
                                if let image = selectedImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 200)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                } else {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Select Cover Image")
                                    }
                                    .foregroundColor(.blue)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 200)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(10)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                    // Add padding at the bottom for keyboard
                    .padding(.bottom, keyboardHeight)
                }
            }
            .navigationTitle("Create Meet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        // Dismiss keyboard before creating
                        focusedField = nil
                        createMeet()
                    }
                    .disabled(title.isEmpty || description.isEmpty || address.isEmpty || selectedLocation == nil || selectedImage == nil || isLoading)
                }
                
                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .sheet(isPresented: $showLocationPicker) {
                LocationPicker(selectedLocation: $selectedLocation, address: $address)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onTapGesture {
                // Dismiss keyboard when tapping outside text fields
                focusedField = nil
            }
            .onAppear {
                // Set up keyboard notifications
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
                    if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                        keyboardHeight = keyboardFrame.height
                    }
                }
                
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                    keyboardHeight = 0
                }
            }
            .onDisappear {
                // Remove keyboard notifications
                NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
                NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
            }
        }
    }
    
    private func createMeet() {
        guard let location = selectedLocation,
              let image = selectedImage else { return }
        
        isLoading = true
        
        Task {
            do {
                try await viewModel.createMeet(
                    title: title,
                    description: description,
                    date: date,
                    type: type,
                    location: location,
                    address: address,
                    rules: rules.filter { !$0.isEmpty },
                    tags: tags.filter { !$0.isEmpty },
                    coverImage: image,
                    capacity: capacity,
                    vehicleType: .car,
                    routeType: .city
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }
}

struct LocationPicker: View {
    @Binding var selectedLocation: CLLocationCoordinate2D?
    @Binding var address: String
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationManager: LocationManager = LocationManager()
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var mapProxy: MapProxy?
    @State private var showingSearchResults = false
    @State private var keyboardHeight: CGFloat = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                Map(position: .constant(MapCameraPosition.region(region))) {
                    if let location = selectedLocation {
                        Marker("Selected Location", coordinate: location)
                    }
                    
                    // User location annotation
                    if locationManager.location != nil {
                        UserAnnotation()
                    }
                }
                .mapStyle(.standard)
                .onMapCameraChange { context in
                    region = context.region
                }
                .mapControls {
                    MapCompass()
                    MapScaleView()
                }
                .onTapGesture { point in
                    // Convert tap point to map coordinates
                    let coordinate = convertTapToCoordinate(point, in: region)
                    selectedLocation = coordinate
                    // Use reverse geocoding to get the address
                    Task {
                        await getAddress(for: coordinate)
                    }
                    
                    // Dismiss keyboard if active
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                
                // Search Results List
                if showingSearchResults && !searchResults.isEmpty {
                    VStack {
                        List(searchResults, id: \.self) { item in
                            Button {
                                selectedLocation = item.placemark.coordinate
                                address = item.name ?? item.placemark.title ?? "Selected location"
                                showingSearchResults = false
                                
                                // Dismiss keyboard
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(item.name ?? "Unknown Location")
                                        .font(.headline)
                                    Text(item.placemark.title ?? "")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .listStyle(.plain)
                        .background(Color(.systemBackground))
                        .frame(maxHeight: 300)
                        .cornerRadius(10)
                        .padding()
                        .shadow(radius: 5)
                        
                        Spacer()
                    }
                    // Adjust for keyboard if visible
                    .padding(.bottom, keyboardHeight)
                }
            }
            .navigationTitle("Pick Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .disabled(selectedLocation == nil)
                }
            }
            .searchable(text: $searchText, prompt: "Search for a location")
            .onChange(of: searchText) { oldValue, newValue in
                if !newValue.isEmpty {
                    searchNearbyPlaces(query: newValue)
                    showingSearchResults = true
                } else {
                    showingSearchResults = false
                }
            }
            .onAppear {
                locationManager.requestLocation()
                
                // Only set the initial region if location is available and region hasn't been set yet
                if let location = locationManager.location {
                    // Use default span or adjust based on accuracy
                    let span = MKCoordinateSpan(
                        latitudeDelta: 0.05,
                        longitudeDelta: 0.05
                    )
                    
                    // Create a valid region with bounds checking
                    let newRegion = MKCoordinateRegion(
                        center: location.coordinate,
                        span: span
                    )
                    
                    // Only update if the region is valid
                    if newRegion.center.latitude.isFinite && newRegion.center.longitude.isFinite &&
                       newRegion.span.latitudeDelta.isFinite && newRegion.span.longitudeDelta.isFinite {
                        region = newRegion
                    }
                }
                
                // Set up keyboard notifications
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
                    if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                        keyboardHeight = keyboardFrame.height
                    }
                }
                
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                    keyboardHeight = 0
                }
            }
            .onDisappear {
                // Remove keyboard notifications
                NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
                NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
            }
            .onChange(of: locationManager.location) { oldValue, newValue in
                // Only update region if it's the first time we're getting a location
                if oldValue == nil && newValue != nil {
                    // Create a valid region with bounds checking
                    let newRegion = MKCoordinateRegion(
                        center: newValue!.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    )
                    
                    // Only update if the region is valid
                    if newRegion.center.latitude.isFinite && newRegion.center.longitude.isFinite &&
                       newRegion.span.latitudeDelta.isFinite && newRegion.span.longitudeDelta.isFinite {
                        region = newRegion
                    }
                }
            }
        }
    }
    
    private func searchNearbyPlaces(query: String) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = region
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response else {
                print("Search error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            DispatchQueue.main.async {
                searchResults = response.mapItems
            }
        }
    }
    
    private func getAddress(for coordinate: CLLocationCoordinate2D) async {
        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
            if let placemark = placemarks.first {
                let addressComponents = [
                    placemark.name,
                    placemark.thoroughfare,
                    placemark.locality,
                    placemark.administrativeArea
                ].compactMap { $0 }
                
                address = addressComponents.joined(separator: ", ")
            }
        } catch {
            print("Geocoding error: \(error.localizedDescription)")
            address = "Selected location"
        }
    }
    
    private func convertTapToCoordinate(_ point: CGPoint, in region: MKCoordinateRegion) -> CLLocationCoordinate2D {
        // Calculate the percentage of the map width and height that was tapped
        let width = max(UIScreen.main.bounds.width, 1) // Prevent division by zero
        let height = max(UIScreen.main.bounds.height, 1) // Prevent division by zero
        
        let xPercent = min(max(point.x / width, 0), 1) // Clamp between 0 and 1
        let yPercent = min(max(point.y / height, 0), 1) // Clamp between 0 and 1
        
        // Calculate the latitude and longitude based on the tap position
        let latitude = region.center.latitude + (region.span.latitudeDelta * (0.5 - yPercent))
        let longitude = region.center.longitude + (region.span.longitudeDelta * (xPercent - 0.5))
        
        // Ensure coordinates are valid
        let validLatitude = min(max(latitude, -90), 90)
        let validLongitude = min(max(longitude, -180), 180)
        
        return CLLocationCoordinate2D(latitude: validLatitude, longitude: validLongitude)
    }
}

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let icon: String
    var isMultiline: Bool = false
    var focused: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                if isMultiline {
                    ZStack {
                        if text.isEmpty {
                            Text(title)
                                .foregroundColor(.gray.opacity(0.5))
                                .padding(.top, 8)
                                .padding(.leading, 4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        TextEditor(text: $text)
                            .frame(height: 100)
                            .padding(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                } else {
                    TextField(title, text: $text)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
            }
            .padding(2)
            .background(focused ? Color.blue.opacity(0.05) : Color.clear)
            .cornerRadius(8)
        }
    }
}

#Preview {
    CreateMeetView(viewModel: MeetViewModel())
} 
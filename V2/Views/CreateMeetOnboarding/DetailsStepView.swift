import SwiftUI
import PhotosUI
import UIKit

struct DetailsStepView: View {
    @ObservedObject var onboardingState: CreateMeetOnboardingState
    @State private var animateElements = false
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case rule(Int), tag(Int)
    }
    
    var body: some View {
        ZStack {
            // Background decoration
            Circle()
                .fill(MeetSpotColors.pink500.opacity(0.1))
                .frame(width: 200, height: 200)
                .blur(radius: 60)
                .offset(x: 150, y: -100)
            
            Circle()
                .fill(MeetSpotColors.purple900.opacity(0.1))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: -150, y: 300)
                
            // Main content
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Meet Details")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Add visual appeal and important information")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        Image(systemName: CreateMeetStep.details.systemIcon)
                            .font(.system(size: 40))
                            .foregroundColor(MeetSpotColors.pink500)
                            .opacity(animateElements ? 1 : 0)
                            .rotationEffect(.degrees(animateElements ? 0 : -30))
                            .offset(y: animateElements ? 0 : -10)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: animateElements)
                    }
                    .padding(.top, 20)
                    
                    // Form fields container
                    VStack(spacing: 24) {
                        // Cover image selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Cover Image")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                            
                            ImageSelector(
                                selectedImage: $onboardingState.selectedImage,
                                showImagePicker: $onboardingState.showImagePicker
                            )
                        }
                        .padding(.horizontal)
                        .offset(y: animateElements ? 0 : 20)
                        .opacity(animateElements ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: animateElements)
                        
                        // Vehicle Type and Route Type selectors
                        HStack(spacing: 16) {
                            // Vehicle Type selector
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Vehicle Type")
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                VehicleTypeSelector(selectedType: $onboardingState.vehicleType)
                            }
                            
                            // Route Type selector
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Route Type")
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                RouteTypeSelector(selectedType: $onboardingState.routeType)
                            }
                        }
                        .padding(.horizontal)
                        .offset(y: animateElements ? 0 : 20)
                        .opacity(animateElements ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: animateElements)
                        
                        // Rules section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Rules")
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Spacer()
                                
                                Button(action: {
                                    withAnimation(.spring()) {
                                        onboardingState.addRule()
                                    }
                                }) {
                                    Label("Add Rule", systemImage: "plus.circle.fill")
                                        .font(.subheadline)
                                        .foregroundColor(MeetSpotColors.pink500)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                            
                            VStack(spacing: 12) {
                                ForEach(onboardingState.rules.indices, id: \.self) { index in
                                    HStack {
                                        Image(systemName: "checkmark.circle")
                                            .foregroundColor(MeetSpotColors.pink500)
                                        
                                        TextField("Enter rule...", text: $onboardingState.rules[index])
                                            .foregroundColor(.white)
                                            .focused($focusedField, equals: .rule(index))
                                        
                                        if onboardingState.rules.count > 1 {
                                            Button(action: {
                                                withAnimation(.spring()) {
                                                    onboardingState.removeRule(at: index)
                                                }
                                            }) {
                                                Image(systemName: "minus.circle.fill")
                                                    .foregroundColor(.red.opacity(0.7))
                                            }
                                            .buttonStyle(BorderlessButtonStyle())
                                        }
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Material.ultraThinMaterial)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(
                                                        focusedField == .rule(index) ? MeetSpotColors.pink500 : Color.white.opacity(0.1),
                                                        lineWidth: focusedField == .rule(index) ? 2 : 1
                                                    )
                                            )
                                    )
                                    .transition(.scale.combined(with: .opacity))
                                }
                            }
                        }
                        .padding(.horizontal)
                        .offset(y: animateElements ? 0 : 20)
                        .opacity(animateElements ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3), value: animateElements)
                        
                        // Tags section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Tags")
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Spacer()
                                
                                Button(action: {
                                    withAnimation(.spring()) {
                                        onboardingState.addTag()
                                    }
                                }) {
                                    Label("Add Tag", systemImage: "plus.circle.fill")
                                        .font(.subheadline)
                                        .foregroundColor(MeetSpotColors.pink500)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                            
                            // Tags input
                            VStack(spacing: 12) {
                                ForEach(onboardingState.tags.indices, id: \.self) { index in
                                    HStack {
                                        Image(systemName: "tag.fill")
                                            .foregroundColor(MeetSpotColors.pink500)
                                        
                                        TextField("Enter tag...", text: $onboardingState.tags[index])
                                            .foregroundColor(.white)
                                            .focused($focusedField, equals: .tag(index))
                                        
                                        if onboardingState.tags.count > 1 {
                                            Button(action: {
                                                withAnimation(.spring()) {
                                                    onboardingState.removeTag(at: index)
                                                }
                                            }) {
                                                Image(systemName: "minus.circle.fill")
                                                    .foregroundColor(.red.opacity(0.7))
                                            }
                                            .buttonStyle(BorderlessButtonStyle())
                                        }
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Material.ultraThinMaterial)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(
                                                        focusedField == .tag(index) ? MeetSpotColors.pink500 : Color.white.opacity(0.1),
                                                        lineWidth: focusedField == .tag(index) ? 2 : 1
                                                    )
                                            )
                                    )
                                    .transition(.scale.combined(with: .opacity))
                                }
                            }
                        }
                        .padding(.horizontal)
                        .offset(y: animateElements ? 0 : 20)
                        .opacity(animateElements ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.4), value: animateElements)
                        
                        Spacer(minLength: 80)
                    }
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Material.ultraThinMaterial)
                            .backgroundStyle(Color.black.opacity(0.3))
                    )
                    .mediumShadow()
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
            }
        }
        .sheet(isPresented: $onboardingState.showImagePicker) {
            ImagePicker(image: $onboardingState.selectedImage)
        }
        .onAppear {
            withAnimation {
                animateElements = true
            }
        }
        .onTapGesture {
            focusedField = nil
        }
    }
}

// Image picker that shows selected image or upload button
struct ImageSelector: View {
    @Binding var selectedImage: UIImage?
    @Binding var showImagePicker: Bool
    @State private var isHovering = false
    
    var body: some View {
        Button(action: {
            showImagePicker = true
        }) {
            if let image = selectedImage {
                // Show selected image with edit overlay on hover
                ZStack(alignment: .center) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .opacity(isHovering ? 0.7 : 1.0)
                    
                    if isHovering {
                        VStack(spacing: 12) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                            
                            Text("Change Image")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .transition(.opacity)
                    }
                }
                .onTapGesture {
                    // Simulate hover effect on touch
                    isHovering = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isHovering = false
                    }
                }
            } else {
                // Show upload button
                VStack(spacing: 16) {
                    Image(systemName: "photo.fill")
                        .font(.system(size: 40))
                        .foregroundColor(MeetSpotColors.pink500)
                    
                    Text("Upload Cover Image")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Tap to select an image")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Material.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    MeetSpotColors.pink500.opacity(0.5),
                                    style: StrokeStyle(lineWidth: 2, dash: [5])
                                )
                        )
                )
                .contentShape(Rectangle())
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Vehicle type selector
struct VehicleTypeSelector: View {
    @Binding var selectedType: VehicleType
    
    var body: some View {
        Picker("", selection: $selectedType) {
            ForEach(VehicleType.allCases, id: \.self) { type in
                HStack {
                    Image(systemName: iconForVehicle(type))
                    Text(type.rawValue.capitalized)
                }
                .tag(type)
            }
        }
        .pickerStyle(.menu)
        .tint(.white)
        .padding()
        .frame(maxWidth: .infinity)
        .background(vehiclePickerBackground)
        .overlay(vehiclePickerOverlay)
    }
    
    // Extract background into a separate property
    private var vehiclePickerBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Material.ultraThinMaterial)
    }
    
    // Extract overlay into a separate property
    private var vehiclePickerOverlay: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(Color.white.opacity(0.2), lineWidth: 1)
    }
    
    // Get icon for vehicle type
    func iconForVehicle(_ type: VehicleType) -> String {
        switch type {
        case .car: return "car.fill"
        case .bike: return "bicycle"
        case .both: return "car.fill" // Default icon for "both" type
        }
    }
}

// Route type selector
struct RouteTypeSelector: View {
    @Binding var selectedType: RouteType
    
    var body: some View {
        Picker("", selection: $selectedType) {
            ForEach(RouteType.allCases, id: \.self) { type in
                HStack {
                    Image(systemName: iconForRoute(type))
                    Text(type.rawValue.capitalized)
                }
                .tag(type)
            }
        }
        .pickerStyle(.menu)
        .tint(.white)
        .padding()
        .frame(maxWidth: .infinity)
        .background(routePickerBackground)
        .overlay(routePickerOverlay)
    }
    
    // Extract background into a separate property
    private var routePickerBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Material.ultraThinMaterial)
    }
    
    // Extract overlay into a separate property
    private var routePickerOverlay: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(Color.white.opacity(0.2), lineWidth: 1)
    }
    
    // Get icon for route type
    func iconForRoute(_ type: RouteType) -> String {
        switch type {
        case .city: return "building.2.fill"
        case .mountain: return "mountain.2.fill"
        case .coastal: return "water.waves"
        case .scenic: return "binoculars.fill"
        }
    }
}

// Preview
struct DetailsStepView_Previews: PreviewProvider {
    static var previews: some View {
        DetailsStepView(onboardingState: CreateMeetOnboardingState())
            .preferredColorScheme(.dark)
    }
} 
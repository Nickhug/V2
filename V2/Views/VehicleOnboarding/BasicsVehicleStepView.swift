import SwiftUI

struct BasicsVehicleStepView: View {
    @ObservedObject var onboardingState: VehicleOnboardingState
    @State private var animateElements = false
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case make, model
    }
    
    var body: some View {
        ZStack {
            // Background decoration
            Circle()
                .fill(MeetSpotColors.pink500.opacity(0.1))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: -150, y: -100)
            
            Circle()
                .fill(MeetSpotColors.purple900.opacity(0.1))
                .frame(width: 250, height: 250)
                .blur(radius: 60)
                .offset(x: 150, y: 300)
                
            // Main content
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tell us about your ride")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Add the main details of your vehicle")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        Image(systemName: VehicleStep.basics.systemIcon)
                            .font(.system(size: 40))
                            .foregroundColor(MeetSpotColors.pink500)
                            .opacity(animateElements ? 1 : 0)
                            .rotationEffect(.degrees(animateElements ? 0 : -30))
                            .offset(y: animateElements ? 0 : -10)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: animateElements)
                    }
                    .padding(.top, 20)
                    
                    // Form fields container
                    VStack(spacing: 20) {
                        // Vehicle Type Selector
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Vehicle Type")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                            
                            HStack(spacing: 12) {
                                vehicleTypeButton(.car, icon: "car.fill", title: "Car")
                                vehicleTypeButton(.bike, icon: "bicycle", title: "Bike")
                            }
                        }
                        .padding(.horizontal)
                        .offset(x: animateElements ? 0 : -50)
                        .opacity(animateElements ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: animateElements)
                        
                        // Make field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Make")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                            
                            GlassmorphicComponents.TextField(
                                text: $onboardingState.make,
                                placeholder: "e.g. Toyota",
                                icon: "building.2.fill",
                                isFocused: focusedField == .make
                            )
                            .focused($focusedField, equals: .make)
                        }
                        .padding(.horizontal)
                        .offset(x: animateElements ? 0 : -50)
                        .opacity(animateElements ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: animateElements)
                        
                        // Model field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Model")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                            
                            GlassmorphicComponents.TextField(
                                text: $onboardingState.model,
                                placeholder: "e.g. Supra",
                                icon: "car.side.fill",
                                isFocused: focusedField == .model
                            )
                            .focused($focusedField, equals: .model)
                        }
                        .padding(.horizontal)
                        .offset(x: animateElements ? 0 : -50)
                        .opacity(animateElements ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3), value: animateElements)
                        
                        // Year picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Year")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                            
                            YearPickerView(year: $onboardingState.year)
                        }
                        .padding(.horizontal)
                        .offset(x: animateElements ? 0 : -50)
                        .opacity(animateElements ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.4), value: animateElements)
                        
                        Spacer(minLength: 60)
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
        .onAppear {
            withAnimation {
                animateElements = true
            }
        }
        .onTapGesture {
            focusedField = nil
        }
    }
    
    private func vehicleTypeButton(_ buttonType: VehicleType, icon: String, title: String) -> some View {
        Button {
            withAnimation {
                onboardingState.type = buttonType
            }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(onboardingState.type == buttonType ? .white : .white.opacity(0.5))
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Material.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                onboardingState.type == buttonType ? 
                                    MeetSpotColors.pink500 : Color.white.opacity(0.1),
                                lineWidth: onboardingState.type == buttonType ? 2 : 1
                            )
                    )
            )
            .shadow(
                color: onboardingState.type == buttonType ? 
                    MeetSpotColors.pink500.opacity(0.5) : Color.black.opacity(0.1),
                radius: 10, 
                x: 0, 
                y: 5
            )
            .animation(.spring(), value: onboardingState.type)
        }
    }
}

// Year picker with wheel style
struct YearPickerView: View {
    @Binding var year: Int
    let currentYear = Calendar.current.component(.year, from: Date())
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 24, height: 24)
                
                Picker("", selection: $year) {
                    ForEach((1900...currentYear).reversed(), id: \.self) { year in
                        Text(String(year))
                            .foregroundColor(.white)
                            .tag(year)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 120)
                .clipped()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Material.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
} 
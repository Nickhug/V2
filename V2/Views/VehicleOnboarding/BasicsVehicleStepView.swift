import SwiftUI

struct BasicsVehicleStepView: View {
    @ObservedObject var onboardingState: VehicleOnboardingState
    @State private var animateElements = false
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case make, model
    }
    
    var body: some View {
        ScrollView {
            // Main content
            VStack(spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Vehicle Details")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Tell us about your vehicle")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Image(systemName: VehicleStep.basics.systemIcon)
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                        .opacity(animateElements ? 1 : 0)
                        .rotationEffect(.degrees(animateElements ? 0 : -30))
                        .offset(y: animateElements ? 0 : -10)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: animateElements)
                }
                .padding(.top, 20)
                
                // Form container
                VStack(spacing: 20) {
                    // Vehicle Type Selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Vehicle Type")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        HStack(spacing: 12) {
                            vehicleTypeButton(.car, icon: "car.fill", title: "Car")
                            vehicleTypeButton(.bike, icon: "bicycle", title: "Bike")
                            vehicleTypeButton(.mixed, icon: "car.and.bicycle", title: "Mixed")
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
                            placeholder: "e.g. Corolla",
                            icon: "car.fill",
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
                        
                        Picker("Year", selection: $onboardingState.year) {
                            ForEach((1950...Calendar.current.component(.year, from: Date())).reversed(), id: \.self) { year in
                                Text(String(year))
                                    .foregroundColor(.white)
                                    .tag(year)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
                        .padding(.horizontal, -16)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal)
                    .offset(x: animateElements ? 0 : -50)
                    .opacity(animateElements ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.4), value: animateElements)
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
                    .font(.system(size: 24))
                    .foregroundColor(onboardingState.type == buttonType ? .black : .white)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(onboardingState.type == buttonType ? .black : .white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(onboardingState.type == buttonType ? Color.white : Color.white.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(onboardingState.type == buttonType ? Color.black : Color.white.opacity(0.2), lineWidth: onboardingState.type == buttonType ? 1.5 : 1)
            )
        }
    }
} 
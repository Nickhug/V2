import SwiftUI

struct ModificationsVehicleStepView: View {
    @ObservedObject var onboardingState: VehicleOnboardingState
    @State private var animateElements = false
    @State private var newModification = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Vehicle Modifications")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Add any modifications you've made")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Image(systemName: VehicleStep.modifications.systemIcon)
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                        .opacity(animateElements ? 1 : 0)
                        .rotationEffect(.degrees(animateElements ? 0 : -30))
                        .offset(y: animateElements ? 0 : -10)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: animateElements)
                }
                .padding(.top, 20)
                
                // Modifications container
                VStack(spacing: 20) {
                    // Info text
                    Text("List any modifications or upgrades you've made to your vehicle. This is optional but helps others know what makes your ride special.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : 10)
                        .animation(.easeIn.delay(0.1), value: animateElements)
                    
                    // Add new modification field
                    HStack {
                        TextField("", text: $newModification)
                            .viewPlaceholder(when: newModification.isEmpty) {
                                Text("Type a modification...").foregroundColor(.white.opacity(0.3))
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            )
                        
                        Button {
                            if !newModification.isEmpty {
                                withAnimation {
                                    onboardingState.modifications.append(newModification)
                                    newModification = ""
                                }
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.black)
                                .padding(8)
                                .background(Color.white)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.black, lineWidth: 1.5)
                                )
                        }
                        .disabled(newModification.isEmpty)
                        .opacity(newModification.isEmpty ? 0.5 : 1)
                    }
                    .padding(.horizontal)
                    .opacity(animateElements ? 1 : 0)
                    .offset(y: animateElements ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: animateElements)
                    
                    // Modifications list
                    VStack(spacing: 10) {
                        if onboardingState.modifications.isEmpty || (onboardingState.modifications.count == 1 && onboardingState.modifications[0].isEmpty) {
                            Text("No modifications added yet")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.5))
                                .padding(.vertical, 20)
                        } else {
                            ForEach(onboardingState.modifications.indices, id: \.self) { index in
                                if !onboardingState.modifications[index].isEmpty {
                                    HStack {
                                        Image(systemName: "wrench.fill")
                                            .foregroundColor(.white.opacity(0.8))
                                        
                                        Text(onboardingState.modifications[index])
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Button {
                                            withAnimation {
                                                onboardingState.modifications.remove(at: index)
                                                if onboardingState.modifications.isEmpty {
                                                    onboardingState.modifications = [""]
                                                }
                                            }
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.white.opacity(0.7))
                                        }
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.ultraThinMaterial)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                            )
                                    )
                                    .transition(.opacity.combined(with: .move(edge: .leading)))
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .opacity(animateElements ? 1 : 0)
                    .offset(y: animateElements ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: animateElements)
                    
                    // Common modifications suggestions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("COMMON MODIFICATIONS")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.6))
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(exampleModifications, id: \.self) { mod in
                                    Button {
                                        if !onboardingState.modifications.contains(mod) {
                                            withAnimation {
                                                if onboardingState.modifications.count == 1 && onboardingState.modifications[0].isEmpty {
                                                    onboardingState.modifications[0] = mod
                                                } else {
                                                    onboardingState.modifications.append(mod)
                                                }
                                            }
                                        }
                                    } label: {
                                        Text(mod)
                                            .font(.footnote)
                                            .foregroundColor(onboardingState.modifications.contains(mod) ? .black : .white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(onboardingState.modifications.contains(mod) ? Color.white : Color.white.opacity(0.1))
                                            .clipShape(Capsule())
                                            .overlay(
                                                Capsule()
                                                    .stroke(onboardingState.modifications.contains(mod) ? Color.black : Color.white.opacity(0.2), lineWidth: onboardingState.modifications.contains(mod) ? 1.5 : 1)
                                            )
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .opacity(animateElements ? 1 : 0)
                    .offset(y: animateElements ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.4), value: animateElements)
                }
                .padding(.bottom, 100)
            }
        }
        .onAppear {
            withAnimation {
                animateElements = true
            }
        }
    }
    
    // Example modifications for suggestions
    private let exampleModifications = [
        "Performance Exhaust",
        "Lowering Springs",
        "Cold Air Intake",
        "ECU Tune",
        "Coilovers",
        "Aftermarket Wheels",
        "Window Tint",
        "Turbo Kit",
        "Body Kit",
        "Upgraded Brakes"
    ]
} 
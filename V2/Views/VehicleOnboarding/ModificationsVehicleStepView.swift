import SwiftUI

struct ModificationsVehicleStepView: View {
    @ObservedObject var onboardingState: VehicleOnboardingState
    @State private var animateElements = false
    @State private var newModification = ""
    
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
                            .foregroundColor(MeetSpotColors.pink500)
                            .opacity(animateElements ? 1 : 0)
                            .rotationEffect(.degrees(animateElements ? 0 : -30))
                            .offset(y: animateElements ? 0 : -10)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: animateElements)
                    }
                    .padding(.top, 20)
                    
                    // Modifications container
                    VStack(spacing: 24) {
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
                                .placeholder(when: newModification.isEmpty) {
                                    Text("Type a modification...").foregroundColor(.white.opacity(0.3))
                                }
                                .foregroundColor(.white)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Material.ultraThinMaterial)
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
                                    .foregroundColor(MeetSpotColors.pink500)
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
                                                .foregroundColor(MeetSpotColors.pink500.opacity(0.8))
                                            
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
                                                    .foregroundColor(.white.opacity(0.6))
                                            }
                                        }
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Material.ultraThinMaterial.opacity(0.5))
                                        )
                                        .transition(.scale.combined(with: .opacity))
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity)
                        .animation(.spring(), value: onboardingState.modifications)
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : 20)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: animateElements)
                        
                        // Examples
                        VStack(alignment: .leading, spacing: 12) {
                            Text("POPULAR MODIFICATIONS")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.6))
                            
                            // Suggestion chips
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(exampleModifications, id: \.self) { mod in
                                        Button {
                                            withAnimation {
                                                if !onboardingState.modifications.contains(mod) {
                                                    onboardingState.modifications.append(mod)
                                                }
                                            }
                                        } label: {
                                            Text(mod)
                                                .font(.caption)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(
                                                    Capsule()
                                                        .fill(Material.ultraThinMaterial)
                                                )
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : 20)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.4), value: animateElements)
                        
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
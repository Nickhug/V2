import SwiftUI

struct PreviewVehicleStepView: View {
    @ObservedObject var onboardingState: VehicleOnboardingState
    @State private var animateElements = false
    
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
                            Text("Preview Your Vehicle")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Review the information before adding your vehicle")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        Image(systemName: VehicleStep.preview.systemIcon)
                            .font(.system(size: 40))
                            .foregroundColor(MeetSpotColors.pink500)
                            .opacity(animateElements ? 1 : 0)
                            .rotationEffect(.degrees(animateElements ? 0 : -30))
                            .offset(y: animateElements ? 0 : -10)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: animateElements)
                    }
                    .padding(.top, 20)
                    
                    // Preview content
                    VStack(spacing: 24) {
                        // Vehicle photos preview
                        VStack(alignment: .leading, spacing: 12) {
                            Text("PHOTOS")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal)
                            
                            if onboardingState.vehiclePhotos.isEmpty {
                                Text("No photos added")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.5))
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 20)
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(onboardingState.vehiclePhotos.indices, id: \.self) { index in
                                            Image(uiImage: onboardingState.vehiclePhotos[index])
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 200, height: 130)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                                .mediumShadow()
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : 10)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: animateElements)
                        
                        // Vehicle details
                        VStack(alignment: .leading, spacing: 12) {
                            Text("DETAILS")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal)
                            
                            // Basic details card
                            PreviewCardSection {
                                // Vehicle type
                                PreviewInfoRow(
                                    icon: onboardingState.type == .car ? "car.fill" : "bicycle",
                                    iconColor: .blue,
                                    title: "Vehicle Type",
                                    value: onboardingState.type.rawValue.capitalized
                                )
                                
                                // Make & Model
                                PreviewInfoRow(
                                    icon: "building.2.fill",
                                    iconColor: .purple,
                                    title: "Make & Model",
                                    value: "\(onboardingState.make) \(onboardingState.model)"
                                )
                                
                                // Year
                                PreviewInfoRow(
                                    icon: "calendar",
                                    iconColor: .green,
                                    title: "Year",
                                    value: "\(onboardingState.year)"
                                )
                            }
                        }
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : 10)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: animateElements)
                        
                        // Modifications
                        VStack(alignment: .leading, spacing: 12) {
                            Text("MODIFICATIONS")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal)
                            
                            // Modifications card
                            PreviewCardSection {
                                if onboardingState.modifications.isEmpty || (onboardingState.modifications.count == 1 && onboardingState.modifications[0].isEmpty) {
                                    HStack {
                                        Image(systemName: "wrench.fill")
                                            .foregroundColor(.gray)
                                        
                                        Text("No modifications added")
                                            .foregroundColor(.white.opacity(0.5))
                                        
                                        Spacer()
                                    }
                                } else {
                                    ForEach(onboardingState.getModificationsArray(), id: \.self) { mod in
                                        HStack {
                                            Image(systemName: "wrench.fill")
                                                .foregroundColor(.orange)
                                            
                                            Text(mod)
                                                .foregroundColor(.white)
                                            
                                            Spacer()
                                        }
                                    }
                                }
                            }
                        }
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : 10)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: animateElements)
                        
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
}

// Preview card section
struct PreviewCardSection<Content: View>: View {
    @ViewBuilder var content: Content
    
    var body: some View {
        VStack(spacing: 16) {
            content
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Material.ultraThinMaterial.opacity(0.5))
        )
        .padding(.horizontal)
    }
}

// Preview info row
struct PreviewInfoRow: View {
    var icon: String
    var iconColor: Color
    var title: String
    var value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(iconColor)
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .fill(iconColor.opacity(0.2))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
    }
} 
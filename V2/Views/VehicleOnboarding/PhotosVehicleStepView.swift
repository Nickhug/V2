import SwiftUI
import PhotosUI

struct PhotosVehicleStepView: View {
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
                            Text("Vehicle Photos")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Show off your ride with some photos")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        Image(systemName: VehicleStep.photos.systemIcon)
                            .font(.system(size: 40))
                            .foregroundColor(MeetSpotColors.pink500)
                            .opacity(animateElements ? 1 : 0)
                            .rotationEffect(.degrees(animateElements ? 0 : -30))
                            .offset(y: animateElements ? 0 : -10)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: animateElements)
                    }
                    .padding(.top, 20)
                    
                    // Photos selection container
                    VStack(spacing: 24) {
                        Text("Upload up to 5 photos of your vehicle")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .opacity(animateElements ? 1 : 0)
                            .animation(.easeIn.delay(0.1), value: animateElements)
                        
                        if onboardingState.vehiclePhotos.isEmpty {
                            // Empty state - show upload button
                            PhotosPicker(
                                selection: $onboardingState.selectedPhotos,
                                maxSelectionCount: 5,
                                matching: .images
                            ) {
                                VStack(spacing: 16) {
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .font(.system(size: 50))
                                        .foregroundColor(MeetSpotColors.pink500)
                                    
                                    Text("Select Photos")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Text("Tap to choose photos from your library")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.6))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 220)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Material.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                        )
                                )
                                .mediumShadow()
                            }
                            .padding(.horizontal, 24)
                            .opacity(animateElements ? 1 : 0)
                            .offset(y: animateElements ? 0 : 20)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: animateElements)
                        } else {
                            // Photos grid view
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                ForEach(onboardingState.vehiclePhotos.indices, id: \.self) { index in
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: onboardingState.vehiclePhotos[index])
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(height: 180)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .mediumShadow()
                                        
                                        // Delete button
                                        Button {
                                            withAnimation {
                                                onboardingState.vehiclePhotos.remove(at: index)
                                                if index < onboardingState.uploadedPhotoUrls.count {
                                                    onboardingState.uploadedPhotoUrls.remove(at: index)
                                                }
                                            }
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.title2)
                                                .foregroundColor(.white)
                                                .shadow(radius: 2)
                                        }
                                        .padding(8)
                                    }
                                    .transition(.scale.combined(with: .opacity))
                                }
                                
                                // Add more button (if less than 5 photos)
                                if onboardingState.vehiclePhotos.count < 5 {
                                    PhotosPicker(
                                        selection: $onboardingState.selectedPhotos,
                                        maxSelectionCount: 5 - onboardingState.vehiclePhotos.count,
                                        matching: .images
                                    ) {
                                        VStack {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.system(size: 40))
                                                .foregroundColor(MeetSpotColors.pink500)
                                            
                                            Text("Add More")
                                                .font(.caption)
                                                .foregroundColor(.white)
                                        }
                                        .frame(height: 180)
                                        .frame(maxWidth: .infinity)
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
                            .padding(.horizontal)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: onboardingState.vehiclePhotos.count)
                        }
                        
                        // Premium badge
                        HStack(spacing: 12) {
                            Image(systemName: "crown.fill")
                                .foregroundColor(Color.yellow)
                            
                            VStack(alignment: .leading) {
                                Text("Unlock Premium")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text("Add unlimited vehicle photos with a premium subscription")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(LinearGradient(
                                    colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .padding(.top, 16)
                        .padding(.horizontal)
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : 20)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.4), value: animateElements)
                        
                        Spacer(minLength: 60)
                    }
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
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
import SwiftUI
import PhotosUI

struct PhotosVehicleStepView: View {
    @ObservedObject var onboardingState: VehicleOnboardingState
    @State private var animateElements = false
    
    var body: some View {
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
                        .foregroundColor(.white)
                        .opacity(animateElements ? 1 : 0)
                        .rotationEffect(.degrees(animateElements ? 0 : -30))
                        .offset(y: animateElements ? 0 : -10)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: animateElements)
                }
                .padding(.top, 20)
                
                // Photos selection container
                VStack(spacing: 16) {
                    // Photo picker or grid
                    if onboardingState.vehiclePhotos.isEmpty {
                        // Empty state with photo picker
                        PhotosPicker(selection: $onboardingState.selectedPhotos, maxSelectionCount: 5, matching: .images) {
                            VStack(spacing: 16) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                                
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
                            .background(.ultraThinMaterial)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
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
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                    
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
                                PhotosPicker(selection: $onboardingState.selectedPhotos, maxSelectionCount: 5 - onboardingState.vehiclePhotos.count, matching: .images) {
                                    VStack {
                                        Image(systemName: "plus.circle")
                                            .font(.system(size: 30))
                                            .foregroundColor(.white)
                                        
                                        Text("Add More")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 180)
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .animation(.spring(), value: onboardingState.vehiclePhotos.count)
                    }
                    
                    // Photo guidelines
                    VStack(spacing: 12) {
                        Text("Photo Guidelines")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            bulletPoint("Clear, well-lit photos work best")
                            bulletPoint("Include multiple angles of your vehicle")
                            bulletPoint("Show off any modifications you've made")
                            bulletPoint("Maximum 5 photos allowed")
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                    .opacity(animateElements ? 1 : 0)
                    .offset(y: animateElements ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: animateElements)
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
    
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.subheadline)
                .foregroundColor(.white)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
} 
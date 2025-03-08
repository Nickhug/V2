import SwiftUI

struct WelcomeStepView: View {
    @ObservedObject var onboardingState: CreateMeetOnboardingState
    @State private var animateElements = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header image - reduced height
                ZStack {
                    // Image with blur effect
                    Image("car_meet_hero") // Assuming you have this image in assets
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: geometry.size.height * 0.35) // Reduced from 0.4
                        .clipped()
                        .overlay(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(0.3),
                                    Color.black.opacity(0.6)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    // Floating car icons with animations
                    ZStack {
                        Image(systemName: "car.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.8))
                            .offset(x: animateElements ? 120 : -120, y: animateElements ? -40 : 40)
                            .rotationEffect(.degrees(animateElements ? 10 : -10))
                        
                        Image(systemName: "bicycle")
                            .font(.system(size: 30))
                            .foregroundColor(.white.opacity(0.8))
                            .offset(x: animateElements ? -100 : 100, y: animateElements ? -60 : 60)
                            .rotationEffect(.degrees(animateElements ? -15 : 15))
                        
                        Image(systemName: "figure.wave")
                            .font(.system(size: 35))
                            .foregroundColor(.white.opacity(0.8))
                            .offset(x: animateElements ? 60 : -60, y: animateElements ? 70 : -70)
                    }
                    .animation(
                        Animation.easeInOut(duration: 5)
                            .repeatForever(autoreverses: true),
                        value: animateElements
                    )
                }
                .frame(height: geometry.size.height * 0.35) // Reduced from 0.4
                
                // Content - remove ScrollView to prevent scrolling
                VStack(alignment: .leading, spacing: 16) { // Reduced spacing from 24
                    // Title and subtitle in a more compact layout
                    VStack(alignment: .leading, spacing: 8) { // Reduced spacing
                        // Title
                        Text("Create an Amazing Meet")
                            .font(.system(size: 28, weight: .bold)) // Reduced font size
                            .foregroundColor(.white)
                            .padding(.top, 20) // Reduced top padding
                            .opacity(animateElements ? 1 : 0)
                            .offset(y: animateElements ? 0 : 20)
                            .animation(
                                Animation.spring(response: 0.5, dampingFraction: 0.8)
                                    .delay(0.1),
                                value: animateElements
                            )
                        
                        // Subtitle
                        Text("Connect with others, share experiences, and make memories on the road.")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.8))
                            .opacity(animateElements ? 1 : 0)
                            .offset(y: animateElements ? 0 : 20)
                            .animation(
                                Animation.spring(response: 0.5, dampingFraction: 0.8)
                                    .delay(0.2),
                                value: animateElements
                            )
                    }
                    
                    // Feature cards - more compact
                    VStack(spacing: 12) { // Reduced spacing from 16
                        // Create feature card for location
                        FeatureCard(
                            icon: "map.fill",
                            title: "Choose a Location",
                            description: "Select the perfect spot for your meetup",
                            delay: 0.3
                        )
                        
                        // Create feature card for details
                        FeatureCard(
                            icon: "car.fill",
                            title: "Vehicle Details",
                            description: "Set the type of vehicles and capacity",
                            delay: 0.4
                        )
                        
                        // Create feature card for route
                        FeatureCard(
                            icon: "road.lanes",
                            title: "Add a Route",
                            description: "Define a driving route for your meetup",
                            delay: 0.5
                        )
                    }
                    .opacity(animateElements ? 1 : 0)
                    .offset(y: animateElements ? 0 : 30)
                    .animation(
                        Animation.spring(response: 0.5, dampingFraction: 0.8),
                        value: animateElements
                    )
                    
                    Spacer() // Add flexible space
                    
                    // Start button
                    Button(action: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            onboardingState.moveToNextStep()
                        }
                    }) {
                        HStack {
                            Text("Let's Get Started")
                                .font(.headline)
                            
                            Image(systemName: "arrow.right")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [MeetSpotColors.pink500, MeetSpotColors.purple900]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .pronouncedShadow()
                    }
                    .padding(.bottom, 20) // Add bottom padding
                    .opacity(animateElements ? 1 : 0)
                    .offset(y: animateElements ? 0 : 30)
                    .animation(
                        Animation.spring(response: 0.5, dampingFraction: 0.8)
                            .delay(0.6),
                        value: animateElements
                    )
                }
                .padding(.horizontal, 24)
                .frame(maxHeight: .infinity) // Take all available space
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Material.ultraThinMaterial)
                        .backgroundStyle(MeetSpotColors.backgroundGradient)
                )
                .cornerRadius(30, corners: [.topLeft, .topRight])
                .offset(y: -30)
            }
        }
        .ignoresSafeArea(edges: .all)
        .onAppear {
            // Start the animations when the view appears
            withAnimation {
                animateElements = true
            }
        }
    }
}

// Make FeatureCard more compact
private struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let delay: Double
    
    @State private var animate = false
    
    var body: some View {
        HStack(spacing: 12) { // Reduced spacing
            // Icon
            ZStack {
                Circle()
                    .fill(MeetSpotColors.pink500.opacity(0.2))
                    .frame(width: 50, height: 50) // Reduced size from 56
                
                Image(systemName: icon)
                    .font(.system(size: 22)) // Reduced size from 24
                    .foregroundColor(MeetSpotColors.pink500)
            }
            .scaleEffect(animate ? 1.0 : 0.8)
            .opacity(animate ? 1.0 : 0.6)
            .animation(
                Animation.spring(response: 0.5, dampingFraction: 0.6)
                    .delay(delay),
                value: animate
            )
            
            // Text content
            VStack(alignment: .leading, spacing: 2) { // Reduced spacing
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
            }
        }
        .padding(12) // Reduced padding from 16
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Material.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(MeetSpotColors.pink500.opacity(0.3), lineWidth: 1)
                )
        )
        .mediumShadow()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    animate = true
                }
            }
        }
    }
}

// Preview
struct WelcomeStepView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeStepView(onboardingState: CreateMeetOnboardingState())
            .preferredColorScheme(.dark)
    }
} 
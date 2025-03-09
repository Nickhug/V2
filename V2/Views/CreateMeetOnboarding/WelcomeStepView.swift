import SwiftUI

struct WelcomeStepView: View {
    @ObservedObject var onboardingState: CreateMeetOnboardingState
    @State private var animateElements = false
    
    var body: some View {
        ScrollView {
            // Main content
            VStack(spacing: 40) {
                // Animated welcome icon
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.15),
                                    Color.white.opacity(0.0)
                                ]),
                                center: .center,
                                startRadius: 50,
                                endRadius: 120
                            )
                        )
                        .scaleEffect(animateElements ? 1 : 0.8)
                        .opacity(animateElements ? 0.6 : 0)
                    
                    // Icon
                    Image(systemName: "flag.checkered")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .foregroundColor(.white)
                        .shadow(color: Color.white.opacity(0.5), radius: 15, x: 0, y: 0)
                        .scaleEffect(animateElements ? 1 : 0.5)
                        .opacity(animateElements ? 1 : 0)
                }
                .frame(width: 180, height: 180)
                .padding(.vertical, 40)
                
                // Title and description
                VStack(spacing: 16) {
                    Text("Create an Amazing Meet")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .offset(y: animateElements ? 0 : 20)
                        .opacity(animateElements ? 1 : 0)
                    
                    Text("Connect with others, share experiences, and make memories on the road.")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .offset(y: animateElements ? 0 : 20)
                        .opacity(animateElements ? 1 : 0)
                }
                
                // Features grid
                VStack(spacing: 16) {
                    // Create feature card for location
                    FeatureCard(
                        icon: "map.fill",
                        title: "Choose a Location",
                        description: "Select the perfect spot for your meetup",
                        animateElements: animateElements,
                        delay: 0.3
                    )
                    
                    // Create feature card for details
                    FeatureCard(
                        icon: "car.fill",
                        title: "Vehicle Details",
                        description: "Set the type of vehicles and capacity",
                        animateElements: animateElements,
                        delay: 0.4
                    )
                    
                    // Create feature card for route
                    FeatureCard(
                        icon: "road.lanes",
                        title: "Add a Route",
                        description: "Define a driving route for your meetup",
                        animateElements: animateElements,
                        delay: 0.5
                    )
                }
                .padding(.horizontal, 24)
                
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
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.black, lineWidth: 1.5)
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
                    .offset(y: animateElements ? 0 : 20)
                    .opacity(animateElements ? 1 : 0)
                }
                .padding(.horizontal, 32)
                .padding(.top, 24)
            }
            .padding(.bottom, 100)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
                animateElements = true
            }
        }
    }
}

// Make FeatureCard more consistent with design
private struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let animateElements: Bool
    let delay: Double
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
            
            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .opacity(animateElements ? 1 : 0)
        .offset(y: animateElements ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(delay), value: animateElements)
    }
}

// Preview
struct WelcomeStepView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black // Simulating the background
            WelcomeStepView(onboardingState: CreateMeetOnboardingState())
        }
    }
} 
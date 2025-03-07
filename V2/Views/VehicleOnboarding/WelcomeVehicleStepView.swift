import SwiftUI

struct WelcomeVehicleStepView: View {
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
            VStack(spacing: 40) {
                // Animated welcome car icon
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    MeetSpotColors.pink500.opacity(0.7),
                                    MeetSpotColors.pink500.opacity(0.0)
                                ]),
                                center: .center,
                                startRadius: 50,
                                endRadius: 120
                            )
                        )
                        .scaleEffect(animateElements ? 1 : 0.8)
                        .opacity(animateElements ? 0.6 : 0)
                    
                    // Car icon
                    Image(systemName: "car.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .foregroundColor(.white)
                        .shadow(color: MeetSpotColors.pink500.opacity(0.5), radius: 15, x: 0, y: 0)
                        .scaleEffect(animateElements ? 1 : 0.5)
                        .opacity(animateElements ? 1 : 0)
                }
                .frame(width: 180, height: 180)
                .padding(.vertical, 40)
                
                // Title and description
                VStack(spacing: 16) {
                    Text("Add Your Vehicle")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .offset(y: animateElements ? 0 : 20)
                        .opacity(animateElements ? 1 : 0)
                    
                    Text("Tell us about your ride so others can see what you're driving")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .offset(y: animateElements ? 0 : 20)
                        .opacity(animateElements ? 1 : 0)
                }
                
                // Start button
                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        onboardingState.moveToNextStep()
                    }
                }) {
                    HStack {
                        Text("Get Started")
                            .font(.headline)
                        
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [MeetSpotColors.pink500, MeetSpotColors.purple900]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: MeetSpotColors.pink500.opacity(0.5), radius: 15, x: 0, y: 8)
                    .offset(y: animateElements ? 0 : 20)
                    .opacity(animateElements ? 1 : 0)
                }
                .padding(.horizontal, 32)
                .padding(.top, 24)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
                animateElements = true
            }
        }
    }
} 
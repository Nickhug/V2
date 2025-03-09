import SwiftUI

struct WelcomeVehicleStepView: View {
    @ObservedObject var onboardingState: VehicleOnboardingState
    @State private var animateElements = false
    
    var body: some View {
        ScrollView {
            // Main content
            VStack(spacing: 40) {
                // Animated welcome car icon
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
                    
                    // Car icon
                    Image(systemName: "car.fill")
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
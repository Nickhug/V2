import SwiftUI
import MapKit
import Foundation

struct BasicsStepView: View {
    @ObservedObject var onboardingState: CreateMeetOnboardingState
    @State private var animateElements = false
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case title, description
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Basic Information")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Let's start with the essential details")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Image(systemName: CreateMeetStep.basics.systemIcon)
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                        .opacity(animateElements ? 1 : 0)
                        .rotationEffect(.degrees(animateElements ? 0 : -30))
                        .offset(y: animateElements ? 0 : -10)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: animateElements)
                }
                .padding(.top, 20)
                
                // Form fields container
                VStack(spacing: 20) {
                    // Title field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Meet Title")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        GlassmorphicComponents.TextField(
                            text: $onboardingState.title,
                            placeholder: "Enter a catchy title",
                            icon: "textformat.alt",
                            isFocused: focusedField == .title
                        )
                        .focused($focusedField, equals: .title)
                    }
                    .offset(x: animateElements ? 0 : -50)
                    .opacity(animateElements ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: animateElements)
                    
                    // Description field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        GlassmorphicComponents.TextEditor(
                            text: $onboardingState.description,
                            placeholder: "Describe your meet...",
                            icon: "text.quote",
                            isFocused: focusedField == .description
                        )
                        .focused($focusedField, equals: .description)
                        .frame(height: 120)
                    }
                    .offset(x: animateElements ? 0 : -50)
                    .opacity(animateElements ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: animateElements)
                    
                    // Date picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date & Time")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        GlassmorphicComponents.DatePicker(
                            date: $onboardingState.date,
                            icon: "calendar"
                        )
                    }
                    .offset(x: animateElements ? 0 : -50)
                    .opacity(animateElements ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3), value: animateElements)
                    
                    // Meet type selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Meet Type")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 12) {
                            ForEach(V2MeetType.allCases, id: \.self) { type in
                                MeetTypeButton(
                                    type: type,
                                    isSelected: onboardingState.meetType == type,
                                    action: {
                                        withAnimation(.spring()) {
                                            onboardingState.meetType = type
                                        }
                                    }
                                )
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .offset(x: animateElements ? 0 : -50)
                    .opacity(animateElements ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.4), value: animateElements)
                    
                    // Capacity selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Capacity")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        CapacitySelector(capacity: $onboardingState.capacity)
                    }
                    .offset(x: animateElements ? 0 : -50)
                    .opacity(animateElements ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.5), value: animateElements)
                }
                .padding(.vertical, 20)
                .padding(.horizontal)
            }
            .padding(.horizontal)
            .padding(.bottom, 100)
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
                animateElements = true
            }
        }
        .onTapGesture {
            focusedField = nil
        }
    }
}

// Capacity selector with +/- buttons
struct CapacitySelector: View {
    @Binding var capacity: Int
    
    var body: some View {
        HStack {
            Image(systemName: "person.3.fill")
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
            
            Spacer()
            
            // Minus button
            Button(action: {
                if capacity > 10 {
                    capacity -= 10
                    hapticsLight()
                }
            }) {
                Image(systemName: "minus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            // Capacity display
            Text("\(capacity)")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 60)
                .animation(.spring(), value: capacity)
            
            // Plus button
            Button(action: {
                if capacity < 1000 {
                    capacity += 10
                    hapticsLight()
                }
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
    
    // Light haptic feedback
    func hapticsLight() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// Preview
struct BasicsStepView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black // Simulating the background
            BasicsStepView(onboardingState: CreateMeetOnboardingState())
        }
    }
} 
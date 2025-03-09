import SwiftUI
import PhotosUI

// Move FocusField enum outside of OnboardingView struct so it's accessible to all views in the file
enum FocusField {
    case name, bio, location, instagram, twitter, facebook
}

struct OnboardingView: View {
    @ObservedObject var viewModel: AuthViewModel
    @FocusState private var focusedField: FocusField?
    @State private var animateElements = false
    
    var body: some View {
        ZStack {
            // Background
            AnimatedGradientBackground()
            
            // Content
            VStack(spacing: 20) {
                // Progress and Step indicator
                progressHeader
                
                // Current step view
                TabView(selection: $viewModel.onboardingState.currentStep) {
                    WelcomeOnboardingStep(viewModel: viewModel, animateElements: $animateElements)
                        .tag(OnboardingStep.welcome)
                    
                    AboutOnboardingStep(viewModel: viewModel, focusedField: $focusedField, animateElements: $animateElements)
                        .tag(OnboardingStep.about)
                    
                    PreferencesOnboardingStep(viewModel: viewModel, animateElements: $animateElements)
                        .tag(OnboardingStep.preferences)
                    
                    CompleteOnboardingStep(viewModel: viewModel, animateElements: $animateElements)
                        .tag(OnboardingStep.complete)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: viewModel.onboardingState.currentStep)
                
                // Navigation buttons
                navigationButtons
            }
        }
        .alert(isPresented: $viewModel.onboardingState.showError) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.onboardingState.errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                animateElements = true
            }
        }
        .onChange(of: viewModel.onboardingState.currentStep) { _, _ in
            animateElements = false
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                animateElements = true
            }
        }
        .onChange(of: viewModel.selectedImage) { _, newValue in
            if newValue != nil {
                Task {
                    await viewModel.handlePhotoSelection()
                }
            }
        }
    }
    
    // Progress header view
    private var progressHeader: some View {
        VStack(spacing: 8) {
            // Progress circles
            HStack(spacing: 8) {
                ForEach(OnboardingStep.allCases) { step in
                    Circle()
                        .fill(step.rawValue <= viewModel.onboardingState.currentStep.rawValue ? MeetSpotColors.pink500 : Color.white.opacity(0.2))
                        .frame(width: 10, height: 10)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .scaleEffect(step == viewModel.onboardingState.currentStep ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.onboardingState.currentStep)
                }
            }
            
            // Step title
            Text(viewModel.onboardingState.currentStep.title)
                .font(.headline)
                .foregroundColor(.white)
                .animation(.easeInOut, value: viewModel.onboardingState.currentStep)
                .id(viewModel.onboardingState.currentStep.title) // Force redraw on change
                .transition(.opacity)
        }
        .padding(.top, 20)
    }
    
    // Navigation buttons
    private var navigationButtons: some View {
        HStack(spacing: 20) {
            if viewModel.onboardingState.currentStep != .welcome {
                Button(action: {
                    withAnimation {
                        viewModel.onboardingState.moveToPreviousStep()
                    }
                }) {
                    Text("Back")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white)
                        .frame(width: 100)
                        .padding(.vertical, 16)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                }
            }
            
            Button(action: {
                if viewModel.onboardingState.isLastStep {
                    Task {
                        await viewModel.completeOnboarding()
                    }
                } else {
                    withAnimation {
                        viewModel.onboardingState.moveToNextStep()
                    }
                }
            }) {
                HStack {
                    if viewModel.onboardingState.isLoading {
                        // Simple Circle-based spinner animation
                        Circle()
                            .trim(from: 0, to: 0.7)
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 20, height: 20)
                            .rotationEffect(Angle(degrees: 270))
                            .rotationEffect(Angle(degrees: viewModel.onboardingState.isLoading ? 360 : 0))
                            .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false), value: viewModel.onboardingState.isLoading)
                            .padding(.trailing, 8)
                    }
                    
                    Text(viewModel.onboardingState.isLastStep ? "Complete" : "Next")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: viewModel.onboardingState.currentStep == .welcome ? .infinity : .none)
                .frame(minWidth: 100)
                .padding(.vertical, 16)
                .padding(.horizontal, 24)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [MeetSpotColors.pink500, MeetSpotColors.purple900]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: MeetSpotColors.pink500.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .disabled(!viewModel.onboardingState.canContinue || viewModel.onboardingState.isLoading)
            .opacity((!viewModel.onboardingState.canContinue || viewModel.onboardingState.isLoading) ? 0.7 : 1)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }
}

// MARK: - Onboarding Step Views

struct WelcomeOnboardingStep: View {
    @ObservedObject var viewModel: AuthViewModel
    @Binding var animateElements: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Welcome animation
                VStack(spacing: 24) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(MeetSpotColors.pink500)
                        .opacity(animateElements ? 1 : 0)
                        .scaleEffect(animateElements ? 1 : 0.7)
                        .padding(.bottom, 8)
                    
                    Text("Welcome to MeetSpot")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : 20)
                    
                    Text("Let's set up your profile to help you connect with other automotive enthusiasts.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : 20)
                }
                .padding(.top, 40)
                
                // Feature highlights
                VStack(spacing: 16) {
                    FeatureCard(
                        icon: "person.fill",
                        title: "Create Your Profile",
                        description: "Let others know who you are and what you're about.",
                        delay: 0.0
                    )
                    .opacity(animateElements ? 1 : 0)
                    .offset(y: animateElements ? 0 : 20)
                    
                    FeatureCard(
                        icon: "gearshape.fill",
                        title: "Set Preferences",
                        description: "Customize your experience to match your interests.",
                        delay: 0.1
                    )
                    .opacity(animateElements ? 1 : 0)
                    .offset(y: animateElements ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animateElements)
                    
                    FeatureCard(
                        icon: "car.fill",
                        title: "Add Vehicles",
                        description: "Showcase your rides and connect with similar enthusiasts.",
                        delay: 0.2
                    )
                    .opacity(animateElements ? 1 : 0)
                    .offset(y: animateElements ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateElements)
                }
                .padding(.horizontal, 24)
                
                Spacer(minLength: 100)
            }
        }
    }
}

struct AboutOnboardingStep: View {
    @ObservedObject var viewModel: AuthViewModel
    var focusedField: FocusState<FocusField?>.Binding
    @Binding var animateElements: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile image picker
                VStack(spacing: 16) {
                    Text("Profile Picture")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                        .opacity(animateElements ? 1 : 0)
                    
                    PhotoPickerView(viewModel: viewModel)
                        .opacity(animateElements ? 1 : 0)
                        .scaleEffect(animateElements ? 1 : 0.8)
                }
                .padding(.top, 20)
                
                // Profile info
                VStack(spacing: 20) {
                    // Bio field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bio")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.leading, 4)
                            .opacity(animateElements ? 1 : 0)
                        
                        HStack(alignment: .top) {
                            Image(systemName: "text.quote")
                                .foregroundColor(focusedField.wrappedValue == .bio ? MeetSpotColors.pink500 : .white.opacity(0.5))
                                .font(.system(size: 20))
                                .frame(width: 36)
                                .padding(.top, 16)
                            
                            ZStack(alignment: .topLeading) {
                                if viewModel.onboardingState.bio.isEmpty {
                                    Text("Tell us about yourself...")
                                        .foregroundColor(.white.opacity(0.3))
                                        .padding(.top, 18)
                                        .padding(.leading, 3)
                                }
                                
                                TextEditor(text: $viewModel.onboardingState.bio)
                                    .foregroundColor(.white)
                                    .focused(focusedField, equals: .bio)
                                    .frame(minHeight: 120)
                                    .scrollContentBackground(.hidden)
                                    .background(.clear)
                                    .padding(.vertical, 8)
                            }
                        }
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Material.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    focusedField.wrappedValue == .bio ? MeetSpotColors.pink500 : Color.white.opacity(0.1),
                                    lineWidth: focusedField.wrappedValue == .bio ? 1.5 : 1
                                )
                        )
                        .frame(height: 120)
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : 20)
                    }
                    
                    // Location field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.leading, 4)
                            .opacity(animateElements ? 1 : 0)
                        
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(focusedField.wrappedValue == .location ? MeetSpotColors.pink500 : .white.opacity(0.5))
                                .font(.system(size: 20))
                                .frame(width: 36)
                            
                            TextField("", text: $viewModel.onboardingState.location)
                                .viewPlaceholder(when: viewModel.onboardingState.location.isEmpty) {
                                    Text("City, State").foregroundColor(.white.opacity(0.3))
                                }
                                .focused(focusedField, equals: .location)
                                .foregroundColor(.white)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Material.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    focusedField.wrappedValue == .location ? MeetSpotColors.pink500 : Color.white.opacity(0.1),
                                    lineWidth: focusedField.wrappedValue == .location ? 1.5 : 1
                                )
                        )
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : 20)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animateElements)
                    }
                }
                .padding(.horizontal, 24)
                
                // Social links section
                VStack(spacing: 20) {
                    Text("Social Links (Optional)")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : 10)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateElements)
                    
                    // Instagram
                    SocialLinkField(
                        icon: "camera.circle.fill",
                        iconColor: Color(red: 0.8, green: 0.2, blue: 0.5),
                        platform: "Instagram",
                        text: $viewModel.onboardingState.instagram,
                        focusedField: focusedField,
                        currentField: .instagram,
                        animateElements: $animateElements,
                        animationDelay: 0.3
                    )
                    
                    // Twitter
                    SocialLinkField(
                        icon: "bird.circle.fill",
                        iconColor: Color.blue,
                        platform: "Twitter/X",
                        text: $viewModel.onboardingState.twitter,
                        focusedField: focusedField,
                        currentField: .twitter,
                        animateElements: $animateElements,
                        animationDelay: 0.4
                    )
                    
                    // Facebook
                    SocialLinkField(
                        icon: "person.2.circle.fill",
                        iconColor: Color.blue,
                        platform: "Facebook",
                        text: $viewModel.onboardingState.facebook,
                        focusedField: focusedField,
                        currentField: .facebook,
                        animateElements: $animateElements,
                        animationDelay: 0.5
                    )
                }
                .padding(.horizontal, 24)
                
                Spacer(minLength: 100)
            }
            .padding(.top, 20)
        }
    }
}

struct PreferencesOnboardingStep: View {
    @ObservedObject var viewModel: AuthViewModel
    @Binding var animateElements: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Preferences header
                VStack(spacing: 8) {
                    Text("Personalize Your Experience")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .opacity(animateElements ? 1 : 0)
                    
                    Text("Set your preferences to enhance your MeetSpot experience.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : 10)
                }
                .padding(.top, 20)
                
                // Notifications
                PreferenceToggle(
                    icon: "bell.fill",
                    iconColor: .black,
                    title: "Notifications",
                    description: "Receive alerts about meets, invites, and messages",
                    isOn: $viewModel.onboardingState.preferences.notificationsEnabled,
                    animateElements: $animateElements,
                    animationDelay: 0.1
                )
                
                // Location sharing
                PreferenceToggle(
                    icon: "location.circle.fill",
                    iconColor: .black,
                    title: "Location Sharing",
                    description: "Allow location sharing for meets and nearby events",
                    isOn: $viewModel.onboardingState.preferences.locationSharingEnabled,
                    animateElements: $animateElements,
                    animationDelay: 0.2
                )
                
                // Dark mode
                PreferenceToggle(
                    icon: "moon.stars.fill",
                    iconColor: MeetSpotColors.purple200,
                    title: "Dark Mode",
                    description: "Enable dark mode for a more comfortable experience",
                    isOn: $viewModel.onboardingState.preferences.darkModeEnabled,
                    animateElements: $animateElements,
                    animationDelay: 0.3
                )
                
                // Vehicle interests
                VStack(alignment: .leading, spacing: 16) {
                    Text("Vehicle Interests")
                        .font(.headline)
                        .foregroundColor(.white)
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : 10)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: animateElements)
                    
                    VehicleInterestSelector(
                        selectedTypes: $viewModel.onboardingState.preferences.vehicleInterests,
                        animateElements: $animateElements
                    )
                    .opacity(animateElements ? 1 : 0)
                    .offset(y: animateElements ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: animateElements)
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                
                // Route preferences
                VStack(alignment: .leading, spacing: 16) {
                    Text("Route Preferences")
                        .font(.headline)
                        .foregroundColor(.white)
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : 10)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6), value: animateElements)
                    
                    RoutePreferenceSelector(
                        selectedTypes: $viewModel.onboardingState.preferences.routePreferences,
                        animateElements: $animateElements
                    )
                    .opacity(animateElements ? 1 : 0)
                    .offset(y: animateElements ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.7), value: animateElements)
                }
                .padding(.horizontal, 24)
                
                Spacer(minLength: 100)
            }
        }
    }
}

struct CompleteOnboardingStep: View {
    @ObservedObject var viewModel: AuthViewModel
    @Binding var animateElements: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Success animation
                VStack(spacing: 24) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(MeetSpotColors.pink500)
                        .opacity(animateElements ? 1 : 0)
                        .scaleEffect(animateElements ? 1 : 0.6)
                    
                    VStack(spacing: 16) {
                        Text("You're All Set!")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .opacity(animateElements ? 1 : 0)
                            .offset(y: animateElements ? 0 : 20)
                        
                        Text("Your profile is ready. Start exploring the automotive community.")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .opacity(animateElements ? 1 : 0)
                            .offset(y: animateElements ? 0 : 20)
                    }
                }
                .padding(.top, 40)
                
                // Next steps
                VStack(spacing: 24) {
                    SummaryCard(
                        icon: "car.fill",
                        title: "Add Your Vehicles",
                        description: "Share your rides with the community",
                        animateElements: $animateElements,
                        animationDelay: 0.2
                    )
                    
                    SummaryCard(
                        icon: "map.fill",
                        title: "Discover Meets",
                        description: "Find automotive gatherings near you",
                        animateElements: $animateElements,
                        animationDelay: 0.3
                    )
                    
                    SummaryCard(
                        icon: "person.2.fill",
                        title: "Connect with Others",
                        description: "Build your network of enthusiasts",
                        animateElements: $animateElements,
                        animationDelay: 0.4
                    )
                }
                .padding(.horizontal, 24)
                
                Spacer(minLength: 100)
            }
        }
    }
}

// MARK: - Supporting Views

struct PhotoPickerView: View {
    @ObservedObject var viewModel: AuthViewModel
    @State private var avatarImage: UIImage?
    
    var body: some View {
        VStack {
            PhotosPicker(selection: $viewModel.selectedImage, matching: .images) {
                if let avatar = avatarImage {
                    // Show the selected image
                    Image(uiImage: avatar)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(MeetSpotColors.pink500, lineWidth: 3)
                        )
                        .overlay(
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(MeetSpotColors.pink500)
                                .background(Circle().fill(Color.white))
                                .offset(x: 40, y: 40)
                        )
                } else {
                    // Show placeholder
                    ZStack {
                        Circle()
                            .fill(Material.ultraThinMaterial)
                            .frame(width: 120, height: 120)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            )
                        
                        Image(systemName: "person.crop.circle.fill.badge.plus")
                            .font(.system(size: 50))
                            .foregroundColor(MeetSpotColors.pink500)
                        
                        Text("Add Photo")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .offset(y: 50)
                    }
                    .frame(width: 120, height: 140)
                }
            }
            .onChange(of: viewModel.onboardingState.avatar) { _, newAvatar in
                avatarImage = newAvatar
            }
            .onAppear {
                // Initialize the local state with the current avatar
                avatarImage = viewModel.onboardingState.avatar
            }
        }
    }
}

struct SocialLinkField: View {
    let icon: String
    let iconColor: Color
    let platform: String
    @Binding var text: String
    var focusedField: FocusState<FocusField?>.Binding
    let currentField: FocusField
    @Binding var animateElements: Bool
    let animationDelay: Double
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(focusedField.wrappedValue == currentField ? iconColor : .white.opacity(0.5))
                .font(.system(size: 20))
                .frame(width: 36)
            
            TextField("", text: $text)
                .viewPlaceholder(when: text.isEmpty) {
                    Text("Your \(platform) username").foregroundColor(.white.opacity(0.3))
                }
                .focused(focusedField, equals: currentField)
                .foregroundColor(.white)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .submitLabel(.next)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Material.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    focusedField.wrappedValue == currentField ? iconColor : Color.white.opacity(0.1),
                    lineWidth: focusedField.wrappedValue == currentField ? 1.5 : 1
                )
        )
        .opacity(animateElements ? 1 : 0)
        .offset(y: animateElements ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(animationDelay), value: animateElements)
    }
}

struct PreferenceToggle: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    @Binding var isOn: Bool
    @Binding var animateElements: Bool
    let animationDelay: Double
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(iconColor)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: MeetSpotColors.pink500))
                .labelsHidden()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Material.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal, 24)
        .opacity(animateElements ? 1 : 0)
        .offset(y: animateElements ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(animationDelay), value: animateElements)
    }
}

struct VehicleInterestSelector: View {
    @Binding var selectedTypes: [VehicleType]
    @Binding var animateElements: Bool
    
    private let allTypes: [VehicleType] = VehicleType.allCases
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(allTypes, id: \.self) { type in
                VehicleTypeButton(
                    type: type,
                    isSelected: selectedTypes.contains(type),
                    action: {
                        toggleType(type)
                    }
                )
            }
        }
    }
    
    private func toggleType(_ type: VehicleType) {
        withAnimation {
            if selectedTypes.contains(type) {
                selectedTypes.removeAll { $0 == type }
                // Ensure at least one type is selected
                if selectedTypes.isEmpty {
                    selectedTypes = [type]
                }
            } else {
                selectedTypes.append(type)
            }
        }
    }
}

struct RoutePreferenceSelector: View {
    @Binding var selectedTypes: [RouteType]
    @Binding var animateElements: Bool
    
    private let allTypes: [RouteType] = RouteType.allCases
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(allTypes, id: \.self) { type in
                RouteTypeButton(
                    type: type,
                    isSelected: selectedTypes.contains(type),
                    action: {
                        toggleType(type)
                    }
                )
            }
        }
    }
    
    private func toggleType(_ type: RouteType) {
        withAnimation {
            if selectedTypes.contains(type) {
                selectedTypes.removeAll { $0 == type }
                // Ensure at least one type is selected
                if selectedTypes.isEmpty {
                    selectedTypes = [type]
                }
            } else {
                selectedTypes.append(type)
            }
        }
    }
}

struct VehicleTypeButton: View {
    let type: VehicleType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: iconForType(type))
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                
                Text(type.rawValue.capitalized)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? MeetSpotColors.pink500 : Color.white.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    private func iconForType(_ type: VehicleType) -> String {
        switch type {
        case .car: return "car.fill"
        case .bike: return "bicycle"
        case .both: return "car.and.bicycle"
        case .mixed: return "car.and.bicycle"
        }
    }
}

struct RouteTypeButton: View {
    let type: RouteType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: iconForType(type))
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                
                Text(type.rawValue.capitalized)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? MeetSpotColors.pink500 : Color.white.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    private func iconForType(_ type: RouteType) -> String {
        switch type {
        case .city: return "building.2.fill"
        case .mountain: return "mountain.2.fill"
        case .coastal: return "water.waves"
        case .scenic: return "sun.horizon.fill"
        }
    }
}

struct SummaryCard: View {
    let icon: String
    let title: String
    let description: String
    @Binding var animateElements: Bool
    let animationDelay: Double
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(MeetSpotColors.pink500)
                .frame(width: 60, height: 60)
                .background(Material.ultraThinMaterial)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: MeetSpotColors.pink500.opacity(0.3), radius: 8, x: 0, y: 4)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.5))
                .font(.system(size: 14, weight: .bold))
        }
        .padding(16)
        .background(Material.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .opacity(animateElements ? 1 : 0)
        .offset(y: animateElements ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(animationDelay), value: animateElements)
    }
}

// MARK: - Supporting Components

// Glass-style feature card component
private struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let delay: Double
    
    init(icon: String, title: String, description: String, delay: Double = 0.0) {
        self.icon = icon
        self.title = title
        self.description = description
        self.delay = delay
    }
    
    var body: some View {
        HStack(spacing: 20) {
            // Animated icon
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [MeetSpotColors.pink500, MeetSpotColors.purple900]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: MeetSpotColors.pink500.opacity(0.3), radius: 8, x: 0, y: 4)
            
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
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .white.opacity(0.5),
                            .clear,
                            .clear,
                            .white.opacity(0.2)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 10)
    }
}

#Preview {
    OnboardingView(viewModel: AuthViewModel())
} 
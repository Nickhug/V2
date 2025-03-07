import SwiftUI
import MapKit

struct PreviewStepView: View {
    @ObservedObject var onboardingState: CreateMeetOnboardingState
    @State private var animateElements = false
    
    var body: some View {
        ZStack {
            // Background decoration
            Circle()
                .fill(MeetSpotColors.pink500.opacity(0.1))
                .frame(width: 280, height: 280)
                .blur(radius: 70)
                .offset(x: 150, y: -150)
            
            Circle()
                .fill(MeetSpotColors.purple900.opacity(0.1))
                .frame(width: 280, height: 280)
                .blur(radius: 70)
                .offset(x: -150, y: 200)
                
            // Main content
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Ready to Create")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Review your meet details")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        Image(systemName: CreateMeetStep.preview.systemIcon)
                            .font(.system(size: 40))
                            .foregroundColor(MeetSpotColors.pink500)
                            .opacity(animateElements ? 1 : 0)
                            .rotationEffect(.degrees(animateElements ? 0 : -30))
                            .offset(y: animateElements ? 0 : -10)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: animateElements)
                    }
                    .padding(.top)
                    
                    // Cover image
                    if let image = onboardingState.selectedImage {
                        ZStack(alignment: .bottomLeading) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.black.opacity(0.7),
                                            Color.black.opacity(0.3),
                                            Color.black.opacity(0)
                                        ]),
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                            
                            // Title overlay
                            Text(onboardingState.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding()
                                .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 2)
                        }
                        .mediumShadow()
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : 20)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.8).delay(0.1),
                            value: animateElements
                        )
                    }
                    
                    // Info section
                    VStack(spacing: 16) {
                        // Basic details section
                        SectionCard(title: "Basic Details") {
                            // Meet type
                            InfoRow(
                                icon: onboardingState.meetType.iconName,
                                iconColor: onboardingState.meetType.color,
                                title: "Meet Type",
                                value: onboardingState.meetType.displayName
                            )
                            
                            // Date
                            InfoRow(
                                icon: "calendar",
                                iconColor: .blue,
                                title: "Date & Time",
                                value: onboardingState.date.formatted(date: .long, time: .shortened)
                            )
                            
                            // Capacity
                            InfoRow(
                                icon: "person.3",
                                iconColor: .green,
                                title: "Capacity",
                                value: "\(onboardingState.capacity) people"
                            )
                            
                            // Description snippet
                            InfoRow(
                                icon: "text.alignleft",
                                iconColor: .purple,
                                title: "Description",
                                value: onboardingState.description.count > 50 ?
                                    onboardingState.description.prefix(50) + "..." :
                                    onboardingState.description
                            )
                        }
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : 20)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.8).delay(0.2),
                            value: animateElements
                        )
                        
                        // Location section
                        SectionCard(title: "Location") {
                            if let location = onboardingState.selectedLocation {
                                // Map preview
                                MapPreview(coordinate: location)
                                    .frame(height: 120)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .padding(.top, 4)
                                
                                // Address
                                InfoRow(
                                    icon: "mappin.circle.fill",
                                    iconColor: MeetSpotColors.pink500,
                                    title: "Address",
                                    value: onboardingState.address
                                )
                            }
                        }
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : 20)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.8).delay(0.3),
                            value: animateElements
                        )
                        
                        // Vehicle and route section
                        SectionCard(title: "Vehicle & Route") {
                            // Vehicle type
                            InfoRow(
                                icon: vehicleIcon(for: onboardingState.vehicleType),
                                iconColor: .orange,
                                title: "Vehicle Type",
                                value: onboardingState.vehicleType.rawValue.capitalized
                            )
                            
                            // Route type
                            InfoRow(
                                icon: routeIcon(for: onboardingState.routeType),
                                iconColor: .blue,
                                title: "Route Type",
                                value: onboardingState.routeType.rawValue.capitalized
                            )
                            
                            // Selected route if any
                            if let route = onboardingState.selectedRoute {
                                InfoRow(
                                    icon: "map.fill",
                                    iconColor: MeetSpotColors.pink500,
                                    title: "Route",
                                    value: route.title
                                )
                                
                                if let distance = route.formattedDistance {
                                    InfoRow(
                                        icon: "arrow.triangle.swap",
                                        iconColor: .green,
                                        title: "Distance",
                                        value: distance
                                    )
                                }
                                
                                InfoRow(
                                    icon: "clock.fill",
                                    iconColor: .blue,
                                    title: "Duration",
                                    value: "\(route.estimatedTime) minutes"
                                )
                            } else {
                                Text("No route selected")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.top, 4)
                            }
                        }
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : 20)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.8).delay(0.4),
                            value: animateElements
                        )
                        
                        // Rules section
                        if onboardingState.rules.contains(where: { !$0.isEmpty }) {
                            SectionCard(title: "Rules") {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(onboardingState.rules.filter({ !$0.isEmpty }), id: \.self) { rule in
                                        HStack(alignment: .top, spacing: 8) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(MeetSpotColors.pink500)
                                                .font(.system(size: 16))
                                            
                                            Text(rule)
                                                .font(.subheadline)
                                                .foregroundColor(.white)
                                                .multilineTextAlignment(.leading)
                                        }
                                    }
                                }
                            }
                            .opacity(animateElements ? 1 : 0)
                            .offset(y: animateElements ? 0 : 20)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.8).delay(0.5),
                                value: animateElements
                            )
                        }
                        
                        // Tags section
                        if onboardingState.tags.contains(where: { !$0.isEmpty }) {
                            SectionCard(title: "Tags") {
                                FlowLayout(
                                    items: onboardingState.tags.filter({ !$0.isEmpty }),
                                    itemSpacing: 8,
                                    lineSpacing: 8
                                ) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(
                                            Capsule()
                                                .fill(MeetSpotColors.pink500.opacity(0.2))
                                                .overlay(
                                                    Capsule()
                                                        .stroke(MeetSpotColors.pink500.opacity(0.5), lineWidth: 1)
                                                )
                                        )
                                }
                            }
                            .opacity(animateElements ? 1 : 0)
                            .offset(y: animateElements ? 0 : 20)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.8).delay(0.6),
                                value: animateElements
                            )
                        }
                    }
                    
                    Spacer(minLength: 70)
                }
                .padding(.horizontal)
            }
        }
        .onAppear {
            withAnimation {
                animateElements = true
            }
        }
    }
    
    // Helper functions for icons
    private func vehicleIcon(for type: VehicleType) -> String {
        switch type {
        case .car: return "car.fill"
        case .bike: return "bicycle"
        case .both: return "car.fill" // Fallback to car icon for "both" type
        }
    }
    
    private func routeIcon(for type: RouteType) -> String {
        switch type {
        case .city: return "building.2.fill"
        case .mountain: return "mountain.2.fill"
        case .coastal: return "water.waves"
        case .scenic: return "binoculars.fill"
        }
    }
}

// Section card component
struct SectionCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section title
            Text(title)
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
            
            // Content
            content
                .padding(.leading, 4)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
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
}

// Info row component
struct InfoRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.system(size: 16))
                .frame(width: 20, height: 20)
            
            // Title and value
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// Map preview component
struct MapPreview: View {
    let coordinate: CLLocationCoordinate2D
    
    var body: some View {
        Map(position: .constant(MapCameraPosition.region(
            MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        ))) {
            Marker("Selected Location", coordinate: coordinate)
                .tint(MeetSpotColors.pink500)
        }
        .disabled(true)
        .overlay(
            Color.black.opacity(0.1)
                .allowsHitTesting(false)
        )
        .mediumShadow()
    }
}

// Flow layout for tags
struct FlowLayout<T: Hashable, V: View>: View {
    let items: [T]
    let itemSpacing: CGFloat
    let lineSpacing: CGFloat
    @ViewBuilder let viewBuilder: (T) -> V
    
    var body: some View {
        GeometryReader { geometry in
            FlowLayoutHelper(
                width: geometry.size.width,
                items: items,
                itemSpacing: itemSpacing,
                lineSpacing: lineSpacing,
                viewBuilder: viewBuilder
            )
        }
        .frame(minHeight: 0, maxHeight: .infinity)
    }
}

fileprivate struct FlowLayoutHelper<T: Hashable, V: View>: View {
    let width: CGFloat
    let items: [T]
    let itemSpacing: CGFloat
    let lineSpacing: CGFloat
    @ViewBuilder let viewBuilder: (T) -> V
    
    var body: some View {
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeight: CGFloat = 0
        
        ZStack(alignment: .topLeading) {
            ForEach(items, id: \.self) { item in
                viewBuilder(item)
                    .alignmentGuide(.leading) { d in
                        if x + d.width > width {
                            x = 0
                            y += maxHeight + lineSpacing
                            maxHeight = 0
                        }
                        
                        let result = x
                        if d.height > maxHeight {
                            maxHeight = d.height
                        }
                        
                        x += d.width + itemSpacing
                        return -result
                    }
                    .alignmentGuide(.top) { _ in -y }
            }
        }
    }
}

// Preview
struct PreviewStepView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewStepView(onboardingState: CreateMeetOnboardingState())
            .preferredColorScheme(.dark)
    }
} 
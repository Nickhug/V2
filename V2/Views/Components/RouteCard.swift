import SwiftUI
import MapKit

struct RouteCard: View {
    enum Style {
        case list // Simple list style
        case selectable // Interactive selection style with map preview
    }
    
    let route: Route
    var isSelected: Bool = false
    var onSelect: (() -> Void)? = nil
    var style: Style = .list
    
    var body: some View {
        switch style {
        case .list:
            listStyle
        case .selectable:
            selectableStyle
        }
    }
    
    private var listStyle: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(route.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                Label {
                    Text("\(String(format: "%.1f", route.distance)) km")
                } icon: {
                    Image(systemName: "speedometer")
                        .foregroundColor(.blue)
                }
                .font(.subheadline)
            }
            
            Text(route.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                Label {
                    Text("\(route.estimatedTime) min")
                } icon: {
                    Image(systemName: "clock")
                        .foregroundColor(.orange)
                }
                .font(.caption)
                
                Spacer()
                
                Label {
                    Text(route.difficulty.rawValue)
                } icon: {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.green)
                }
                .font(.caption)
            }
        }
        .padding()
        .background(Material.ultraThinMaterial)
        .cornerRadius(12)
    }
    
    private var selectableStyle: some View {
        Button(action: { onSelect?() }) {
            HStack(spacing: 16) {
                // Map preview
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(MeetSpotColors.purple900.opacity(0.3))
                        .frame(width: 100, height: 80)
                    
                    // Route path visualization (simplified)
                    Path { path in
                        if route.routeData.coordinates.count > 1 {
                            path.move(to: CGPoint(x: 30, y: 50))
                            
                            // Create a meandering path
                            path.addCurve(
                                to: CGPoint(x: 70, y: 40),
                                control1: CGPoint(x: 40, y: 20),
                                control2: CGPoint(x: 60, y: 60)
                            )
                        }
                    }
                    .stroke(MeetSpotColors.pink500, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    
                    // Start and end points
                    Circle()
                        .fill(MeetSpotColors.pink500)
                        .frame(width: 8, height: 8)
                        .position(x: 30, y: 50)
                    
                    Circle()
                        .fill(MeetSpotColors.purple900)
                        .frame(width: 8, height: 8)
                        .position(x: 70, y: 40)
                }
                
                // Route details
                VStack(alignment: .leading, spacing: 4) {
                    Text(route.title)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(route.description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                    
                    HStack {
                        Label {
                            Text("\(String(format: "%.1f", route.distance)) km")
                        } icon: {
                            Image(systemName: "speedometer")
                        }
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                        
                        Spacer()
                        
                        Label {
                            Text("\(route.estimatedTime) min")
                        } icon: {
                            Image(systemName: "clock")
                        }
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? MeetSpotColors.purple900.opacity(0.7) : Color(uiColor: UIColor.systemBackground).opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(isSelected ? MeetSpotColors.pink500 : Color.clear, lineWidth: 2)
                    )
            )
            .padding(.horizontal)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RouteCard_Previews: PreviewProvider {
    static let mockRoute = Route(
        id: "1",
        meetId: nil,
        creatorId: "user1",
        title: "Mountain Loop",
        description: "Scenic mountain drive",
        routeData: RouteData(coordinates: [
            Coordinate(latitude: 37.7749, longitude: -122.4194),
            Coordinate(latitude: 37.3382, longitude: -121.8863)
        ]),
        distance: 25.5,
        estimatedTime: 45,
        difficulty: .moderate
    )
    
    static var previews: some View {
        VStack(spacing: 20) {
            RouteCard(route: mockRoute)
            
            RouteCard(
                route: mockRoute,
                isSelected: true,
                onSelect: {},
                style: .selectable
            )
            
            RouteCard(
                route: mockRoute,
                isSelected: false,
                onSelect: {},
                style: .selectable
            )
        }
        .padding()
        .background(Color.black)
        .previewLayout(.sizeThatFits)
    }
} 
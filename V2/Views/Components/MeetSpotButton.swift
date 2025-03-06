import SwiftUI

struct MeetSpotButton: View {
    let meet: Meet
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Title and Status
                HStack {
                    Text(meet.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    StatusBadge(status: meet.status)
                }
                
                // Date and Time
                HStack {
                    Label {
                        Text(meet.date, style: .date)
                    } icon: {
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Label {
                        Text(meet.date, style: .time)
                    } icon: {
                        Image(systemName: "clock")
                            .foregroundColor(.orange)
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                
                // Location
                Label {
                    Text(meet.address)
                } icon: {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.red)
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                
                // Vehicle and Route Types
                HStack {
                    Label {
                        Text(meet.vehicleType.rawValue)
                    } icon: {
                        Image(systemName: "car.fill")
                            .foregroundColor(.purple)
                    }
                    
                    Spacer()
                    
                    Label {
                        Text(meet.routeType.rawValue)
                    } icon: {
                        Image(systemName: "map")
                            .foregroundColor(.green)
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 3)
        }
    }
}

// MARK: - Preview
struct MeetSpotButton_Previews: PreviewProvider {
    static var previews: some View {
        MeetSpotButton(
            meet: Meet.mockMeets[0],
            onTap: {}
        )
        .padding()
        .previewLayout(.sizeThatFits)
        
        MeetSpotButton(
            meet: Meet.mockMeets[1],
            onTap: {}
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 
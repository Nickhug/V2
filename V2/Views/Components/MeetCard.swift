import SwiftUI

struct MeetCard: View {
    let meet: Meet
    var style: MeetCardStyle = .light
    var onJoin: (() -> Void)?
    var onTap: (() -> Void)?
    
    enum MeetCardStyle {
        case light
        case dark
    }
    
    var body: some View {
        Button(action: {
            if let onTap = onTap {
                onTap()
            }
        }) {
            // Simplified card layout
            VStack(alignment: .leading, spacing: 0) {
                // Cover image
                if !meet.coverImage.isEmpty {
                    AsyncImageView(imageName: meet.coverImage, downsample: true)
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 150)
                        .clipShape(Rectangle())
                } else {
                    // Fallback image
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 150)
                }
                
                // Card content
                VStack(alignment: .leading, spacing: 8) {
                    // Title
                    Text(meet.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    // Status
                    Text(meet.status.displayName)
                        .font(.caption)
                        .foregroundColor(meet.status.color)
                    
                    // Date
                    HStack {
                        Image(systemName: "calendar")
                        Text(meet.formattedDate)
                    }
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    
                    // Join button if applicable
                    if let onJoin = onJoin, meet.status.allowsInteraction {
                        Button(action: onJoin) {
                            Text("Join")
                                .font(.subheadline)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .padding(.top, 4)
                    }
                }
                .padding(12)
            }
            .background(Color.black.opacity(0.3))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(BorderlessButtonStyle())
    }
}

#Preview {
    VStack(spacing: 20) {
        MeetCard(meet: Meet.mockMeets[0])
        MeetCard(meet: Meet.mockMeets[1], style: .dark)
        MeetCard(meet: Meet.mockMeets[2], onJoin: {})
    }
    .padding()
} 
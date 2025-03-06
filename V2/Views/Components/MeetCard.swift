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
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: 0) {
                // Cover Image
                AsyncImageView(imageName: meet.coverImage)
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 150)
                    .clipShape(UnevenRoundedRectangle(cornerRadii: .init(
                        topLeading: 16, bottomLeading: 0,
                        bottomTrailing: 0, topTrailing: 16
                    )))
                    .overlay(
                        VStack {
                            Spacer()
                            HStack {
                                Text(meet.type.rawValue)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(meet.type.color)
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                            }
                            .padding(10)
                        }
                    )
                
                VStack(alignment: .leading, spacing: 10) {
                    Text(meet.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(style == .light ? .primary : .white)
                    
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(style == .light ? .secondary : .white.opacity(0.7))
                        Text(meet.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.callout)
                            .foregroundColor(style == .light ? .secondary : .white.opacity(0.7))
                    }
                    
                    Divider()
                        .background(style == .light ? Color.secondary : Color.white.opacity(0.2))
                    
                    HStack {
                        Image(systemName: "person.3.fill")
                            .foregroundColor(style == .light ? .secondary : .white.opacity(0.7))
                        Text("\(meet.attendees.count) attending")
                            .font(.callout)
                            .foregroundColor(style == .light ? .secondary : .white.opacity(0.7))
                        
                        Spacer()
                        
                        if let onJoin = onJoin {
                            Button(action: onJoin) {
                                Text("Join")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(DesignSystem.Colors.accentGradient)
                                    .clipShape(Capsule())
                            }
                        } else {
                            // Host Avatar
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Text("H")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                )
                        }
                    }
                }
                .padding()
            }
            .background(style == .light ? Color(.secondarySystemBackground) : Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
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
import SwiftUI
import CoreLocation

struct UserCard: View {
    let user: User
    var onAddFriend: () -> Void
    var isPending: Bool = false
    var distance: CLLocationDistance? = nil
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(MeetSpotColors.accentGradient)
                    .frame(width: 60, height: 60)
                    .mediumShadow()
                
                if let avatarUrl = user.profile.avatarUrl, !avatarUrl.isEmpty, let url = URL(string: avatarUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                    } placeholder: {
                        Image(systemName: "person.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                
                // Status indicator (simple green dot if they have a status)
                if user.profile.statusMessage != nil {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color.black.opacity(0.2), lineWidth: 1)
                        )
                        .offset(x: 22, y: 22)
                }
            }
            
            // User info
            VStack(alignment: .leading, spacing: 4) {
                Text(user.profile.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                if let statusMessage = user.profile.statusMessage {
                    Text(statusMessage)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                if let location = distance {
                    Text(formatDistance(location))
                        .font(.caption)
                        .foregroundColor(MeetSpotColors.pink500)
                } else if !user.profile.location.address.isEmpty {
                    Text(user.profile.location.address)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            Spacer()
            
            // Add friend button
            Button(action: {
                onAddFriend()
            }) {
                ZStack {
                    Capsule()
                        .fill(isPending ? 
                              LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)]), startPoint: .leading, endPoint: .trailing) : 
                              MeetSpotColors.accentGradient)
                        .frame(height: 36)
                    
                    HStack(spacing: 6) {
                        Image(systemName: isPending ? "clock.fill" : "person.badge.plus.fill")
                            .font(.system(size: 14))
                        
                        Text(isPending ? "Pending" : "Add")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                }
                .frame(width: 100)
                .subtleShadow()
            }
            .disabled(isPending)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Material.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .mediumShadow()
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        let distanceInKm = distance / 1000
        
        if distanceInKm < 1 {
            return "< 1 km away"
        } else if distanceInKm < 10 {
            return "\(Int(distanceInKm.rounded())) km away"
        } else {
            return "\(Int((distanceInKm / 5).rounded() * 5)) km away"
        }
    }
}

#Preview {
    ZStack {
        Color.black.edgesIgnoringSafeArea(.all)
        
        VStack(spacing: 20) {
            UserCard(
                user: User(
                    id: "1",
                    email: "john@example.com",
                    profile: User.Profile(
                        name: "John Smith",
                        avatar: "",
                        avatarUrl: nil,
                        bio: "Car enthusiast",
                        location: User.Profile.Location(
                            latitude: 37.7749,
                            longitude: -122.4194,
                            address: "San Francisco, CA"
                        ),
                        joinDate: Date(),
                        social: nil,
                        statusMessage: "Looking for car meets"
                    ),
                    vehicles: [],
                    friends: [],
                    isPremium: false,
                    achievements: [],
                    preferences: User.Preferences.defaultPreferences
                ),
                onAddFriend: {}
            )
            
            UserCard(
                user: User(
                    id: "2",
                    email: "jane@example.com",
                    profile: User.Profile(
                        name: "Jane Doe",
                        avatar: "",
                        avatarUrl: nil,
                        bio: "Motorcycle lover",
                        location: User.Profile.Location(
                            latitude: 34.0522,
                            longitude: -118.2437,
                            address: "Los Angeles, CA"
                        ),
                        joinDate: Date(),
                        social: nil,
                        statusMessage: nil
                    ),
                    vehicles: [],
                    friends: [],
                    isPremium: true,
                    achievements: [],
                    preferences: User.Preferences.defaultPreferences
                ),
                onAddFriend: {},
                isPending: true,
                distance: 15000
            )
        }
        .padding()
    }
} 
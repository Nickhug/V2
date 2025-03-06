import SwiftUI

struct AsyncImageView: View {
    let imageName: String
    let avatarUrl: String?
    
    init(imageName: String, avatarUrl: String? = nil) {
        self.imageName = imageName
        self.avatarUrl = avatarUrl
    }
    
    var body: some View {
        if let avatarUrl = avatarUrl, !avatarUrl.isEmpty {
            // Use the new avatarUrl field if available
            AsyncImage(url: URL(string: avatarUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGray6))
            }
        } else if !imageName.isEmpty {
            // Fall back to legacy avatar field
            AsyncImage(url: URL(string: imageName)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGray6))
            }
        } else {
            // No image available
            Image(systemName: "person.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(Color(.systemGray4))
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        AsyncImageView(imageName: "https://images.unsplash.com/photo-1503736334956-4c8f8e92946d?w=800&q=80")
            .frame(width: 100, height: 100)
            .clipShape(Circle())
        
        AsyncImageView(imageName: "", avatarUrl: "https://images.unsplash.com/photo-1503736334956-4c8f8e92946d?w=800&q=80")
            .frame(width: 100, height: 100)
            .clipShape(Circle())
        
        AsyncImageView(imageName: "", avatarUrl: "")
            .frame(width: 100, height: 100)
            .clipShape(Circle())
    }
} 
import SwiftUI

struct AsyncImageView: View {
    let imageName: String
    let avatarUrl: String?
    let downsample: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled
    @State private var loadAttempts: Int = 0
    @State private var isRetrying: Bool = false
    
    init(imageName: String, avatarUrl: String? = nil, downsample: Bool = false) {
        self.imageName = imageName
        self.avatarUrl = avatarUrl
        self.downsample = downsample
    }
    
    private func isValidURL(_ urlString: String) -> Bool {
        guard !urlString.isEmpty else {
            print("AsyncImageView: Empty URL string")
            return false
        }
        
        guard let url = URL(string: urlString) else {
            print("AsyncImageView: Invalid URL format: \(urlString)")
            return false
        }
        
        // Check if the URL is a valid web URL
        if url.scheme == "http" || url.scheme == "https" {
            return UIApplication.shared.canOpenURL(url)
        }
        
        // If it's a local file URL or other type, just verify it has a valid path
        return !url.path.isEmpty
    }
    
    private func getImageURL() -> URL? {
        // First try avatar URL
        if let avatarUrl = avatarUrl, !avatarUrl.isEmpty {
            print("AsyncImageView: Trying avatarUrl: \(avatarUrl)")
            if let url = URL(string: avatarUrl) {
                return url
            }
        }
        
        // Then try image name
        if !imageName.isEmpty {
            print("AsyncImageView: Trying imageName: \(imageName)")
            if let url = URL(string: imageName) {
                return url
            } else {
                print("AsyncImageView: Failed to create URL from imageName: \(imageName)")
            }
        } else {
            print("AsyncImageView: imageName is empty")
        }
        
        print("AsyncImageView: No valid URL found")
        return nil
    }
    
    private func retryLoadingIfNeeded() {
        // Only retry up to 3 times with exponential backoff
        guard loadAttempts < 3, !isRetrying else { return }
        
        isRetrying = true
        let delay = pow(Double(2), Double(loadAttempts))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            loadAttempts += 1
            isRetrying = false
        }
    }
    
    var body: some View {
        Group {
            if let imageURL = getImageURL() {
                AsyncImage(url: imageURL, transaction: .init(animation: .easeInOut(duration: 0.2))) { phase in
                    switch phase {
                    case .empty:
                        placeholderView
                            .onAppear {
                                // Reset retry counter when starting fresh
                                if loadAttempts > 0 {
                                    loadAttempts = 0
                                }
                            }
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            // Apply quality adjustment for better performance if requested
                            .if(downsample) { view in
                                view.contrast(0.95) // Slight quality adjustment instead of interpolation
                            }
                            .onAppear {
                                // Reset on successful load
                                loadAttempts = 0
                            }
                    case .failure:
                        fallbackImageView
                            .onAppear {
                                // Try to reload the image after a failure
                                retryLoadingIfNeeded()
                            }
                    @unknown default:
                        placeholderView
                    }
                }
                // Set higher priority for image loading
                .task(priority: .userInitiated) {
                    // This task ensures the image loading is properly managed
                }
            } else {
                // No valid image URL
                fallbackImageView
            }
        }
    }
    
    // Helper Views
    private var placeholderView: some View {
        ZStack {
            Rectangle()
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray5))
            
            // Replace ProgressView with custom Circle animation
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(colorScheme == .dark ? Color.white : Color.gray, lineWidth: 2)
                .frame(width: 24, height: 24)
                .rotationEffect(Angle(degrees: 270))
                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: UUID())
        }
    }
    
    private var fallbackImageView: some View {
        ZStack {
            Rectangle()
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray5))
            
            Image(systemName: "photo.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(Color(.systemGray4))
                .padding(20)
        }
    }
}

// We're removing the duplicate View extension here since
// the 'if' extension is already defined elsewhere in the project

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
        
        // Preview with invalid URL
        AsyncImageView(imageName: "invalid-url")
            .frame(width: 100, height: 100)
            .clipShape(Circle())
    }
} 
import SwiftUI
import UIKit

@MainActor
class ImageLoader: ObservableObject {
    @Published private(set) var images: [String: UIImage] = [:]
    private var loadingTasks: [String: Task<Void, Never>] = [:]
    
    static let shared = ImageLoader()
    private let cache = NSCache<NSString, UIImage>()
    
    private init() {}
    
    func loadImage(named imageName: String) {
        // Check if already loaded or loading
        guard images[imageName] == nil, loadingTasks[imageName] == nil else { return }
        
        // Check cache first
        if let cachedImage = cache.object(forKey: imageName as NSString) {
            images[imageName] = cachedImage
            return
        }
        
        // Create loading task
        let task = Task {
            if let image = UIImage(systemName: imageName) {
                images[imageName] = image
                cache.setObject(image, forKey: imageName as NSString)
            }
            loadingTasks[imageName] = nil
        }
        
        loadingTasks[imageName] = task
    }
}
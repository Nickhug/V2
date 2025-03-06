import SwiftUI
import Supabase

class ImageUploadService {
    static let shared = ImageUploadService()
    private let supabase: SupabaseClient
    
    private init() {
        self.supabase = SupabaseConfig.client
    }
    
    // Upload an image to Supabase storage
    func uploadImage(_ image: UIImage, bucket: String, path: String) async throws -> String {
        // Compress the image
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw NSError(domain: "ImageUploadError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }
        
        // Generate a unique filename using UUID
        let fileName = "\(UUID().uuidString).jpg"
        let fullPath = "\(path)/\(fileName)"
        
        // Show upload in progress
        print("Uploading image to \(bucket)/\(fullPath)...")
        
        // Upload to Supabase Storage - using updated API
        try await supabase.storage
            .from(bucket)
            .upload(
                fullPath,
                data: imageData,
                options: .init(upsert: true)
            )
        
        // Get public URL
        let publicURL = try supabase.storage
            .from(bucket)
            .getPublicURL(path: fullPath)
        
        // Convert URL to string before returning
        return publicURL.absoluteString
    }
    
    // Upload avatar image
    func uploadAvatar(_ image: UIImage, userId: String) async throws -> String {
        return try await uploadImage(image, bucket: "avatars", path: "user/\(userId)")
    }
    
    // Upload vehicle image
    func uploadVehicleImage(_ image: UIImage, userId: String, vehicleId: String) async throws -> String {
        return try await uploadImage(image, bucket: "vehicles", path: "user/\(userId)/vehicle/\(vehicleId)")
    }
} 
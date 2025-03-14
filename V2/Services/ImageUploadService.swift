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
        
        do {
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
            
            print("Successfully uploaded image to \(bucket)/\(fullPath)")
            // Convert URL to string before returning
            return publicURL.absoluteString
        } catch let error as StorageError {
            print("Storage error during image upload to \(bucket)/\(fullPath): \(error)")
            
            // Check for bucket existence issues
            if error.message.contains("bucket") || error.message.contains("404") {
                print("Possible bucket not found issue - ensure the '\(bucket)' bucket exists in Supabase")
            }
            
            // Check for authentication issues
            if error.message.contains("auth") || error.message.contains("401") {
                print("Possible authentication issue - verify user is logged in and has proper permissions")
            }
            
            // Rethrow with more context
            throw error
        } catch {
            print("Unexpected error during image upload to \(bucket)/\(fullPath): \(error)")
            throw error
        }
    }
    
    // Upload avatar image
    func uploadAvatar(_ image: UIImage, userId: String) async throws -> String {
        return try await uploadImage(image, bucket: "avatars", path: "user/\(userId)")
    }
    
    // Upload vehicle image
    func uploadVehicleImage(_ image: UIImage, userId: String, vehicleId: String) async throws -> String {
        return try await uploadImage(image, bucket: "vehicles", path: "user/\(userId)/vehicle/\(vehicleId)")
    }
    
    // Upload post image
    func uploadPostImage(_ image: UIImage, userId: String) async throws -> String {
        print("DEBUG: Starting post image upload for user \(userId)")
        do {
            let url = try await uploadImage(image, bucket: "posts", path: "user/\(userId)/posts")
            print("DEBUG: Successfully uploaded post image, URL: \(url)")
            return url
        } catch {
            print("DEBUG: Failed to upload post image: \(error)")
            
            // Get more detailed information about the error
            let nsError = error as NSError
            print("DEBUG: Error domain: \(nsError.domain), code: \(nsError.code)")
            if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? Error {
                print("DEBUG: Underlying error: \(underlyingError)")
            }
            
            // Check network connectivity
            if nsError.domain == NSURLErrorDomain {
                print("DEBUG: This appears to be a network connectivity issue")
                if nsError.code == NSURLErrorNotConnectedToInternet {
                    print("DEBUG: Device is not connected to the internet")
                } else if nsError.code == NSURLErrorTimedOut {
                    print("DEBUG: Request timed out")
                } else if nsError.code == NSURLErrorCannotConnectToHost {
                    print("DEBUG: Cannot connect to host")
                }
            }
            
            throw error
        }
    }
} 
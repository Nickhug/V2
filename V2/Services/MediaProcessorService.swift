import Foundation
import AVFoundation
import UIKit
import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

// Service responsible for processing media (images and videos) with overlays
// Make MediaProcessorService conform to Sendable to fix isolation issues
@available(iOS 13.0, *)
final class MediaProcessorService: @unchecked Sendable {
    
    // MARK: - Public Methods
    
    /// Process image with overlays and drawings
    /// - Parameters:
    ///   - image: The source image
    ///   - textOverlays: Array of text overlays to render
    ///   - drawingPaths: Array of drawing paths to render
    /// - Returns: Processed UIImage with all overlays applied
    func processImageWithOverlays(image: UIImage, 
                                 textOverlays: [TextOverlay],
                                 drawingPaths: [DrawingPath]) -> UIImage {
        // Use renderer to draw overlays on the image
        let renderer = UIGraphicsImageRenderer(size: image.size)
        
        return renderer.image { context in
            // Draw the base image
            let rect = CGRect(origin: .zero, size: image.size)
            image.draw(in: rect)
            
            let ctx = context.cgContext
            
            // Calculate scale factor between UIKit coordinate system and image size
            let scaleFactorX = image.size.width / UIScreen.main.bounds.width
            let scaleFactorY = image.size.height / UIScreen.main.bounds.height
            
            // Draw all paths
            renderDrawingPaths(paths: drawingPaths, 
                              context: ctx, 
                              scaleFactorX: scaleFactorX, 
                              scaleFactorY: scaleFactorY)
            
            // Draw all text overlays
            renderTextOverlays(overlays: textOverlays, 
                              context: ctx, 
                              scaleFactorX: scaleFactorX, 
                              scaleFactorY: scaleFactorY)
        }
    }
    
    /// Process video with overlays and drawings
    /// - Parameters:
    ///   - videoURL: The source video URL
    ///   - textOverlays: Array of text overlays to render
    ///   - drawingPaths: Array of drawing paths to render
    ///   - progressHandler: Optional handler for reporting progress (0.0 to 1.0)
    /// - Returns: URL to the processed video file
    func processVideoWithOverlays(videoURL: URL, 
                                 textOverlays: [TextOverlay],
                                 drawingPaths: [DrawingPath],
                                 progressHandler: ((Float) -> Void)? = nil) async throws -> URL {
        print("📹 Processing video with overlays: \(textOverlays.count) text, \(drawingPaths.count) drawings")
        
        // Create asset from the source video
        let asset = AVURLAsset(url: videoURL)
        
        // Create composition for the video track
        let composition = AVMutableComposition()
        
        // Load video tracks asynchronously
        let videoTracks = try await asset.loadTracks(withMediaType: .video)
        guard let videoTrack = videoTracks.first,
              let compositionVideoTrack = composition.addMutableTrack(
                withMediaType: .video,
                preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw MediaProcessingError.videoTrackCreationFailed
        }
        
        // Load duration asynchronously
        let duration = try await asset.load(.duration)
        
        // Copy the video track into the composition
        try compositionVideoTrack.insertTimeRange(
            CMTimeRange(start: .zero, duration: duration),
            of: videoTrack,
            at: .zero
        )
        
        // Get the video track's preferred transform asynchronously
        let preferredTransform = try await videoTrack.load(.preferredTransform)
        compositionVideoTrack.preferredTransform = preferredTransform
        
        // Load audio tracks asynchronously and copy if exists
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        if let audioTrack = audioTracks.first,
           let compositionAudioTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid) {
            
            try compositionAudioTrack.insertTimeRange(
                CMTimeRange(start: .zero, duration: duration),
                of: audioTrack,
                at: .zero
            )
        }
        
        // Create video composition for overlays
        let videoComposition = try await createVideoComposition(
            with: asset,
            textOverlays: textOverlays,
            drawingPaths: drawingPaths
        )
        
        // Create the output URL
        let outputURL = createTemporaryURL(extension: "mp4")
        
        // Use the new async export method in iOS 18
        do {
            // Create export session
            guard let exportSession = AVAssetExportSession(
                asset: composition,
                presetName: AVAssetExportPresetHighestQuality) else {
                throw MediaProcessingError.exportSessionCreationFailed
            }
            
            // Configure export session
            exportSession.outputURL = outputURL
            exportSession.outputFileType = .mp4
            exportSession.videoComposition = videoComposition
            exportSession.shouldOptimizeForNetworkUse = true
            
            // Create a progress observer for the export
            if let progressHandler = progressHandler {
                // Create a task to periodically monitor and report progress
                Task {
                    // Use the new states method on the instance, not the type
                    for await _ in exportSession.states(updateInterval: 0.1) {
                        // Report progress if available
                        progressHandler(exportSession.progress)
                    }
                }
            }
            
            // Perform the export using the new async iOS 18 API
            try await exportSession.export(to: outputURL, as: .mp4)
            
            print("✅ Video processing completed successfully")
            return outputURL
        } catch {
            print("❌ Video export failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    /// Creates a video composition with overlays
    private func createVideoComposition(with asset: AVAsset, 
                                      textOverlays: [TextOverlay],
                                      drawingPaths: [DrawingPath]) async throws -> AVMutableVideoComposition {
        // Load video tracks asynchronously
        let videoTracks = try await asset.loadTracks(withMediaType: .video)
        guard let videoTrack = videoTracks.first else {
            throw MediaProcessingError.videoTrackCreationFailed
        }
        
        // Get track dimensions asynchronously
        let trackSize = try await videoTrack.load(.naturalSize)
        
        // Handle rotation if needed (get preferred transform asynchronously)
        let transform = try await videoTrack.load(.preferredTransform)
        var renderSize = trackSize
        
        // Handle video orientation
        if transform.ty == trackSize.width {
            // Portrait video
            renderSize = CGSize(width: trackSize.height, height: trackSize.width)
        }
        
        // Create videoComposition using the proper iOS 18 API with completion handler
        let videoComposition = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<AVMutableVideoComposition, Error>) in
            AVMutableVideoComposition.videoComposition(with: asset) { [weak self] request in
                // Get the source image (video frame)
                let sourceImage = request.sourceImage.clampedToExtent()
                guard let self = self else {
                    request.finish(with: sourceImage, context: nil)
                    return
                }
                
                // Calculate scale factors
                let scaleFactorX = renderSize.width / UIScreen.main.bounds.width
                let scaleFactorY = renderSize.height / UIScreen.main.bounds.height
                
                // Create CIImage to draw on
                var outputImage = sourceImage
                
                // Add drawing paths
                for path in drawingPaths {
                    // Skip empty paths
                    guard path.points.count >= 2 else { continue }
                    
                    // Create path for this drawing
                    let pathImage = self.createCIImageFromDrawingPath(
                        path: path,
                        size: renderSize,
                        scaleFactorX: scaleFactorX,
                        scaleFactorY: scaleFactorY
                    )
                    
                    // Composite the path over the current output image
                    outputImage = pathImage.composited(over: outputImage)
                }
                
                // Add text overlays
                for overlay in textOverlays {
                    // Create text image for this overlay
                    if let textImage = self.createCIImageFromTextOverlay(
                        overlay: overlay,
                        size: renderSize,
                        scaleFactorX: scaleFactorX,
                        scaleFactorY: scaleFactorY
                    ) {
                        // Composite the text over the current output image
                        outputImage = textImage.composited(over: outputImage)
                    }
                }
                
                // Finish with the final composited image
                request.finish(with: outputImage, context: nil)
            } completionHandler: { composition, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let composition = composition else {
                    continuation.resume(throwing: MediaProcessingError.videoCompositionCreationFailed)
                    return
                }
                
                // Set the render size and framerate
                composition.renderSize = renderSize
                composition.frameDuration = CMTime(value: 1, timescale: 30) // 30 fps
                continuation.resume(returning: composition)
            }
        }
        
        return videoComposition
    }
    
    /// Creates a CIImage for a drawing path
    private func createCIImageFromDrawingPath(path: DrawingPath, 
                                           size: CGSize,
                                           scaleFactorX: CGFloat, 
                                           scaleFactorY: CGFloat) -> CIImage {
        // Create a new image context
        let renderer = UIGraphicsImageRenderer(size: size)
        
        // Draw the path
        let pathImage = renderer.image { context in
            let ctx = context.cgContext
            
            // Set path properties
            ctx.setStrokeColor(UIColor(path.color).cgColor)
            ctx.setLineWidth(path.lineWidth * scaleFactorX)
            ctx.setLineCap(.round)
            ctx.setLineJoin(.round)
            
            // Draw the path
            for (i, point) in path.points.enumerated() {
                let scaledPoint = CGPoint(
                    x: point.x * scaleFactorX,
                    y: point.y * scaleFactorY
                )
                
                if i == 0 {
                    ctx.move(to: scaledPoint)
                } else {
                    ctx.addLine(to: scaledPoint)
                }
            }
            
            ctx.strokePath()
        }
        
        // Convert UIImage to CIImage
        guard let ciImage = CIImage(image: pathImage) else {
            return CIImage.empty()
        }
        
        return ciImage
    }
    
    /// Creates a CIImage for a text overlay
    private func createCIImageFromTextOverlay(overlay: TextOverlay, 
                                           size: CGSize,
                                           scaleFactorX: CGFloat, 
                                           scaleFactorY: CGFloat) -> CIImage? {
        // Create attributes for the text
        let font = getUIFont(from: overlay.fontName, size: overlay.fontSize * scaleFactorX)
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor(overlay.color)
        ]
        
        // Create attributed string
        let attributedString = NSAttributedString(string: overlay.text, attributes: attributes)
        
        // Calculate text size
        let textSize = attributedString.size()
        
        // Create a renderer with enough space for the text
        let padding: CGFloat = 20 // Extra padding to ensure rotation doesn't clip
        let renderSize = CGSize(
            width: textSize.width + padding * 2,
            height: textSize.height + padding * 2
        )
        
        // Create a transparent image to draw the text on
        let renderer = UIGraphicsImageRenderer(size: renderSize)
        
        let textImage = renderer.image { context in
            let ctx = context.cgContext
            
            // Move to center
            ctx.translateBy(x: renderSize.width / 2, y: renderSize.height / 2)
            
            // Apply rotation
            ctx.rotate(by: overlay.rotation.radians)
            
            // Draw text centered
            attributedString.draw(at: CGPoint(
                x: -textSize.width / 2,
                y: -textSize.height / 2
            ))
        }
        
        // Convert to CIImage
        guard var ciImage = CIImage(image: textImage) else {
            return nil
        }
        
        // Position at the overlay's position
        let positionX = overlay.position.x * scaleFactorX - renderSize.width / 2
        let positionY = size.height - (overlay.position.y * scaleFactorY + renderSize.height / 2)
        
        ciImage = ciImage.transformed(by: CGAffineTransform(translationX: positionX, y: positionY))
        
        return ciImage
    }
    
    /// Renders drawing paths to a CGContext
    private func renderDrawingPaths(paths: [DrawingPath], 
                                  context: CGContext, 
                                  scaleFactorX: CGFloat, 
                                  scaleFactorY: CGFloat) {
        for path in paths {
            if path.points.count < 2 { continue }
            
            context.setStrokeColor(UIColor(path.color).cgColor)
            context.setLineWidth(path.lineWidth * scaleFactorX)
            context.setLineCap(.round)
            context.setLineJoin(.round)
            
            for (i, point) in path.points.enumerated() {
                let scaledPoint = CGPoint(
                    x: point.x * scaleFactorX,
                    y: point.y * scaleFactorY
                )
                
                if i == 0 {
                    context.move(to: scaledPoint)
                } else {
                    context.addLine(to: scaledPoint)
                }
            }
            
            context.strokePath()
        }
    }
    
    /// Renders text overlays to a CGContext
    private func renderTextOverlays(overlays: [TextOverlay], 
                                  context: CGContext, 
                                  scaleFactorX: CGFloat, 
                                  scaleFactorY: CGFloat) {
        for overlay in overlays {
            let scaledPosition = CGPoint(
                x: overlay.position.x * scaleFactorX,
                y: overlay.position.y * scaleFactorY
            )
            
            let font = getUIFont(from: overlay.fontName, size: overlay.fontSize * scaleFactorX)
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor(overlay.color)
            ]
            
            let attributedString = NSAttributedString(string: overlay.text, attributes: attributes)
            let textSize = attributedString.size()
            
            context.saveGState()
            context.translateBy(x: scaledPosition.x, y: scaledPosition.y)
            context.rotate(by: overlay.rotation.radians)
            
            attributedString.draw(at: CGPoint(x: -textSize.width / 2, y: -textSize.height / 2))
            
            context.restoreGState()
        }
    }
    
    /// Helper to convert font name to UIFont
    private func getUIFont(from fontName: String, size: CGFloat) -> UIFont {
        switch fontName {
        case "System Bold":
            return UIFont.systemFont(ofSize: size, weight: .bold)
        case "System Italic":
            return UIFont.italicSystemFont(ofSize: size)
        case "Helvetica":
            return UIFont(name: "Helvetica", size: size) ?? UIFont.systemFont(ofSize: size)
        case "Arial":
            return UIFont(name: "Arial", size: size) ?? UIFont.systemFont(ofSize: size)
        case "Georgia":
            return UIFont(name: "Georgia", size: size) ?? UIFont.systemFont(ofSize: size)
        default:
            return UIFont.systemFont(ofSize: size)
        }
    }
    
    /// Creates a temporary URL for exported media
    private func createTemporaryURL(extension fileExtension: String) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "\(UUID().uuidString).\(fileExtension)"
        return tempDir.appendingPathComponent(fileName)
    }
}

// MARK: - Errors

enum MediaProcessingError: Error {
    case videoTrackCreationFailed
    case exportSessionCreationFailed
    case exportFailed
    case exportCancelled
    case unknownError
    case videoCompositionCreationFailed
}

// MARK: - Extension for StoryCreationViewModel integration
extension MediaProcessorService {
    // Create singleton instance to prevent state issues
    static let shared = MediaProcessorService()
    
    // CRITICAL: Add a synchronous method to immediately process a text overlay and draw it
    // This prevents state loss by immediately rendering the overlay after creation
    func createAndRenderTextOverlayPreview(overlay: TextOverlay, size: CGSize) -> UIImage {
        // Create attributes
        let font = getUIFont(from: overlay.fontName, size: overlay.fontSize)
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor(overlay.color)
        ]
        
        // Create attributed string
        let attributedString = NSAttributedString(string: overlay.text, attributes: attributes)
        
        // Calculate text size
        let textSize = attributedString.size()
        
        // Create a renderer with enough space for the text
        let padding: CGFloat = 20
        let renderSize = CGSize(
            width: textSize.width + padding * 2,
            height: textSize.height + padding * 2
        )
        
        // Create a transparent image
        let renderer = UIGraphicsImageRenderer(size: renderSize)
        
        return renderer.image { context in
            let ctx = context.cgContext
            
            // Move to center
            ctx.translateBy(x: renderSize.width / 2, y: renderSize.height / 2)
            
            // Apply rotation
            ctx.rotate(by: overlay.rotation.radians)
            
            // Draw text centered
            attributedString.draw(at: CGPoint(
                x: -textSize.width / 2,
                y: -textSize.height / 2
            ))
        }
    }
} 
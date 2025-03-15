import Foundation
import SwiftUI
import Combine
import CoreLocation
import PhotosUI
import AVFoundation

@MainActor
class StoryCreationViewModel: NSObject, ObservableObject {
    // Published properties for UI
    @Published var selectedImage: UIImage?
    @Published var selectedVideo: URL?
    @Published var caption: String = ""
    @Published var location: CLLocationCoordinate2D?
    @Published var locationName: String?
    @Published var isLoading: Bool = false
    @Published var error: Error?
    @Published var showErrorMessage: Bool = false
    @Published var errorMessage: String = ""
    @Published var mediaType: MediaType = .image
    @Published var showCaptionField: Bool = false
    @Published var showLocationPicker: Bool = false
    @Published var showCamera: Bool = false
    @Published var captureMode: CaptureMode = .photo
    
    // Editor properties
    @Published var textOverlays: [TextOverlay] = []
    @Published var currentImageScale: CGFloat = 1.0
    @Published var currentImageOffset: CGSize = .zero
    @Published var selectedTextOverlay: UUID?
    @Published var brushColor: Color = .white
    @Published var brushSize: CGFloat = 3.0
    @Published var drawingPaths: [DrawingPath] = []
    @Published var currentDrawingPath: DrawingPath?
    @Published var editingMode: EditingMode = .transform
    
    // History stacks for undo/redo
    @Published var drawingHistory: [[DrawingPath]] = []
    @Published var textHistory: [[TextOverlay]] = []
    @Published var historyIndex: Int = 0
    
    // Animation properties
    @Published var toolTransitionActive: Bool = false
    
    // New properties for enhanced text editing
    @Published var selectedFont: Font = .system(size: 24)
    @Published var selectedFontName: String = "System"
    @Published var selectedFontSize: CGFloat = 24
    @Published var availableFonts: [String] = ["System", "System Bold", "System Italic", "Helvetica", "Arial", "Georgia"]
    @Published var availableFontSizes: [CGFloat] = [16, 20, 24, 32, 40, 48]
    @Published var shouldKeepEditing: Bool = false // Flag to maintain edit mode
    
    // Reference to the StoriesViewModel
    private let storiesViewModel: StoriesViewModel
    
    // Photo capture related properties
    private var captureSession: AVCaptureSession?
    private var cameraOutput = AVCapturePhotoOutput()
    private var videoOutput = AVCaptureMovieFileOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var videoRecordingStartTime: Date?
    private var isRecording: Bool = false
    
    // Media reference cache - these are kept separate from published properties
    // to maintain strong references and prevent deallocation
    private var imageCache: UIImage?
    private var videoCache: URL?
    
    // Add a new property to track preloading state
    @Published var isMediaPreloaded: Bool = false
    
    // Enum for media type
    enum MediaType {
        case image
        case video
    }
    
    // Enum for capture mode
    enum CaptureMode {
        case photo
        case video
    }
    
    // Enum for editor modes
    enum EditingMode {
        case transform
        case text
        case draw
        case stickers
    }
    
    init(storiesViewModel: StoriesViewModel) {
        self.storiesViewModel = storiesViewModel
        super.init()
        // Camera launches directly in the new design
        self.showCamera = true
    }
    
    // MARK: - Editor Methods
    
    func addTextOverlay() {
        print("Adding new text overlay")
        // Ensure we're in text editing mode
        editingMode = .text
        shouldKeepEditing = true
        
        // Save current state to history before adding
        saveTextHistory()
        
        let newOverlay = TextOverlay(
            id: UUID(),
            text: "Tap to edit",
            position: CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2),
            fontSize: selectedFontSize,
            color: .white,
            rotation: 0,
            fontName: selectedFontName
        )
        textOverlays.append(newOverlay)
        selectedTextOverlay = newOverlay.id
        print("Created new text overlay with ID: \(newOverlay.id) using font: \(selectedFontName) size: \(selectedFontSize)")
        
        // Add animation transition
        animateToolTransition()
    }
    
    func removeTextOverlay(id: UUID) {
        // Save current state to history before removal
        saveTextHistory()
        
        textOverlays.removeAll(where: { overlay in
            overlay.id == id
        })
        if selectedTextOverlay == id {
            selectedTextOverlay = nil
        }
    }
    
    func startDrawing(at point: CGPoint) {
        let newPath = DrawingPath(id: UUID(), color: brushColor, lineWidth: brushSize, points: [point])
        currentDrawingPath = newPath
    }
    
    func continueDrawing(to point: CGPoint) {
        guard var path = currentDrawingPath else { return }
        path.points.append(point)
        currentDrawingPath = path
    }
    
    func endDrawing() {
        guard let path = currentDrawingPath, !path.points.isEmpty else { return }
        
        // Save current state to history for undo
        saveDrawingHistory()
        
        drawingPaths.append(path)
        currentDrawingPath = nil
    }
    
    func clearDrawings() {
        // Save current state to history before clearing
        if !drawingPaths.isEmpty {
            saveDrawingHistory()
            drawingPaths.removeAll()
            currentDrawingPath = nil
        }
    }
    
    func undoLastDrawing() {
        if !drawingPaths.isEmpty && historyIndex > 0 {
            historyIndex -= 1
            drawingPaths = drawingHistory[historyIndex]
        }
    }
    
    func redoDrawing() {
        if historyIndex < drawingHistory.count - 1 {
            historyIndex += 1
            drawingPaths = drawingHistory[historyIndex]
        }
    }
    
    private func saveDrawingHistory() {
        // Remove any redo history if we're not at the end
        if historyIndex < drawingHistory.count - 1 {
            drawingHistory = Array(drawingHistory.prefix(historyIndex + 1))
        }
        
        // Add current state to history
        drawingHistory.append(drawingPaths)
        historyIndex = drawingHistory.count - 1
    }
    
    private func saveTextHistory() {
        // Remove any redo history if we're not at the end
        if historyIndex < textHistory.count - 1 {
            textHistory = Array(textHistory.prefix(historyIndex + 1))
        }
        
        // Add current state to history
        textHistory.append(textOverlays)
        historyIndex = textHistory.count - 1
    }
    
    func animateToolTransition() {
        // Set flag for UI animation
        toolTransitionActive = true
        
        // Reset after animation duration
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.toolTransitionActive = false
        }
    }
    
    func resetImageTransform() {
        currentImageScale = 1.0
        currentImageOffset = .zero
    }
    
    // MARK: - Media Selection Methods
    
    func handleSelectedVideo(_ url: URL) {
        selectedVideo = url
        selectedImage = nil
        mediaType = .video
    }
    
    // MARK: - Camera Methods
    
    func showCameraCapture() {
        showCamera = true
        setupCaptureSession()
    }
    
    func setupCaptureSession() {
        captureSession = AVCaptureSession()
        
        // Configure the session for high resolution capture
        if let session = captureSession {
            session.sessionPreset = .high
            
            // Get the back camera
            guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                showErrorMessage = true
                errorMessage = "Could not access the camera"
                return
            }
            
            // Connect the camera to the capture session
            do {
                let cameraInput = try AVCaptureDeviceInput(device: backCamera)
                if session.canAddInput(cameraInput) {
                    session.addInput(cameraInput)
                }
                
                // Setup photo output
                if session.canAddOutput(cameraOutput) {
                    session.addOutput(cameraOutput)
                }
                
                // Setup video output
                if session.canAddOutput(videoOutput) {
                    session.addOutput(videoOutput)
                }
                
                // Start the session on a background thread
                Task.detached {
                    session.startRunning()
                }
            } catch {
                self.error = error
                showErrorMessage = true
                errorMessage = "Failed to setup camera: \(error.localizedDescription)"
            }
        }
    }
    
    func switchCaptureMode() {
        captureMode = captureMode == .photo ? .video : .photo
    }
    
    func capturePhoto() {
        guard let captureSession = captureSession, captureSession.isRunning else {
            showErrorMessage = true
            errorMessage = "Camera is not ready"
            return
        }
        
        let settings = AVCapturePhotoSettings()
        cameraOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func startVideoRecording() {
        guard let captureSession = captureSession, captureSession.isRunning, !isRecording else {
            return
        }
        
        guard let tempURL = createTempFileURL() else {
            showErrorMessage = true
            errorMessage = "Could not create temporary file for video"
            return
        }
        
        videoOutput.startRecording(to: tempURL, recordingDelegate: self)
        isRecording = true
        videoRecordingStartTime = Date()
    }
    
    func stopVideoRecording() {
        guard isRecording else { return }
        
        videoOutput.stopRecording()
        isRecording = false
        videoRecordingStartTime = nil
    }
    
    private func createTempFileURL() -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "\(UUID().uuidString).mov"
        return tempDir.appendingPathComponent(fileName)
    }
    
    // MARK: - Story Creation Methods
    
    func uploadStory() async -> Bool {
        guard (selectedImage != nil || selectedVideo != nil) else {
            showErrorMessage = true
            errorMessage = "No media selected"
            return false
        }
        
        isLoading = true
        
        var success = false
        var finalImage: UIImage?
        
        // If there are any overlays or drawings, render them onto the image
        if let image = selectedImage, (!textOverlays.isEmpty || !drawingPaths.isEmpty) {
            finalImage = renderOverlaysToImage(image)
        } else {
            finalImage = selectedImage
        }
        
        // Determine which type of story to share
        if let image = finalImage {
            // Try to share image story
            success = await storiesViewModel.createImageStory(
                image: image,
                caption: caption.isEmpty ? nil : caption,
                location: location,
                locationName: locationName
            )
        } else if let videoURL = selectedVideo {
            // Try to share video story
            success = await storiesViewModel.createVideoStory(
                videoURL: videoURL,
                caption: caption.isEmpty ? nil : caption,
                location: location,
                locationName: locationName
            )
        }
        
        isLoading = false
        
        if !success {
            showErrorMessage = true
            errorMessage = "Failed to upload story"
        }
        
        return success
    }
    
    private func renderOverlaysToImage(_ image: UIImage) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        
        return renderer.image { context in
            // Draw the base image with current scale and offset
            let rect = CGRect(origin: .zero, size: image.size)
            image.draw(in: rect)
            
            let ctx = context.cgContext
            
            // Calculate scale factor between UIKit coordinate system and image size
            let scaleFactorX = image.size.width / UIScreen.main.bounds.width
            let scaleFactorY = image.size.height / UIScreen.main.bounds.height
            
            // Draw all paths
            for path in drawingPaths {
                if path.points.count < 2 { continue }
                
                ctx.setStrokeColor(UIColor(path.color).cgColor)
                ctx.setLineWidth(path.lineWidth * scaleFactorX)
                ctx.setLineCap(.round)
                ctx.setLineJoin(.round)
                
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
            
            // Draw all text overlays
            for overlay in textOverlays {
                let scaledPosition = CGPoint(
                    x: overlay.position.x * scaleFactorX,
                    y: overlay.position.y * scaleFactorY
                )
                
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: overlay.fontSize * scaleFactorX),
                    .foregroundColor: UIColor(overlay.color)
                ]
                
                let attributedString = NSAttributedString(string: overlay.text, attributes: attributes)
                let textSize = attributedString.size()
                
                ctx.saveGState()
                ctx.translateBy(x: scaledPosition.x, y: scaledPosition.y)
                ctx.rotate(by: overlay.rotation)
                
                attributedString.draw(at: CGPoint(x: -textSize.width / 2, y: -textSize.height / 2))
                
                ctx.restoreGState()
            }
        }
    }
    
    private func resetState() {
        clearMedia() // Use the new method to clear all media references
        caption = ""
        location = nil
        locationName = nil
        showCaptionField = false
        showCamera = true
        textOverlays = []
        currentImageScale = 1.0
        currentImageOffset = .zero
        selectedTextOverlay = nil
        
        // Reset drawing state
        drawingPaths = []
        currentDrawingPath = nil
        shouldKeepEditing = false
        editingMode = .transform
    }
    
    func cancelStoryCreation() {
        resetState()
        storiesViewModel.showStoryCreator = false
    }
    
    // MARK: - Location Methods
    
    func updateLocation(coordinate: CLLocationCoordinate2D, name: String) {
        location = coordinate
        locationName = name
        showLocationPicker = false
    }
    
    // Add a method to change font for selected text
    func updateTextFont(fontName: String, fontSize: CGFloat? = nil) {
        guard let selectedId = selectedTextOverlay,
              let index = textOverlays.firstIndex(where: { $0.id == selectedId }) else {
            print("No text selected to update font")
            return
        }
        
        // Save state for undo history
        saveTextHistory()
        
        textOverlays[index].fontName = fontName
        selectedFontName = fontName
        
        // Update font size if provided
        if let newSize = fontSize {
            textOverlays[index].fontSize = newSize
            selectedFontSize = newSize
        }
        
        print("Updated text overlay font: \(fontName), size: \(textOverlays[index].fontSize)")
    }
    
    // Add a method to ensure editor stays in current mode
    func maintainEditingMode() {
        // This prevents the editing mode from changing unexpectedly
        shouldKeepEditing = true
        
        // Use a small buffer to ensure media references are established
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Ensure text editing mode persists if needed
            if self.editingMode == .text && self.textOverlays.isEmpty {
                // Create a text overlay if none exists
                self.addTextOverlay()
            } else if self.editingMode == .text && self.selectedTextOverlay == nil && !self.textOverlays.isEmpty {
                // Select the first text overlay if none is selected
                self.selectedTextOverlay = self.textOverlays.first?.id
            }
            
            print("Maintaining editing mode: \(self.editingMode)")
            
            // Reset after a delay to allow state to settle
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.animateToolTransition()
            }
        }
    }
    
    // Improve transform functionality
    func applyTransform(scale: CGFloat, offset: CGSize) {
        currentImageScale *= scale
        currentImageOffset = CGSize(
            width: currentImageOffset.width + offset.width,
            height: currentImageOffset.height + offset.height
        )
        print("Applied transform - scale: \(currentImageScale), offset: \(currentImageOffset)")
    }
    
    // New methods for enhanced transforms
    func rotateImage(angle: Angle) {
        // Implementation for image rotation
    }
    
    func flipImage(horizontal: Bool) {
        // Implementation for image flipping
    }
    
    // Override selectedImage setter to update cache
    func setSelectedImage(_ image: UIImage?) {
        // Use a longer buffer and ensure proper synchronization
        if let img = image {
            // Create strong local reference immediately
            self.imageCache = img
            
            // Direct assignment without delay to avoid race conditions
            self.selectedImage = img
            
            // Log the update
            print("📥 StoryCreationViewModel: Image reference cached and published")
            
            // If setting an image, clear any video reference
            self.selectedVideo = nil
            self.videoCache = nil
            
            // Set media preload flag
            self.isMediaPreloaded = true
        } else {
            self.selectedImage = nil
            self.imageCache = nil
        }
    }
    
    // Override selectedVideo setter to update cache
    func setSelectedVideo(_ url: URL?) {
        if let videoURL = url {
            // Create a strong local reference immediately
            self.videoCache = videoURL
            
            // Direct assignment without delay to avoid race conditions
            self.selectedVideo = videoURL
            print("📥 StoryCreationViewModel: Video reference cached and published")
            
            // If setting a video, clear any image reference
            self.selectedImage = nil
            self.imageCache = nil
            
            // Set media preload flag
            self.isMediaPreloaded = true
        } else {
            self.selectedVideo = nil
            self.videoCache = nil
        }
    }
    
    // Method to restore media reference if lost
    func restoreMediaReferences() {
        if selectedImage == nil && imageCache != nil {
            print("🔄 StoryCreationViewModel: Restoring image from cache")
            // Use dispatch group for synchronization
            let group = DispatchGroup()
            group.enter()
            
            DispatchQueue.main.async {
                self.selectedImage = self.imageCache
                group.leave()
            }
            
            group.notify(queue: .main) {
                print("✅ Image reference restored: \(self.selectedImage != nil)")
            }
        }
        
        if selectedVideo == nil && videoCache != nil {
            print("🔄 StoryCreationViewModel: Restoring video from cache")
            selectedVideo = videoCache
        }
    }
    
    // Method to clear all media
    func clearMedia() {
        selectedImage = nil
        selectedVideo = nil
        imageCache = nil
        videoCache = nil
        print("🗑️ StoryCreationViewModel: All media references cleared")
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension StoryCreationViewModel: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            DispatchQueue.main.async {
                self.error = error
                self.showErrorMessage = true
                self.errorMessage = "Failed to capture photo: \(error.localizedDescription)"
            }
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            DispatchQueue.main.async {
                self.showErrorMessage = true
                self.errorMessage = "Failed to process photo data"
            }
            return
        }
        
        DispatchQueue.main.async {
            self.selectedImage = image
            self.selectedVideo = nil
            self.mediaType = .image
            self.showCamera = false
            self.showCaptionField = true
        }
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate
extension StoryCreationViewModel: AVCaptureFileOutputRecordingDelegate {
    nonisolated func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        // Recording started
    }
    
    nonisolated func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        DispatchQueue.main.async {
            self.isRecording = false
        }
        
        if let error = error {
            DispatchQueue.main.async {
                self.error = error
                self.showErrorMessage = true
                self.errorMessage = "Failed to record video: \(error.localizedDescription)"
            }
            return
        }
        
        DispatchQueue.main.async {
            self.selectedVideo = outputFileURL
            self.selectedImage = nil
            self.mediaType = .video
            self.showCamera = false
            self.showCaptionField = true
        }
    }
}

// Define models for text overlays and drawing paths
struct TextOverlay: Identifiable {
    var id: UUID
    var text: String
    var position: CGPoint
    var fontSize: CGFloat
    var color: Color
    var rotation: CGFloat
    var fontName: String = "System" // Default font name
}

struct DrawingPath: Identifiable {
    var id: UUID
    var color: Color
    var lineWidth: CGFloat
    var points: [CGPoint]
} 
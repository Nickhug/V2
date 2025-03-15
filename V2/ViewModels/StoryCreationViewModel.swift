import Foundation
import SwiftUI
import Combine
import CoreLocation
import PhotosUI
import AVFoundation

// Import editor models directly
import SwiftUI

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
    @Published var _selectedTextOverlay: UUID? {
        didSet {
            if let overlayId = _selectedTextOverlay, oldValue != overlayId {
                // Auto-update editing mode to match selection
                if !editingMode.isTextMode || editingMode.selectedOverlayId != overlayId {
                    _internalSetEditingMode(.text(overlayId: overlayId))
                    shouldKeepEditing = true
                }
            } else if _selectedTextOverlay == nil && oldValue != nil {
                // Selection was cleared, but keep the text mode with nil selection
                if editingMode.isTextMode {
                    _internalSetEditingMode(.text(overlayId: nil))
                }
            }
        }
    }
    @Published var brushColor: Color = .white
    @Published var brushSize: CGFloat = 3.0
    @Published var drawingPaths: [DrawingPath] = []
    @Published var currentDrawingPath: DrawingPath?
    @Published var editingMode: EditingMode = .transform {
        willSet {
            // Force shouldKeepEditing to be true for all non-transform modes
            if case .transform = newValue {
                // Allow transform mode to not keep editing
            } else {
                shouldKeepEditing = true
            }
        }
        didSet {
            // Force stateManager to ensure consistency
            // No need for DispatchAsync since we're already on the main actor
            stateManager?.enforceStateConsistency()
        }
    }
    
    // History stacks for undo/redo
    @Published var drawingHistory: [[DrawingPath]] = []
    @Published var textHistory: [[TextOverlay]] = []
    @Published var drawingHistoryIndex: Int = 0
    @Published var textHistoryIndex: Int = 0
    
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
    
    // Add reference to the media processor service
    private let mediaProcessor = MediaProcessorService()
    
    // Add property to track processing progress
    @Published var processingProgress: Float = 0.0
    
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
    
    // Add stateManager property
    private var stateManager: OverlayStateManager!
    
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
    
    // Enum for editor modes - REPLACED with State Machine implementation
    enum EditingMode: Equatable {
        case transform
        case text(overlayId: UUID?)
        case draw
        case stickers
        
        // Prevent unwanted transitions
        func canTransitionTo(_ newMode: EditingMode) -> Bool {
            // Special case: Allow transform mode only when explicitly requested
            if case .transform = newMode {
                return true
            }
            
            // Prevent automatic deselection of text mode
            if case .text = self, case .transform = newMode {
                return false
            }
            
            // Prevent automatic deselection of draw mode
            if case .draw = self, case .transform = newMode {
                return false
            }
            
            // Always allow transitions between editing modes
            return true
        }
        
        // State information accessors
        var isTextMode: Bool {
            if case .text = self { return true }
            return false
        }
        
        var isDrawMode: Bool {
            if case .draw = self { return true }
            return false
        }
        
        var selectedOverlayId: UUID? {
            if case .text(let overlayId) = self { return overlayId }
            return nil
        }
    }
    
    init(storiesViewModel: StoriesViewModel) {
        self.storiesViewModel = storiesViewModel
        super.init()
        // Camera launches directly in the new design
        self.showCamera = true
        
        // Initialize the state manager immediately - no need for dispatch since we're on the main actor
        self.stateManager = OverlayStateManager(viewModel: self)
    }
    
    // MARK: - Editor Methods
    
    func addTextOverlay() {
        print("Adding new text overlay")
        // Ensure we're in text editing mode with no specific overlay yet
        
        // Save current state to history before adding
        saveTextHistory()
        
        // Create a new overlay with a stable UUID
        let overlayId = UUID()
        let newOverlay = TextOverlay(
            id: overlayId,
            text: "Tap to edit",
            position: CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2),
            fontSize: selectedFontSize,
            color: .white,
            rotation: .zero,
            fontName: selectedFontName
        )
        
        // Add to the collection
        textOverlays.append(newOverlay)
        
        // Set directly in the editing mode to ensure they stay linked
        editingMode = .text(overlayId: overlayId)
        shouldKeepEditing = true
        
        // Also set in the separate property for backward compatibility
        _selectedTextOverlay = overlayId
        
        print("Created new text overlay with ID: \(overlayId) using font: \(selectedFontName) size: \(selectedFontSize)")
        
        // Minimal animation to avoid state resets
        withAnimation(.easeInOut(duration: 0.2)) {
            toolTransitionActive = true
            // No nesting of animations or delayed state changes
        }
        
        // Reset animation flag after delay without touching other state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.toolTransitionActive = false
        }
    }
    
    func removeTextOverlay(id: UUID) {
        // Save current state to history before removal
        saveTextHistory()
        
        textOverlays.removeAll(where: { overlay in
            overlay.id == id
        })
        if _selectedTextOverlay == id {
            _selectedTextOverlay = nil
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
        if !drawingPaths.isEmpty && drawingHistoryIndex > 0 {
            drawingHistoryIndex -= 1
            drawingPaths = drawingHistory[drawingHistoryIndex]
            // Critical: Don't reset editing mode here
            shouldKeepEditing = true
        }
    }
    
    func redoDrawing() {
        if drawingHistoryIndex < drawingHistory.count - 1 {
            drawingHistoryIndex += 1
            drawingPaths = drawingHistory[drawingHistoryIndex]
            // Critical: Don't reset editing mode here
            shouldKeepEditing = true
        }
    }
    
    private func saveDrawingHistory() {
        // Remove any redo history if we're not at the end
        if drawingHistoryIndex < drawingHistory.count - 1 {
            drawingHistory = Array(drawingHistory.prefix(drawingHistoryIndex + 1))
        }
        
        // Add current state to history
        drawingHistory.append(drawingPaths)
        drawingHistoryIndex = drawingHistory.count - 1
    }
    
    private func saveTextHistory() {
        // Remove any redo history if we're not at the end
        if textHistoryIndex < textHistory.count - 1 {
            textHistory = Array(textHistory.prefix(textHistoryIndex + 1))
        }
        
        // Add current state to history
        textHistory.append(textOverlays)
        textHistoryIndex = textHistory.count - 1
    }
    
    func animateToolTransition() {
        // Set flag for UI animation
        toolTransitionActive = true
        
        // CRITICAL FIX: Immediately validate state first, before animation even starts
        validateOverlayState()
        
        // DO NOT reset the shouldKeepEditing flag - this is the key issue
        // Reset after animation duration - give more time for UI to stabilize
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.toolTransitionActive = false
            
            // IMPORTANT: Always validate overlay state, not just when shouldKeepEditing is true
            // This ensures we don't lose state during transitions
            self.validateOverlayState()
            
            // Force consistent state for text mode
            if self.editingMode.isTextMode {
                // Ensure we have a text overlay and selection
                if self.textOverlays.isEmpty {
                    self.addTextOverlay()
                } else if self._selectedTextOverlay == nil {
                    self._selectedTextOverlay = self.textOverlays.first?.id
                }
            }
            
            // Add debugging for tool transition completion
            print("🔄 Tool transition animation completed - Mode: \(self.editingMode), shouldKeepEditing: \(self.shouldKeepEditing)")
            
            // Run a second validation pass after a small delay to catch any state loss
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.validateOverlayState()
            }
        }
    }
    
    // New method to validate and preserve overlay state
    func validateOverlayState() {
        // Force check to make sure text overlay state is consistent
        if editingMode.isTextMode {
            // Critical fix: Create an overlay if needed - don't just select an existing one
            if textOverlays.isEmpty {
                print("🔄 Text mode active but no overlays - creating new overlay")
                addTextOverlay()
            } else if _selectedTextOverlay == nil {
                _selectedTextOverlay = textOverlays.first?.id
                print("🔍 Restored text selection state to \(String(describing: _selectedTextOverlay))")
            } else {
                // Verify the selected overlay still exists (it may have been deleted)
                let overlayExists = textOverlays.contains(where: { $0.id == _selectedTextOverlay })
                if !overlayExists {
                    _selectedTextOverlay = textOverlays.first?.id
                    print("🔄 Selected overlay no longer exists - selecting first available")
                }
            }
        }
        
        // Force check to make sure drawing state is consistent
        if editingMode.isDrawMode {
            // Ensure at least one path exists for visual feedback
            if drawingPaths.isEmpty && currentDrawingPath == nil {
                print("🔍 Drawing mode active but no paths - drawing tool still ready")
                shouldKeepEditing = true
            }
        }
        
        // Most important: Ensure shouldKeepEditing flag is properly set based on mode
        switch editingMode {
        case .text, .draw, .stickers:
            shouldKeepEditing = true
        default:
            break
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
        
        do {
            // Process based on media type
            if let image = selectedImage {
                // Use OverlayRenderingService to render overlays
                let renderingService = OverlayRenderingService.shared
                let hasOverlays = !renderingService.textOverlays.isEmpty || !renderingService.drawingPaths.isEmpty
                
                if hasOverlays {
                    // Process image with overlays using the rendering service
                    print("🖼️ Processing image with \(renderingService.textOverlays.count) text overlays and \(renderingService.drawingPaths.count) drawings")
                    
                    let processedImage = renderingService.renderOverlaysToImage(image)
                    
                    // Upload the processed image
                    success = await storiesViewModel.createImageStory(
                        image: processedImage,
                        caption: caption.isEmpty ? nil : caption,
                        location: location,
                        locationName: locationName
                    )
                } else {
                    // Upload the original image if no overlays
                    success = await storiesViewModel.createImageStory(
                        image: image,
                        caption: caption.isEmpty ? nil : caption,
                        location: location,
                        locationName: locationName
                    )
                }
            } else if let videoURL = selectedVideo {
                // For videos, we still use the mediaProcessor as video processing is more complex
                // Check if the video has overlays or drawings
                let renderingService = OverlayRenderingService.shared
                let hasOverlays = !renderingService.textOverlays.isEmpty || !renderingService.drawingPaths.isEmpty
                
                if hasOverlays {
                    // Show processing state
                    errorMessage = "Processing video..."
                    showErrorMessage = true
                    
                    // Convert rendering service overlays to legacy format for video processing
                    let legacyTextOverlays = renderingService.textOverlays.map { overlay -> TextOverlay in
                        return TextOverlay(
                            id: overlay.id,
                            text: overlay.text,
                            position: overlay.position,
                            fontSize: overlay.fontSize,
                            color: overlay.color,
                            rotation: Angle(radians: overlay.rotation.radians),
                            fontName: overlay.fontName
                        )
                    }
                    
                    let legacyDrawingPaths = renderingService.drawingPaths.map { path -> DrawingPath in
                        return DrawingPath(
                            id: path.id,
                            color: path.color,
                            lineWidth: path.lineWidth,
                            points: path.points
                        )
                    }
                    
                    // Process video with overlays
                    print("🎬 Processing video with \(renderingService.textOverlays.count) text overlays and \(renderingService.drawingPaths.count) drawings")
                    let processedVideoURL = try await mediaProcessor.processVideoWithOverlays(
                        videoURL: videoURL,
                        textOverlays: legacyTextOverlays,
                        drawingPaths: legacyDrawingPaths,
                        progressHandler: { [weak self] (progress: Float) in
                            DispatchQueue.main.async {
                                self?.processingProgress = progress
                                if self?.showErrorMessage == true {
                                    self?.errorMessage = "Processing video: \(Int(progress * 100))%"
                                }
                            }
                        }
                    )
                    
                    // Hide the processing message
                    showErrorMessage = false
                    
                    // Upload the processed video
                    success = await storiesViewModel.createVideoStory(
                        videoURL: processedVideoURL,
                        caption: caption.isEmpty ? nil : caption,
                        location: location,
                        locationName: locationName
                    )
                } else {
                    // Upload the original video if no overlays
                    success = await storiesViewModel.createVideoStory(
                        videoURL: videoURL,
                        caption: caption.isEmpty ? nil : caption,
                        location: location,
                        locationName: locationName
                    )
                }
            }
            
            // Reset state after successful upload
            if success {
                resetState()
            }
            
        } catch {
            print("❌ Error processing or uploading story: \(error)")
            errorMessage = "Failed to process or upload story: \(error.localizedDescription)"
            showErrorMessage = true
            success = false
        }
        
        isLoading = false
        return success
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
        _selectedTextOverlay = nil
        
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
        guard let selectedId = _selectedTextOverlay,
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
        
        // CRITICAL FIX: Don't nest asyncAfter calls that could reset state
        // Process immediately, then schedule only needed validations
        
        // Ensure text editing mode persists if needed
        if case .text = self.editingMode, self.textOverlays.isEmpty {
            // Create a text overlay if none exists
            self.addTextOverlay()
        } else if case .text = self.editingMode, self._selectedTextOverlay == nil, !self.textOverlays.isEmpty {
            // Select the first text overlay if none is selected
            self._selectedTextOverlay = self.textOverlays.first?.id
        }
        
        print("Maintaining editing mode: \(self.editingMode)")
        
        // CRITICAL FIX: Use multiple timed validation checks to ensure state persistence
        // This creates a cascading series of checks that help prevent state loss
        
        // First check - almost immediate (0.1s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if self.shouldKeepEditing {
                self.validateOverlayState()
            }
        }
        
        // Second check - medium delay (0.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if self.shouldKeepEditing {
                self.validateOverlayState()
            }
        }
        
        // Third check - longer delay (1.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Only validate state - do NOT trigger more animations or state changes
            if self.shouldKeepEditing {
                // Print current state for debugging
                print("📋 Current overlay state - Text overlays: \(self.textOverlays.count), Drawing paths: \(self.drawingPaths.count), Editing mode: \(self.editingMode)")
                
                // Re-validate state to ensure persistence
                self.validateOverlayState()
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
    
    // CRITICAL ADDITION: Create a safe method to change editing mode that prevents unwanted transitions
    func setEditingMode(_ newMode: EditingMode, force: Bool = false) {
        // Skip if no change needed
        if newMode == editingMode { return }
        
        // Check if transition is allowed (unless forced)
        if !force && !editingMode.canTransitionTo(newMode) {
            print("🛑 Blocked unsafe transition from \(editingMode) to \(newMode)")
            return
        }
        
        print("✅ Mode transition: \(editingMode) -> \(newMode)")
        
        // Process based on new mode
        switch newMode {
        case .text(let overlayId):
            let targetId = overlayId ?? textOverlays.first?.id
            
            // Create text overlay if needed
            if textOverlays.isEmpty {
                addTextOverlay()
                return // addTextOverlay will set the mode appropriately
            } else if let targetId = targetId {
                // We have overlays and a target ID
                _selectedTextOverlay = targetId
                editingMode = .text(overlayId: targetId)
            } else {
                // We have overlays but no specific target, select the first one
                _selectedTextOverlay = textOverlays.first?.id
                editingMode = .text(overlayId: textOverlays.first?.id)
            }
            
        case .draw:
            // Simply set the mode, drawing creation happens on touch
            editingMode = .draw
            
        case .stickers:
            editingMode = .stickers
            
        case .transform:
            // Only get here if transition was allowed
            editingMode = .transform
        }
        
        // Ensure shouldKeepEditing is set appropriately
        if case .transform = newMode {
            shouldKeepEditing = false
        } else {
            shouldKeepEditing = true
        }
        
        // Force immediate state persistence to prevent issues
        forceStatePersistence()
    }
    
    // Create a computed property that wraps _selectedTextOverlay
    var selectedTextOverlay: UUID? {
        get {
            // First check editing mode for the most accurate value
            if case .text(let overlayId) = editingMode, let overlayId = overlayId {
                return overlayId
            }
            // Fall back to the published property if not in text mode
            return _selectedTextOverlay
        }
        set {
            // Update both the backing property and potentially the editing mode
            _selectedTextOverlay = newValue
            // Note: No need to update editingMode here as the didSet on _selectedTextOverlay handles it
        }
    }
    
    // Helper method for internal editing mode changes that won't trigger recursion
    private func _internalSetEditingMode(_ newMode: EditingMode) {
        editingMode = newMode
    }
    
    // New method to force state persistence
    func forceStatePersistence() {
        stateManager?.enforceStateConsistency()
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

// Add a dedicated overlay state manager to prevent any state loss
@MainActor
class OverlayStateManager {
    private var timer: Timer?
    private weak var viewModel: StoryCreationViewModel?
    private var isActive = true
    
    init(viewModel: StoryCreationViewModel) {
        self.viewModel = viewModel
        startPersistenceTimer()
    }
    
    private func startPersistenceTimer() {
        // Create a timer that runs on the main thread but handles actor isolation correctly
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            // Capture self weakly to avoid retain cycles
            guard let self else { return }
            
            // Use Task with MainActor to properly handle actor isolation
            Task { @MainActor in
                // Now we're explicitly on the main actor so we can safely access isolated properties
                guard self.isActive, let _ = self.viewModel else { return }
                self.enforceStateConsistency()
            }
        }
    }
    
    func enforceStateConsistency() {
        guard let viewModel = viewModel else { return }
        
        // Forcefully maintain text editing mode if that's what we're supposed to be in
        if case .text = viewModel.editingMode {
            // Make sure shouldKeepEditing stays true
            viewModel.shouldKeepEditing = true
            
            // Get the selected overlay ID
            var overlayId: UUID? = nil
            if case .text(let id) = viewModel.editingMode {
                overlayId = id
            }
            
            // If we have text overlays but no selected overlay, select one
            if !viewModel.textOverlays.isEmpty && overlayId == nil {
                overlayId = viewModel.textOverlays.first?.id
                // Force reset the editing mode with this ID
                if let id = overlayId {
                    viewModel._selectedTextOverlay = id
                }
            }
            
            // If we have no text overlays but are in text mode, create one
            if viewModel.textOverlays.isEmpty {
                // Don't call the regular method as it might have state issues
                // Instead directly modify the arrays
                let newId = UUID()
                let newOverlay = TextOverlay(
                    id: newId,
                    text: "Tap to edit",
                    position: CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2),
                    fontSize: viewModel.selectedFontSize,
                    color: .white,
                    rotation: .zero,
                    fontName: viewModel.selectedFontName
                )
                viewModel.textOverlays.append(newOverlay)
                viewModel._selectedTextOverlay = newId
            }
            
            // Force synchronize the selected overlay with editing mode
            if case .text(let activeId) = viewModel.editingMode, 
               let activeId = activeId,
               viewModel._selectedTextOverlay != activeId {
                viewModel._selectedTextOverlay = activeId
            }
        }
        
        // Similarly for drawing mode
        if case .draw = viewModel.editingMode {
            viewModel.shouldKeepEditing = true
        }
        
        // For any non-transform mode, always keep editing
        if case .transform = viewModel.editingMode {
            // Transform mode is allowed to not be editing
        } else {
            viewModel.shouldKeepEditing = true
        }
    }
    
    func setActive(_ active: Bool) {
        isActive = active
    }
    
    deinit {
        timer?.invalidate()
        timer = nil
    }
} 
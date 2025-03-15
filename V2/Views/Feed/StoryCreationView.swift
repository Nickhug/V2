import SwiftUI
import PhotosUI
import AVKit
import CoreLocation
@preconcurrency import AVFoundation
import Photos
// Add specific import for camera components
// No import needed if CameraComponents.swift is part of the same module

// MARK: - Story Creation State
enum StoryCreationState {
    case camera
    case preloading
    case editor
}

// MARK: - Main StoryCreationView
struct StoryCreationView: View {
    @ObservedObject var viewModel: StoryCreationViewModel
    @Binding var isPresented: Bool
    
    // State management
    @State private var creationState: StoryCreationState = .camera
    @State private var isPreloadingMedia = false
    @State private var showEditor = false
    
    // Media references
    @State private var localImageRef: UIImage?
    @State private var localVideoRef: URL?
    
    @Environment(\.presentationMode) var presentationMode
    @State private var showPhotosPicker = false
    @State private var photoSelection: PhotosPickerItem? = nil
    @State private var showCaptionSheet = false
    @State private var processingMedia = false
    
    // Add a StateObject for the camera view model so it's lifecycle is tied to this view
    @StateObject private var cameraViewModel = CameraViewModel()
    
    @StateObject private var locationManager: LocationManager = LocationManager()
    
    var body: some View {
        ZStack {
            Group {
                if creationState == .camera {
                    ImprovedCameraPreviewWithOverlay(
                        model: cameraViewModel,
                        didCapturePhoto: { image in
                            guard let image = image else { return }
                            print("📸 Photo captured with size: \(image.size)")
                            
                            // Show haptic feedback
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            
                            // Create strong reference immediately
                            localImageRef = image
                            
                            // Use dispatch group to ensure proper synchronization
                            let group = DispatchGroup()
                            group.enter()
                            
                            // Update view model with captured image
                            viewModel.setSelectedImage(image)
                            
                            // Wait briefly to ensure image is set
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                // Verify image reference exists
                                guard viewModel.selectedImage != nil || localImageRef != nil else {
                                    print("⚠️ Failed to maintain image reference")
                                    return
                                }
                                
                                // Begin state transition
                                withAnimation {
                                    creationState = .preloading
                                    isPreloadingMedia = true
                                }
                                
                                group.leave()
                            }
                            
                            // Once image is set and state is updated, show editor
                            group.notify(queue: .main) {
                                // Final verification and recovery if needed
                                if viewModel.selectedImage == nil && localImageRef != nil {
                                    print("🔄 Restoring image reference before showing editor")
                                    viewModel.setSelectedImage(localImageRef)
                                }
                                
                                // Delay editor presentation slightly
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    withAnimation {
                                        creationState = .editor
                                        isPreloadingMedia = false
                                        showEditor = true
                                    }
                                }
                            }
                        },
                        didCaptureVideo: { videoURL in
                            print("🎥 Video captured at: \(videoURL)")
                            
                            // Show haptic feedback
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            
                            // Create strong reference and update view model
                            localVideoRef = videoURL
                            viewModel.mediaType = .video
                            viewModel.setSelectedVideo(videoURL)
                            
                            // Transition through states
                            withAnimation {
                                creationState = .preloading
                                isPreloadingMedia = true
                            }
                            
                            // Delay to show editor
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation {
                                    creationState = .editor
                                    isPreloadingMedia = false
                                    showEditor = true
                                }
                            }
                        }
                    )
                } else if creationState == .editor {
                    StoryEditorView(
                        viewModel: viewModel,
                        isPresented: $isPresented,
                        onShare: {
                            print("📤 Share button pressed in editor")
                            Task {
                                if await viewModel.uploadStory() {
                                    isPresented = false
                                }
                            }
                        },
                        onCancel: {
                            print("❌ Editor cancelled")
                            withAnimation {
                                creationState = .camera
                                showEditor = false
                            }
                        }
                    )
                }
            }
            
            // Preloading overlay
            if isPreloadingMedia {
                Color.black
                    .overlay(
                        VStack(spacing: 16) {
                            LoadingSpinner(color: .white, lineWidth: 3, size: 40)
                            Text("Preparing media...")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    )
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    // New method to handle media preloading before showing editor
    private func preloadMediaAndShowEditor() {
        print("🔄 Starting media preload process")
        print("📊 Current state:")
        print("  • Media type: \(viewModel.mediaType)")
        print("  • Selected image: \(viewModel.selectedImage != nil ? "exists" : "nil")")
        print("  • Selected video: \(viewModel.selectedVideo != nil ? "exists" : "nil")")
        print("  • Local video ref: \(localVideoRef != nil ? "exists" : "nil")")
        print("  • Show camera: \(creationState == .camera)")
        print("  • Show editor: \(creationState == .editor)")
        
        // Show preloading overlay
        withAnimation {
            creationState = .preloading
            print("🔄 Preloading overlay shown")
        }
        
        // Ensure we're on the main thread for state updates
        DispatchQueue.main.async {
            if viewModel.mediaType == .video {
                print("🎥 Handling video media type")
                
                // Check both view model and local reference
                let videoRef = viewModel.selectedVideo ?? localVideoRef
                
                guard let video = videoRef else {
                    print("❌ No valid video reference found")
                    withAnimation {
                        creationState = .camera
                    }
                    viewModel.errorMessage = "Failed to prepare video for editing"
                    viewModel.showErrorMessage = true
                    return
                }
                
                print("✅ Valid video reference found: \(video)")
                
                // Ensure both references are set
                localVideoRef = video
                viewModel.setSelectedVideo(video)
                
                print("📊 Video references synchronized:")
                print("  • Local ref exists: \(localVideoRef != nil)")
                print("  • Selected video exists: \(viewModel.selectedVideo != nil)")
                
                // Use a slight delay to ensure UI updates are complete
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        // Update state in correct order
                        creationState = .editor
                        isPreloadingMedia = false
                        showEditor = true
                        
                        print("📊 Final state after transition:")
                        print("  • Show camera: \(creationState == .camera)")
                        print("  • Show editor: \(creationState == .editor)")
                        print("  • Is preloading: \(creationState == .preloading)")
                    }
                }
            } else if viewModel.mediaType == .image {
                print("📸 Handling image media type")
                
                // Check both view model and local reference
                let imageRef = viewModel.selectedImage ?? localImageRef
                
                guard let image = imageRef else {
                    print("❌ No valid image reference found")
                    withAnimation {
                        creationState = .camera
                    }
                    viewModel.errorMessage = "Failed to prepare image for editing"
                    viewModel.showErrorMessage = true
                    return
                }
                
                print("✅ Valid image reference found")
                
                // Ensure both references are set
                localImageRef = image
                viewModel.setSelectedImage(image)
                
                print("📊 Image references synchronized:")
                print("  • Local ref exists: \(localImageRef != nil)")
                print("  • Selected image exists: \(viewModel.selectedImage != nil)")
                
                // Use a slight delay to ensure UI updates are complete
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        // Update state in correct order
                        creationState = .editor
                        isPreloadingMedia = false
                        showEditor = true
                        
                        print("📊 Final state after transition:")
                        print("  • Show camera: \(creationState == .camera)")
                        print("  • Show editor: \(creationState == .editor)")
                        print("  • Is preloading: \(creationState == .preloading)")
                    }
                }
            } else {
                print("❌ No media type selected")
                withAnimation {
                    creationState = .camera
                }
                viewModel.errorMessage = "No media selected for editing"
                viewModel.showErrorMessage = true
            }
        }
    }
    
    // Fix the attempt to recover media function - break up complex expressions
    private func attemptMediaRecovery() async -> Any? {
        let fileManager = FileManager.default
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let mediaDirectory = cachesDirectory.appendingPathComponent("StoryMedia", isDirectory: true)
        
        guard fileManager.fileExists(atPath: mediaDirectory.path) else {
            print("❌ Media directory does not exist")
            return nil
        }
        
        do {
            // Get all files in the directory
            let fileURLs = try fileManager.contentsOfDirectory(
                at: mediaDirectory, 
                includingPropertiesForKeys: [.creationDateKey],
                options: [.skipsHiddenFiles]
            )
            
            // Filter by image and video extensions
            let mediaFiles = fileURLs.filter { url in
                let ext = url.pathExtension.lowercased()
                return ext == "jpg" || ext == "jpeg" || ext == "png" || ext == "mov" || ext == "mp4"
            }
            
            // Exit early if no files found
            if mediaFiles.isEmpty {
                print("❌ No media files found in cache")
                return nil
            }
            
            // Get creation dates
            var filesWithDates: [(url: URL, date: Date)] = []
            for url in mediaFiles {
                if let date = try url.resourceValues(forKeys: [.creationDateKey]).creationDate {
                    filesWithDates.append((url: url, date: date))
                }
            }
            
            // Sort by creation date
            filesWithDates.sort { $0.date > $1.date }
            
            // Get the most recent file
            guard let mostRecent = filesWithDates.first else {
                print("❌ Could not determine most recent file")
                return nil
            }
            
            let mostRecentFile = mostRecent.url
            print("✅ Found most recent file: \(mostRecentFile.lastPathComponent)")
            
            // Try to load it based on type
            let fileExtension = mostRecentFile.pathExtension.lowercased()
            
            if fileExtension == "jpg" || fileExtension == "jpeg" || fileExtension == "png" {
                // Handle image files
                let imageData = try Data(contentsOf: mostRecentFile)
                guard let image = UIImage(data: imageData) else {
                    print("❌ Failed to create UIImage from data")
                    return nil
                }
                print("✅ Successfully loaded image from cache")
                return image
            } else if fileExtension == "mov" || fileExtension == "mp4" {
                // Handle video files
                if fileManager.fileExists(atPath: mostRecentFile.path) {
                    print("✅ Successfully found video in cache")
                    return mostRecentFile
                }
            }
            
            print("❌ Failed to load media from most recent file")
            return nil
        } catch {
            print("❌ Error searching cache: \(error.localizedDescription)")
            return nil
        }
    }
    
    private var placeholderView: some View {
        print("⚠️ No media to display in editor")
        return VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.yellow)
            Text("Media not available")
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

// MARK: - Camera Preview
struct CameraPreviewView: UIViewRepresentable {
    var session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.frame
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        // Ensure the session is running on a background thread
        if !session.isRunning {
            Task.detached(priority: .userInitiated) {
                // Verify we're not on the main thread
                dispatchPrecondition(condition: .notOnQueue(.main))
                await session.startRunning()
                print("📸 Started camera session from preview layer")
            }
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update the preview layer frame when the view size changes
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
        }
    }
}

// MARK: - Camera View Model
@MainActor
final class CameraViewModel: NSObject, ObservableObject, AVCaptureFileOutputRecordingDelegate {
    @Published var isRecording = false
    @Published var flashOn = false
    @Published var isSessionRunning = false
    @Published var setupError: String?
    @Published var cameraPermissionGranted = false
    @Published var cameraSetupProgress: Double = 0 // Track setup progress
    
    var session = AVCaptureSession()
    var photoOutput = AVCapturePhotoOutput()
    var videoOutput = AVCaptureMovieFileOutput()
    var currentDevice: AVCaptureDevice?
    var currentPosition: AVCaptureDevice.Position = .back
    private var sessionQueue = DispatchQueue(label: "camera.session.queue")
    
    // VideoCompletionHandler made public for ImprovedCameraView
    var videoCompletionHandler: ((URL?) -> Void)?
    
    // Strong reference to current delegate to prevent premature deallocation
    var currentPhotoCaptureDelegate: AVCapturePhotoCaptureDelegate?
    
    // Flag to track if deinitialization is in progress
    private var isBeingDeallocated = false
    
    // Add a counter for retry attempts
    private var setupAttempts = 0
    private let maxSetupAttempts = 3
    
    override init() {
        super.init()
        print("📸 CameraViewModel initialized")
        // Check camera permissions on init
        checkCameraPermission()
    }
    
    func createTempURL() -> URL? {
        let fileManager = FileManager.default
        do {
            // Use the app's cache directory for temporary files
            let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
            let mediaDirectory = cacheDirectory.appendingPathComponent("StoryMedia", isDirectory: true)
            
            // Create media directory if it doesn't exist
            if !fileManager.fileExists(atPath: mediaDirectory.path) {
                try fileManager.createDirectory(at: mediaDirectory, withIntermediateDirectories: true, attributes: nil)
            }
            
            // Create a unique filename with timestamp and UUID
            let fileName = "\(Date().timeIntervalSince1970)_\(UUID().uuidString).mov"
            let fileURL = mediaDirectory.appendingPathComponent(fileName)
            
            print("📸 Created temporary URL for video: \(fileURL.path)")
            return fileURL
        } catch {
            print("❌ Error creating temporary URL: \(error.localizedDescription)")
            return nil
        }
    }
    
    func checkCameraPermission() {
        print("📸 Checking camera permission")
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                print("📸 Camera permission already granted")
                DispatchQueue.main.async {
                    self.cameraPermissionGranted = true
                    self.cameraSetupProgress = 0.3 // Permission granted progress
                }
                // Only setup camera after permissions are confirmed
                self.setupCamera()
                
            case .notDetermined:
                print("📸 Requesting camera permission")
                DispatchQueue.main.async {
                    self.cameraSetupProgress = 0.1 // Starting permission request
                }
                
                // Request permission
                AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                    Task { @MainActor in
                        guard let self = self, !self.isBeingDeallocated else { 
                            print("📸 Camera permission callback - view model is being deallocated, aborting")
                            return 
                        }
                        
                        print("📸 Camera permission response: \(granted ? "granted" : "denied")")
                        self.cameraPermissionGranted = granted
                        self.cameraSetupProgress = granted ? 0.3 : 0 // Update progress
                        
                        if granted {
                            print("📸 Camera permission granted, setting up camera")
                            self.setupCamera()
                        } else {
                            print("❌ Camera permission denied")
                            self.setupError = "Camera permission is required to take photos"
                        }
                    }
                }
                
            case .denied, .restricted:
                print("❌ Camera permission denied or restricted")
                DispatchQueue.main.async {
                    self.cameraPermissionGranted = false
                    self.setupError = "Camera access was denied. Please enable camera access in Settings."
                    self.cameraSetupProgress = 0 // Reset progress
                }
                
            @unknown default:
                print("❓ Unknown camera permission status")
                DispatchQueue.main.async {
                    self.setupError = "Unknown camera permission status"
                    self.cameraSetupProgress = 0 // Reset progress
                }
        }
    }
    
    func setupCamera() {
        print("📸 Setting up camera")
        
        // Check if we're being deallocated
        if isBeingDeallocated {
            print("📸 Setup camera called while being deallocated, ignoring")
            return
        }
        
        // Reset session state
        isSessionRunning = false
        setupError = nil
        cameraSetupProgress = 0.4 // Starting setup process
        
        // Make sure we're on the session queue to avoid blocking the main thread
        Task.detached { [weak self] in
            await MainActor.run { [weak self] in
                guard let self = self, !self.isBeingDeallocated else { 
                    print("❌ Self is nil or being deallocated when setting up camera")
                    return 
                }
                
                // Increment setup attempts
                self.setupAttempts += 1
                
                // Make sure we're not already running a session
                if self.session.isRunning {
                    print("📸 Camera session already running, stopping first")
                    self.session.stopRunning()
                    self.isSessionRunning = false
                }
                
                // Clear any existing inputs/outputs before reconfiguring
                for input in self.session.inputs {
                    self.session.removeInput(input)
                }
                
                for output in self.session.outputs {
                    self.session.removeOutput(output)
                }
                
                self.cameraSetupProgress = 0.5 // Inputs/outputs cleared
                
                // Start configuration
                self.session.beginConfiguration()
                
                // Update progress
                self.cameraSetupProgress = 0.6 // Configuration started
                
                // Set up video input
                do {
                    guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: self.currentPosition) else {
                        print("❌ Failed to get camera device for position: \(self.currentPosition)")
                        self.setupError = "Failed to access camera device"
                        self.cameraSetupProgress = 0 // Reset progress on error
                        self.session.commitConfiguration()
                        return
                    }
                    
                    let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                    self.currentDevice = videoDevice
                    
                    if self.session.canAddInput(videoDeviceInput) {
                        self.session.addInput(videoDeviceInput)
                        print("📸 Added video input to session")
                        
                        self.cameraSetupProgress = 0.7 // Video input added
                    } else {
                        print("❌ Could not add video input to session")
                        self.setupError = "Failed to setup camera input"
                        self.cameraSetupProgress = 0 // Reset progress on error
                        self.session.commitConfiguration()
                        return
                    }
                } catch {
                    print("❌ Error creating video input: \(error.localizedDescription)")
                    self.setupError = "Error setting up camera: \(error.localizedDescription)"
                    self.cameraSetupProgress = 0 // Reset progress on error
                    self.session.commitConfiguration()
                    return
                }
                
                // Update progress
                self.cameraSetupProgress = 0.8 // Setup almost complete
                
                // Set up photo output
                if self.session.canAddOutput(self.photoOutput) {
                    self.session.addOutput(self.photoOutput)
                    print("📸 Added photo output to session")
                } else {
                    print("❌ Could not add photo output to session")
                    self.setupError = "Failed to setup camera output"
                    self.cameraSetupProgress = 0 // Reset progress on error
                    self.session.commitConfiguration()
                    return
                }
                
                // Set up video output
                if self.session.canAddOutput(self.videoOutput) {
                    self.session.addOutput(self.videoOutput)
                    print("📸 Added video output to session")
                } else {
                    print("⚠️ Could not add video output to session")
                    // Not critical if we're primarily taking photos
                }
                
                // Set session preset quality
                if self.session.canSetSessionPreset(.high) {
                    self.session.sessionPreset = .high
                    print("📸 Set session preset to high quality")
                }
                
                // Update progress
                self.cameraSetupProgress = 0.9 // Configuration complete
                
                self.session.commitConfiguration()
                print("📸 Camera configuration committed")
                
                // Start the session on the session queue
                if !self.session.isRunning && !self.isBeingDeallocated {
                    print("📸 Starting camera session")
                    
                    // COMPLETELY REWRITTEN APPROACH:
                    // 1. Capture all MainActor properties locally before entering Task
                    // 2. Use nonisolated Task to avoid actor isolation issues
                    // 3. Proper Swift 6 isolation safety
                    
                    // First capture everything we need from the MainActor scope
                    let capturedSession = self.session
                    
                    // Use sessionQueue instead of directly creating a Task for better isolation
                    sessionQueue.async {
                        // This closure is not @Sendable and runs on a background queue
                        // We're using our captured values to avoid isolation issues
                        Task {
                            // Start the session - it's truly async
                            capturedSession.startRunning()
                            
                            // Jump back to the MainActor for UI updates
                            await MainActor.run {
                                // Re-check isBeingDeallocated safely inside MainActor context 
                                guard !self.isBeingDeallocated else { return }
                                
                                self.isSessionRunning = capturedSession.isRunning
                                self.cameraSetupProgress = 1.0 // Setup complete
                                self.setupAttempts = 0 // Reset attempts on success
                                print("📸 Camera session running: \(self.isSessionRunning)")
                            }
                        }
                    }
                }
            }
        }
    }
    
    func stopSession() {
        print("📸 Stopping camera session")
        
        // Set flag to prevent any new operations
        isBeingDeallocated = true
        
        // Reset progress
        cameraSetupProgress = 0
        
        // Ensure we're not recording when stopping the session
        if isRecording {
            Task.detached { [weak self] in
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.videoOutput.stopRecording()
                    self.isRecording = false
                }
            }
        }
        
        // Stop session on background thread to avoid UI freezes
        Task.detached { [weak self] in
            await MainActor.run { [weak self] in
                guard let self = self else { 
                    print("📸 Self is nil when stopping session")
                    return 
                }
                
                if self.session.isRunning {
                    print("📸 Stopping running session")
                    self.session.stopRunning()
                    self.isSessionRunning = false
                    print("📸 Camera session stopped")
                } else {
                    print("📸 Session already stopped, no action needed")
                }
                
                // Clear delegates and references
                self.currentPhotoCaptureDelegate = nil
                self.videoCompletionHandler = nil
            }
        }
    }
    
    deinit {
        print("📸 CameraViewModel deinit - cleaning up")
        // Make sure we stop the session when this view model is deallocated
        isBeingDeallocated = true
        
        // We don't need to call stopSession here as it should be called by parent view
        // Instead, just clean up any strong references
        currentPhotoCaptureDelegate = nil
        videoCompletionHandler = nil
    }
    
    func switchCamera() {
        Task.detached { [weak self] in
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                
                print("📸 Switching camera")
                self.session.beginConfiguration()
                
                // Remove existing input
                for input in self.session.inputs {
                    if let deviceInput = input as? AVCaptureDeviceInput, 
                       deviceInput.device.hasMediaType(.video) {
                        self.session.removeInput(deviceInput)
                    }
                }
                
                // Toggle camera position
                self.currentPosition = self.currentPosition == .back ? .front : .back
                
                // Add new input
                do {
                    guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: self.currentPosition) else {
                        print("❌ Failed to get \(self.currentPosition) camera device")
                        self.session.commitConfiguration()
                        return
                    }
                    
                    let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                    self.currentDevice = videoDevice
                    
                    if self.session.canAddInput(videoDeviceInput) {
                        self.session.addInput(videoDeviceInput)
                        print("📸 Switched to \(self.currentPosition) camera")
                    } else {
                        print("❌ Could not add \(self.currentPosition) camera input to session")
                    }
                } catch {
                    print("❌ Error switching camera: \(error.localizedDescription)")
                }
                
                self.session.commitConfiguration()
            }
        }
    }
    
    func toggleFlash() {
        Task.detached { [weak self] in
            await MainActor.run { [weak self] in
                guard let self = self, let device = self.currentDevice, device.hasFlash else { 
                    print("📸 Flash not available")
                    return 
                }
                
                do {
                    try device.lockForConfiguration()
                    
                    // Toggle torch for video mode
                    if device.hasTorch && self.flashOn {
                        device.torchMode = .off
                        print("📸 Torch turned off")
                    } else if device.hasTorch {
                        try device.setTorchModeOn(level: AVCaptureDevice.maxAvailableTorchLevel)
                        print("📸 Torch turned on")
                    }
                    
                    // Toggle flash for photo mode
                    if self.photoOutput.supportedFlashModes.contains(.on) && self.flashOn {
                        print("📸 Flash set to off for future photos")
                    } else if self.photoOutput.supportedFlashModes.contains(.on) {
                        print("📸 Flash set to on for future photos")
                    }
                    
                    self.flashOn.toggle()
                    
                    device.unlockForConfiguration()
                } catch {
                    print("❌ Error toggling flash: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        print("📸 capturePhoto called")
        
        if !session.isRunning {
            print("❌ Camera session not running. Can't capture photo")
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }
        
        Task.detached { [weak self] in
            await MainActor.run { [weak self] in
                guard let self = self else { 
                    DispatchQueue.main.async {
                        print("❌ Self is nil, capturePhoto failed")
                        completion(nil)
                    }
                    return
                }
                
                let settings = AVCapturePhotoSettings()
                
                // Apply flash settings if flash is on and available
                if self.flashOn, 
                   let device = self.currentDevice, 
                   device.hasFlash,
                   self.photoOutput.supportedFlashModes.contains(.on) {
                    settings.flashMode = .on
                }
                
                print("📸 Capturing photo with settings: \(settings)")
                
                // Create delegate that will be retained until capture completes
                let delegate = CameraPhotoCaptureDelegate { image in
                    guard let capturedImage = image else {
                        print("❌ Photo capture failed, no image returned")
                        DispatchQueue.main.async {
                            completion(nil)
                        }
                        return
                    }
                    
                    // Create a file URL in the Documents directory
                    let fileManager = FileManager.default
                    let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
                    let mediaDirectory = cacheDirectory.appendingPathComponent("StoryMedia", isDirectory: true)
                    
                    // Create directory if it doesn't exist
                    if !fileManager.fileExists(atPath: mediaDirectory.path) {
                        do {
                            try fileManager.createDirectory(at: mediaDirectory, withIntermediateDirectories: true, attributes: nil)
                        } catch {
                            print("❌ Failed to create media directory: \(error.localizedDescription)")
                        }
                    }
                    
                    let imageFileName = "\(Date().timeIntervalSince1970)_\(UUID().uuidString).jpg"
                    let imageUrl = mediaDirectory.appendingPathComponent(imageFileName)
                    
                    // Ensure we have the highest quality JPEG
                    guard let imageData = capturedImage.jpegData(compressionQuality: 0.95) else {
                        print("❌ Failed to create JPEG data from captured image")
                        DispatchQueue.main.async {
                            completion(capturedImage) // Fall back to original if we can't create data
                        }
                        return
                    }
                    
                    do {
                        // Write to file
                        try imageData.write(to: imageUrl)
                        print("✅ Successfully saved captured image to: \(imageUrl.path)")
                        
                        // Read it back to ensure it's properly saved
                        let savedData = try Data(contentsOf: imageUrl)
                        guard let savedImage = UIImage(data: savedData) else {
                            print("⚠️ Saved image, but couldn't read it back. Using original capture.")
                            DispatchQueue.main.async {
                                completion(capturedImage)
                            }
                            return
                        }
                        
                        print("✅ Successfully verified image at: \(imageUrl.path)")
                        
                        // Ensure state updates happen on main thread in the correct order
                        DispatchQueue.main.async {
                            print("Photo capture completed, returning saved image")
                            completion(savedImage)
                        }
                    } catch {
                        print("❌ Failed to save captured image: \(error.localizedDescription)")
                        DispatchQueue.main.async {
                            // Fall back to original image if can't save
                            completion(capturedImage)
                        }
                    }
                }
                
                // Store delegate to avoid deallocation before capture completes
                self.currentPhotoCaptureDelegate = delegate
                
                self.photoOutput.capturePhoto(with: settings, delegate: delegate)
            }
        }
    }
    
    // Update the AVCaptureFileOutputRecordingDelegate methods to be nonisolated
    // to prevent actor isolation warnings in Swift 6
    nonisolated func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("📸 Started recording video to: \(fileURL.absoluteString)")
        // Recording started - already handled by isRecording property
    }
    
    nonisolated func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("❌ Error recording video: \(error.localizedDescription)")
            Task { @MainActor [weak self] in
                guard let self = self, !self.isBeingDeallocated else { return }
                self.videoCompletionHandler?(nil)
                self.videoCompletionHandler = nil
            }
            return
        }
        
        // Verify the video file exists and is valid
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: outputFileURL.path) else {
            print("❌ Video file doesn't exist at path: \(outputFileURL.path)")
            Task { @MainActor [weak self] in
                guard let self = self, !self.isBeingDeallocated else { return }
                self.videoCompletionHandler?(nil)
                self.videoCompletionHandler = nil
            }
            return
        }
        
        // Create a copy in the StoryMedia directory for persistence
        do {
            let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
            let mediaDirectory = cacheDirectory.appendingPathComponent("StoryMedia", isDirectory: true)
            
            // Create directory if it doesn't exist
            if !fileManager.fileExists(atPath: mediaDirectory.path) {
                try fileManager.createDirectory(at: mediaDirectory, withIntermediateDirectories: true, attributes: nil)
            }
            
            let fileName = "\(Date().timeIntervalSince1970)_\(UUID().uuidString).mov"
            let persistentURL = mediaDirectory.appendingPathComponent(fileName)
            
            // Copy the file
            try fileManager.copyItem(at: outputFileURL, to: persistentURL)
            print("📸 Copied video to persistent storage: \(persistentURL.path)")
            
            // Use the persistent URL for the completion handler
            print("📸 Video recording completed successfully at: \(persistentURL.absoluteString)")
            Task { @MainActor [weak self] in
                guard let self = self, !self.isBeingDeallocated else { return }
                self.videoCompletionHandler?(persistentURL)
                self.videoCompletionHandler = nil
            }
        } catch {
            print("❌ Error copying video to persistent storage: \(error.localizedDescription)")
            // Fall back to original URL if copy fails
            print("📸 Falling back to original video URL: \(outputFileURL.absoluteString)")
            Task { @MainActor [weak self] in
                guard let self = self, !self.isBeingDeallocated else { return }
                self.videoCompletionHandler?(outputFileURL)
                self.videoCompletionHandler = nil
            }
        }
    }
    
    func startRecording() {
        guard !isRecording else { 
            print("📸 Already recording")
            return 
        }
        
        // Check if we're being deallocated
        if isBeingDeallocated {
            print("📸 StartRecording called while being deallocated, ignoring")
            return
        }
        
        print("📸 Starting video recording")
        
        guard let url = createTempURL() else { 
            print("❌ Failed to create temp URL for video recording")
            return 
        }
        
        Task.detached { [weak self] in
            await MainActor.run { [weak self] in
                guard let self = self, !self.isBeingDeallocated else {
                    print("❌ Self is nil or being deallocated when starting recording")
                    return
                }
                
                print("📸 Starting recording to: \(url.absoluteString)")
                self.videoOutput.startRecording(to: url, recordingDelegate: self)
                self.isRecording = true
            }
        }
    }
    
    func stopRecording(completion: @escaping (URL?) -> Void) {
        guard isRecording else {
            print("📸 Not currently recording when stopRecording was called")
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }
        
        // Check if we're being deallocated
        if isBeingDeallocated {
            print("📸 StopRecording called while being deallocated, ignoring")
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }
        
        print("📸 Stopping video recording")
        videoCompletionHandler = { url in
            if let url = url {
                print("📸 Video recording completed successfully at: \(url.absoluteString)")
            } else {
                print("❌ Video recording failed to produce a valid URL")
            }
            DispatchQueue.main.async {
                completion(url)
            }
        }
        
        Task.detached { [weak self] in
            await MainActor.run { [weak self] in
                guard let self = self, !self.isBeingDeallocated else {
                    print("❌ Self is nil or being deallocated when stopping recording")
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                
                self.videoOutput.stopRecording()
                self.isRecording = false
            }
        }
    }
}

// MARK: - Camera Photo Capture Delegate
nonisolated class CameraPhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (UIImage?) -> Void
    
    init(completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
        super.init()
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        print("Photo output delegate called")
        
        if let error = error {
            print("Error capturing photo: \(error)")
            completion(nil)
            return
        }
        
        guard let imageData = photo.fileDataRepresentation() else {
            print("Failed to get image data representation")
            completion(nil)
            return
        }
        
        guard let image = UIImage(data: imageData) else {
            print("Failed to create UIImage from data")
            completion(nil)
            return
        }
        
        print("Photo captured successfully: \(image.size)")
        completion(image)
    }
}

// MARK: - Location Result Model
struct LocationResult: Identifiable {
    let id: UUID
    let name: String
    let subtitle: String?
    let coordinate: CLLocationCoordinate2D
}

// MARK: - StoryEditorView
struct StoryEditorView: View {
    @ObservedObject var viewModel: StoryCreationViewModel
    @Binding var isPresented: Bool
    var onShare: () -> Void
    var onCancel: () -> Void
    
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0
    @State private var activeTextEditId: UUID?
    @State private var textInput: String = ""
    @GestureState private var isDragging: Bool = false
    @State private var currentLocation: CGPoint = .zero
    @Environment(\.colorScheme) private var colorScheme
    
    // Add local strong references to media to prevent deallocation
    @State private var localImageRef: UIImage?
    @State private var localVideoRef: URL?
    
    // New state for controlling edit modes
    @State private var showTopEditTools: Bool = true
    @State private var selectedEditTool: EditingTool = .none
    
    // Define the available editing tools
    enum EditingTool: String, CaseIterable {
        case none = "None"
        case filter = "Filter"
        case adjust = "Adjust"
        case text = "Text"
        case sticker = "Sticker"
        case draw = "Draw"
        
        var icon: String {
            switch self {
            case .none: return ""
            case .filter: return "camera.filters"
            case .adjust: return "slider.horizontal.3"
            case .text: return "textformat"
            case .sticker: return "face.smiling"
            case .draw: return "scribble"
            }
        }
    }
    
    // Helper to convert font name to SwiftUI Font
    private func getFont(name: String, size: CGFloat) -> Font {
        switch name {
        case "System Bold":
            return .system(size: size, weight: .bold)
        case "System Italic":
            return .system(size: size, design: .serif).italic()
        case "Helvetica":
            return .custom("Helvetica", size: size)
        case "Arial":
            return .custom("Arial", size: size)
        case "Georgia":
            return .custom("Georgia", size: size)
        default:
            return .system(size: size)
        }
    }
    
    // MARK: - Media Recovery
    
    /// Attempts to recover the most recent media file from the cache directory
    private func attemptMediaRecovery() async -> Any? {
        let fileManager = FileManager.default
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let mediaDirectory = cachesDirectory.appendingPathComponent("StoryMedia", isDirectory: true)
        
        guard fileManager.fileExists(atPath: mediaDirectory.path) else {
            print("❌ Media directory does not exist")
            return nil
        }
        
        do {
            // Get all files in the directory
            let fileURLs = try fileManager.contentsOfDirectory(at: mediaDirectory, 
                                                             includingPropertiesForKeys: [.creationDateKey],
                                                             options: [.skipsHiddenFiles])
            
            // Filter by image and video extensions
            let mediaFiles = fileURLs.filter { url in
                let ext = url.pathExtension.lowercased()
                return ext == "jpg" || ext == "jpeg" || ext == "png" || ext == "mov" || ext == "mp4"
            }
            
            // Sort by creation date (most recent first)
            let sortedFiles = try mediaFiles.sorted { url1, url2 in
                let date1 = try url1.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                let date2 = try url2.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                return date1 > date2
            }
            
            // Get the most recent file
            guard let mostRecentFile = sortedFiles.first else {
                print("❌ No media files found in cache")
                return nil
            }
            
            print("✅ Found most recent file: \(mostRecentFile.lastPathComponent)")
            
            // Try to load it based on type
            let fileExtension = mostRecentFile.pathExtension.lowercased()
            
            if fileExtension == "jpg" || fileExtension == "jpeg" || fileExtension == "png" {
                // It's an image - try to load it
                if let imageData = try? Data(contentsOf: mostRecentFile),
                   let image = UIImage(data: imageData) {
                    print("✅ Successfully loaded image from cache")
                    return image
                }
            } else if fileExtension == "mov" || fileExtension == "mp4" {
                // It's a video - verify it exists
                if fileManager.fileExists(atPath: mostRecentFile.path) {
                    print("✅ Successfully found video in cache")
                    return mostRecentFile
                }
            }
            
            print("❌ Failed to load media from most recent file")
            return nil
        } catch {
            print("❌ Error searching cache: \(error.localizedDescription)")
            return nil
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background layer
                Color.black.edgesIgnoringSafeArea(.all)
                
                // Image or Video Layer directly in main ZStack with proper positioning
                mediaContentView(geometry: geometry)
                
                // Text overlays - extracted into separate method to simplify body
                textOverlaysView
                
                // UI Overlays
                VStack(spacing: 0) {
                    // Top navigation bar - extracted to a separate view
                    topNavigationBar(geometry: geometry)
                    
                    // Instagram-style editing tools - extracted to a separate view
                    if showTopEditTools && (viewModel.selectedImage != nil || viewModel.selectedVideo != nil || localImageRef != nil || localVideoRef != nil) {
                        editingToolsBar
                        
                        // Add filter/adjust controls if those tools are selected
                        if selectedEditTool == .filter {
                            FilterToolsView()
                        } else if selectedEditTool == .adjust {
                            AdjustToolsView()
                        }
                    }
                    
                    Spacer()
                    
                    // Only show bottom toolbar for specific editing modes - moved up from bottom with proper padding
                    if selectedEditTool == .text {
                        // Text editing toolbar
                        textEditingToolbar
                            .padding(.bottom, geometry.safeAreaInsets.bottom + 8)
                    } else if selectedEditTool == .draw {
                        // Drawing toolbar
                        drawingToolbar
                            .padding(.bottom, geometry.safeAreaInsets.bottom + 8)
                    } else if selectedEditTool == .sticker {
                        // Sticker toolbar
                        stickerToolbar
                            .padding(.bottom, geometry.safeAreaInsets.bottom + 8)
                    } else {
                        // Always show basic controls for videos to keep toolbar visible
                        if viewModel.mediaType == .video {
                            videoControlsToolbar
                                .padding(.bottom, geometry.safeAreaInsets.bottom + 8)
                        }
                    }
                }
                .edgesIgnoringSafeArea(.top)
                
                // Text editing overlay
                textEditingOverlay
                
                // Loading overlay
                if viewModel.isLoading {
                    loadingOverlay
                }
            }
            .preferredColorScheme(.dark)
            .statusBar(hidden: true)
            .onAppear {
                print("Story editor appeared")
                print("📊 Media Status on Appear:")
                print("  ➡️ viewModel.selectedImage: \(viewModel.selectedImage != nil ? "exists" : "nil")")
                print("  ➡️ viewModel.selectedVideo: \(viewModel.selectedVideo != nil ? "exists" : "nil")")
                print("  ➡️ localImageRef: \(localImageRef != nil ? "exists" : "nil")")
                print("  ➡️ localVideoRef: \(localVideoRef != nil ? "exists" : "nil")")
                
                // Verify media is preloaded and ensure toolbar is visible initially
                showTopEditTools = true
                
                if viewModel.selectedImage == nil && viewModel.selectedVideo == nil {
                    print("⚠️ Media not preloaded before showing editor")
                    
                    // Attempt recovery from local references
                    if let image = localImageRef {
                        print("🔄 Recovering from local image reference")
                        viewModel.setSelectedImage(image)
                    } else if let video = localVideoRef {
                        print("🔄 Recovering from local video reference")
                        viewModel.setSelectedVideo(video)
                    } else {
                        print("⚠️ Could not recover media references")
                    }
                }
                
                // Reset transform state
                scale = 1.0
                offset = .zero
                
                // Create local references if they don't exist but viewModel has media
                if let image = viewModel.selectedImage, localImageRef == nil {
                    localImageRef = image
                    print("📥 Created local image reference from viewModel")
                }
                
                if let video = viewModel.selectedVideo, localVideoRef == nil {
                    localVideoRef = video
                    print("📥 Created local video reference from viewModel")
                }
            }
            .onTapGesture {
                // Only toggle toolbar if we're not in a specific editing mode
                if selectedEditTool == .none && viewModel.mediaType == .image {
                    // Toggle visibility of top editing tools only for images
                    withAnimation {
                        showTopEditTools.toggle()
                    }
                } else if viewModel.mediaType == .video {
                    // For videos, always show toolbar
                    withAnimation {
                        showTopEditTools = true
                    }
                }
            }
        }
        .coordinateSpace(name: "container")
        .edgesIgnoringSafeArea(.all)
    }
    
    // Extract top navigation bar to a separate view
    private func topNavigationBar(geometry: GeometryProxy) -> some View {
        HStack {
            // Cancel button
            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Circle().fill(Color.black.opacity(0.5)))
            }
            .padding(.leading, 16)
            .padding(.top, 8)
            
            Spacer()
            
            // Next/Share button
            Button(action: shareButtonAction) {
                Text("Share")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.blue))
            }
            .padding(.trailing, 16)
            .padding(.top, 8)
            .disabled(viewModel.isLoading || (viewModel.selectedImage == nil && viewModel.selectedVideo == nil && localImageRef == nil && localVideoRef == nil))
        }
        .padding(.bottom, 8)
        .background(Color.black.opacity(0.3))
        .padding(.top, geometry.safeAreaInsets.top)
    }
    
    // Extract share button action to reduce complexity
    private func shareButtonAction() {
        // Ensure we have strong references to media before proceeding
        if viewModel.selectedImage == nil && localImageRef != nil {
            print("Restoring image reference before sharing")
            viewModel.setSelectedImage(localImageRef)
        }
        
        if viewModel.selectedVideo == nil && localVideoRef != nil {
            print("Restoring video reference before sharing")
            viewModel.setSelectedVideo(localVideoRef)
        }
        
        // Commit current transform
        viewModel.currentImageScale *= scale
        viewModel.currentImageOffset = CGSize(
            width: viewModel.currentImageOffset.width + offset.width,
            height: viewModel.currentImageOffset.height + offset.height
        )
        scale = 1.0
        offset = .zero
        
        // Share story
        onShare()
    }
    
    // Extract editing tools bar to a separate view
    private var editingToolsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(EditingTool.allCases.filter({ $0 != .none }), id: \.self) { tool in
                    editingToolButton(for: tool)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
        }
        .background(Color.black.opacity(0.3))
    }
    
    // Extract individual editing tool button
    private func editingToolButton(for tool: EditingTool) -> some View {
        VStack(spacing: 4) {
            Image(systemName: tool.icon)
                .font(.system(size: 20))
                .foregroundColor(selectedEditTool == tool ? .white : .white.opacity(0.7))
            
            Text(tool.rawValue)
                .font(.system(size: 12))
                .foregroundColor(selectedEditTool == tool ? .white : .white.opacity(0.7))
        }
        .frame(width: 60, height: 50)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(selectedEditTool == tool ? Color.white.opacity(0.3) : Color.clear)
        )
        .onTapGesture {
            handleToolSelection(tool)
        }
    }
    
    // Extract tool selection logic to reduce complexity
    private func handleToolSelection(_ tool: EditingTool) {
        // Capture for closure to avoid reference issues
        let selectedTool = tool
        
        // Add buffer to ensure media references are established
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeInOut(duration: 0.2)) {
                if selectedEditTool == selectedTool {
                    // Do nothing - keep the tool selected
                } else {
                    // Toggle on
                    selectedEditTool = selectedTool
                    
                    // Update the viewModel's editing mode to match
                    switch selectedTool {
                    case .text:
                        viewModel.editingMode = .text
                        // Maintain shouldKeepEditing state
                        viewModel.shouldKeepEditing = true
                        if viewModel.textOverlays.isEmpty {
                            viewModel.addTextOverlay()
                        } else if viewModel.selectedTextOverlay == nil {
                            viewModel.selectedTextOverlay = viewModel.textOverlays.first?.id
                        }
                    case .draw:
                        viewModel.editingMode = .draw
                    case .sticker:
                        viewModel.editingMode = .stickers
                    default:
                        viewModel.editingMode = .transform
                    }
                }
            }
        }
    }
    
    // MARK: - Toolbars
    
    // Text editing toolbar
    private var textEditingToolbar: some View {
        VStack(spacing: 8) {
            // Text color options
            HStack(spacing: 15) {
                let colors: [Color] = [.white, .yellow, .red, .blue, .green, .pink, .purple, .orange]
                
                ForEach(colors, id: \.self) { color in
                    Circle()
                        .fill(color)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 1)
                                .opacity(viewModel.selectedTextOverlay != nil && 
                                         viewModel.textOverlays.first(where: { $0.id == viewModel.selectedTextOverlay })?.color == color ? 1 : 0)
                        )
                        .onTapGesture {
                            if let selectedId = viewModel.selectedTextOverlay,
                               let index = viewModel.textOverlays.firstIndex(where: { $0.id == selectedId }) {
                                viewModel.textOverlays[index].color = color
                            } else if !viewModel.textOverlays.isEmpty {
                                viewModel.selectedTextOverlay = viewModel.textOverlays.first?.id
                            }
                        }
                }
            }
            .padding(.vertical, 8)
            
            // Font and size controls
            HStack(spacing: 20) {
                // Add text button
                Button(action: {
                    viewModel.addTextOverlay()
                }) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                
                // Font style toggle
                Button(action: {
                    let newFont = viewModel.selectedFontName == "System" ? "System Bold" : "System"
                    viewModel.updateTextFont(fontName: newFont)
                }) {
                    Image(systemName: "bold")
                        .font(.system(size: 18))
                        .foregroundColor(viewModel.selectedFontName == "System Bold" ? .white : .white.opacity(0.7))
                }
                
                // Font size adjust
                HStack(spacing: 15) {
                    Button(action: {
                        let newSize = max(16, viewModel.selectedFontSize - 4)
                        viewModel.updateTextFont(fontName: viewModel.selectedFontName, fontSize: newSize)
                    }) {
                        Image(systemName: "minus")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    }
                    
                    Button(action: {
                        let newSize = min(60, viewModel.selectedFontSize + 4)
                        viewModel.updateTextFont(fontName: viewModel.selectedFontName, fontSize: newSize)
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.5))
        .cornerRadius(12)
        .padding(.bottom, 10)
    }
    
    // Drawing toolbar
    private var drawingToolbar: some View {
        VStack(spacing: 8) {
            // Brush color options
            HStack(spacing: 15) {
                let brushColors: [Color] = [.white, .black, .yellow, .red, .blue, .green, .pink, .purple, .orange]
                
                ForEach(brushColors, id: \.self) { color in
                    Circle()
                        .fill(color)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 1)
                                .opacity(viewModel.brushColor == color ? 1 : 0)
                        )
                        .onTapGesture {
                            viewModel.brushColor = color
                        }
                }
            }
            .padding(.vertical, 8)
            
            // Brush size and controls
            HStack(spacing: 20) {
                // Clear button
                Button(action: {
                    viewModel.clearDrawings()
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 18))
                            .foregroundColor(.white)
                }
                
                // Undo button
                Button(action: {
                    if !viewModel.drawingPaths.isEmpty {
                        viewModel.undoLastDrawing()
                    }
                }) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                
                // Brush size
                HStack(spacing: 12) {
                    ForEach([3.0, 6.0, 10.0], id: \.self) { size in
                        Circle()
                            .fill(viewModel.brushColor)
                            .frame(width: size, height: size)
                            .padding(8)
                            .background(
                                Circle()
                                    .stroke(viewModel.brushSize == size ? Color.white : Color.clear, lineWidth: 1)
                            )
                            .onTapGesture {
                                viewModel.brushSize = size
                            }
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.5))
        .cornerRadius(12)
        .padding(.bottom, 10)
    }
    
    // Sticker toolbar (placeholder for now)
    private var stickerToolbar: some View {
        VStack {
            Text("Stickers Coming Soon")
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.5))
        .cornerRadius(12)
        .padding(.bottom, 10)
    }
    
    // Drawing canvas overlay
    private var drawingCanvasOverlay: some View {
        Group {
            if selectedEditTool == .draw {
                drawingCanvas
            }
        }
    }
    
    // Extract drawing canvas into its own property for better type-checking
    private var drawingCanvas: some View {
        Canvas { context, size in
            // Draw existing paths first
            drawCompletedPaths(in: context)
            
            // Then draw current path if exists
            drawCurrentPath(in: context)
        }
        .gesture(drawingGesture)
    }
    
    // Helper to draw all completed paths
    private func drawCompletedPaths(in context: GraphicsContext) {
        for path in viewModel.drawingPaths {
            let stroke = createStrokePath(from: path.points)
            context.stroke(stroke, with: .color(path.color), lineWidth: path.lineWidth)
        }
    }
    
    // Helper to draw current path
    private func drawCurrentPath(in context: GraphicsContext) {
        if let currentPath = viewModel.currentDrawingPath {
            let stroke = createStrokePath(from: currentPath.points)
            context.stroke(stroke, with: .color(currentPath.color), lineWidth: currentPath.lineWidth)
        }
    }
    
    // Helper to create a stroke path from points
    private func createStrokePath(from points: [CGPoint]) -> Path {
        var stroke = Path()
        if points.count >= 2 {
            stroke.move(to: points[0])
            for point in points.dropFirst() {
                stroke.addLine(to: point)
            }
        }
        return stroke
    }
    
    // Drawing gesture separated out
    private var drawingGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                let location = value.location
                
                if viewModel.currentDrawingPath == nil {
                    viewModel.startDrawing(at: location)
                } else {
                    viewModel.continueDrawing(to: location)
                }
            }
            .onEnded { _ in
                viewModel.endDrawing()
            }
    }
    
    // Text editing overlay
    private var textEditingOverlay: some View {
        Group {
            if let editId = activeTextEditId,
               let index = viewModel.textOverlays.firstIndex(where: { $0.id == editId }) {
                TextEditorOverlay(
                    text: $textInput,
                    textColor: viewModel.textOverlays[index].color,
                    fontName: viewModel.textOverlays[index].fontName,
                    fontSize: viewModel.textOverlays[index].fontSize,
                    getFont: getFont,
                    onDone: {
                        // Ensure we maintain text mode
                        viewModel.textOverlays[index].text = textInput
                        // Make sure we stay in text editing mode
                        viewModel.editingMode = .text
                        viewModel.shouldKeepEditing = true
                        DispatchQueue.main.async {
                            activeTextEditId = nil
                            // Ensure we have the right text overlay selected
                            viewModel.selectedTextOverlay = editId
                            viewModel.maintainEditingMode()
                        }
                    },
                    onColorChange: { color in
                        DispatchQueue.main.async {
                            viewModel.textOverlays[index].color = color
                            viewModel.maintainEditingMode()
                        }
                    },
                    onFontChange: { fontName in
                        DispatchQueue.main.async {
                            viewModel.updateTextFont(fontName: fontName)
                            viewModel.maintainEditingMode()
                        }
                    },
                    onSizeChange: { fontSize in
                        DispatchQueue.main.async {
                            viewModel.updateTextFont(fontName: viewModel.selectedFontName, fontSize: fontSize)
                            viewModel.maintainEditingMode()
                        }
                    },
                    availableFonts: viewModel.availableFonts,
                    availableFontSizes: viewModel.availableFontSizes
                )
            }
        }
    }
    
    // Loading overlay
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                LoadingSpinner(color: .white, lineWidth: 3, size: 50)
                
                Text("Uploading story...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
    }
    
    // Transform gesture
    private func transformGesture(geometry: GeometryProxy) -> some Gesture {
        let dragGesture = DragGesture()
            .updating($isDragging) { _, state, _ in
                state = true
            }
            .onChanged { value in
                self.offset = CGSize(
                    width: self.lastOffset.width + value.translation.width,
                    height: self.lastOffset.height + value.translation.height
                )
                // Ensure we stay in transform mode
                viewModel.maintainEditingMode()
            }
            .onEnded { value in
                self.lastOffset = self.offset
                // Apply transform to view model
                viewModel.applyTransform(scale: 1.0, offset: CGSize(
                    width: value.translation.width,
                    height: value.translation.height
                ))
            }
        
        let magnificationGesture = MagnificationGesture()
            .onChanged { value in
                self.scale = max(0.5, self.lastScale * value)
                // Ensure we stay in transform mode
                viewModel.maintainEditingMode()
            }
            .onEnded { value in
                self.lastScale = self.scale
                // Apply scale to view model
                viewModel.applyTransform(scale: value, offset: .zero)
            }
        
        return SimultaneousGesture(dragGesture, magnificationGesture)
    }
    
    // Extract media content view to simplify body
    @ViewBuilder
    private func mediaContentView(geometry: GeometryProxy) -> some View {
        if let image = localImageRef ?? viewModel.selectedImage {
            imageContentView(image: image, geometry: geometry)
                .onAppear {
                    print("📸 Image view appeared in editor")
                    // If viewModel is missing the reference but we have a local one, restore it
                    if viewModel.selectedImage == nil && localImageRef != nil {
                        print("🔄 Restoring image reference to viewModel")
                        viewModel.setSelectedImage(localImageRef)
                    }
                }
        } else if let video = localVideoRef ?? viewModel.selectedVideo {
            CustomVideoPlayerView(videoURL: video)
                .aspectRatio(contentMode: .fill)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .offset(offset)
                .scaleEffect(scale)
                .clipped()
                .onAppear {
                    print("🎥 Video view appeared in editor")
                    // If viewModel is missing the reference but we have a local one, restore it
                    if viewModel.selectedVideo == nil && localVideoRef != nil {
                        print("🔄 Restoring video reference to viewModel")
                        viewModel.setSelectedVideo(localVideoRef)
                    }
                    // Ensure toolbar remains visible for video
                    showTopEditTools = true
                }
        } else {
            placeholderView()
                .onAppear {
                    print("⚠️ No media to display in editor")
                    // Attempt one final recovery from disk cache
                    Task {
                        if let recovered = await attemptMediaRecovery() {
                            if let image = recovered as? UIImage {
                                print("✅ Recovered image from disk")
                                localImageRef = image
                                viewModel.setSelectedImage(image)
                            } else if let videoUrl = recovered as? URL {
                                print("✅ Recovered video from disk")
                                localVideoRef = videoUrl
                                viewModel.setSelectedVideo(videoUrl)
                            }
                        }
                    }
                }
        }
    }
    
    private func imageContentView(image: UIImage, geometry: GeometryProxy) -> some View {
        print("📸 Displaying image in editor")
        return Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .offset(offset)
            .scaleEffect(scale)
            .clipped()
    }
    
    // Add the missing placeholderView function
    private func placeholderView() -> some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.yellow)
            Text("Media not available")
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
    
    // MARK: - Video Player Implementation
    
    // Create a more robust video player using UIViewRepresentable
    struct CustomVideoPlayerView: UIViewRepresentable {
        let videoURL: URL
        @State private var playerItem: AVPlayerItem?
        
        // Use fileprivate instead of private to allow access within the file
        fileprivate var playerManager = PlayerManager()
        
        // Create a shared instance manager for static access
        private static let sharedPlayerManager = PlayerManager()
        
        // Get the player for this instance - use instance playerManager
        private var player: AVPlayer {
            playerManager.getPlayer(for: videoURL)
        }
        
        // Static accessor method to get a player for a URL - use sharedPlayerManager
        static func getPlayer(for url: URL) -> AVPlayer {
            return sharedPlayerManager.getPlayer(for: url)
        }
        
        // Static method to play/pause a specific video - use sharedPlayerManager
        static func togglePlayback(for url: URL, play: Bool) {
            let player = sharedPlayerManager.getPlayer(for: url)
            if play {
                player.play()
                print("🎬 Video playback resumed via static method")
            } else {
                player.pause()
                print("🎬 Video playback paused via static method")
            }
        }
        
        func makeUIView(context: Context) -> UIView {
            print("🎬 Creating video player view for URL: \(videoURL.lastPathComponent)")
            
            // Create container view
            let view = UIView(frame: .zero)
            view.backgroundColor = .black
            
            // Create player layer
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.videoGravity = .resizeAspectFill
            playerLayer.frame = view.bounds
            view.layer.addSublayer(playerLayer)
            
            // Store layer in coordinator
            context.coordinator.playerLayer = playerLayer
            
            // Configure player for looping
            context.coordinator.setupPlayerForLooping()
            
            // Start playback (auto-play)
            player.play()
            print("🎬 Video playback started")
            
            return view
        }
        
        func updateUIView(_ uiView: UIView, context: Context) {
            // Update the player layer frame when the view size changes
            if let playerLayer = context.coordinator.playerLayer {
                playerLayer.frame = uiView.bounds
            }
        }
        
        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }
        
        class Coordinator: NSObject {
            let parent: CustomVideoPlayerView
            var playerLayer: AVPlayerLayer?
            private var timeObserverToken: Any?
            private var itemEndObserver: NSObjectProtocol?
            private var playerItemObserver: NSKeyValueObservation?
            
            init(_ parent: CustomVideoPlayerView) {
                self.parent = parent
                super.init()
            }
            
            func setupPlayerForLooping() {
                // Remove any existing observers
                removeObservers()
                
                // Observe player item changes
                playerItemObserver = parent.player.observe(\.currentItem, options: [.new]) { [weak self] player, _ in
                    guard let self = self else { return }
                    
                    // Setup observation for the new item
                    if let item = player.currentItem {
                        self.observePlayerItem(item)
                    }
                }
                
                // Set up initial observation for current item
                if let currentItem = parent.player.currentItem {
                    observePlayerItem(currentItem)
                }
            }
            
            func observePlayerItem(_ item: AVPlayerItem) {
                // Remove existing end observer first
                if let itemEndObserver = itemEndObserver {
                    NotificationCenter.default.removeObserver(itemEndObserver)
                    self.itemEndObserver = nil
                }
                
                // Set up new observer for looping
                itemEndObserver = NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemDidPlayToEndTime,
                    object: item,
                    queue: .main
                ) { [weak self] _ in
                    // Restart playback from beginning when it reaches the end
                    self?.parent.player.seek(to: .zero)
                    self?.parent.player.play()
                    print("🎬 Video reached end, looping from beginning")
                }
            }
            
            func removeObservers() {
                // Remove time observer
                if let timeObserverToken = timeObserverToken {
                    parent.player.removeTimeObserver(timeObserverToken)
                    self.timeObserverToken = nil
                }
                
                // Remove end observer
                if let itemEndObserver = itemEndObserver {
                    NotificationCenter.default.removeObserver(itemEndObserver)
                    self.itemEndObserver = nil
                }
                
                // Remove player item observer
                playerItemObserver?.invalidate()
                playerItemObserver = nil
            }
            
            deinit {
                removeObservers()
                print("🎬 Video player coordinator cleaned up")
            }
        }
        
        static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
            print("🎬 Cleaning up video player resources")
            coordinator.removeObservers()
            coordinator.playerLayer?.removeFromSuperlayer()
            
            // Clean up the player resources when view is dismantled
            // Fixed conditional binding - videoURL is already non-optional
            let videoURL = coordinator.parent.videoURL
            
            // Clean up local instance
            coordinator.parent.playerManager.cleanupPlayer(for: videoURL)
            
            // Also clean up in shared manager
            CustomVideoPlayerView.sharedPlayerManager.cleanupPlayer(for: videoURL)
        }
    }
    
    // PlayerManager to handle shared player instances
    class PlayerManager: ObservableObject {
        private var players: [URL: AVPlayer] = [:]
        
        func getPlayer(for url: URL) -> AVPlayer {
            if let existingPlayer = players[url] {
                print("🎬 Using existing player for: \(url.lastPathComponent)")
                
                // Check if the player item is still valid, if not recreate it
                if existingPlayer.currentItem?.status == .failed || existingPlayer.currentItem == nil {
                    print("🎬 Existing player item is invalid, recreating...")
                    existingPlayer.replaceCurrentItem(with: AVPlayerItem(url: url))
                }
                
                return existingPlayer
            } else {
                print("🎬 Creating new player for: \(url.lastPathComponent)")
                let player = AVPlayer(url: url)
                
                // Add periodic time observer to keep player active
                let timeScale = CMTimeScale(NSEC_PER_SEC)
                let interval = CMTime(seconds: 0.5, preferredTimescale: timeScale)
                player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak player] _ in
                    // This keeps the player connection alive
                    if let player = player, player.timeControlStatus == .playing {
                        // Player is still active
                    }
                }
                
                players[url] = player
                return player
            }
        }
        
        func pauseAllPlayers() {
            for (_, player) in players {
                player.pause()
            }
        }
        
        func cleanupPlayer(for url: URL) {
            if let player = players[url] {
                player.pause()
                player.replaceCurrentItem(with: nil)
                players.removeValue(forKey: url)
                print("🎬 Player cleaned up for: \(url.lastPathComponent)")
            }
        }
        
        func cleanupAllPlayers() {
            for (url, player) in players {
                player.pause()
                player.replaceCurrentItem(with: nil)
                print("🎬 Player cleaned up for: \(url.lastPathComponent)")
            }
            players.removeAll()
            print("🎬 All players cleaned up")
        }
        
        deinit {
            print("🎬 PlayerManager being deallocated, cleaning up resources")
            cleanupAllPlayers()
        }
    }
    
    // Track video playback state
    @State private var isVideoPlaying: Bool = true
    
    // Video controls toolbar with play/pause functionality
    private var videoControlsToolbar: some View {
        HStack(spacing: 20) {
            Spacer()
            
            // Play/Pause button
            Button(action: {
                toggleVideoPlayback()
            }) {
                Image(systemName: isVideoPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.black.opacity(0.7)))
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
    
    // Toggle video playback
    private func toggleVideoPlayback() {
        if let videoURL = localVideoRef ?? viewModel.selectedVideo {
            isVideoPlaying.toggle()
            
            // Use the static accessor instead of direct access to private property
            CustomVideoPlayerView.togglePlayback(for: videoURL, play: isVideoPlaying)
        }
    }
    
    // Extract text overlays view to simplify body method
    @ViewBuilder
    private var textOverlaysView: some View {
        ZStack {
            ForEach(viewModel.textOverlays) { overlay in
                createTextOverlayView(for: overlay)
                    .position(x: overlay.position.x, y: overlay.position.y)
            }
        }
    }
    
    // Helper method to create a TextOverlayView for a specific overlay
    private func createTextOverlayView(for overlay: TextOverlay) -> some View {
        // Determine if this overlay is selected
        let isSelected = viewModel.selectedTextOverlay == overlay.id
        
        // Determine if editing is enabled for this overlay
        let isEditingEnabled = selectedEditTool == .text || 
                               (viewModel.editingMode == .text && selectedEditTool == .none)
        
        return TextOverlayView(
            overlay: overlay,
            isSelected: isSelected,
            isEditing: false, // Replace viewModel.isEditingText
            onTap: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.selectedTextOverlay = overlay.id
                    viewModel.shouldKeepEditing = true
                }
            },
            onDelete: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.removeTextOverlay(id: overlay.id)
                }
            },
            onMove: { newPosition in
                updateOverlayPosition(overlay: overlay, newPosition: newPosition)
            },
            onRotate: { angle in
                updateOverlayRotation(overlay: overlay, angle: angle)
            },
            onSelect: {
                viewModel.selectedTextOverlay = overlay.id
            },
            isEnabled: isEditingEnabled
        )
    }
    
    // Helper method to update overlay position
    private func updateOverlayPosition(overlay: TextOverlay, newPosition: CGPoint) {
        // Apply position update
        if let index = viewModel.textOverlays.firstIndex(where: { $0.id == overlay.id }) {
            var updatedOverlay = overlay
            updatedOverlay.position = newPosition
            viewModel.textOverlays[index] = updatedOverlay
        }
    }
    
    // Helper method to update overlay rotation
    private func updateOverlayRotation(overlay: TextOverlay, angle: Angle) {
        // Apply rotation update
        if let index = viewModel.textOverlays.firstIndex(where: { $0.id == overlay.id }) {
            var updatedOverlay = overlay
            updatedOverlay.rotation = angle.degrees
            viewModel.textOverlays[index] = updatedOverlay
        }
    }
}

// MARK: - Filter Tools View
struct FilterToolsView: View {
    // Example filters
    let filters = ["Normal", "Clarendon", "Gingham", "Moon", "Lark", "Reyes", "Juno", "Slumber", "Crema", "Ludwig"]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(filters, id: \.self) { filter in
                    VStack(spacing: 4) {
                        Circle()
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: 50, height: 50)
                        
                        Text(filter)
                            .font(.system(size: 11))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color.black.opacity(0.2))
    }
}

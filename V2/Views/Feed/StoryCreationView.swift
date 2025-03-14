import SwiftUI
import PhotosUI
import AVKit
import CoreLocation
@preconcurrency import AVFoundation
import Photos
// Add specific import for camera components
// No import needed if CameraComponents.swift is part of the same module

// MARK: - Main StoryCreationView
struct StoryCreationView: View {
    @ObservedObject var viewModel: StoryCreationViewModel
    @Binding var isPresented: Bool
    
    // Add state for tracking preloading status
    @State private var isPreloadingMedia: Bool = false
    @State private var showEditor: Bool = false
    
    @Environment(\.presentationMode) var presentationMode
    @State private var showPhotosPicker = false
    @State private var photoSelection: PhotosPickerItem? = nil
    @State private var showCaptionSheet = false
    @State private var processingMedia = false
    
    // Add local strong references to prevent deallocation
    @State private var localImageRef: UIImage?
    @State private var localVideoRef: URL?
    
    // Add a StateObject for the camera view model so it's lifecycle is tied to this view
    @StateObject private var cameraViewModel = CameraViewModel()
    
    @StateObject private var locationManager: LocationManager = LocationManager()
    
    var body: some View {
        ZStack {
            // Main content
            Group {
                if viewModel.showCamera {
                    // Use the ImprovedCameraPreviewWithOverlay directly
                    ImprovedCameraPreviewWithOverlay(
                        model: cameraViewModel,
                        didCapturePhoto: { image in
                            guard let image = image else { return }
                            print("📸 Photo captured with size: \(image.size)")
                            
                            // Show haptic feedback
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            
                            // Handle photo capture
                            viewModel.setSelectedImage(image)
                            viewModel.mediaType = .image
                            
                            // Show editing screen with preloading
                            preloadMediaAndShowEditor()
                        },
                        didCaptureVideo: { videoURL in
                            print("🎥 Video captured at: \(videoURL)")
                            
                            // Show haptic feedback
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            
                            // Handle video capture
                            viewModel.setSelectedVideo(videoURL)
                            viewModel.mediaType = .video
                            
                            // Show editing screen with preloading
                            preloadMediaAndShowEditor()
                        }
                    )
                } else if showEditor {
                    StoryEditorView(
                        viewModel: viewModel,
                        isPresented: $showEditor,
                        onShare: {
                            Task {
                                if await viewModel.uploadStory() {
                                    // Close the story creation view on success
                                    isPresented = false
                                }
                            }
                        },
                        onCancel: {
                            showEditor = false
                            viewModel.showCamera = true
                        }
                    )
                } else {
                    // Placeholder view - should not be visible
                    Color.black
                }
            }
            
            // Media preloading overlay if needed
            if isPreloadingMedia {
                ZStack {
                    Color.black
                        .edgesIgnoringSafeArea(.all)
                        .opacity(0.7)
                    
                    VStack(spacing: 16) {
                        LoadingSpinner(color: .white, lineWidth: 3, size: 40)
                        Text("Preparing media...")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .transition(.opacity)
            }
        }
        .onChange(of: viewModel.selectedImage) { oldValue, newValue in
            print("📐 selectedImage changed: \(newValue != nil ? "exists" : "nil")")
        }
        .onChange(of: viewModel.selectedVideo) { oldValue, newValue in
            print("📐 selectedVideo changed: \(newValue != nil ? "exists" : "nil")")
        }
        .onAppear {
            // Reset camera view on appear
            viewModel.showCamera = true
            showEditor = false
        }
    }
    
    // New method to handle media preloading before showing editor
    private func preloadMediaAndShowEditor() {
        // Show preloading overlay
        withAnimation {
            isPreloadingMedia = true
        }
        
        // Directly handle the media reference creation
        if viewModel.mediaType == .image {
            if let image = viewModel.selectedImage {
                // Create local reference
                localImageRef = image
                print("📥 Created local image reference before showing editor")
                
                // Show editor with a slight delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    withAnimation {
                        viewModel.showCamera = false
                        isPreloadingMedia = false
                        showEditor = true
                    }
                }
            } else {
                // Failed to get image
                withAnimation {
                    isPreloadingMedia = false
                }
                viewModel.errorMessage = "Failed to prepare image for editing"
                viewModel.showErrorMessage = true
            }
        } else if viewModel.mediaType == .video {
            if let videoURL = viewModel.selectedVideo {
                // Create local reference
                localVideoRef = videoURL
                print("📥 Created local video reference before showing editor")
                
                // Show editor with a slight delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    withAnimation {
                        viewModel.showCamera = false
                        isPreloadingMedia = false
                        showEditor = true
                    }
                }
            } else {
                // Failed to get video
                withAnimation {
                    isPreloadingMedia = false
                }
                viewModel.errorMessage = "Failed to prepare video for editing"
                viewModel.showErrorMessage = true
            }
        } else {
            // No media selected
            withAnimation {
                isPreloadingMedia = false
            }
            viewModel.errorMessage = "No media selected for editing"
            viewModel.showErrorMessage = true
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
                        DispatchQueue.main.async {
                            print("❌ Photo capture failed, no image returned")
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
        
        print("📸 Video recording completed successfully at: \(outputFileURL.absoluteString)")
        Task { @MainActor [weak self] in
            guard let self = self, !self.isBeingDeallocated else { return }
            self.videoCompletionHandler?(outputFileURL)
            self.videoCompletionHandler = nil
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
                    if showTopEditTools && (viewModel.selectedImage != nil || viewModel.selectedVideo != nil) {
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
                
                // Verify media is preloaded
                if viewModel.selectedImage == nil && viewModel.selectedVideo == nil {
                    print("⚠️ Media not preloaded before showing editor")
                    // Print message but continue
                    print("⚠️ Could not recover media references")
                }
                
                // Reset transform state
                scale = 1.0
                offset = .zero
                
                
                // Ensure we have local references to media - redundant but kept for safety
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if localImageRef == nil {
                        localImageRef = viewModel.selectedImage
                        if viewModel.selectedImage != nil {
                            print("📥 Created local image reference on appear")
                        }
                    }
                    
                    if localVideoRef == nil {
                        localVideoRef = viewModel.selectedVideo
                        if viewModel.selectedVideo != nil {
                            print("📥 Created local video reference on appear")
                        }
                    }
                }
            }
            .onTapGesture {
                // Only handle tap if not in editing mode
                if selectedEditTool == .none {
                    // Toggle visibility of top editing tools
                    withAnimation {
                        showTopEditTools.toggle()
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
        Group {
            if let image = viewModel.selectedImage ?? localImageRef {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .offset(offset)
                    .scaleEffect(scale)
                    .clipped()
            } else if let video = viewModel.selectedVideo ?? localVideoRef {
                VideoPlayer(player: AVPlayer(url: video))
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .offset(offset)
                    .scaleEffect(scale)
                    .clipped()
            }
        }
    }
    
    // Extract text overlays view to simplify body method
    @ViewBuilder
    private var textOverlaysView: some View {
        ZStack {
            ForEach(viewModel.textOverlays) { overlay in
                TextOverlayView(
                    overlay: overlay,
                    isSelected: viewModel.selectedTextOverlay == overlay.id,
                    isEditing: false, // Replace viewModel.isEditingText
                    onTap: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.selectedTextOverlay = overlay.id
                            viewModel.shouldKeepEditing = true
                        }
                    },
                    onDelete: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.removeTextOverlay(id: overlay.id) // Fix the method call
                        }
                    },
                    onMove: { newPosition in
                        // Apply position update
                        if let index = viewModel.textOverlays.firstIndex(where: { $0.id == overlay.id }) {
                            var updatedOverlay = overlay
                            updatedOverlay.position = newPosition
                            viewModel.textOverlays[index] = updatedOverlay
                        }
                    },
                    onRotate: { angle in
                        // Apply rotation update
                        if let index = viewModel.textOverlays.firstIndex(where: { $0.id == overlay.id }) {
                            var updatedOverlay = overlay
                            updatedOverlay.rotation = angle.degrees
                            viewModel.textOverlays[index] = updatedOverlay
                        }
                    },
                    onSelect: {
                        viewModel.selectedTextOverlay = overlay.id
                    },
                    isEnabled: selectedEditTool == .text || (viewModel.editingMode == .text && selectedEditTool == .none)
                )
                .position(x: overlay.position.x, y: overlay.position.y)
            }
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

// MARK: - Adjust Tools View
struct AdjustToolsView: View {
    let adjustments = ["Brightness", "Contrast", "Structure", "Warmth", "Saturation", "Color", "Fade", "Highlights", "Shadows", "Vignette", "Sharpen"]
    @State private var sliderValue: Double = 0.0
    @State private var selectedAdjustment: String = "Brightness"
    
    var body: some View {
        VStack(spacing: 0) {
            // Adjustment selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(adjustments, id: \.self) { adjustment in
                        Text(adjustment)
                            .font(.system(size: 13))
                            .foregroundColor(selectedAdjustment == adjustment ? .white : .white.opacity(0.7))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                selectedAdjustment == adjustment ?
                                    Color.white.opacity(0.2) :
                                    Color.clear
                            )
                            .cornerRadius(8)
                            .onTapGesture {
                                selectedAdjustment = adjustment
                            }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            
            // Adjustment slider
            HStack {
                Text("-")
                    .foregroundColor(.white)
                
                Slider(value: $sliderValue, in: -100...100, step: 1)
                    .accentColor(.white)
                
                Text("+")
                    .foregroundColor(.white)
                
                Text("\(Int(sliderValue))")
                    .foregroundColor(.white)
                    .frame(width: 40)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color.black.opacity(0.2))
    }
}

// MARK: - Text Overlay Views

struct TextOverlayView: View {
    let overlay: TextOverlay
    let isSelected: Bool
    let isEditing: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    let onMove: (CGPoint) -> Void
    let onRotate: (Angle) -> Void
    let onSelect: () -> Void
    let isEnabled: Bool
    
    @State private var position: CGPoint
    @State private var startRotation: Angle = .zero
    @GestureState private var rotation: Angle = .zero
    @GestureState private var isDragging: Bool = false
    
    init(overlay: TextOverlay, isSelected: Bool, isEditing: Bool, onTap: @escaping () -> Void, onDelete: @escaping () -> Void, onMove: @escaping (CGPoint) -> Void, onRotate: @escaping (Angle) -> Void, onSelect: @escaping () -> Void, isEnabled: Bool) {
        self.overlay = overlay
        self.isSelected = isSelected
        self.isEditing = isEditing
        self.onTap = onTap
        self.onDelete = onDelete
        self.onMove = onMove
        self.onRotate = onRotate
        self.onSelect = onSelect
        self.isEnabled = isEnabled
        self._position = State(initialValue: overlay.position)
    }
    
    var body: some View {
        ZStack {
            // Extract complex text configuration into separate properties
            textOverlayContent
            
            // Delete button when selected
            if isSelected {
                deleteButton
            }
        }
    }
    
    // Extract text content to simplify the body
    private var textOverlayContent: some View {
        Text(overlay.text)
            .font(getFont(name: overlay.fontName, size: overlay.fontSize))
            .foregroundColor(overlay.color)
            .fixedSize()
            .padding(isSelected ? 8 : 0)
            .background(selectionIndicator)
            .rotationEffect(Angle(radians: Double(overlay.rotation)) + rotation)
            .position(position)
            .opacity(isEditing ? 0 : 1)
            .modifier(GestureModifier(dragGesture: dragGesture, rotationGesture: rotationGesture))
            .onTapGesture {
                handleTap()
            }
    }
    
    // Extract background indicator for clarity
    private var selectionIndicator: some View {
        RoundedRectangle(cornerRadius: 3)
            .stroke(isSelected ? Color.white : Color.clear, lineWidth: 1)
            .background(Color.clear)
    }
    
    // Extract delete button
    private var deleteButton: some View {
        VStack {
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
            .offset(x: -50, y: -30)
        }
        .position(position)
    }
    
    // Extract drag gesture using concrete type
    private var dragGesture: _EndedGesture<_ChangedGesture<GestureStateGesture<DragGesture, Bool>>>? {
        if isSelected {
            return DragGesture(coordinateSpace: .named("container"))
                .updating($isDragging) { _, state, _ in
                    state = true
                }
                .onChanged { value in
                    self.position = value.location
                }
                .onEnded { value in
                    onMove(value.location)
                }
        } else {
            return nil
        }
    }
    
    // Extract rotation gesture using concrete type
    private var rotationGesture: _EndedGesture<GestureStateGesture<RotationGesture, Angle>>? {
        if isSelected {
            return RotationGesture()
                .updating($rotation) { angle, state, _ in
                    state = angle
                }
                .onEnded { angle in
                    onRotate(angle)
                }
        } else {
            return nil
        }
    }
    
    // Extract tap handler to simplify view
    private func handleTap() {
        if isSelected {
            // Force state to update on main thread to prevent disappearing
            DispatchQueue.main.async {
                onTap()
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
}

struct TextEditorOverlay: View {
    @Binding var text: String
    let textColor: Color
    let fontName: String
    let fontSize: CGFloat
    let getFont: (String, CGFloat) -> Font
    let onDone: () -> Void
    let onColorChange: (Color) -> Void
    let onFontChange: (String) -> Void
    let onSizeChange: (CGFloat) -> Void
    let availableFonts: [String]
    let availableFontSizes: [CGFloat]
    
    @State private var selectedColor: Color
    
    init(text: Binding<String>, textColor: Color, fontName: String, fontSize: CGFloat, getFont: @escaping (String, CGFloat) -> Font, onDone: @escaping () -> Void, onColorChange: @escaping (Color) -> Void, onFontChange: @escaping (String) -> Void, onSizeChange: @escaping (CGFloat) -> Void, availableFonts: [String], availableFontSizes: [CGFloat]) {
        self._text = text
        self.textColor = textColor
        self.fontName = fontName
        self.fontSize = fontSize
        self.getFont = getFont
        self.onDone = onDone
        self.onColorChange = onColorChange
        self.onFontChange = onFontChange
        self.onSizeChange = onSizeChange
        self._selectedColor = State(initialValue: textColor)
        self.availableFonts = availableFonts
        self.availableFontSizes = availableFontSizes
    }
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    onDone()
                }
            
            // Editor panel
            editorPanelView
        }
    }
    
    private var editorPanelView: some View {
        VStack(spacing: 20) {
            // Text field
            textFieldView
            
            // Font selection
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(availableFonts, id: \.self) { name in
                        Text("Aa")
                            .font(getFont(name, fontSize))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(fontName == name ? Color.blue.opacity(0.5) : Color.gray.opacity(0.3))
                            )
                        .onTapGesture {
                            onFontChange(name)
                        }
                    }
                }
            }
            
            // Font size selection
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(availableFontSizes, id: \.self) { size in
                        Text("\(Int(size))")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(fontSize == size ? Color.blue.opacity(0.5) : Color.gray.opacity(0.3))
                            )
                        .onTapGesture {
                            onSizeChange(size)
                        }
                    }
                }
            }
            
            // Color selection
            colorSelectionView
            
            // Done button
            doneButtonView
        }
        .padding(24)
        .background(Color(UIColor.systemGray6).opacity(0.9))
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }
    
    private var textFieldView: some View {
        TextField("Enter text", text: $text)
            .font(getFont(fontName, fontSize))
            .foregroundColor(selectedColor)
            .multilineTextAlignment(.center)
            .padding()
            .background(Color.black.opacity(0.5))
            .cornerRadius(12)
    }
    
    private var colorSelectionView: some View {
        HStack(spacing: 16) {
            ForEach(colorOptions, id: \.self) { color in
                colorCircleView(for: color)
            }
        }
    }
    
    private func colorCircleView(for color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: 30, height: 30)
            .overlay(
                Circle()
                    .stroke(selectedColor == color ? Color.white : Color.clear, lineWidth: 2)
            )
            .onTapGesture {
                selectedColor = color
                onColorChange(color)
            }
    }
    
    private var doneButtonView: some View {
        Button(action: onDone) {
            Text("Done")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 10)
                .background(Color.blue)
                .cornerRadius(20)
        }
        .padding(.top, 10)
    }
    
    private var colorOptions: [Color] {
        [.white, .yellow, .red, .blue, .green, .purple, .orange]
    }
}

// MARK: - Location Picker View
struct LocationPickerView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var locationManager = LocationManager()
    @State private var searchText = ""
    @State private var locations: [LocationResult] = []
    @State private var isSearching = false
    var onSelectLocation: (CLLocationCoordinate2D, String) -> Void
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack {
                // Custom navigation bar
                HStack {
                    Text("Add Location")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                }
                .padding()
                .background(Color.black.opacity(0.8))
                
                // Search bar
                TextField("Search location", text: $searchText)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    .onSubmit {
                        searchLocations()
                    }
                
                if isSearching {
                    ProgressView()
                        .tint(.white)
                        .padding()
                } else if !locations.isEmpty {
                    // Location results
                    List {
                        ForEach(locations) { location in
                            Button(action: {
                                onSelectLocation(location.coordinate, location.name)
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                HStack {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundColor(.blue)
                                    
                                    VStack(alignment: .leading) {
                                        Text(location.name)
                                            .foregroundColor(.white)
                                        
                                        if let subtitle = location.subtitle {
                                            Text(subtitle)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(PlainListStyle())
                } else {
                    // Current location button
                    Button(action: {
                        if let location = locationManager.location {
                            onSelectLocation(location.coordinate, "Current Location")
                            presentationMode.wrappedValue.dismiss()
                        }
                    }) {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.blue)
                            
                            Text("Use Current Location")
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .padding()
                    .disabled(locationManager.location == nil)
                    .opacity(locationManager.location == nil ? 0.5 : 1.0)
                    
                    Spacer()
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
        .statusBar(hidden: true)
        .onAppear {
            locationManager.requestLocation()
        }
    }
    
    private func searchLocations() {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        locations = []
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(searchText) { placemarks, error in
            isSearching = false
            
            if let error = error {
                print("Geocoding error: \(error)")
                return
            }
            
            guard let placemarks = placemarks else { return }
            
            locations = placemarks.compactMap { placemark in
                guard let name = placemark.name,
                      let location = placemark.location else {
                    return nil
                }
                
                var subtitle: String?
                if let locality = placemark.locality, let country = placemark.country {
                    subtitle = "\(locality), \(country)"
                } else if let country = placemark.country {
                    subtitle = country
                }
                
                return LocationResult(
                    id: UUID(),
                    name: name,
                    subtitle: subtitle,
                    coordinate: location.coordinate
                )
            }
        }
    }
}

// MARK: - Previews
struct StoryCreationView_Previews: PreviewProvider {
    static var previews: some View {
        StoryCreationView(viewModel: StoryCreationViewModel(storiesViewModel: StoriesViewModel()), isPresented: .constant(true))
    }
}

// MARK: - Gesture Helpers
// A completely different component-based approach to gesture handling

// Protocol for gesture application behavior
protocol GestureApplicator {
    associatedtype Content: View
    associatedtype Result: View
    func apply(to content: Content) -> Result
}

// Concrete implementation for no gestures
struct NoGestureApplicator<Content: View>: GestureApplicator {
    func apply(to content: Content) -> Content {
        content
    }
}

// Concrete implementation for single drag gesture
struct DragGestureApplicator<Content: View>: GestureApplicator {
    let gesture: DragGesture
    
    func apply(to content: Content) -> some View {
        content.gesture(gesture)
    }
}

// Concrete implementation for single rotation gesture
struct RotationGestureApplicator<Content: View>: GestureApplicator {
    let gesture: RotationGesture
    
    func apply(to content: Content) -> some View {
        content.gesture(gesture)
    }
}

// Concrete implementation for both gestures
struct CombinedGestureApplicator<Content: View>: GestureApplicator {
    let dragGesture: DragGesture
    let rotationGesture: RotationGesture
    
    func apply(to content: Content) -> some View {
        content
            .simultaneousGesture(dragGesture)
            .simultaneousGesture(rotationGesture)
    }
}

// Type-erasing modifier that selects the appropriate applicator
struct GestureModifier: ViewModifier {
    // Store concrete typed gestures instead of type-erased ones
    private var dragGesture: DragGesture?
    private var rotationGesture: RotationGesture?
    
    // Public initializer takes the original types for compatibility
    init(dragGesture: (any Gesture)?, rotationGesture: (any Gesture)?) {
        // Cast to concrete types if possible, otherwise nil
        self.dragGesture = dragGesture as? DragGesture
        self.rotationGesture = rotationGesture as? RotationGesture
    }
    
    func body(content: Content) -> some View {
        // Choose the right concrete applicator based on available gestures
        if let drag = dragGesture, let rotation = rotationGesture {
            CombinedGestureApplicator(dragGesture: drag, rotationGesture: rotation)
                .apply(to: content)
        } else if let drag = dragGesture {
            DragGestureApplicator(gesture: drag)
                .apply(to: content)
        } else if let rotation = rotationGesture {
            RotationGestureApplicator(gesture: rotation)
                .apply(to: content)
        } else {
            NoGestureApplicator()
                .apply(to: content)
        }
    }
}


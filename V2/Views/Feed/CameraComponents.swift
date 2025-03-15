import SwiftUI
import AVFoundation
import Combine

// MARK: - Camera View
struct ImprovedCameraView: UIViewRepresentable {
    @ObservedObject var model: CameraViewModel
    var photoMode: Bool
    var didCapturePhoto: ((UIImage?) -> Void)?
    var didCaptureVideo: ((URL) -> Void)?
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: model.session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.frame
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Coordinator
    class Coordinator: NSObject {
        let parent: ImprovedCameraView
        
        init(_ parent: ImprovedCameraView) {
            self.parent = parent
            super.init()
        }
    }
}

// MARK: - Camera Preview
struct CameraPreview: View {
    @ObservedObject var model: CameraViewModel
    @State private var selectedMode: CameraMode = .photo
    
    var didCapturePhoto: ((UIImage?) -> Void)?
    var didCaptureVideo: ((URL) -> Void)?
    
    enum CameraMode {
        case photo, video
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Camera View
                if model.cameraPermissionGranted {
                    ImprovedCameraView(
                        model: model,
                        photoMode: selectedMode == .photo,
                        didCapturePhoto: didCapturePhoto,
                        didCaptureVideo: didCaptureVideo
                    )
                } else {
                    // Permission denied view
                    VStack {
                        Text("Camera Access Required")
                            .font(.headline)
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                }
                
                // Controls overlay
                if model.cameraPermissionGranted {
                    VStack {
                        Spacer()
                        // Basic capture button
                        Button(action: {
                            if selectedMode == .photo {
                                model.capturePhoto { image in
                                    didCapturePhoto?(image)
                                }
                            }
                        }) {
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                                .frame(width: 72, height: 72)
                        }
                        .padding(.bottom, 30)
                    }
                }
            }
        }
        .onAppear {
            model.checkCameraPermission()
        }
    }
}

// MARK: - Camera Preview with Controls
struct ImprovedCameraPreviewWithOverlay: View {
    @ObservedObject var model: CameraViewModel
    @State private var selectedMode: CameraMode = .photo
    @State private var isCapturing = false
    
    // Add state for zoom selection
    @State private var selectedZoomOption: CameraViewModel.ZoomOption?
    
    var didCapturePhoto: ((UIImage?) -> Void)?
    var didCaptureVideo: ((URL) -> Void)?
    
    enum CameraMode {
        case photo, video
    }
    
    var body: some View {
        ZStack {
            // Camera view with permission checks
            GeometryReader { geometry in
                ZStack {
                    // Camera permission check
                    if !model.cameraPermissionGranted {
                        // Camera access required view
                        VStack(spacing: 20) {
                            Image(systemName: "camera.slash.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                            
                            Text("Camera Access Required")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text(model.setupError ?? "To take photos and videos, please allow access to your camera in Settings.")
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal)
                            
                            Button(action: {
                                // Open settings
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Text("Open Settings")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.white)
                                    .cornerRadius(8)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black)
                    } else if let error = model.setupError {
                        // Camera error view
                        VStack(spacing: 20) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.yellow)
                            
                            Text("Camera Error")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text(error)
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal)
                            
                            Button(action: {
                                // Retry camera setup
                                model.setupCamera()
                            }) {
                                Text("Retry")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.white)
                                    .cornerRadius(8)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black)
                    } else {
                        // Camera preview with UIViewRepresentable
                        ImprovedCameraView(model: model, photoMode: selectedMode == .photo, didCapturePhoto: didCapturePhoto, didCaptureVideo: didCaptureVideo)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                        
                        // Camera initializing overlay
                        if model.cameraSetupProgress < 1.0 {
                            ZStack {
                                Color.black
                                    .ignoresSafeArea()
                                
                                VStack(spacing: 20) {
                                    // Progress indicator
                                    if model.cameraSetupProgress > 0 {
                                        ProgressView(value: model.cameraSetupProgress, total: 1.0)
                                            .progressViewStyle(LinearProgressViewStyle())
                                            .frame(width: 200)
                                            .tint(.white)
                                    } else {
                                        ImprovedLoadingSpinner(color: .white, lineWidth: 3, size: 50)
                                    }
                                    
                                    Text("Initializing camera...")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                            }
                            .transition(.opacity)
                        }
                        
                        // Camera controls (only show when camera is ready)
                        if model.isSessionRunning && model.cameraSetupProgress >= 1.0 {
                            // Camera controls overlay
                            VStack {
                                // Top controls
                                HStack {
                                    Spacer()
                                    
                                    // Flash button
                                    Button(action: {
                                        model.flashOn.toggle()
                                    }) {
                                        Image(systemName: model.flashOn ? "bolt.fill" : "bolt.slash.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.white)
                                            .frame(width: 40, height: 40)
                                            .background(Color.black.opacity(0.5))
                                            .clipShape(Circle())
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    // Toggle camera button
                                    Button(action: {
                                        // Switch camera
                                        withAnimation {
                                            model.switchCamera()
                                        }
                                    }) {
                                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                                            .font(.system(size: 20))
                                            .foregroundColor(.white)
                                            .frame(width: 40, height: 40)
                                            .background(Color.black.opacity(0.5))
                                            .clipShape(Circle())
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(.horizontal, 10)
                                }
                                .padding(.horizontal)
                                .padding(.top, 8)
                                
                                Spacer()
                                
                                // Bottom Controls Section
                                VStack(spacing: 20) {
                                    // Add zoom selector above the capture buttons
                                    ZoomSelectorView(model: model, selectedOption: $selectedZoomOption)
                                        .padding(.bottom, 12)
                                    
                                    // Mode selector (photo/video)
                                    HStack {
                                        Spacer()
                                        
                                        // Photo mode button
                                        Button(action: {
                                            selectedMode = .photo
                                        }) {
                                            Text("Photo")
                                                .font(.subheadline)
                                                .fontWeight(selectedMode == .photo ? .bold : .regular)
                                                .foregroundColor(selectedMode == .photo ? .white : .white.opacity(0.6))
                                                .padding(.vertical, 8)
                                                .padding(.horizontal, 16)
                                                .background(selectedMode == .photo ? Color.white.opacity(0.3) : Color.clear)
                                                .cornerRadius(16)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        
                                        // Video mode button
                                        Button(action: {
                                            selectedMode = .video
                                        }) {
                                            Text("Video")
                                                .font(.subheadline)
                                                .fontWeight(selectedMode == .video ? .bold : .regular)
                                                .foregroundColor(selectedMode == .video ? .white : .white.opacity(0.6))
                                                .padding(.vertical, 8)
                                                .padding(.horizontal, 16)
                                                .background(selectedMode == .video ? Color.white.opacity(0.3) : Color.clear)
                                                .cornerRadius(16)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        
                                        Spacer()
                                    }
                                    .padding(.bottom, 20)
                                    
                                    // Capture button row
                                    HStack {
                                        Spacer()
                                        
                                        // Capture button
                                        Button(action: {
                                            isCapturing = true
                                            
                                            if selectedMode == .photo {
                                                // Capture photo with feedback
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    // Flash animation
                                                    let flashView = UIView(frame: UIScreen.main.bounds)
                                                    flashView.backgroundColor = .white
                                                    flashView.alpha = 0.8
                                                    
                                                    // Get the active window scene
                                                    if let windowScene = UIApplication.shared.connectedScenes
                                                        .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
                                                       let window = windowScene.windows.first {
                                                        window.addSubview(flashView)
                                                        
                                                        UIView.animate(withDuration: 0.2, animations: {
                                                            flashView.alpha = 0
                                                        }) { _ in
                                                            flashView.removeFromSuperview()
                                                        }
                                                    }
                                                }
                                                
                                                // Haptic feedback
                                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                                generator.prepare()
                                                generator.impactOccurred()
                                                
                                                model.capturePhoto { image in
                                                    DispatchQueue.main.async {
                                                        if let image = image {
                                                            // Trigger completion handler on main thread
                                                            didCapturePhoto?(image)
                                                            
                                                            // Success haptic
                                                            let successGenerator = UINotificationFeedbackGenerator()
                                                            successGenerator.notificationOccurred(.success)
                                                        } else {
                                                            // Error haptic
                                                            let errorGenerator = UINotificationFeedbackGenerator()
                                                            errorGenerator.notificationOccurred(.error)
                                                        }
                                                        isCapturing = false
                                                    }
                                                }
                                            } else {
                                                // Toggle video recording
                                                if !model.isRecording {
                                                    model.startRecording { url in
                                                        if let url = url {
                                                            didCaptureVideo?(url)
                                                        }
                                                        isCapturing = false
                                                    }
                                                } else {
                                                    model.stopRecording()
                                                }
                                            }
                                        }) {
                                            ZStack {
                                                Circle()
                                                    .stroke(Color.white, lineWidth: 3)
                                                    .frame(width: 72, height: 72)
                                                
                                                if selectedMode == .video && model.isRecording {
                                                    // Recording indicator
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .fill(Color.red)
                                                        .frame(width: 26, height: 26)
                                                } else {
                                                    Circle()
                                                        .fill(Color.white)
                                                        .frame(width: 66, height: 66)
                                                }
                                            }
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .disabled(isCapturing && selectedMode == .photo)
                                        
                                        Spacer()
                                    }
                                    .padding(.bottom, 30)
                                }
                            }
                        }
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .background(Color.black)
            }
        }
        .onAppear {
            // Make sure camera is set up when view appears
            if model.cameraSetupProgress < 0.3 {
                model.checkCameraPermission()
            }
            
            // Initialize the default zoom option
            selectedZoomOption = model.zoomOptions.first(where: { $0.isDefault }) ?? model.zoomOptions[1]
        }
    }
}

// MARK: - Improved Loading Spinner
struct ImprovedLoadingSpinner: View {
    var color: Color = .blue
    var lineWidth: CGFloat = 2
    var size: CGFloat = 40
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.75)
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .frame(width: size, height: size)
            .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
            .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Photo Capture Processor
class PhotoCaptureProcessor: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (UIImage?) -> Void
    
    init(completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
        super.init()
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("❌ Error capturing photo: \(error.localizedDescription)")
            completion(nil)
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("❌ Failed to convert photo data to UIImage")
            completion(nil)
            return
        }
        
        completion(image)
    }
}

// MARK: - Camera View Model Extensions
extension CameraViewModel {
    // Add these methods if they don't exist in the original CameraViewModel
    
    func startRecording(completion: @escaping (URL?) -> Void) {
        guard session.isRunning, !isRecording else {
            print("❌ Cannot start recording - session not running or already recording")
            completion(nil)
            return
        }
        
        // Create temporary URL for video
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "video_\(Date().timeIntervalSince1970).mov"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        // Start recording
        videoOutput.startRecording(to: fileURL, recordingDelegate: self)
        
        // Store completion handler
        videoCompletionHandler = completion
        
        // Update state
        DispatchQueue.main.async {
            self.isRecording = true
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        videoOutput.stopRecording()
        
        // Update state
        DispatchQueue.main.async {
            self.isRecording = false
        }
    }
}

// MARK: - Zoom Selector View
struct ZoomSelectorView: View {
    @ObservedObject var model: CameraViewModel
    @Binding var selectedOption: CameraViewModel.ZoomOption?
    
    // Animation state
    @State private var showZoomOptions: Bool = false
    
    var body: some View {
        ZStack {
            // Main zoom selector button when options are hidden
            if !showZoomOptions {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showZoomOptions = true
                    }
                }) {
                    ZStack {
                        // Background
                        Circle()
                            .fill(Color.black.opacity(0.5))
                            .frame(width: 36, height: 36)
                        
                        // Zoom Text
                        Text(selectedOption?.name ?? "1x")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                // Expanded horizontal zoom options
                HStack(spacing: 20) {
                    ForEach(model.zoomOptions) { option in
                        Button(action: {
                            selectZoomOption(option)
                        }) {
                            ZStack {
                                // Background
                                Circle()
                                    .fill(option.id == selectedOption?.id ? Color.white : Color.black.opacity(0.5))
                                    .frame(width: 36, height: 36)
                                
                                // Zoom Text
                                Text(option.name)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(option.id == selectedOption?.id ? .black : .white)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.4))
                )
                .transition(.scale(scale: 0.95).combined(with: .opacity))
            }
        }
        .onChange(of: selectedOption) { _, newValue in
            if let option = newValue {
                model.selectZoomOption(option)
            }
        }
    }
    
    private func selectZoomOption(_ option: CameraViewModel.ZoomOption) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedOption = option
            showZoomOptions = false
        }
    }
} 
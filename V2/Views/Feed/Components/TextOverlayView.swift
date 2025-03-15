import SwiftUI

// MARK: - Text Overlay View
struct TextOverlayView: View {
    // Properties
    let overlay: TextOverlay
    let isSelected: Bool
    let isEditing: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    let onMove: (CGPoint) -> Void
    let onRotate: (Angle) -> Void
    let onSelect: () -> Void
    let isEnabled: Bool
    
    // Gesture states
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var rotation: Angle = .zero
    @State private var lastRotation: Angle = .zero
    @GestureState private var isMoving: Bool = false
    
    // CRITICAL FIX: Add a timer to periodically ensure selection state is maintained
    // This prevents overlay from disappearing due to state loss
    @State private var keepAliveTimer: Timer?
    // Add last selection time to help with persistence
    @State private var lastSelectionTime: Date = Date()
    
    // Helpers to get font
    private func getFont() -> Font {
        switch overlay.fontName {
        case "System Bold":
            return .system(size: overlay.fontSize, weight: .bold)
        case "System Italic":
            return .system(size: overlay.fontSize, weight: .regular, design: .default).italic()
        case "Helvetica":
            return .custom("Helvetica", size: overlay.fontSize)
        case "Arial":
            return .custom("Arial", size: overlay.fontSize)
        case "Georgia":
            return .custom("Georgia", size: overlay.fontSize)
        default:
            return .system(size: overlay.fontSize)
        }
    }
    
    var body: some View {
        // Breaking down the complex view into smaller components
        contentView
            .gesture(isEnabled ? moveGesture : nil)
            .gesture(isEnabled && isSelected ? rotationGesture : nil)
            .onAppear {
                // CRITICAL FIX: Start the keep-alive timer when the overlay appears
                startKeepAliveTimer()
            }
            .onDisappear {
                // Clean up timer when overlay disappears
                stopKeepAliveTimer()
            }
    }
    
    // Content view with text and selection frame
    private var contentView: some View {
        ZStack {
            // Text content
            Text(overlay.text)
                .font(getFont())
                .foregroundColor(overlay.color)
                .multilineTextAlignment(.center)
                .rotationEffect(overlay.rotation + rotation)
                .fixedSize()
                .onTapGesture {
                    onTap()
                    // CRITICAL FIX: Also refresh the keep-alive timer on tap
                    refreshKeepAliveTimer()
                }
            
            // Selection frame when selected and in edit mode
            if isSelected && isEnabled {
                selectionFrame
            }
        }
        .offset(offset)
    }
    
    // CRITICAL FIX: Methods to manage the keep-alive timer
    private func startKeepAliveTimer() {
        // Create a timer that fires every 0.1 seconds to maintain state
        keepAliveTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            // Keep selection active on a more frequent basis
            if isSelected {
                // Re-trigger selection to prevent state loss
                DispatchQueue.main.async {
                    // Update selection timestamp
                    lastSelectionTime = Date()
                    onSelect()
                }
            } else if Date().timeIntervalSince(lastSelectionTime) < 2.0 {
                // If we were selected very recently (within last 2 seconds)
                // but lost selection, try to restore it
                DispatchQueue.main.async {
                    onSelect()
                }
            }
        }
    }
    
    private func stopKeepAliveTimer() {
        keepAliveTimer?.invalidate()
        keepAliveTimer = nil
    }
    
    private func refreshKeepAliveTimer() {
        stopKeepAliveTimer()
        startKeepAliveTimer()
    }
    
    // Selection frame with controls
    private var selectionFrame: some View {
        // Break down the complex selection frame into simpler parts
        ZStack {
            // Border
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.white, lineWidth: 1)
                .padding(.all, -10)
            
            // Delete button
            deleteButton
            
            // Rotate handle
            rotateHandle
        }
    }
    
    // Delete button component
    private var deleteButton: some View {
        VStack {
            HStack {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .background(Color.black.opacity(0.7))
                        .clipShape(Circle())
                }
                .padding(5)
                
                Spacer()
            }
            Spacer()
        }
        .padding(.all, -10)
    }
    
    // Rotate handle component
    private var rotateHandle: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Image(systemName: "arrow.up.left.and.arrow.down.right.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.7))
                    .clipShape(Circle())
                    .padding(5)
            }
        }
        .padding(.all, -10)
    }
    
    // Move gesture for positioning
    private var moveGesture: some Gesture {
        DragGesture()
            .updating($isMoving) { _, state, _ in
                state = true
            }
            .onChanged { value in
                let newOffset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
                self.offset = newOffset
                
                // Calculate the new position based on the current offset
                let newPosition = CGPoint(
                    x: overlay.position.x + value.translation.width,
                    y: overlay.position.y + value.translation.height
                )
                
                onMove(newPosition)
                
                // CRITICAL FIX: Reset the keep-alive timer during movement
                refreshKeepAliveTimer()
            }
            .onEnded { value in
                self.lastOffset = self.offset
            }
    }
    
    // Rotation gesture for the handle
    private var rotationGesture: some Gesture {
        RotationGesture()
            .onChanged { angle in
                self.rotation = angle
                onRotate(angle)
                
                // CRITICAL FIX: Reset the keep-alive timer during rotation
                refreshKeepAliveTimer()
            }
            .onEnded { angle in
                self.lastRotation = self.rotation
                self.rotation = .zero
            }
    }
} 
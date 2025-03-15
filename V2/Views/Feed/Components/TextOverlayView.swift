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
            .opacity(isEnabled ? 1.0 : 0.0)
    }
    
    // Content view with text and selection frame
    private var contentView: some View {
        ZStack {
            // Text content
            Text(overlay.text)
                .font(getFont())
                .foregroundColor(overlay.color)
                .multilineTextAlignment(.center)
                .rotationEffect(Angle(degrees: Double(overlay.rotation)) + rotation)
                .fixedSize()
                .onTapGesture {
                    onTap()
                }
            
            // Selection frame when selected
            if isSelected {
                selectionFrame
            }
        }
        .offset(offset)
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
            }
            .onEnded { angle in
                self.lastRotation = self.rotation
                self.rotation = .zero
            }
    }
} 
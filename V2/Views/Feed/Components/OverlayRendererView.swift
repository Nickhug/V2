import SwiftUI

/// View responsible for rendering overlays managed by the OverlayRenderingService
struct OverlayRendererView: View {
    @ObservedObject private var service = OverlayRenderingService.shared
    
    // Optional callback when a text overlay is tapped
    var onTextTap: ((UUID) -> Void)?
    
    var body: some View {
        ZStack {
            // Text Overlays
            renderTextOverlays()
            
            // Drawing Paths
            renderDrawingPaths()
        }
    }
    
    /// Helper to render text overlays
    @ViewBuilder
    private func renderTextOverlays() -> some View {
        ForEach(service.textOverlays) { overlay in
            RendererTextOverlayView(
                overlay: overlay,
                isSelected: service.selectedTextOverlayId == overlay.id,
                onTap: {
                    service.selectTextOverlay(id: overlay.id)
                    onTextTap?(overlay.id)
                },
                onDelete: {
                    service.removeTextOverlay(id: overlay.id)
                },
                onMove: { newPosition in
                    service.updateTextOverlayPosition(id: overlay.id, newPosition: newPosition)
                },
                onRotate: { angle in
                    service.updateTextOverlayRotation(id: overlay.id, rotation: angle)
                }
            )
        }
    }
    
    /// Helper to render all drawing paths
    @ViewBuilder
    private func renderDrawingPaths() -> some View {
        DrawingPathsView(
            completedPaths: service.drawingPaths,
            currentPath: service.currentDrawingPath,
            brushSize: service.brushSize,
            brushColor: service.brushColor
        )
    }
}

/// View for rendering a single text overlay
struct RendererTextOverlayView: View {
    let overlay: TextOverlay
    let isSelected: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    let onMove: (CGPoint) -> Void
    let onRotate: (Angle) -> Void
    
    // Gesture state
    @State private var dragOffset: CGSize = .zero
    @State private var rotation: Angle = .zero
    
    private func font() -> Font {
        switch overlay.fontName {
        case "System Bold":
            return .system(size: overlay.fontSize, weight: .bold)
        case "System Italic":
            return .system(size: overlay.fontSize, weight: .regular).italic()
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
        ZStack {
            // Text content
            Text(overlay.text)
                .font(font())
                .foregroundColor(overlay.color)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .shadow(color: .black.opacity(0.5), radius: 2, x: 1, y: 1)
                .rotationEffect(overlay.rotation + rotation)
                .position(
                    x: overlay.position.x + dragOffset.width,
                    y: overlay.position.y + dragOffset.height
                )
                .gesture(
                    TapGesture()
                        .onEnded { _ in
                            onTap()
                        }
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation
                        }
                        .onEnded { value in
                            // Apply the drag to update position
                            let newPosition = CGPoint(
                                x: overlay.position.x + value.translation.width,
                                y: overlay.position.y + value.translation.height
                            )
                            onMove(newPosition)
                            dragOffset = .zero
                        }
                )
            
            // Selection UI (only visible when selected)
            if isSelected {
                // Delete button (top right corner)
                Circle()
                    .fill(Color.red)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .position(
                        x: overlay.position.x + 50 + dragOffset.width, 
                        y: overlay.position.y - 40 + dragOffset.height
                    )
                    .onTapGesture {
                        onDelete()
                    }
                
                // Rotation handle (bottom right corner)
                Circle()
                    .fill(Color.blue)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                    )
                    .position(
                        x: overlay.position.x + 50 + dragOffset.width,
                        y: overlay.position.y + 40 + dragOffset.height
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                // Calculate rotation based on movement relative to center
                                let center = overlay.position
                                let startPoint = CGPoint(
                                    x: center.x + 50,
                                    y: center.y + 40
                                )
                                let currentPoint = value.location
                                
                                let startAngle = atan2(startPoint.y - center.y, startPoint.x - center.x)
                                let currentAngle = atan2(currentPoint.y - center.y, currentPoint.x - center.x)
                                
                                // Update rotation state
                                rotation = Angle(radians: currentAngle - startAngle)
                            }
                            .onEnded { _ in
                                // Apply rotation
                                let newRotation = overlay.rotation + rotation
                                onRotate(newRotation)
                                rotation = .zero
                            }
                    )
                
                // Selection border
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 2, dash: [5]))
                    .frame(width: 100, height: 100) // Placeholder size - should be dynamic
                    .position(overlay.position)
                    .offset(dragOffset)
                    .rotationEffect(overlay.rotation + rotation)
            }
        }
    }
}

/// View for rendering drawing paths
struct DrawingPathsView: View {
    let completedPaths: [DrawingPath]
    let currentPath: DrawingPath?
    let brushSize: CGFloat
    let brushColor: Color
    
    var body: some View {
        Canvas { context, size in
            // Draw completed paths
            for path in completedPaths {
                let strokePath = createPath(from: path.points)
                context.stroke(
                    strokePath,
                    with: .color(path.color),
                    lineWidth: path.width
                )
            }
            
            // Draw current path if one exists
            if let current = currentPath, !current.points.isEmpty {
                let strokePath = createPath(from: current.points)
                context.stroke(
                    strokePath,
                    with: .color(current.color),
                    lineWidth: current.width
                )
            }
        }
    }
    
    // Creates a smooth path from points
    private func createPath(from points: [CGPoint]) -> Path {
        var path = Path()
        
        guard !points.isEmpty else { return path }
        
        path.move(to: points[0])
        
        if points.count < 3 {
            // For just 2 points, draw a line
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
        } else {
            // For 3+ points, create a smooth curve
            for i in 1..<points.count-1 {
                let prevPoint = points[i-1]
                let currentPoint = points[i]
                let nextPoint = points[i+1]
                
                // Create control points
                let _ = CGPoint(
                    x: (prevPoint.x + currentPoint.x) / 2,
                    y: (prevPoint.y + currentPoint.y) / 2
                )
                
                let controlPoint2 = CGPoint(
                    x: (currentPoint.x + nextPoint.x) / 2,
                    y: (currentPoint.y + nextPoint.y) / 2
                )
                
                // Add quadratic curve
                path.addQuadCurve(to: controlPoint2, control: currentPoint)
            }
            
            // Add the last point
            path.addLine(to: points.last!)
        }
        
        return path
    }
} 
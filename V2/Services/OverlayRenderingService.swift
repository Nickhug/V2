import Foundation
import SwiftUI
import UIKit
import Combine

/// A global rendering service that maintains overlay state separate from SwiftUI's state system
/// This moves the responsibility of rendering overlays away from SwiftUI to prevent disappearance
class OverlayRenderingService: ObservableObject {
    // Singleton instance - use this to access the service from anywhere
    static let shared = OverlayRenderingService()
    
    // MARK: - Published properties for UI binding
    @Published var textOverlays: [TextOverlay] = []
    @Published var drawingPaths: [DrawingPath] = []
    @Published var currentDrawingPath: DrawingPath?
    @Published var selectedTextOverlayId: UUID?
    @Published var editingMode: EditingMode = .transform
    @Published var shouldKeepEditing: Bool = false
    
    // For drawing capabilities
    @Published var brushColor: Color = .white
    @Published var brushSize: CGFloat = 3.0
    
    // Compatibility property for the updated ViewModel
    var completedDrawingPaths: [DrawingPath] {
        get { return drawingPaths }
    }
    
    // For text editing
    @Published var selectedFontName: String = "System"
    @Published var selectedFontSize: CGFloat = 24
    
    // Private properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Lifecycle
    
    private init() {
        // Initialize the service
        setupLogging()
    }
    
    private func setupLogging() {
        // Add a throttled publisher to reduce console spam
        $textOverlays
            .throttle(for: 0.5, scheduler: RunLoop.main, latest: true)
            .sink { [weak self] overlays in
                guard let self = self else { return }
                print("📊 OverlayRenderingService: \(overlays.count) text overlays, selected: \(String(describing: self.selectedTextOverlayId))")
            }
            .store(in: &cancellables)
            
        $drawingPaths
            .throttle(for: 0.5, scheduler: RunLoop.main, latest: true)
            .sink { paths in
                print("📊 OverlayRenderingService: \(paths.count) drawing paths")
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public API
    
    /// The main enum for editing modes - use this instead of the one in ViewModel
    enum EditingMode: Equatable {
        case transform
        case text(overlayId: UUID?)
        case draw
        case stickers
        
        var isTextMode: Bool {
            if case .text = self { return true }
            return false
        }
        
        var isDrawMode: Bool {
            if case .draw = self { return true }
            return false
        }
    }
    
    // MARK: - Text overlay management
    
    func addTextOverlay() {
        let newId = UUID()
        let newOverlay = TextOverlay(
            id: newId,
            text: "Tap to edit",
            position: CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2),
            fontSize: selectedFontSize,
            color: .white,
            rotation: .zero,
            fontName: selectedFontName
        )
        
        textOverlays.append(newOverlay)
        selectedTextOverlayId = newId
        editingMode = .text(overlayId: newId)
        shouldKeepEditing = true
        
        print("📝 OverlayRenderingService: Added text overlay with ID \(newId)")
    }
    
    func removeTextOverlay(id: UUID) {
        textOverlays.removeAll { $0.id == id }
        
        if selectedTextOverlayId == id {
            selectedTextOverlayId = textOverlays.first?.id
            
            if let newSelectedId = selectedTextOverlayId {
                editingMode = .text(overlayId: newSelectedId)
            } else {
                // No more text overlays
                editingMode = .transform
                shouldKeepEditing = false
            }
        }
    }
    
    func updateTextOverlayPosition(id: UUID, newPosition: CGPoint) {
        guard let index = textOverlays.firstIndex(where: { $0.id == id }) else { return }
        textOverlays[index].position = newPosition
    }
    
    func updateTextOverlayRotation(id: UUID, rotation: Angle) {
        guard let index = textOverlays.firstIndex(where: { $0.id == id }) else { return }
        textOverlays[index].rotation = rotation
    }
    
    func updateTextOverlayText(id: UUID, newText: String) {
        guard let index = textOverlays.firstIndex(where: { $0.id == id }) else { return }
        textOverlays[index].text = newText
    }
    
    func updateTextOverlayFont(id: UUID, fontName: String?, fontSize: CGFloat?) {
        guard let index = textOverlays.firstIndex(where: { $0.id == id }) else { return }
        
        if let fontName = fontName {
            textOverlays[index].fontName = fontName
            selectedFontName = fontName
        }
        
        if let fontSize = fontSize {
            textOverlays[index].fontSize = fontSize
            selectedFontSize = fontSize
        }
    }
    
    func updateTextOverlayColor(id: UUID, color: Color) {
        guard let index = textOverlays.firstIndex(where: { $0.id == id }) else { return }
        textOverlays[index].color = color
    }
    
    func selectTextOverlay(id: UUID?) {
        selectedTextOverlayId = id
        
        if let id = id {
            editingMode = .text(overlayId: id)
            shouldKeepEditing = true
        } else if case .text = editingMode {
            // If we're in text mode but deselecting, keep the mode
            editingMode = .text(overlayId: nil)
        }
    }
    
    // MARK: - Drawing management
    
    func startDrawing(at point: CGPoint) {
        let newPath = DrawingPath(
            id: UUID(),
            color: brushColor,
            lineWidth: brushSize,
            points: [point]
        )
        currentDrawingPath = newPath
        editingMode = .draw
        shouldKeepEditing = true
    }
    
    func continueDrawing(to point: CGPoint) {
        guard var path = currentDrawingPath else { return }
        path.points.append(point)
        currentDrawingPath = path
    }
    
    func endDrawing() {
        guard let path = currentDrawingPath, !path.points.isEmpty else { return }
        drawingPaths.append(path)
        currentDrawingPath = nil
    }
    
    func clearDrawings() {
        drawingPaths.removeAll()
        currentDrawingPath = nil
    }
    
    // MARK: - Mode management
    
    func setEditingMode(_ mode: EditingMode) {
        switch mode {
        case .text(let overlayId):
            if textOverlays.isEmpty {
                addTextOverlay()
            } else if let overlayId = overlayId {
                selectedTextOverlayId = overlayId
                editingMode = .text(overlayId: overlayId)
                shouldKeepEditing = true
            } else if let firstId = textOverlays.first?.id {
                selectedTextOverlayId = firstId
                editingMode = .text(overlayId: firstId)
                shouldKeepEditing = true
            } else {
                editingMode = .text(overlayId: nil)
                shouldKeepEditing = true
            }
            
        case .draw:
            editingMode = .draw
            shouldKeepEditing = true
            
        case .stickers:
            editingMode = .stickers
            shouldKeepEditing = true
            
        case .transform:
            editingMode = .transform
            shouldKeepEditing = false
        }
    }
    
    // MARK: - Special methods
    
    /// Call this when exporting to get flat representations of all overlays
    func getAllOverlays() -> (textOverlays: [TextOverlay], drawingPaths: [DrawingPath]) {
        return (textOverlays: textOverlays, drawingPaths: drawingPaths)
    }
    
    /// Reset all state - call when done with an editing session
    func reset() {
        textOverlays.removeAll()
        drawingPaths.removeAll()
        currentDrawingPath = nil
        selectedTextOverlayId = nil
        editingMode = .transform
        shouldKeepEditing = false
    }
    
    /// Render all overlays onto the provided image
    /// - Parameter image: The base image to render on
    /// - Returns: A new UIImage with all overlays rendered
    func renderOverlaysToImage(_ image: UIImage) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        
        let renderedImage = renderer.image { context in
            // Draw the original image
            image.draw(in: CGRect(origin: .zero, size: image.size))
            
            let cgContext = context.cgContext
            
            // Scale factor to convert from screen coordinates to image coordinates
            let scaleX = image.size.width / UIScreen.main.bounds.width
            let scaleY = image.size.height / UIScreen.main.bounds.height
            
            // Draw all completed paths
            for path in drawingPaths {
                if path.points.count < 2 { continue }
                
                let uiColor = UIColor(path.color)
                cgContext.setStrokeColor(uiColor.cgColor)
                cgContext.setLineWidth(path.lineWidth * scaleX) // Scale line width
                cgContext.setLineCap(.round)
                cgContext.setLineJoin(.round)
                
                let scaledPoints = path.points.map { CGPoint(x: $0.x * scaleX, y: $0.y * scaleY) }
                
                cgContext.move(to: scaledPoints[0])
                for point in scaledPoints.dropFirst() {
                    cgContext.addLine(to: point)
                }
                
                cgContext.strokePath()
            }
            
            // Draw current path if any
            if let currentPath = currentDrawingPath, currentPath.points.count >= 2 {
                let uiColor = UIColor(currentPath.color)
                cgContext.setStrokeColor(uiColor.cgColor)
                cgContext.setLineWidth(currentPath.lineWidth * scaleX)
                cgContext.setLineCap(.round)
                cgContext.setLineJoin(.round)
                
                let scaledPoints = currentPath.points.map { CGPoint(x: $0.x * scaleX, y: $0.y * scaleY) }
                
                cgContext.move(to: scaledPoints[0])
                for point in scaledPoints.dropFirst() {
                    cgContext.addLine(to: point)
                }
                
                cgContext.strokePath()
            }
            
            // Draw all text overlays
            for overlay in textOverlays {
                // Skip empty text
                if overlay.text.isEmpty { continue }
                
                // Convert SwiftUI Color to UIKit
                let uiColor = UIColor(overlay.color)
                
                // Determine font
                let fontSize = overlay.fontSize * scaleX // Scale font size
                let uiFont: UIFont
                
                switch overlay.fontName {
                case "System Bold":
                    uiFont = UIFont.systemFont(ofSize: fontSize, weight: .bold)
                case "System Italic":
                    uiFont = UIFont.italicSystemFont(ofSize: fontSize)
                case "Helvetica":
                    uiFont = UIFont(name: "Helvetica", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
                case "Arial":
                    uiFont = UIFont(name: "Arial", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
                case "Georgia":
                    uiFont = UIFont(name: "Georgia", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
                default:
                    uiFont = UIFont.systemFont(ofSize: fontSize)
                }
                
                // Create string attributes
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: uiFont,
                    .foregroundColor: uiColor
                ]
                
                // Calculate text size
                let text = overlay.text as NSString
                let textSize = text.size(withAttributes: attributes)
                
                // Scale and position text
                let scaledPosition = CGPoint(
                    x: overlay.position.x * scaleX,
                    y: overlay.position.y * scaleY
                )
                
                // Create rect centered on the position
                let textRect = CGRect(
                    x: scaledPosition.x - textSize.width / 2,
                    y: scaledPosition.y - textSize.height / 2,
                    width: textSize.width,
                    height: textSize.height
                )
                
                // Save context state
                cgContext.saveGState()
                
                // Apply rotation around the center point
                cgContext.translateBy(x: scaledPosition.x, y: scaledPosition.y)
                cgContext.rotate(by: CGFloat(overlay.rotation.radians))
                cgContext.translateBy(x: -scaledPosition.x, y: -scaledPosition.y)
                
                // Draw the text
                text.draw(in: textRect, withAttributes: attributes)
                
                // Restore context state
                cgContext.restoreGState()
            }
        }
        
        print("Rendered overlays to image")
        return renderedImage
    }
}

// MARK: - Helper extensions

extension OverlayRenderingService.EditingMode {
    var selectedOverlayId: UUID? {
        if case .text(let overlayId) = self { return overlayId }
        return nil
    }
} 
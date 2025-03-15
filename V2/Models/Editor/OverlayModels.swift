import Foundation
import SwiftUI

/// Text overlay model for the story editor
public struct TextOverlay: Identifiable, Sendable {
    public var id: UUID
    public var text: String
    public var position: CGPoint
    public var fontSize: CGFloat
    public var color: Color
    public var rotation: Angle
    public var fontName: String
    
    public init(
        id: UUID,
        text: String,
        position: CGPoint,
        fontSize: CGFloat,
        color: Color,
        rotation: Angle,
        fontName: String
    ) {
        self.id = id
        self.text = text
        self.position = position
        self.fontSize = fontSize
        self.color = color
        self.rotation = rotation
        self.fontName = fontName
    }
}

/// Drawing path model for the story editor
public struct DrawingPath: Identifiable, Sendable {
    public var id: UUID
    public var color: Color
    public var lineWidth: CGFloat
    public var points: [CGPoint]
    
    // Backward compatibility for OverlayRendererView
    public var width: CGFloat {
        return lineWidth
    }
    
    public init(
        id: UUID,
        color: Color,
        lineWidth: CGFloat,
        points: [CGPoint]
    ) {
        self.id = id
        self.color = color
        self.lineWidth = lineWidth
        self.points = points
    }
}

import SwiftUI
import AVFoundation

/// A view that integrates drawing, text editing and other media editing tools
/// using the OverlayRenderingService instead of relying on SwiftUI state
struct ServiceBasedEditorView: View {
    @ObservedObject private var service = OverlayRenderingService.shared
    
    // Media content to edit
    let image: UIImage?
    let videoURL: URL?
    
    // Editor state
    @State private var activeTextEditId: UUID?
    @State private var textInput: String = ""
    @State private var selectedEditTool: EditorTool = .none
    
    // Tool selection options
    enum EditorTool {
        case none
        case text
        case draw
        case sticker
    }
    
    init(image: UIImage? = nil, videoURL: URL? = nil) {
        self.image = image
        self.videoURL = videoURL
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background media (image or video)
                mediaLayer
                
                // Overlay rendering layer
                OverlayRendererView(onTextTap: { id in
                    handleTextTap(id: id)
                })
                
                // Drawing area (when in draw mode)
                if case .draw = service.editingMode {
                    drawingArea
                }
                
                // Text editing overlay (when actively editing text)
                if let editId = activeTextEditId {
                    textEditingLayer(for: editId)
                }
                
                // Editor UI
                VStack {
                    // Top toolbar with editing options
                    editorToolbar
                    
                    Spacer()
                    
                    // Bottom toolbar (tool-specific options)
                    if selectedEditTool != .none {
                        toolOptionsView
                    }
                }
            }
        }
        .ignoresSafeArea(.all, edges: .all)
        .onAppear {
            // Reset any previous state
            service.reset()
        }
    }
    
    // MARK: - Layers
    
    private var mediaLayer: some View {
        ZStack {
            // Background color
            Color.black
            
            // Image content
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
            
            // Video content
            if let videoURL = videoURL {
                VideoPlayerView(url: videoURL, player: .constant(nil), isPlaying: .constant(true))
                    .aspectRatio(contentMode: .fit)
            }
        }
    }
    
    private var drawingArea: some View {
        GeometryReader { geometry in
            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .local)
                        .onChanged { value in
                            let location = value.location
                            
                            if service.currentDrawingPath == nil {
                                service.startDrawing(at: location)
                            } else {
                                service.continueDrawing(to: location)
                            }
                        }
                        .onEnded { _ in
                            service.endDrawing()
                        }
                )
        }
    }
    
    // MARK: - Toolbars and Controls
    
    private var editorToolbar: some View {
        HStack(spacing: 30) {
            // Draw tool
            Button(action: {
                selectTool(.draw)
            }) {
                Image(systemName: "pencil.tip")
                    .font(.system(size: 24))
                    .foregroundColor(selectedEditTool == .draw ? .yellow : .white)
            }
            
            // Text tool
            Button(action: {
                selectTool(.text)
            }) {
                Image(systemName: "textformat")
                    .font(.system(size: 24))
                    .foregroundColor(selectedEditTool == .text ? .yellow : .white)
            }
            
            // Sticker tool
            Button(action: {
                selectTool(.sticker)
            }) {
                Image(systemName: "face.smiling")
                    .font(.system(size: 24))
                    .foregroundColor(selectedEditTool == .sticker ? .yellow : .white)
            }
        }
        .padding()
        .background(Color.black.opacity(0.5))
        .cornerRadius(15)
        .padding(.top, 10)
    }
    
    @ViewBuilder
    private var toolOptionsView: some View {
        switch selectedEditTool {
        case .draw:
            drawToolbar
        case .text:
            if activeTextEditId == nil {
                textToolbar
            } else {
                EmptyView() // Text editor is showing its own controls
            }
        case .sticker:
            stickerToolbar
        case .none:
            EmptyView()
        }
    }
    
    private var drawToolbar: some View {
        VStack {
            // Color selection
            colorSelectionView
            
            // Brush size and actions
            HStack(spacing: 20) {
                // Clear button
                clearButton
                
                // Brush size
                brushSizeSelector
            }
        }
        .padding()
        .background(Color.black.opacity(0.5))
        .cornerRadius(15)
        .padding(.bottom, 20)
    }
    
    private var colorSelectionView: some View {
        HStack(spacing: 15) {
            ForEach([Color.white, Color.yellow, Color.red, Color.blue, Color.green, Color.orange], id: \.self) { color in
                colorButton(color)
            }
        }
    }
    
    private func colorButton(_ color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: 30, height: 30)
            .overlay(
                Circle()
                    .stroke(service.brushColor == color ? Color.white : Color.clear, lineWidth: 3)
            )
            .onTapGesture {
                service.brushColor = color
            }
    }
    
    private var clearButton: some View {
        Button(action: {
            service.clearDrawings()
        }) {
            Image(systemName: "trash")
                .font(.system(size: 18))
                .foregroundColor(.white)
        }
    }
    
    private var brushSizeSelector: some View {
        HStack(spacing: 12) {
            ForEach([3.0, 6.0, 10.0], id: \.self) { size in
                brushSizeButton(size)
            }
        }
    }
    
    private func brushSizeButton(_ size: CGFloat) -> some View {
        Circle()
            .fill(service.brushColor)
            .frame(width: size, height: size)
            .padding(8)
            .background(
                Circle()
                    .stroke(service.brushSize == size ? Color.white : Color.clear, lineWidth: 1)
            )
            .onTapGesture {
                service.brushSize = size
            }
    }
    
    private var textToolbar: some View {
        HStack {
            Button(action: {
                service.addTextOverlay()
            }) {
                Label("Add Text", systemImage: "plus.circle")
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(Color.black.opacity(0.5))
        .cornerRadius(15)
        .padding(.bottom, 20)
    }
    
    private var stickerToolbar: some View {
        Text("Stickers Coming Soon")
            .foregroundColor(.white)
            .padding()
            .background(Color.black.opacity(0.5))
            .cornerRadius(15)
            .padding(.bottom, 20)
    }
    
    // MARK: - Text Editing
    
    private func textEditingLayer(for editId: UUID) -> some View {
        // Find the overlay we're editing
        if let index = service.textOverlays.firstIndex(where: { $0.id == editId }) {
            let overlay = service.textOverlays[index]
            return AnyView(
                TextEditorOverlay(
                    text: $textInput,
                    textColor: overlay.color,
                    fontName: overlay.fontName,
                    fontSize: overlay.fontSize,
                    getFont: { name, size in
                        getFont(name: name, size: size)
                    },
                    onDone: {
                        // Update the text and return to selection
                        service.updateTextOverlayText(id: editId, newText: textInput)
                        activeTextEditId = nil
                    },
                    onColorChange: { color in
                        service.updateTextOverlayColor(id: editId, color: color)
                    },
                    onFontChange: { fontName in
                        service.updateTextOverlayFont(id: editId, fontName: fontName, fontSize: nil)
                    },
                    onSizeChange: { size in
                        service.updateTextOverlayFont(id: editId, fontName: nil, fontSize: size)
                    },
                    availableFonts: ["System", "System Bold", "System Italic", "Helvetica", "Arial", "Georgia"],
                    availableFontSizes: [16, 20, 24, 32, 40, 48]
                )
            )
        } else {
            // If overlay not found, cancel editing
            activeTextEditId = nil
            return AnyView(EmptyView())
        }
    }
    
    // MARK: - Tool Selection Logic
    
    private func selectTool(_ tool: EditorTool) {
        if selectedEditTool == tool {
            // If same tool selected, leave it selected
            return
        }
        
        // Switch to new tool
        selectedEditTool = tool
        
        // Update the service's mode to match
        switch tool {
        case .text:
            service.setEditingMode(.text(overlayId: service.selectedTextOverlayId))
            if service.textOverlays.isEmpty {
                service.addTextOverlay()
            }
        case .draw:
            service.setEditingMode(.draw)
        case .sticker:
            service.setEditingMode(.stickers)
        case .none:
            service.setEditingMode(.transform)
        }
    }
    
    // MARK: - Event Handlers
    
    private func handleTextTap(id: UUID) {
        // Set text editing mode
        service.setEditingMode(.text(overlayId: id))
        selectedEditTool = .text
        
        // Check if we should enter text edit mode
        if service.selectedTextOverlayId == id {
            if let overlay = service.textOverlays.first(where: { $0.id == id }) {
                // Prepare text editor
                textInput = overlay.text
                activeTextEditId = id
            }
        }
    }
    
    // MARK: - Helper Methods
    
    // Font helper
    private func getFont(name: String, size: CGFloat) -> Font {
        switch name {
        case "System Bold":
            return .system(size: size, weight: .bold)
        case "System Italic":
            return .system(size: size, weight: .regular).italic()
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
import SwiftUI

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
    @State private var showFontSelector: Bool = false
    @State private var showSizeSelector: Bool = false
    
    init(
        text: Binding<String>,
        textColor: Color,
        fontName: String,
        fontSize: CGFloat,
        getFont: @escaping (String, CGFloat) -> Font,
        onDone: @escaping () -> Void,
        onColorChange: @escaping (Color) -> Void,
        onFontChange: @escaping (String) -> Void,
        onSizeChange: @escaping (CGFloat) -> Void,
        availableFonts: [String],
        availableFontSizes: [CGFloat]
    ) {
        self._text = text
        self.textColor = textColor
        self.fontName = fontName
        self.fontSize = fontSize
        self.getFont = getFont
        self.onDone = onDone
        self.onColorChange = onColorChange
        self.onFontChange = onFontChange
        self.onSizeChange = onSizeChange
        self.availableFonts = availableFonts
        self.availableFontSizes = availableFontSizes
        self._selectedColor = State(initialValue: textColor)
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
            VStack(spacing: 20) {
                // Break down the text field configuration into separate modifiers
                // to help the compiler with type checking
                textFieldView
                
                // Color selection
                colorSelectionView
                
                // Font and size controls
                fontAndSizeControlsView
                
                // Font selector dropdown
                if showFontSelector {
                    fontSelectorView
                }
                
                // Size selector dropdown
                if showSizeSelector {
                    sizeSelectorView
                }
                
                // Done button
                doneButtonView
            }
            .padding(24)
            .background(Color(UIColor.systemGray5).opacity(0.9))
            .cornerRadius(16)
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Extracted Views
    
    // Text field component
    private var textFieldView: some View {
        // Create the font first to simplify the expression
        let font = getFont(fontName, fontSize)
        
        return TextField("Enter text", text: $text)
            .font(font)
            .foregroundColor(selectedColor)
            .multilineTextAlignment(.center)
            .padding()
            .background(Color.black.opacity(0.5))
            .cornerRadius(12)
    }
    
    // Color selection component
    private var colorSelectionView: some View {
        HStack(spacing: 16) {
            let colors: [Color] = [.white, .yellow, .red, .blue, .green, .purple, .orange]
            
            ForEach(colors, id: \.self) { color in
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
        }
    }
    
    // Font and size controls component
    private var fontAndSizeControlsView: some View {
        HStack(spacing: 20) {
            // Font selector
            fontSelectorButton
            
            // Size selector
            sizeSelectorButton
        }
    }
    
    // Font selector button
    private var fontSelectorButton: some View {
        Button(action: {
            withAnimation {
                showFontSelector.toggle()
                showSizeSelector = false
            }
        }) {
            HStack {
                Text(fontName)
                    .font(.caption)
                    .foregroundColor(.white)
                
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.7))
            .cornerRadius(8)
        }
    }
    
    // Size selector button
    private var sizeSelectorButton: some View {
        Button(action: {
            withAnimation {
                showSizeSelector.toggle()
                showFontSelector = false
            }
        }) {
            HStack {
                Text("\(Int(fontSize))")
                    .font(.caption)
                    .foregroundColor(.white)
                
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.7))
            .cornerRadius(8)
        }
    }
    
    // Font selector component
    private var fontSelectorView: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(availableFonts, id: \.self) { font in
                    Button(action: {
                        onFontChange(font)
                        withAnimation {
                            showFontSelector = false
                        }
                    }) {
                        Text(font)
                            .foregroundColor(.white)
                            .font(.system(size: 14))
                            .padding(.vertical, 4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding()
        }
        .frame(height: 150)
        .background(Color.black.opacity(0.8))
        .cornerRadius(10)
    }
    
    // Size selector component
    private var sizeSelectorView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(availableFontSizes, id: \.self) { size in
                    Button(action: {
                        onSizeChange(size)
                        withAnimation {
                            showSizeSelector = false
                        }
                    }) {
                        Text("\(Int(size))")
                            .font(.system(size: size * 0.5))
                            .foregroundColor(.white)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(fontSize == size ? Color.white : Color.clear, lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
        }
        .frame(height: 60)
        .background(Color.black.opacity(0.8))
        .cornerRadius(10)
    }
    
    // Done button component
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
} 
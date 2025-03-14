struct TextEditorOverlay: View {
    @Binding var text: String
    let textColor: Color
    let onDone: () -> Void
    let onColorChange: (Color) -> Void
    
    @State private var selectedColor: Color
    
    init(text: Binding<String>, textColor: Color, onDone: @escaping () -> Void, onColorChange: @escaping (Color) -> Void) {
        self._text = text
        self.textColor = textColor
        self.onDone = onDone
        self.onColorChange = onColorChange
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
                // Text field
                TextField("Enter text", text: $text)
                    .font(.system(size: 20))
                    .foregroundColor(selectedColor)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(12)
                
                // Color selection
                HStack(spacing: 16) {
                    ForEach([Color.white, Color.yellow, Color.red, Color.blue, Color.green, Color.purple, Color.orange], id: \.self) { color in
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
                
                // Done button
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
            .padding(24)
            .background(Color(UIColor.systemGray6).opacity(0.9))
            .cornerRadius(16)
            .padding(.horizontal, 20)
        }
    }
} 
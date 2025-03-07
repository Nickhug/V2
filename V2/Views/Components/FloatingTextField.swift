import SwiftUI

struct FloatingTextField: View {
    let placeholder: String
    let icon: String
    @Binding var text: String
    var isSecure: Bool = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            textFieldContent
        }
        .animation(.easeInOut, value: isFocused)
    }
    
    private var textFieldContent: some View {
        HStack(spacing: Theme.Spacing.medium) {
            iconView
            textField
            clearButton
        }
        .padding(.horizontal, Theme.Spacing.medium)
        .padding(.vertical, Theme.Spacing.small)
        .background(backgroundLayer)
        .overlay(borderLayer)
        .overlay(placeholderLayer, alignment: .leading)
        .shadow(
            color: isFocused ? Theme.Colors.accent.opacity(0.2) : Theme.shadowColor,
            radius: Theme.shadowRadius * 0.5,
            x: 0,
            y: 4
        )
    }
    
    private var iconView: some View {
        Image(systemName: icon)
            .foregroundColor(isFocused ? Theme.Colors.accent : Theme.Colors.textSecondary)
            .frame(width: 24)
            .animation(.easeOut, value: isFocused)
    }
    
    private var textField: some View {
        Group {
            if isSecure {
                SecureField("", text: $text)
                    .focused($isFocused)
            } else {
                TextField("", text: $text)
                    .focused($isFocused)
            }
        }
        .textFieldStyle(.plain)
        .foregroundColor(Theme.Colors.text)
        .font(.body)
    }
    
    private var clearButton: some View {
        Group {
            if !text.isEmpty {
                Button {
                    withAnimation(.easeOut) {
                        text = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Theme.Colors.textSecondary)
                        .opacity(0.7)
                }
            }
        }
    }
    
    private var backgroundLayer: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .fill(Theme.Colors.surface.opacity(0.3))
            Rectangle()
                .fill(.ultraThinMaterial)
        }
    }
    
    private var borderLayer: some View {
        RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
            .stroke(
                isFocused ? Theme.Colors.accent : 
                    (text.isEmpty ? Theme.Colors.textSecondary.opacity(0.2) : Theme.Colors.accent.opacity(0.5)),
                lineWidth: isFocused ? 1.5 : 1
            )
    }
    
    private var placeholderLayer: some View {
        Text(placeholder)
            .font(.caption)
            .foregroundColor(isFocused ? Theme.Colors.accent : Theme.Colors.textSecondary)
            .padding([.leading, .trailing], 4)
            .background(Theme.Colors.surface.opacity(0.3))
            .opacity(text.isEmpty ? 0 : 1)
            .offset(x: 36, y: -25)
            .animation(.easeOut, value: text)
    }
}

#Preview {
    VStack(spacing: 20) {
        FloatingTextField(
            placeholder: "Email",
            icon: "envelope",
            text: .constant("")
        )
        
        FloatingTextField(
            placeholder: "Password",
            icon: "lock",
            text: .constant("test123"),
            isSecure: true
        )
    }
    .padding()
    .background(Theme.Colors.background)
} 
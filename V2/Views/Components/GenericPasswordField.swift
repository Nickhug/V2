import SwiftUI

/// A generic password field component that can work with any FocusState type
struct GenericPasswordField<FocusType>: View {
    @Binding var text: String
    var placeholder: String
    var isFocused: Bool
    var onSubmit: () -> Void
    var onFocusChange: (Bool) -> Void
    
    @State private var isSecured: Bool = true
    
    var body: some View {
        HStack {
            Image(systemName: "lock.fill")
                .foregroundColor(isFocused ? MeetSpotColors.pink500 : .white.opacity(0.5))
                .font(.system(size: 20))
                .frame(width: 36)
            
            Group {
                if isSecured {
                    SecureField("", text: $text)
                        .viewPlaceholder(when: text.isEmpty) {
                            Text(placeholder).foregroundColor(.white.opacity(0.3))
                        }
                        .submitLabel(.go)
                        .onSubmit(onSubmit)
                } else {
                    TextField("", text: $text)
                        .viewPlaceholder(when: text.isEmpty) {
                            Text(placeholder).foregroundColor(.white.opacity(0.3))
                        }
                        .submitLabel(.go)
                        .onSubmit(onSubmit)
                }
            }
            .foregroundColor(.white)
            .onTapGesture {
                onFocusChange(true)
            }
            .autocapitalization(.none)
            .disableAutocorrection(true)
            
            Button(action: {
                isSecured.toggle()
            }) {
                Image(systemName: isSecured ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.white.opacity(0.5))
                    .font(.system(size: 16))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Material.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isFocused ? MeetSpotColors.pink500 : Color.white.opacity(0.1),
                    lineWidth: isFocused ? 1.5 : 1
                )
        )
    }
} 
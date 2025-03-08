import SwiftUI

/// Shared glassmorphic UI components that can be used across the app
struct GlassmorphicComponents {
    
    /// Glass-style TextField with icon
    struct TextField: View {
        @Binding var text: String
        var placeholder: String
        var icon: String
        var isFocused: Bool
        
        var body: some View {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isFocused ? MeetSpotColors.pink500 : .white.opacity(0.5))
                    .frame(width: 24, height: 24)
                    .animation(.spring(), value: isFocused)
                
                SwiftUI.TextField("", text: $text)
                    .viewPlaceholder(when: text.isEmpty) {
                        Text(placeholder).foregroundColor(.white.opacity(0.3))
                    }
                    .foregroundColor(.white)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Material.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isFocused ? MeetSpotColors.pink500 : Color.white.opacity(0.1),
                                lineWidth: isFocused ? 2 : 1
                            )
                    )
            )
            .animation(.spring(), value: isFocused)
        }
    }
    
    /// Glass-style TextEditor with icon
    struct TextEditor: View {
        @Binding var text: String
        var placeholder: String
        var icon: String
        var isFocused: Bool
        
        var body: some View {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(isFocused ? MeetSpotColors.pink500 : .white.opacity(0.5))
                        .frame(width: 24, height: 24)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 12)
                
                ZStack(alignment: .topLeading) {
                    if text.isEmpty {
                        Text(placeholder)
                            .foregroundColor(.white.opacity(0.3))
                            .padding(.horizontal)
                            .padding(.top, 8)
                    }
                    
                    SwiftUI.TextEditor(text: $text)
                        .foregroundColor(.white)
                        .background(Color.clear)
                        .padding(8)
                }
            }
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Material.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isFocused ? MeetSpotColors.pink500 : Color.white.opacity(0.1),
                                lineWidth: isFocused ? 2 : 1
                            )
                    )
            )
            .animation(.spring(), value: isFocused)
        }
    }
    
    /// Glass-style DatePicker
    struct DatePicker: View {
        @Binding var date: Date
        var icon: String
        
        var body: some View {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 24, height: 24)
                
                SwiftUI.DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .colorScheme(.dark)
                    .accentColor(MeetSpotColors.pink500)
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Material.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
}

// For backward compatibility
typealias GlassmorphicTextField = GlassmorphicComponents.TextField
typealias GlassmorphicTextEditor = GlassmorphicComponents.TextEditor
typealias GlassmorphicDatePicker = GlassmorphicComponents.DatePicker 
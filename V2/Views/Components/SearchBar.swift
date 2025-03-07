import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    var onSearch: () -> Void = {}
    var onTextChange: ((String) -> Void)? = nil
    @State private var isActive: Bool = false
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(isActive ? MeetSpotColors.pink500 : .white.opacity(0.6))
                .font(.system(size: 16))
            
            TextField(placeholder, text: $text)
                .foregroundColor(.white)
                .autocorrectionDisabled()
                .onSubmit {
                    onSearch()
                }
                .onChange(of: text) { _, newValue in
                    onTextChange?(newValue)
                }
                .onTapGesture {
                    isActive = true
                }
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                    onTextChange?("")
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.system(size: 16))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Material.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isActive ? MeetSpotColors.pink500 : Color.white.opacity(0.2),
                            lineWidth: isActive ? 2 : 1
                        )
                )
        )
        .onTapGesture {
            isActive = true
        }
    }
}

// MARK: - Preview
struct SearchBar_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                SearchBar(
                    text: .constant(""),
                    placeholder: "Search meets..."
                )
                
                SearchBar(
                    text: .constant("Mountain Drive"),
                    placeholder: "Search meets..."
                )
            }
            .padding()
        }
    }
} 
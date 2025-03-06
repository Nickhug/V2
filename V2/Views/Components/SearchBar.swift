import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    var onSearch: () -> Void = {}
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .onSubmit {
                    onSearch()
                }
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Preview
struct SearchBar_Previews: PreviewProvider {
    static var previews: some View {
        SearchBar(
            text: .constant(""),
            placeholder: "Search meets..."
        )
        .padding()
        .previewLayout(.sizeThatFits)
        
        SearchBar(
            text: .constant("Mountain Drive"),
            placeholder: "Search meets..."
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 
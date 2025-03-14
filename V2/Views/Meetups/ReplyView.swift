import SwiftUI

struct ReplyView: View {
    let comment: MeetComment
    let meet: Meet
    let viewModel: MeetViewModel
    @Binding var replyText: String
    @Environment(\.dismiss) private var dismiss
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Reply to \(viewModel.users.first { $0.id == comment.userId }?.profile.name ?? "comment")", text: $replyText)
                }
                
                Section {
                    Button("Send Reply") {
                        Task {
                            do {
                                try await viewModel.addReply(replyText, to: comment, in: meet)
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                        }
                    }
                    .disabled(replyText.isEmpty)
                }
            }
            .navigationTitle("Reply")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: 
                Button("Cancel") {
                    dismiss()
                }
            )
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
} 
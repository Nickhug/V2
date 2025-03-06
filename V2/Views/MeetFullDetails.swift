import SwiftUI

struct MeetFullDetails: View {
    @State var meet: Meet
    @ObservedObject var viewModel: MeetViewModel
    @State private var newComment = ""
    @State private var showingReplyTo: MeetComment?
    @State private var replyText = ""
    @State private var errorMessage: String?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Cover Image
                AsyncImageView(imageName: meet.coverImage)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [.clear, .black.opacity(0.3)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                // Title and Type
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        MeetSpotType.title(meet.title)
                        Spacer()
                        MeetSpotUI.Badges.status(meet.type.rawValue.capitalized)
                    }
                    
                    MeetSpotType.bodyText(meet.description)
                }
                
                // Date and Location
                MeetSpotUI.Cards.meetCard {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(MeetSpotColors.pink500)
                            MeetSpotType.subtitle(meet.formattedDate)
                        }
                        
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(MeetSpotColors.pink500)
                            MeetSpotType.subtitle(meet.address)
                        }
                        
                        HStack {
                            Image(systemName: "person.3.fill")
                                .foregroundColor(MeetSpotColors.pink500)
                            MeetSpotType.subtitle("\(meet.attendees.count)/\(meet.capacity) Attendees")
                        }
                    }
                    .padding()
                }
                
                // Attendees Section
                VStack(alignment: .leading, spacing: 12) {
                    MeetSpotType.subtitle("Attendees")
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(meet.attendees) { attendee in
                                MeetSpotUI.Cards.profileCard {
                                    VStack(spacing: 8) {
                                        AsyncImageView(imageName: attendee.profile.avatar)
                                            .frame(width: 50, height: 50)
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle()
                                                    .stroke(MeetSpotColors.purple200, lineWidth: 2)
                                            )
                                        
                                        MeetSpotType.caption(attendee.profile.name)
                                    }
                                    .frame(width: 100)
                                }
                            }
                        }
                    }
                }
                
                // Rules Section
                if !meet.rules.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        MeetSpotType.subtitle("Rules")
                        
                        MeetSpotUI.Cards.meetCard {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(meet.rules, id: \.self) { rule in
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(MeetSpotColors.pink500)
                                        MeetSpotType.bodyText(rule)
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
                
                // Comments Section
                VStack(alignment: .leading, spacing: 12) {
                    MeetSpotType.subtitle("Comments")
                    
                    // New Comment Input
                    HStack {
                        TextField("Add a comment...", text: $newComment)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .foregroundColor(.white)
                        
                        Button {
                            Task {
                                do {
                                    try await viewModel.addComment(newComment, to: meet)
                                    newComment = ""
                                } catch {
                                    errorMessage = error.localizedDescription
                                }
                            }
                        } label: {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(MeetSpotColors.pink500)
                        }
                        .disabled(newComment.isEmpty)
                    }
                    
                    // Existing Comments
                    ForEach(meet.comments) { comment in
                        CommentView(comment: comment, meet: meet, viewModel: viewModel, onDelete: {
                            Task {
                                do {
                                    try await viewModel.deleteComment(comment, from: meet)
                                } catch {
                                    errorMessage = error.localizedDescription
                                }
                            }
                        })
                    }
                }
            }
            .padding()
        }
        .background(MeetSpotColors.backgroundGradient)
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

struct CommentView: View {
    let comment: MeetComment
    let meet: Meet
    let viewModel: MeetViewModel
    let onDelete: () -> Void
    @State private var errorMessage: String?
    
    var user: User? {
        viewModel.users.first { $0.id == comment.userId }
    }
    
    var body: some View {
        MeetSpotUI.Cards.meetCard {
            VStack(alignment: .leading, spacing: 12) {
                // User Info
                HStack {
                    AsyncImageView(
                        imageName: user?.profile.avatar ?? "",
                        avatarUrl: user?.profile.avatarUrl
                    )
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(MeetSpotColors.purple200, lineWidth: 1)
                    )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        MeetSpotType.subtitle(user?.profile.name ?? "Unknown")
                        MeetSpotType.caption(comment.timestamp.formatted())
                    }
                    
                    Spacer()
                    
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(MeetSpotColors.pink500)
                    }
                }
                
                MeetSpotType.bodyText(comment.text)
                
                // Likes and Replies
                HStack {
                    Button {
                        Task {
                            do {
                                try await viewModel.likeComment(comment, in: meet)
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: comment.likes > 0 ? "heart.fill" : "heart")
                            Text("\(comment.likes)")
                        }
                        .foregroundColor(comment.likes > 0 ? MeetSpotColors.pink500 : .white.opacity(0.7))
                    }
                    
                    if !comment.replies.isEmpty {
                        MeetSpotType.caption("\(comment.replies.count) replies")
                    }
                }
                
                // Nested Replies
                if !comment.replies.isEmpty {
                    ForEach(comment.replies) { reply in
                        CommentView(comment: reply, meet: meet, viewModel: viewModel, onDelete: onDelete)
                            .padding(.leading, 40)
                    }
                }
            }
            .padding()
        }
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
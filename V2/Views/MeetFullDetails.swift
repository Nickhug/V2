import SwiftUI

struct MeetFullDetails: View {
    @State var meet: Meet
    @ObservedObject var viewModel: MeetViewModel
    @State private var newComment = ""
    @State private var showingReplyTo: MeetComment?
    @State private var replyText = ""
    @State private var errorMessage: String?
    @State private var scrollOffset: CGFloat = 0
    @State private var showFullDescription: Bool = false
    @State private var animateContent: Bool = false
    @State private var heroScale: CGFloat = 1.0
    @State private var selectedTab: Int = 0
    @State private var showDebugAlert = true
    
    private let tabs = ["Details", "Attendees", "Comments"]
    
    var body: some View {
        ZStack(alignment: .top) {
            // DEBUG OVERLAY - IMPOSSIBLE TO MISS
            Color.red.opacity(0.3)
                .ignoresSafeArea()
                .zIndex(100)
            
            Text("DEBUG - MEET DETAILS V2")
                .font(.system(size: 24, weight: .black))
                .foregroundColor(.red)
                .padding()
                .background(Color.black)
                .cornerRadius(10)
                .position(x: UIScreen.main.bounds.width/2, y: 100)
                .zIndex(101)
            
            // Base background - guaranteed to show up
            Color.black
                .ignoresSafeArea()
            
            // Cover image with parallax effect
            GeometryReader { geometry in
                let scrollY = geometry.frame(in: .global).minY
                
                ZStack(alignment: .bottom) {
                    // Cover image
                    AsyncImageView(imageName: meet.coverImage)
                        .frame(width: UIScreen.main.bounds.width)
                        .frame(height: 400 + max(0, -scrollY))
                        .clipped()
                        .blur(radius: min(10, abs(scrollY) / 40))
                        .offset(y: min(0, scrollY / 2))
                        .scaleEffect(heroScale)
                    
                    // Dark gradient overlay
                    LinearGradient(
                        colors: [
                            .clear,
                            .black.opacity(0.3),
                            .black.opacity(0.8),
                            .black
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 400)
                    
                    // Title and info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DEBUGGING: \(meet.title)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.red)
                            .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                            .padding(.horizontal)
                            .padding(.top, 24)
                        
                        HStack {
                            // Type badge
                            Text("DEBUG: \(meet.type.rawValue.capitalized)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.red)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.white)
                                .clipShape(Capsule())
                            
                            Spacer()
                            
                            // Date pill
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 12))
                                Text(meet.formattedDate)
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white)
                            .clipShape(Capsule())
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 400)
            }
            .frame(height: 400)
            .zIndex(1)
            
            // Scrollable content
            ScrollView {
                VStack(spacing: 0) {
                    // Spacer for cover image
                    Color.clear
                        .frame(height: 380)
                    
                    // Content container with visual effect background
                    VStack(spacing: 0) {
                        // Custom tab bar
                        HStack(spacing: 0) {
                            ForEach(0..<tabs.count, id: \.self) { index in
                                Button(action: {
                                    withAnimation(.spring()) {
                                        selectedTab = index
                                    }
                                }) {
                                    VStack(spacing: 8) {
                                        Text(tabs[index])
                                            .fontWeight(selectedTab == index ? .bold : .medium)
                                            .foregroundColor(selectedTab == index ? .white : .white.opacity(0.6))
                                        
                                        // Indicator
                                        Rectangle()
                                            .fill(selectedTab == index ? Color.white : Color.clear)
                                            .frame(height: 3)
                                            .cornerRadius(3)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                        .background(Color.black.opacity(0.7))
                        
                        // Tab content
                        TabView(selection: $selectedTab) {
                            // DETAILS TAB
                            detailsView
                                .tag(0)
                            
                            // ATTENDEES TAB
                            attendeesView
                                .tag(1)
                            
                            // COMMENTS TAB
                            commentsView
                                .tag(2)
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .frame(
                            minHeight: UIScreen.main.bounds.height * 0.7
                        )
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 32)
                            .fill(Color.black)
                            .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: -5)
                    )
                    .offset(y: -20)
                }
            }
            .ignoresSafeArea()
            .onAppear {
                // Animate hero image scale on appear
                withAnimation(.easeOut(duration: 0.8)) {
                    heroScale = 1.05
                }
                
                // Stagger content animations
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3)) {
                    animateContent = true
                }
            }
            
            // Back button
            Button(action: {}) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
            .padding(.leading)
            .padding(.top, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .zIndex(2)
            
            // Share button
            Button(action: {}) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
            .padding(.trailing)
            .padding(.top, 12)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .zIndex(2)
        }
        .alert("DEBUG ALERT - MeetFullDetails View Loaded", isPresented: $showDebugAlert) {
            Button("Confirm This Is Seen", role: .cancel) {
                showDebugAlert = false
            }
        } message: {
            Text("If you can see this alert, the new MeetFullDetails.swift file is being loaded. Tap OK to dismiss.")
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
        .edgesIgnoringSafeArea(.top)
    }
    
    // MARK: - Tab Views
    
    var detailsView: some View {
        VStack(alignment: .leading, spacing: 24) {
            // DEBUG TEXT
            Text("DEBUG: THIS IS THE NEW DETAILS VIEW")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.red)
                .padding()
                .background(Color.black)
                .cornerRadius(10)
            
            // Description
            VStack(alignment: .leading, spacing: 12) {
                Text("About (DEBUG)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.red)
                
                Text(meet.description)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(showFullDescription ? nil : 3)
                    .onTapGesture {
                        withAnimation(.spring()) {
                            showFullDescription.toggle()
                        }
                    }
                
                if !showFullDescription {
                    Button("Show more") {
                        withAnimation(.spring()) {
                            showFullDescription = true
                        }
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(.horizontal)
            .padding(.vertical)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
            )
            
            // Details cards
            HStack(spacing: 16) {
                // Location card
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .foregroundColor(.white)
                        
                        Text("Location")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Text(meet.address)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                )
                
                // Capacity card
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.3.fill")
                            .foregroundColor(.white)
                        
                        Text("Capacity")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    HStack(spacing: 4) {
                        Text("\(meet.attendees.count)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("/ \(meet.capacity)")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                )
            }
            
            // Rules section
            if !meet.rules.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Rules")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(meet.rules, id: \.self) { rule in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 16))
                                
                                Text(rule)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.8))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                )
            }
            
            Spacer(minLength: 60)
        }
        .padding()
        .offset(y: animateContent ? 0 : 50)
        .opacity(animateContent ? 1 : 0)
    }
    
    var attendeesView: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Meet Attendees")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal)
            
            // Attendance progress
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Attendance")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(meet.attendees.count)/\(meet.capacity)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 8)
                        
                        // Fill
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white)
                            .frame(width: min(CGFloat(meet.attendees.count) / CGFloat(meet.capacity) * geometry.size.width, geometry.size.width), height: 8)
                    }
                }
                .frame(height: 8)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
            )
            
            // Attendees grid
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
                ForEach(meet.attendees) { attendee in
                    VStack(spacing: 8) {
                        AsyncImageView(
                            imageName: attendee.profile.avatar,
                            avatarUrl: attendee.profile.avatarUrl
                        )
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 2)
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                        
                        Text(attendee.profile.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.05))
                    )
                    .scaleEffect(animateContent ? 1 : 0.8)
                    .opacity(animateContent ? 1 : 0)
                }
            }
            .padding(.horizontal)
            
            Spacer(minLength: 60)
        }
        .padding()
        .offset(y: animateContent ? 0 : 50)
        .opacity(animateContent ? 1 : 0)
    }
    
    var commentsView: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Discussion")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            // Comment input
            HStack(spacing: 12) {
                TextField("Add a comment...", text: $newComment)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.05))
                    )
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
                        .foregroundColor(.white)
                        .padding(12)
                        .background(
                            Circle()
                                .fill(newComment.isEmpty ? Color.white.opacity(0.1) : Color.white)
                                .shadow(color: newComment.isEmpty ? Color.clear : Color.white.opacity(0.3), radius: 5, x: 0, y: 2)
                        )
                        .foregroundColor(newComment.isEmpty ? .white.opacity(0.5) : .black)
                }
                .disabled(newComment.isEmpty)
            }
            
            // Comments
            if meet.comments.isEmpty {
                VStack {
                    Spacer()
                    Text("No comments yet")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.5))
                    Spacer()
                }
                .frame(height: 200)
            } else {
                ForEach(meet.comments) { comment in
                    CommentCardView(comment: comment, meet: meet, viewModel: viewModel, onDelete: {
                        Task {
                            do {
                                try await viewModel.deleteComment(comment, from: meet)
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                        }
                    })
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                }
            }
            
            Spacer(minLength: 60)
        }
        .padding()
        .offset(y: animateContent ? 0 : 50)
        .opacity(animateContent ? 1 : 0)
    }
}

// MARK: - Supporting Views

struct CommentCardView: View {
    let comment: MeetComment
    let meet: Meet
    let viewModel: MeetViewModel
    let onDelete: () -> Void
    @State private var errorMessage: String?
    @State private var showActions: Bool = false
    @State private var isLiked: Bool = false
    
    var user: User? {
        viewModel.users.first { $0.id == comment.userId }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Author info
            HStack {
                AsyncImageView(
                    imageName: user?.profile.avatar ?? "",
                    avatarUrl: user?.profile.avatarUrl
                )
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
                )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(user?.profile.name ?? "Unknown")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text(comment.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Button {
                    withAnimation(.spring()) {
                        showActions.toggle()
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.8))
                        .rotationEffect(.degrees(showActions ? 90 : 0))
                        .padding(8)
                        .background(showActions ? Color.white.opacity(0.1) : Color.clear)
                        .clipShape(Circle())
                }
            }
            
            // Comment text
            Text(comment.text)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
            
            // Actions
            HStack(spacing: 20) {
                Button {
                    Task {
                        do {
                            try await viewModel.likeComment(comment, in: meet)
                            withAnimation(.spring()) {
                                isLiked.toggle()
                            }
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: comment.likes > 0 ? "heart.fill" : "heart")
                            .font(.system(size: 16))
                        Text("\(comment.likes)")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(comment.likes > 0 ? .white : .white.opacity(0.6))
                }
                
                if !comment.replies.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.right")
                            .font(.system(size: 16))
                        Text("\(comment.replies.count)")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.white.opacity(0.6))
                }
            }
            
            // Action menu
            if showActions {
                HStack {
                    Button {
                        // Reply action
                    } label: {
                        Label("Reply", systemImage: "arrowshape.turn.up.left")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Button {
                        onDelete()
                    } label: {
                        Label("Delete", systemImage: "trash")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.red)
                    }
                }
                .padding(.vertical, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Replies
            if !comment.replies.isEmpty {
                ForEach(comment.replies) { reply in
                    CommentCardView(comment: reply, meet: meet, viewModel: viewModel, onDelete: onDelete)
                        .padding(.leading, 40)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
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
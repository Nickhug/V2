import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject var viewModel = HomeViewModel()
    @EnvironmentObject var meetViewModel: MeetViewModel
    @State private var searchText = ""
    @State private var selectedFeedTab = 0
    @State private var showingCreateMeet = false
    @State private var notificationRefreshTimer: Timer?
    @State private var showingNotifications = false
    @State private var selectedMeet: Meet?
    @State private var showingMeetDetail = false
    
    // Tab visibility state
    @State private var isActiveTab = false
    @State private var isInTransition = false
    @State private var shouldPreloadImages = true
    
    // Scroll state
    @State private var isAtScrollBoundary = false
    @State private var contentHeight: CGFloat = 0
    @State private var screenHeight: CGFloat = UIScreen.main.bounds.height
    @State private var lastContentOffset: CGFloat = 0
    @State private var scrollVelocity: CGFloat = 0
    @State private var lastVelocityUpdate = Date()
    
    // Constants
    private let tabs = ["Recent", "Popular", "Nearby"]
    
    var body: some View {
        ZStack {
            // Background - replace with modern gradient
            ModernGradientBackground()
            
            // Main content
            VStack(spacing: 0) {
                headerSection
                
                feedContent
                    .transition(.identity)
            }
            
            // Floating action button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    createMeetButton
                }
            }
        }
        // Main container modifiers
        .allowsHitTesting(!isInTransition)
        .onAppear(perform: onAppearSetup)
        .onDisappear(perform: onDisappearCleanup)
        .onReceive(NotificationCenter.default.publisher(for: .init("TabWillChange"))) { notification in
            handleTabWillChange(notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("TabDidChange"))) { notification in
            handleTabDidChange(notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("PauseImageLoading"))) { _ in
            handlePauseImageLoading()
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("ResumeImageLoading"))) { _ in
            handleResumeImageLoading()
        }
        // Sheets and modals
        .sheet(isPresented: $showingNotifications) {
            NavigationView {
                NotificationsView()
            }
        }
        .fullScreenCover(isPresented: $showingCreateMeet) {
            CreateMeetOnboardingView(viewModel: meetViewModel)
        }
        .sheet(isPresented: $showingMeetDetail) {
            if let selectedMeet = selectedMeet {
                NavigationView {
                    MeetDetailView(meet: selectedMeet, viewModel: meetViewModel)
                }
            }
        }
    }
    
    // MARK: - Feed Content
    private var feedContent: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                // Scroll position detection
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: ScrollOffsetPreferenceKey.self,
                                  value: geometry.frame(in: .named("scrollView")).minY)
                        .onAppear {
                            screenHeight = UIScreen.main.bounds.height
                            lastContentOffset = 0
                        }
                }
                .frame(height: 0)
                
                // Content height measurement
                GeometryReader { contentGeometry in
                    Color.clear
                        .preference(key: ContentSizePreferenceKey.self, 
                                   value: contentGeometry.size.height)
                }
                .frame(height: 0)
                
                // Main content
                LazyVStack(spacing: 20) {
                    // Featured meet (if available)
                    if let featuredMeet = meetViewModel.upcomingMeets.first {
                        featuredMeetCard(featuredMeet)
                            .ifNotInTransition(!isInTransition) { view in
                                view.mediumShadow()
                            }
                            .id("featured")
                    }
                    
                    // Status-based meet sections
                    statusBasedSections
                        .transaction { transaction in
                            if !shouldPreloadImages || isInTransition {
                                transaction.animation = nil
                                transaction.disablesAnimations = true
                            }
                        }
                    
                    // Tab-specific content sections
                    tabSpecificContent
                        .padding(.top, 16)
                        .id("tab-content")
                    
                    // Bottom spacer
                    Color.clear
                        .frame(height: 20)
                        .id("bottom-boundary")
                }
                .padding(.bottom, 20)
            }
            // Only disable vertical scrolling during transitions, not horizontal
            .scrollDisabled(isInTransition)
            .scrollIndicators(.visible)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 20)
            }
            .refreshable {
                Task {
                    isAtScrollBoundary = false
                    meetViewModel.setScrollBoundaryState(false)
                    
                    // Clear transitional states immediately before refreshing
                    meetViewModel.clearAllTransitionalStates()
                    
                    await viewModel.refresh()
                    await meetViewModel.forceRefreshAll()
                    
                    // Clear again after refresh completes as a safety measure
                    meetViewModel.clearAllTransitionalStates()
                }
            }
            .onChange(of: isAtScrollBoundary) { _, newValue in
                if newValue {
                    withoutAnimation {
                        scrollProxy.scrollTo("tab-content", anchor: .bottom)
                    }
                }
            }
            .onPreferenceChange(ScrollOffsetPreferenceKey.self, perform: handleScrollOffsetChange)
            .onPreferenceChange(ContentSizePreferenceKey.self) { height in
                contentHeight = height
            }
            .coordinateSpace(name: "scrollView")
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 0) {
            // Title and notification area
            HStack {
                Text("Feeds")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.title2)
                    .foregroundColor(.white)
                
                Button(action: {
                    showingNotifications = true
                }) {
                    NotificationButton(count: viewModel.unreadNotificationsCount)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isInTransition)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Search bar
            SearchBar(
                text: $viewModel.searchQuery,
                placeholder: "Search meets...",
                onTextChange: { _ in }
            )
            .padding(.horizontal)
            .padding(.top, 8)
            .disabled(isInTransition)
            
            // Status filter
            StatusFilterView(viewModel: meetViewModel)
                .padding(.bottom, 4)
                .disabled(isInTransition)
            
            // Tab selector
            tabSelectionView
            
            Divider()
                .background(Color.white.opacity(0.15))
                .padding(.horizontal)
        }
        .background(Color.black.opacity(0.2))
        .ifNotInTransition(!isInTransition) { view in
            view.subtleShadow()
        }
    }
    
    // MARK: - Create Meet Button
    private var createMeetButton: some View {
        Button(action: {
            showingCreateMeet = true
        }) {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundColor(.black)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(Color.white)
                        .overlay(
                            Circle()
                                .stroke(Color.black, lineWidth: 1.5)
                        )
                )
                .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 1)
                .ifNotInTransition(!isInTransition) { view in
                    view
                }
        }
        .padding()
        .disabled(isInTransition)
        .opacity(isInTransition ? 0.5 : 1.0)
    }
    
    // MARK: - Status Based Sections
    private var statusBasedSections: some View {
        VStack(alignment: .leading, spacing: 16) {
            // For each status type (upcoming, active, completed, canceled)
            ForEach(MeetStatus.allCases, id: \.self) { status in
                // Special handling for Active Meets section that's causing problems
                if status == .active {
                    activeMeetsSection
                } else {
                    // Regular implementation for other sections
                    VStack(alignment: .leading, spacing: 8) {
                        // Common header
                        statusSectionHeader(status)
                        
                        // Content area with only one visible at a time - prioritized order
                        if meetViewModel.isStatusTransitioning(status) {
                            // PRIORITY 1: Show loading state first if transitioning
                            transitioningStateView(for: status)
                                .id("loading-\(status.rawValue)")
                        } else if let meetsForStatus = meetViewModel.meetsByStatus[status], !meetsForStatus.isEmpty {
                            // PRIORITY 2: Show content if we have meets and not transitioning
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(meetsForStatus) { meet in
                                        MeetCard(
                                            meet: meet,
                                            style: .dark,
                                            onJoin: createOnJoinAction(for: meet),
                                            onTap: {
                                                selectedMeet = meet
                                                showingMeetDetail = true
                                            }
                                        )
                                        .frame(width: 300, height: 300)
                                        .id(meet.id)
                                    }
                                    
                                    // End spacer
                                    Color.clear
                                        .frame(width: 50, height: 50)
                                }
                                .padding(.horizontal)
                            }
                            .frame(height: 330)
                            .id("content-\(status.rawValue)")
                        } else if meetViewModel.isInitialized {
                            // PRIORITY 3: Show empty state if we're initialized but no meets
                            emptyStateView(for: status)
                                .id("empty-\(status.rawValue)")
                        } else {
                            // PRIORITY 4: Fallback - just show a minimal placeholder
                            Color.clear
                                .frame(height: 100)
                                .id("placeholder-\(status.rawValue)")
                        }
                    }
                    .padding(.vertical, 8)
                    // Fixed stable ID for each status section - don't use UUID
                    .id("section-\(status.rawValue)")
                }
            }
        }
    }
    
    // MARK: - Dedicated Active Meets Section
    // Special implementation just for the problematic Active section
    private var activeMeetsSection: some View {
        let status = MeetStatus.active
        let isTransitioning = meetViewModel.isStatusTransitioning(status)
        let hasContent = (meetViewModel.meetsByStatus[status]?.isEmpty == false)
        let isInitialized = meetViewModel.isInitialized
        
        // Calculate a single state string to ensure mutual exclusivity
        let displayState: String = {
            switch (isTransitioning, hasContent, isInitialized) {
            case (true, _, _):
                return "loading"
            case (false, true, _):
                return "content"
            case (false, false, true):
                return "empty"
            default:
                return "placeholder"
            }
        }()
        
        return VStack(alignment: .leading, spacing: 8) {
            // Header
            statusSectionHeader(status)
            
            // Strict switch statement approach
            switch displayState {
            case "loading":
                transitioningStateView(for: status)
                
            case "content":
                if let activeMeets = meetViewModel.meetsByStatus[status], !activeMeets.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(activeMeets) { meet in
                                MeetCard(
                                    meet: meet,
                                    style: .dark,
                                    onJoin: createOnJoinAction(for: meet),
                                    onTap: {
                                        selectedMeet = meet
                                        showingMeetDetail = true
                                    }
                                )
                                .frame(width: 300, height: 300)
                                .id(meet.id)
                            }
                            
                            // End spacer
                            Color.clear
                                .frame(width: 50, height: 50)
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 330)
                } else {
                    // Fallback in case hasContent was true but array is empty now
                    emptyStateView(for: status)
                }
                
            case "empty":
                emptyStateView(for: status)
                
            default: // placeholder
                Color.clear
                    .frame(height: 100)
            }
        }
        .padding(.vertical, 8)
        .id("active-meets-section-\(displayState)")
        // Clear background to force clean rendering
        .background(Color.black.opacity(0.01))
    }
    
    // MARK: - Status Section Header
    private func statusSectionHeader(_ status: MeetStatus) -> some View {
        HStack {
            Image(systemName: status.icon)
                .foregroundColor(status.color)
            
            Text(status.displayName + " Meets")
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            let meetsCount = meetViewModel.meetsByStatus[status]?.count ?? 0
            Text("\(meetsCount)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Tab Selection View
    private var tabSelectionView: some View {
        HStack {
            ForEach(Array(tabs.enumerated()), id: \.element) { index, tab in
                Button(action: {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    withoutAnimation {
                        selectedFeedTab = index
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(tab)
                            .foregroundColor(selectedFeedTab == index ? .white : .white.opacity(0.5))
                            .fontWeight(selectedFeedTab == index ? .bold : .regular)
                        
                        if selectedFeedTab == index {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 6, height: 6)
                        } else {
                            Circle()
                                .fill(Color.clear)
                                .frame(width: 6, height: 6)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(isInTransition)
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Tab Specific Content
    @ViewBuilder
    private var tabSpecificContent: some View {
        switch selectedFeedTab {
        case 0: // Recent
            EmptyView()
            
        case 1: // Popular
            meetsFeedSection(
                title: "Popular Meets",
                meets: viewModel.filteredRecommendedMeets,
                emptyMessage: "No recommended meets found"
            )
            
        case 2: // Nearby
            meetsFeedSection(
                title: "Meets Near You",
                meets: viewModel.filteredNearbyMeets,
                emptyMessage: "No nearby meets found"
            )
            
        default:
            EmptyView()
        }
    }
    
    // MARK: - Feeds Section
    private func meetsFeedSection(title: String, meets: [Meet], emptyMessage: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section title
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            if meets.isEmpty {
                if viewModel.isLoading {
                    // Loading state using an improved Circle animation
                    VStack {
                        LoadingSpinner(color: .white, lineWidth: 3, size: 40)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text(emptyMessage)
                            .font(.headline)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        if !viewModel.searchQuery.isEmpty {
                            Text("Try a different search term")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Rectangle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 40, height: 2)
                            .cornerRadius(1)
                            .padding(.top, 10)
                    }
                    .frame(maxWidth: .infinity, minHeight: 160)
                    .padding(.vertical, 20)
                    .padding(.horizontal, 20)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: MeetSpotStyle.Radius.large))
                    .padding(.horizontal)
                }
            } else {
                // Horizontal scrolling meet cards
                horizontalMeetCardsView(meets: meets)
            }
        }
        .padding(.bottom, meets.isEmpty ? 50 : 0)
    }
    
    // MARK: - Horizontal Meet Cards
    private func horizontalMeetCardsView(meets: [Meet]) -> some View {
        // Basic horizontal scroll with minimal modifiers
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(meets) { meet in
                    MeetCard(
                        meet: meet,
                        style: .dark,
                        onJoin: createOnJoinAction(for: meet),
                        onTap: {
                            selectedMeet = meet
                            showingMeetDetail = true
                        }
                    )
                    .frame(width: 300, height: 300)
                    .id(meet.id)
                }
                
                // End spacer
                Color.clear
                    .frame(width: 50, height: 50)
            }
            .padding(.horizontal)
        }
        .frame(height: 330)
    }
    
    // MARK: - Featured Meet Card
    private func featuredMeetCard(_ meet: Meet) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                // Cover image
                AsyncImageView(imageName: meet.coverImage)
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: MeetSpotStyle.Radius.large))
                    .overlay(
                        LinearGradient(
                            colors: [
                                .clear,
                                .black.opacity(0.4),
                                .black.opacity(0.7)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .clipShape(RoundedRectangle(cornerRadius: MeetSpotStyle.Radius.large))
                    )
                    .ifNotInTransition(!isInTransition) { view in
                        view.mediumShadow()
                    }
                
                // Status badge
                AnimatedStatusBadge(status: meet.status, size: .regular)
                    .padding(12)
                    .opacity(isInTransition ? 0.0 : 1.0)
            }
            
            // Content overlay
            VStack(alignment: .leading, spacing: 8) {
                // Title
                Text(meet.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                // Date and location
                HStack {
                    // Date
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                        Text(meet.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    // Location
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.caption)
                        Text(meet.locationName)
                            .font(.caption)
                            .lineLimit(1)
                    }
                }
                .foregroundColor(.white.opacity(0.8))
                
                Divider()
                    .background(Color.white.opacity(0.2))
                    .padding(.vertical, 4)
                
                // Type indicator
                HStack {
                    Text(meet.type.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(meet.type.color)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                .font(.subheadline)
                
                // Action button
                Button {
                    selectedMeet = meet
                    showingMeetDetail = true
                } label: {
                    Text("View Details")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: MeetSpotStyle.Radius.medium))
                        .overlay(
                            RoundedRectangle(cornerRadius: MeetSpotStyle.Radius.medium)
                                .stroke(Color.black, lineWidth: 1.5)
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 1)
                        .ifNotInTransition(!isInTransition) { view in
                            view
                        }
                }
                .padding(.top, 8)
                .disabled(isInTransition)
                .buttonStyle(BorderlessButtonStyle())
            }
            .padding(16)
            .background(Color.black.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: MeetSpotStyle.Radius.large))
            .offset(y: -70)
            .padding(.bottom, -70)
        }
        .padding(.horizontal)
        .contentShape(Rectangle())
        .onTapGesture {
            selectedMeet = meet
            showingMeetDetail = true
        }
    }
    
    // MARK: - Supporting Views
    
    // Transitioning state view
    private func transitioningStateView(for status: MeetStatus) -> some View {
        HStack {
            Spacer()
            
            VStack(spacing: 12) {
                // Custom animated loading indicator with proper animation
                LoadingSpinner(color: status.color, lineWidth: 2, size: 30)
                
                Text("Updating \(status.displayName.lowercased()) meets...")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 24)
            .frame(height: 120)
            
            Spacer()
        }
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(status.color.opacity(0.15), lineWidth: 1)
        )
        .padding(.horizontal)
    }
    
    // Empty state view
    private func emptyStateView(for status: MeetStatus) -> some View {
        HStack {
            Spacer()
            
            VStack(spacing: 12) {
                Image(systemName: getEmptyStateIcon(for: status))
                    .font(.system(size: 32))
                    .foregroundColor(status.color.opacity(0.8))
                
                Text("No \(status.displayName.lowercased()) meets available")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 24)
            .frame(height: 120)
            
            Spacer()
        }
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(status.color.opacity(0.15), lineWidth: 1)
        )
        .padding(.horizontal)
    }
    
    // MARK: - Helper Methods
    
    // Empty state icons
    private func getEmptyStateIcon(for status: MeetStatus) -> String {
        switch status {
        case .upcoming: return "calendar.badge.clock"
        case .active: return "person.3.fill"
        case .completed: return "checkmark.circle"
        case .canceled: return "xmark.circle"
        }
    }
    
    // Create join action
    private func createOnJoinAction(for meet: Meet) -> (() -> Void)? {
        guard meet.status.allowsInteraction else { return nil }
        
        return {
            Task {
                try? await meetViewModel.joinMeet(meet)
            }
        }
    }
    
    // Setup on appear
    private func onAppearSetup() {
        isActiveTab = true
        meetViewModel.setScrollBoundaryState(false)
        meetViewModel.clearAllTransitionalStates()
        
        // Ensure images load immediately
        shouldPreloadImages = true
        
        startNotificationRefreshTimer()
    }
    
    // Cleanup on disappear
    private func onDisappearCleanup() {
        isActiveTab = false
        shouldPreloadImages = false
        meetViewModel.setScrollBoundaryState(false)
        
        notificationRefreshTimer?.invalidate()
        notificationRefreshTimer = nil
    }
    
    // Start notification timer
    private func startNotificationRefreshTimer() {
        notificationRefreshTimer?.invalidate()
        
        notificationRefreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task {
                await viewModel.fetchUnreadNotificationsCount()
            }
        }
    }
    
    // Handle scroll offset changes (VERTICAL SCROLLING ONLY)
    private func handleScrollOffsetChange(_ value: CGFloat) {
        // Calculate velocity without triggering frequent state updates
        let now = Date()
        let timeDelta = now.timeIntervalSince(lastVelocityUpdate)
        if timeDelta > 0 {
            scrollVelocity = (value - lastContentOffset) / CGFloat(timeDelta)
            lastContentOffset = value
            lastVelocityUpdate = now
        }

        // Optimize boundary detection - avoid frequent state changes during scrolling
        let threshold: CGFloat = 80
        let isScrollingFast = abs(scrollVelocity) > 1000
        let shouldBeAtBoundary = value < threshold && isScrollingFast
        
        // Only update state if it's actually changing, and use debouncing for fast scrolling
        if shouldBeAtBoundary != isAtScrollBoundary {
            // Debounce rapid changes - only update when scrolling has some consistency
            // This helps prevent state thrashing during scrolling
            withoutAnimation {
                isAtScrollBoundary = shouldBeAtBoundary
                
                // Use Task to avoid impacting scroll performance
                Task { @MainActor in
                    // Update view model boundary state
                    meetViewModel.setScrollBoundaryState(shouldBeAtBoundary)
                    
                    // Preemptively clear transitional states when boundary changes
                    // to prevent stuck loading states
                    if !shouldBeAtBoundary {
                        meetViewModel.clearAllTransitionalStates()
                    }
                }
            }
        }
    }
    
    // Tab notification handlers
    private func handleTabWillChange(_ notification: Foundation.Notification) {
        if let userInfo = notification.userInfo as? [String: Any],
           let _ = userInfo["to"] as? String,
           let _ = userInfo["from"] as? String {
            
            // Always set isInTransition for any tab change
            withoutAnimation {
                isInTransition = true
                
                // Stop any ongoing animations or timers that might interfere with transition
                meetViewModel.pauseAllBackgroundOperations()
            }
        }
    }
    
    private func handleTabDidChange(_ notification: Foundation.Notification) {
        if let userInfo = notification.userInfo as? [String: Any],
           let to = userInfo["to"] as? String,
           let _ = userInfo["from"] as? String {
            
            // Update active state based on current tab
            withoutAnimation {
                isActiveTab = (to == "home")
                
                // Use a slight delay to ensure the transition has completed
                // before allowing interaction again
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withoutAnimation {
                        self.isInTransition = false
                        
                        // Resume background operations if this is the active tab
                        if to == "home" {
                            self.meetViewModel.resumeAllBackgroundOperations()
                        }
                    }
                }
            }
        }
    }
    
    // Image loading notification handlers
    private func handlePauseImageLoading() {
        withoutAnimation {
            isInTransition = true
        }
        
        // Automatically resume after a short delay to prevent stuck state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if isInTransition {
                handleResumeImageLoading()
            }
        }
    }
    
    private func handleResumeImageLoading() {
        withoutAnimation {
            isInTransition = false
        }
    }
}

// MARK: - NotificationButton
struct NotificationButton: View {
    let count: Int
    @State private var isAnimating = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: "bell.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.black)
                .padding(MeetSpotStyle.Spacing.small)
                .background(
                    Circle()
                        .fill(Color.white)
                        .overlay(
                            Circle()
                                .stroke(Color.black, lineWidth: 1.5)
                        )
                )
                .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 1)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(
                    count > 0 ? 
                        Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true) : 
                        .default,
                    value: isAnimating
                )
                .onAppear {
                    isAnimating = count > 0
                }
                .onChange(of: count) { _, newCount in
                    isAnimating = newCount > 0
                }
            
            if count > 0 {
                Text("\(count)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(5)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [MeetSpotColors.pink500, MeetSpotColors.purple900],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .subtleShadow()
                    )
                    .offset(x: 5, y: -5)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .contentShape(Circle())
    }
}

// MARK: - Helper Extensions

// ScrollOffset preference key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// ContentSize preference key
struct ContentSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// Remove custom modifier - it's causing problems
struct CompletedMeetsScrollModifier: ViewModifier {
    let isCompletedSection: Bool
    
    func body(content: Content) -> some View {
        // Simply return the content without any modifiers
        content
    }
}

// Add a layout preference key to support optimization
struct LayoutPreferences: PreferenceKey {
    static var defaultValue: Bool = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
} 
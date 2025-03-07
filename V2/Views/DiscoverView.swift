import SwiftUI

struct DiscoverView: View {
    @ObservedObject var viewModel: DiscoverViewModel
    @State private var searchText = ""
    @State private var selectedFilter: MeetFilter = .all
    
    init(viewModel: DiscoverViewModel) {
        self.viewModel = viewModel
    }
    
    enum MeetFilter: String, CaseIterable {
        case all
        case upcoming
        case ongoing
        case completed
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Search Bar
                    SearchBar(
                        text: $searchText,
                        placeholder: "Search meets..."
                    ) {
                        Task {
                            await viewModel.fetchMeets()
                        }
                    }
                    .padding(.horizontal)
                    
                    // Filter Buttons
                    filterButtons
                    
                    // Meet List
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.meets) { meet in
                            MeetCard(
                                meet: meet,
                                onJoin: {
                                    Task {
                                        await viewModel.joinMeet(meet)
                                    }
                                }
                            )
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationTitle("Discover")
            .refreshable {
                await viewModel.fetchMeets()
            }
        }
        .task {
            await viewModel.fetchMeets()
        }
    }
    
    private var filterButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(MeetFilter.allCases, id: \.self) { filter in
                    FilterButton(
                        title: filter.title,
                        isSelected: selectedFilter == filter
                    ) {
                        selectedFilter = filter
                        Task {
                            await viewModel.fetchMeets()
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Meet Filter Extension
extension DiscoverView.MeetFilter {
    var title: String {
        switch self {
        case .all:
            return "All"
        case .upcoming:
            return "Upcoming"
        case .ongoing:
            return "Ongoing"
        case .completed:
            return "Completed"
        }
    }
    
    var status: MeetStatus? {
        switch self {
        case .all:
            return nil
        case .upcoming:
            return .upcoming
        case .ongoing:
            return .active
        case .completed:
            return .completed
        }
    }
}

// MARK: - Preview
struct DiscoverView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoverView(viewModel: DiscoverViewModel())
    }
} 
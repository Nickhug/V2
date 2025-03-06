import SwiftUI

struct UpcomingView: View {
    @ObservedObject var viewModel: MeetViewModel
    @State private var selectedFilter: V2MeetType?
    @State private var searchText: String = ""
    
    var filteredMeets: [Meet] {
        let upcoming = viewModel.upcomingMeets
        guard let filter = selectedFilter else { return upcoming }
        return upcoming.filter { $0.type == filter }
    }
    
    private var filterButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterButton(
                    title: "All", 
                    isSelected: selectedFilter == nil, 
                    action: {
                        withAnimation {
                            selectedFilter = nil
                        }
                    },
                    style: .dark
                )
                
                FilterButton(
                    title: "Cars", 
                    isSelected: selectedFilter == .car, 
                    action: {
                        withAnimation {
                            selectedFilter = .car
                        }
                    },
                    style: .dark
                )
                
                FilterButton(
                    title: "Bikes", 
                    isSelected: selectedFilter == .bike, 
                    action: {
                        withAnimation {
                            selectedFilter = .bike
                        }
                    },
                    style: .dark
                )
                
                FilterButton(
                    title: "Mixed", 
                    isSelected: selectedFilter == .mixed, 
                    action: {
                        withAnimation {
                            selectedFilter = .mixed
                        }
                    },
                    style: .dark
                )
            }
            .padding(.horizontal)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.black.ignoresSafeArea()
                DashboardBackground()
                
                VStack(spacing: 0) {
                    // Filters
                    filterButtons
                    
                    // Meets List
                    if filteredMeets.isEmpty {
                        ContentUnavailableView(
                            "No Upcoming Meets",
                            systemImage: "calendar",
                            description: Text("Check back later for new meets!")
                        )
                        .padding(.top, 40)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 15) {
                                ForEach(filteredMeets) { meet in
                                    MeetCard(
                                        meet: meet,
                                        style: .dark,
                                        onJoin: {
                                            Task {
                                                await viewModel.attendMeet(meet)
                                            }
                                        }
                                    )
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                }
            }
            .navigationTitle("Upcoming")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
} 
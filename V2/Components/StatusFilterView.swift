import SwiftUI

/// A horizontal scrollable filter bar for filtering meets by status
struct StatusFilterView: View {
    @ObservedObject var viewModel: MeetViewModel
    @State private var selectedStatus: MeetStatus? = nil
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button {
                    viewModel.toggleStatusFilter(nil)
                    selectedStatus = nil
                } label: {
                    HStack {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text("All")
                    }
                    .font(.subheadline.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(!viewModel.activelyFilteringByStatus ? Color.accentColor : Color.gray.opacity(0.2))
                    .foregroundColor(!viewModel.activelyFilteringByStatus ? .white : .primary)
                    .cornerRadius(20)
                }
                
                ForEach(MeetStatus.allCases) { status in
                    Button {
                        viewModel.toggleStatusFilter(status)
                        selectedStatus = viewModel.selectedStatusFilter
                    } label: {
                        HStack {
                            Image(systemName: status.icon)
                            Text(status.displayName)
                        }
                        .font(.subheadline.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(viewModel.selectedStatusFilter == status ? status.color : Color.gray.opacity(0.2))
                        .foregroundColor(viewModel.selectedStatusFilter == status ? .white : .primary)
                        .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color.black.opacity(0.02))
    }
}

// MARK: - Status Section Header View
/// A subview for displaying the status section header
struct StatusSectionHeaderView: View {
    let status: MeetStatus
    let count: Int
    
    var body: some View {
        HStack {
            Image(systemName: status.icon)
                .foregroundColor(status.color)
            
            Text(status.displayName + " Meets")
                .font(.headline)
            
            Spacer()
            
            Text("\(count)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
        }
        .padding(.horizontal)
    }
}

// MARK: - Status Meet Cards View
/// A subview for displaying meet cards for a specific status
struct StatusMeetCardsView: View {
    let meets: [Meet]
    let viewModel: MeetViewModel
    @Binding var selectedMeet: Meet?
    @Binding var showingMeetDetail: Bool
    
    var body: some View {
        // Basic horizontal scroll with minimal modifiers
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(meets) { meet in
                    MeetCard(
                        meet: meet,
                        onJoin: createOnJoinAction(for: meet),
                        onTap: {
                            selectedMeet = meet
                            showingMeetDetail = true
                        }
                    )
                    .frame(width: 300)
                    .id(meet.id)
                }
                
                // Simple end spacer
                Color.clear
                    .frame(width: 50, height: 50)
            }
            .padding(.horizontal)
        }
        .frame(height: 320)
    }
    
    // Helper method to create the onJoin closure
    private func createOnJoinAction(for meet: Meet) -> (() -> Void)? {
        if meet.status.allowsInteraction {
            return {
                Task {
                    try? await viewModel.joinMeet(meet)
                }
            }
        } else {
            return nil
        }
    }
}

// MARK: - Status Section View
/// A subview for displaying a complete status section
struct StatusSectionView: View {
    let status: MeetStatus
    let meets: [Meet]
    let viewModel: MeetViewModel
    @Binding var selectedMeet: Meet?
    @Binding var showingMeetDetail: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            StatusSectionHeaderView(status: status, count: meets.count)
            
            StatusMeetCardsView(
                meets: meets,
                viewModel: viewModel,
                selectedMeet: $selectedMeet,
                showingMeetDetail: $showingMeetDetail
            )
        }
        .padding(.vertical, 8)
    }
}

/// A card layout view to show meets grouped by status
struct MeetsByStatusView: View {
    @ObservedObject var viewModel: MeetViewModel
    @State private var selectedMeet: Meet?
    @State private var showingMeetDetail = false
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                // Use ForEach with simple content and extract complex views to subcomponents
                ForEach(MeetStatus.allCases) { status in
                    if let meetsForStatus = viewModel.meetsByStatus[status], !meetsForStatus.isEmpty {
                        StatusSectionView(
                            status: status,
                            meets: meetsForStatus,
                            viewModel: viewModel,
                            selectedMeet: $selectedMeet,
                            showingMeetDetail: $showingMeetDetail
                        )
                    }
                }
            }
            .padding(.vertical)
        }
        .sheet(isPresented: $showingMeetDetail) {
            if let meet = selectedMeet {
                NavigationView {
                    MeetDetailView(meet: meet, viewModel: viewModel)
                }
            }
        }
    }
}

struct StatusFilterView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = MeetViewModel()
        viewModel.meets = Meet.mockMeets
        
        return Group {
            StatusFilterView(viewModel: viewModel)
                .previewLayout(.sizeThatFits)
                .padding()
                
            MeetsByStatusView(viewModel: viewModel)
                .previewLayout(.sizeThatFits)
        }
    }
} 
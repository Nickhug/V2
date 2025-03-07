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

/// A card layout view to show meets grouped by status
struct MeetsByStatusView: View {
    @ObservedObject var viewModel: MeetViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                ForEach(MeetStatus.allCases) { status in
                    if let meetsForStatus = viewModel.meetsByStatus[status], !meetsForStatus.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: status.icon)
                                    .foregroundColor(status.color)
                                
                                Text(status.displayName + " Meets")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Text("\(meetsForStatus.count)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.secondary.opacity(0.1))
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(meetsForStatus) { meet in
                                        MeetCard(meet: meet)
                                            .frame(width: 300)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .padding(.vertical)
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
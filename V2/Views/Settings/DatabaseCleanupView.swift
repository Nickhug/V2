import SwiftUI

struct DatabaseCleanupView: View {
    @StateObject private var viewModel = DatabaseCleanupViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Button(role: .destructive) {
                        Task {
                            await viewModel.cleanupDatabase()
                        }
                    } label: {
                        Label("Clean Database", systemImage: "trash")
                    }
                    .disabled(viewModel.isCleaning)
                } header: {
                    Text("Warning")
                } footer: {
                    Text("This will remove all data from the database. This action cannot be undone.")
                        .foregroundColor(.red)
                }
                
                if viewModel.isCleaning {
                    Section {
                        ProgressView()
                    }
                }
                
                if let error = viewModel.error {
                    Section {
                        Text(error.localizedDescription)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Database Cleanup")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

@MainActor
class DatabaseCleanupViewModel: ObservableObject {
    @Published var isCleaning = false
    @Published var error: Error?
    
    private let supabaseService = SupabaseService.shared
    
    func cleanupDatabase() async {
        isCleaning = true
        error = nil
        
        do {
            // Add your database cleanup logic here
            // For example:
            // try await supabaseService.deleteAllData()
            
            // For now, just simulate a delay
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        } catch {
            self.error = error
        }
        
        isCleaning = false
    }
} 
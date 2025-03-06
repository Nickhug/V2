import SwiftUI

struct RoutesView: View {
    @EnvironmentObject private var routeViewModel: RouteViewModel
    @State private var showingRouteEditor = false
    @State private var searchText = ""
    @State private var filterDifficulty: RouteDifficulty? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                AnimatedGradientBackground()
                
                VStack {
                    // Search and filter bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search routes", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Menu(content: {
                            Button("All Difficulties") {
                                filterDifficulty = nil
                            }
                            
                            Divider()
                            
                            ForEach(RouteDifficulty.allCases, id: \.self) { difficulty in
                                Button(difficulty.description) {
                                    filterDifficulty = difficulty
                                }
                            }
                        }, label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .foregroundColor(.accentColor)
                        })
                    }
                    .padding(.horizontal)
                    
                    // Routes list
                    RoutesListView(editable: true)
                        .environmentObject(routeViewModel)
                }
                .navigationTitle("My Routes")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingRouteEditor = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showingRouteEditor) {
                    RouteEditorView(onRouteSaved: { route in
                        // Refresh routes after saving
                        Task {
                            await routeViewModel.fetchUserRoutes()
                        }
                    })
                    .environmentObject(AuthManager())
                }
                .onAppear {
                    Task {
                        await routeViewModel.fetchUserRoutes()
                    }
                }
            }
        }
    }
    
    // Filter routes based on search text and difficulty filter
    private func filteredRoutes() -> [Route] {
        var routes = routeViewModel.userRoutes
        
        // Apply search filter
        if !searchText.isEmpty {
            routes = routes.filter { route in
                route.title.localizedCaseInsensitiveContains(searchText) ||
                route.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply difficulty filter
        if let difficulty = filterDifficulty {
            routes = routes.filter { $0.difficulty == difficulty }
        }
        
        return routes
    }
} 
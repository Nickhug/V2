import SwiftUI

struct RoutesView: View {
    @EnvironmentObject private var routeViewModel: RouteViewModel
    @State private var showingRouteEditor = false
    @State private var filterDifficulty: RouteDifficulty? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                AnimatedGradientBackground()
                
                VStack {
                    // Search and filter bar
                    HStack {
                        SearchBar(
                            text: $routeViewModel.searchQuery,
                            placeholder: "Search routes",
                            onTextChange: { _ in 
                                // The RouteViewModel handles filtering with computed properties
                            }
                        )
                        
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
                                .font(.system(size: 18))
                                .foregroundColor(Color.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(Material.ultraThinMaterial)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.black, lineWidth: 1.5)
                                        )
                                )
                        })
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    if filteredRoutes().isEmpty {
                        VStack(spacing: 20) {
                            Spacer()
                            Image(systemName: "map.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text("No routes found")
                                .font(.title3)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            if !routeViewModel.searchQuery.isEmpty {
                                Text("Try a different search term")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                            } else if filterDifficulty != nil {
                                Text("Try a different difficulty filter")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            Spacer()
                        }
                        .padding()
                    } else {
                        // Routes list
                        RoutesListView(routes: filteredRoutes(), editable: true)
                            .environmentObject(routeViewModel)
                    }
                }
                .navigationTitle("My Routes")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingRouteEditor = true
                        } label: {
                            Image(systemName: "plus")
                                .foregroundColor(.white)
                        }
                    }
                }
                .navigationBarAppearance(backgroundColor: .clear, textColor: .white)
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
        var routes = routeViewModel.filteredUserRoutes
        
        // Apply difficulty filter if selected
        if let difficulty = filterDifficulty {
            routes = routes.filter { $0.difficulty == difficulty }
        }
        
        return routes
    }
} 
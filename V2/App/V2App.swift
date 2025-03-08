import SwiftUI

@main
struct V2App: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var routeViewModel = RouteViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(routeViewModel)
        }
    }
} 

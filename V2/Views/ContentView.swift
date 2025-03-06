import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            // Add animated gradient background at the root level
            AnimatedGradientBackground()
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            } else {
                Group {
                    if authManager.isAuthenticated {
                        DashboardView()
                    } else {
                        AuthView()
                    }
                }
            }
        }
        .task {
            // Check session on app launch
            await authManager.checkAndRestoreSession()
            isLoading = false
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
}
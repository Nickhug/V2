import SwiftUI

struct DashboardBackground: View {
    var body: some View {
        // Use the new MeshGradient implementation instead of the old background
        ModernGradientBackground()
    }
}

struct DashboardBackground_Previews: PreviewProvider {
    static var previews: some View {
        DashboardBackground()
    }
} 
import SwiftUI

struct VehiclesView: View {
    @StateObject private var viewModel = VehicleViewModel()
    @State private var showingAddVehicle = false
    @State private var error: Error?
    @State private var showingError = false
    
    var body: some View {
        ZStack {
            AnimatedGradientBackground()
            
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.large) {
                    // Header
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Your Vehicles")
                                .font(DesignSystem.Typography.largeTitle)
                                .foregroundColor(DesignSystem.Colors.text)
                            Text("Manage your car collection")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        DesignSystem.GradientButton(title: "Add") {
                            showingAddVehicle = true
                        }
                    }
                    .padding(.horizontal)
                    
                    if viewModel.isLoading {
                        VStack(spacing: DesignSystem.Spacing.medium) {
                            ForEach(0..<3) { _ in
                                VehicleCardSkeleton()
                            }
                        }
                        .padding(.horizontal)
                    } else if viewModel.vehicles.isEmpty {
                        // Empty state
                        VStack(spacing: 16) {
                            Image(systemName: "car.fill")
                                .font(.system(size: 64))
                                .foregroundColor(.white.opacity(0.3))
                            
                            Text("No Vehicles Yet")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Text("Add your first vehicle to get started")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.7))
                            
                            Button(action: { showingAddVehicle = true }) {
                                Text("Add Vehicle")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(DesignSystem.Colors.accentGradient)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(32)
                        .glassCard()
                        .padding()
                    } else {
                        // Vehicle list
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.vehicles, id: \.0.id) { vehicle, user in
                                VehicleCard(vehicle: vehicle, user: user, showOwner: true)
                                    .onTapGesture {
                                        // Handle vehicle tap
                                    }
                            }
                        }
                        .padding()
                    }
                }
                .padding(.top)
            }
        }
        .background(DesignSystem.Colors.backgroundGradient)
        .sheet(isPresented: $showingAddVehicle) {
            VehicleOnboardingView { newVehicle in
                Task {
                    do {
                        try await viewModel.createVehicle(newVehicle)
                        showingAddVehicle = false
                    } catch {
                        self.error = error
                        showingError = true
                    }
                }
            }
            .environmentObject(AuthManager())
        }
        .alert("Error", isPresented: $showingError, presenting: error) { _ in
            Button("OK", role: .cancel) {}
        } message: { error in
            Text(error.localizedDescription)
        }
        .task {
            await viewModel.fetchVehicles()
        }
    }
}

struct VehicleCardSkeleton: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            Rectangle()
                .fill(DesignSystem.Colors.accentGradient.opacity(0.3))
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                Rectangle()
                    .fill(DesignSystem.Colors.textSecondary.opacity(0.3))
                    .frame(width: 150, height: 24)
                    .clipShape(Capsule())
                
                HStack {
                    Rectangle()
                        .fill(DesignSystem.Colors.textSecondary.opacity(0.3))
                        .frame(width: 80, height: 20)
                        .clipShape(Capsule())
                    
                    Rectangle()
                        .fill(DesignSystem.Colors.textSecondary.opacity(0.3))
                        .frame(width: 100, height: 20)
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .redacted(reason: .placeholder)
        .shimmer()
    }
}

#Preview {
    VehiclesView()
} 
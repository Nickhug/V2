import SwiftUI

struct JoinMeetView: View {
    let meet: Meet
    @ObservedObject var viewModel: MeetViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedVehicleId: String? = nil
    @State private var isJoining = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isSuccessful = false
    @State private var showVehicleSelector = false
    
    private var userVehicles: [Vehicle] {
        viewModel.currentUser?.vehicles ?? []
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color.black.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Content
            VStack(spacing: 0) {
                // Header with dismiss button
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("Join Meet")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Empty view for balance
                    Color.clear
                        .frame(width: 36, height: 36)
                }
                .padding(.horizontal)
                .padding(.top, 16)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Meet info card
                        meetInfoCard
                        
                        // Vehicle selection section
                        vehicleSelectionSection
                        
                        // Join button
                        joinButton
                        
                        // Success animation
                        if isSuccessful {
                            successAnimation
                        }
                    }
                    .padding(.top, 16)
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
        }
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // MARK: - UI Components
    
    private var meetInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                // Meet cover image
                AsyncImageView(imageName: meet.coverImage)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    // Title
                    Text(meet.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    // Date and time
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(Color.white.opacity(0.6))
                        Text(meet.formattedDate)
                            .font(.subheadline)
                            .foregroundColor(Color.white.opacity(0.8))
                    }
                    
                    // Location
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(Color.white.opacity(0.6))
                        Text(meet.address)
                            .font(.subheadline)
                            .foregroundColor(Color.white.opacity(0.8))
                            .lineLimit(1)
                    }
                }
                .padding(.leading, 8)
            }
            
            // Attendees
            if !meet.attendees.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Attendees")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.white.opacity(0.8))
                    
                    HStack {
                        ForEach(meet.attendees.prefix(5), id: \.id) { attendee in
                            AsyncImageView(
                                imageName: attendee.profile.avatar,
                                avatarUrl: attendee.profile.avatarUrl
                            )
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                            )
                        }
                        
                        if meet.attendees.count > 5 {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(width: 32, height: 32)
                                Text("+\(meet.attendees.count - 5)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Spacer()
                        
                        Text("\(meet.attendees.count)/\(meet.capacity)")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Capsule())
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Material.ultraThinMaterial)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    private var vehicleSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose Your Vehicle")
                .font(.headline)
                .foregroundColor(.white)
            
            if userVehicles.isEmpty {
                // No vehicles message
                VStack(spacing: 16) {
                    Image(systemName: "car.fill")
                        .font(.system(size: 36))
                        .foregroundColor(Color.white.opacity(0.3))
                    
                    Text("You don't have any vehicles yet")
                        .font(.subheadline)
                        .foregroundColor(Color.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                    
                    Button {
                        // This would navigate to add vehicle
                    } label: {
                        Text("Add Vehicle")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                            )
                            .foregroundColor(.black)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.05))
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Material.ultraThinMaterial)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            } else {
                // Vehicle selection
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(userVehicles, id: \.id) { vehicle in
                            vehicleCard(vehicle)
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 4)
                }
            }
        }
    }
    
    private func vehicleCard(_ vehicle: Vehicle) -> some View {
        let isSelected = selectedVehicleId == vehicle.id
        
        return Button {
            selectedVehicleId = vehicle.id
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // Vehicle image
                if let firstPhoto = vehicle.photos.first, !firstPhoto.isEmpty {
                    AsyncImageView(imageName: firstPhoto)
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    // Placeholder
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                            .frame(height: 100)
                        
                        Image(systemName: "car.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
                
                // Vehicle info
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(vehicle.make) \(vehicle.model)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text(vehicle.formattedYear)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .frame(width: 160)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Material.ultraThinMaterial)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.white : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var joinButton: some View {
        Button {
            joinMeet()
        } label: {
            HStack {
                if isJoining {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        .padding(.trailing, 8)
                }
                
                Text(isJoining ? "Joining..." : "Join Meet")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(selectedVehicleId != nil && !isJoining ? Color.white : Color.white.opacity(0.3))
            )
            .foregroundColor(.black)
        }
        .disabled(selectedVehicleId == nil || isJoining)
        .padding(.top, 16)
    }
    
    private var successAnimation: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundColor(.green)
                .opacity(isSuccessful ? 1 : 0)
                .scaleEffect(isSuccessful ? 1 : 0.5)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isSuccessful)
            
            Text("You've joined the meet!")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .opacity(isSuccessful ? 1 : 0)
                .offset(y: isSuccessful ? 0 : 20)
                .animation(.easeInOut(duration: 0.5).delay(0.2), value: isSuccessful)
            
            Text("See you there!")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .opacity(isSuccessful ? 1 : 0)
                .offset(y: isSuccessful ? 0 : 20)
                .animation(.easeInOut(duration: 0.5).delay(0.3), value: isSuccessful)
            
            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                    )
                    .foregroundColor(.black)
            }
            .opacity(isSuccessful ? 1 : 0)
            .offset(y: isSuccessful ? 0 : 20)
            .animation(.easeInOut(duration: 0.5).delay(0.4), value: isSuccessful)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .transition(.opacity)
    }
    
    // MARK: - Actions
    
    private func joinMeet() {
        guard let vehicleId = selectedVehicleId else {
            showError = true
            errorMessage = "Please select a vehicle to join this meet."
            return
        }
        
        isJoining = true
        
        Task {
            do {
                try await viewModel.joinMeet(meet, vehicleId: vehicleId)
                
                await MainActor.run {
                    isJoining = false
                    isSuccessful = true
                    
                    // Dismiss after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    isJoining = false
                    showError = true
                    errorMessage = "Failed to join meet: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    JoinMeetView(
        meet: Meet.mockMeets[0], 
        viewModel: MeetViewModel()
    )
    .preferredColorScheme(.dark)
} 
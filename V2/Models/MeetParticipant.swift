import Foundation

struct MeetParticipant: Codable {
    let meetId: UUID
    let userId: UUID
    let vehicleId: UUID
    let joinedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case meetId = "meet_id"
        case userId = "user_id"
        case vehicleId = "vehicle_id"
        case joinedAt = "joined_at"
    }
} 
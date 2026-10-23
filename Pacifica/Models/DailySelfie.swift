import Foundation

struct DailySelfie: Codable, Identifiable, Equatable {
    let id: UUID
    let userID: UUID
    let storagePath: String
    let createdAt: String
    let expiresAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case storagePath = "storage_path"
        case createdAt = "created_at"
        case expiresAt = "expires_at"
    }
}

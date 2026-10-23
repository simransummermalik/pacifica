import Foundation

struct ActivityChallenge: Codable, Identifiable, Equatable {
    let id: UUID
    let creatorID: UUID
    let title: String
    let merchant: String
    let stakeAmount: Decimal
    let weekStart: String
    let status: String
    let winnerID: UUID?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case creatorID = "creator_id"
        case title
        case merchant
        case stakeAmount = "stake_amount"
        case weekStart = "week_start"
        case status
        case winnerID = "winner_id"
        case createdAt = "created_at"
    }
}

struct ActivityChallengeEntry: Codable, Identifiable, Equatable {
    let challengeID: UUID
    let userID: UUID
    let prediction: String
    let stakeAmount: Decimal
    let createdAt: String

    var id: String { "\(challengeID.uuidString)-\(userID.uuidString)" }

    enum CodingKeys: String, CodingKey {
        case challengeID = "challenge_id"
        case userID = "user_id"
        case prediction
        case stakeAmount = "stake_amount"
        case createdAt = "created_at"
    }
}

struct ActivityChallengeInsert: Encodable {
    let creatorID: UUID
    let title: String
    let merchant: String
    let stakeAmount: Decimal

    enum CodingKeys: String, CodingKey {
        case creatorID = "creator_id"
        case title
        case merchant
        case stakeAmount = "stake_amount"
    }
}

struct ActivityChallengeEntryInsert: Encodable {
    let challengeID: UUID
    let userID: UUID
    let prediction: String
    let stakeAmount: Decimal

    enum CodingKeys: String, CodingKey {
        case challengeID = "challenge_id"
        case userID = "user_id"
        case prediction
        case stakeAmount = "stake_amount"
    }
}

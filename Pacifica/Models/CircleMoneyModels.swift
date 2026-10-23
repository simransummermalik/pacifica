import Foundation

struct SpendingGoal: Codable, Identifiable, Equatable {
    let id: UUID
    let userID: UUID
    let title: String
    let merchant: String
    let weeklyLimit: Decimal
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case title
        case merchant
        case weeklyLimit = "weekly_limit"
        case createdAt = "created_at"
    }
}

struct MoneyPool: Codable, Identifiable, Equatable {
    let id: UUID
    let creatorID: UUID
    let title: String
    let purpose: String
    let targetAmount: Decimal
    let status: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case creatorID = "creator_id"
        case title
        case purpose
        case targetAmount = "target_amount"
        case status
        case createdAt = "created_at"
    }
}

struct MoneyPoolMember: Codable, Identifiable, Equatable {
    let poolID: UUID
    let userID: UUID
    let pledgedAmount: Decimal
    let createdAt: String

    var id: String { "\(poolID.uuidString)-\(userID.uuidString)" }

    enum CodingKeys: String, CodingKey {
        case poolID = "pool_id"
        case userID = "user_id"
        case pledgedAmount = "pledged_amount"
        case createdAt = "created_at"
    }
}

struct SpendingChallenge: Codable, Identifiable, Equatable {
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

struct ChallengeEntry: Codable, Identifiable, Equatable {
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

struct SpendingGoalInsert: Encodable {
    let userID: UUID
    let title: String
    let merchant: String
    let weeklyLimit: Decimal

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case title
        case merchant
        case weeklyLimit = "weekly_limit"
    }
}

struct MoneyPoolInsert: Encodable {
    let creatorID: UUID
    let title: String
    let purpose: String
    let targetAmount: Decimal

    enum CodingKeys: String, CodingKey {
        case creatorID = "creator_id"
        case title
        case purpose
        case targetAmount = "target_amount"
    }
}

struct PoolPledgeUpsert: Encodable {
    let poolID: UUID
    let userID: UUID
    let pledgedAmount: Decimal

    enum CodingKeys: String, CodingKey {
        case poolID = "pool_id"
        case userID = "user_id"
        case pledgedAmount = "pledged_amount"
    }
}

struct SpendingChallengeInsert: Encodable {
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

struct ChallengeEntryInsert: Encodable {
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

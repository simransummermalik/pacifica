import Foundation

struct Profile: Codable, Identifiable, Equatable {
    let id: UUID
    let username: String
    let displayName: String
    let avatarPath: String?
    let fishColor: String
    let fishType: String
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case displayName = "display_name"
        case avatarPath = "avatar_path"
        case fishColor = "fish_color"
        case fishType = "fish_type"
        case createdAt = "created_at"
    }
}

struct Friendship: Codable, Identifiable, Equatable {
    let id: UUID
    let requesterId: UUID
    let recipientId: UUID
    let status: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case requesterId = "requester_id"
        case recipientId = "recipient_id"
        case status
        case createdAt = "created_at"
    }

    func otherUserID(for userID: UUID) -> UUID {
        requesterId == userID ? recipientId : requesterId
    }
}

struct SpendingGoal: Codable, Identifiable, Equatable {
    let id: UUID
    let userId: UUID
    let title: String
    let merchantOrCategory: String?
    let goalType: String
    let targetAmount: Decimal?
    let startDate: String
    let endDate: String
    let active: Bool
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case merchantOrCategory = "merchant_or_category"
        case goalType = "goal_type"
        case targetAmount = "target_amount"
        case startDate = "start_date"
        case endDate = "end_date"
        case active
        case createdAt = "created_at"
    }
}

struct FeedPost: Codable, Identifiable, Equatable {
    let id: UUID
    let userId: UUID
    let transactionId: UUID?
    let spendingGoalId: UUID?
    let postType: String
    let caption: String?
    let merchant: String?
    let sharedAmount: Decimal?
    let hideAmount: Bool
    let hideMerchant: Bool
    let visibility: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case transactionId = "transaction_id"
        case spendingGoalId = "spending_goal_id"
        case postType = "post_type"
        case caption
        case merchant
        case sharedAmount = "shared_amount"
        case hideAmount = "hide_amount"
        case hideMerchant = "hide_merchant"
        case visibility
        case createdAt = "created_at"
    }
}

struct Reaction: Codable, Identifiable, Equatable {
    let id: UUID
    let postId: UUID
    let userId: UUID
    let reactionType: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case postId = "post_id"
        case userId = "user_id"
        case reactionType = "reaction_type"
        case createdAt = "created_at"
    }
}

struct Debt: Codable, Identifiable, Equatable {
    let id: UUID
    let userId: UUID
    let debtType: String
    let startingBalance: Decimal
    let remainingBalance: Decimal
    let annualInterestRate: Decimal
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case debtType = "debt_type"
        case startingBalance = "starting_balance"
        case remainingBalance = "remaining_balance"
        case annualInterestRate = "annual_interest_rate"
        case createdAt = "created_at"
    }

    var repaidAmount: Decimal {
        startingBalance - remainingBalance
    }

    var repaymentProgress: Double {
        guard startingBalance > 0 else { return 0 }
        let value = NSDecimalNumber(decimal: repaidAmount).doubleValue
        let total = NSDecimalNumber(decimal: startingBalance).doubleValue
        return min(max(value / total, 0), 1)
    }
}

struct DebtPayment: Codable, Identifiable, Equatable {
    let id: UUID
    let debtId: UUID
    let userId: UUID
    let amount: Decimal
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case debtId = "debt_id"
        case userId = "user_id"
        case amount
        case createdAt = "created_at"
    }
}

struct PaymentRequest: Codable, Identifiable, Equatable {
    let id: UUID
    let requesterId: UUID
    let recipientId: UUID
    let amount: Decimal
    let note: String?
    let status: String
    let createdAt: String
    let respondedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case requesterId = "requester_id"
        case recipientId = "recipient_id"
        case amount
        case note
        case status
        case createdAt = "created_at"
        case respondedAt = "responded_at"
    }
}

struct FinancialDataCache: Codable, Identifiable, Equatable {
    let id: UUID
    let source: String
    let seriesId: String
    let observedPeriod: String
    let value: Decimal
    let fetchedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case source
        case seriesId = "series_id"
        case observedPeriod = "observed_period"
        case value
        case fetchedAt = "fetched_at"
    }
}

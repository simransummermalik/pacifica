import Foundation

struct SpendingTransaction: Codable, Identifiable, Equatable {
    let id: UUID
    let userID: UUID
    let merchant: String
    let amount: Decimal
    let category: String
    let spentAt: String
    let visibility: String
    let sourceFeedPostID: UUID?

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case merchant
        case amount
        case category
        case spentAt = "spent_at"
        case visibility
        case sourceFeedPostID = "source_feed_post_id"
    }
}

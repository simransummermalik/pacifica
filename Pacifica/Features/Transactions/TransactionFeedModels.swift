import Foundation

struct ActivityPost: Codable, Identifiable, Equatable {
    let id: UUID
    let userID: UUID
    let postType: String
    let caption: String?
    let merchant: String?
    let sharedAmount: Decimal?
    let visibility: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case postType = "post_type"
        case caption
        case merchant
        case sharedAmount = "shared_amount"
        case visibility
        case createdAt = "created_at"
    }
}

struct ActivityProfile: Decodable, Identifiable {
    let id: UUID
    let displayName: String
    let username: String

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case username
    }
}

struct ActivityReaction: Codable, Identifiable, Equatable {
    let id: UUID
    let postID: UUID
    let userID: UUID
    let reactionType: String

    enum CodingKeys: String, CodingKey {
        case id
        case postID = "post_id"
        case userID = "user_id"
        case reactionType = "reaction_type"
    }
}

struct ActivityComment: Codable, Identifiable, Equatable {
    let id: UUID
    let postID: UUID
    let userID: UUID
    let body: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case postID = "post_id"
        case userID = "user_id"
        case body
        case createdAt = "created_at"
    }
}

struct VoteCounts: Equatable {
    var upvotes = 0
    var downvotes = 0
}

struct CircleStats: Equatable {
    let points: Int
    let level: Int
    let progress: Double
    let commentsWritten: Int
    let votesGiven: Int
    let votesReceived: Int

    static let empty = CircleStats(
        points: 0,
        level: 1,
        progress: 0,
        commentsWritten: 0,
        votesGiven: 0,
        votesReceived: 0
    )
}

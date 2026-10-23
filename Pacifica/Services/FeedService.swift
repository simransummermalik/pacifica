import Foundation

struct FeedService {
    private let client = SupabaseClientProvider.shared

    func fetchPosts(limit: Int = 50) async throws -> [FeedPost] {
        try await client
            .from("feed_posts")
            .select()
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    func createPost(
        transactionID: UUID? = nil,
        spendingGoalID: UUID? = nil,
        postType: String,
        caption: String?,
        merchant: String?,
        sharedAmount: Decimal?,
        hideAmount: Bool,
        hideMerchant: Bool,
        visibility: String = "circle"
    ) async throws -> FeedPost {
        let userID = try currentUserID()
        guard ["circle", "private"].contains(visibility) else {
            throw PacificaServiceError.invalidInput("Post visibility is invalid.")
        }

        let payload = FeedPostInsert(
            userID: userID,
            transactionID: transactionID,
            spendingGoalID: spendingGoalID,
            postType: postType,
            caption: caption,
            merchant: merchant,
            sharedAmount: sharedAmount,
            hideAmount: hideAmount,
            hideMerchant: hideMerchant,
            visibility: visibility
        )

        return try await client
            .from("feed_posts")
            .insert(payload)
            .select()
            .single()
            .execute()
            .value
    }

    func updatePostPrivacy(
        postID: UUID,
        hideAmount: Bool,
        hideMerchant: Bool,
        visibility: String
    ) async throws {
        try await client
            .from("feed_posts")
            .update(
                FeedPostPrivacyUpdate(
                    hideAmount: hideAmount,
                    hideMerchant: hideMerchant,
                    visibility: visibility
                )
            )
            .eq("id", value: postID.uuidString)
            .execute()
    }

    func deletePost(postID: UUID) async throws {
        try await client
            .from("feed_posts")
            .delete()
            .eq("id", value: postID.uuidString)
            .execute()
    }

    func fetchReactions(postID: UUID) async throws -> [Reaction] {
        try await client
            .from("reactions")
            .select()
            .eq("post_id", value: postID.uuidString)
            .execute()
            .value
    }

    func setReaction(postID: UUID, reactionType: String) async throws {
        let userID = try currentUserID()
        guard ["upvote", "downvote"].contains(reactionType) else {
            throw PacificaServiceError.invalidInput("Reaction type is invalid.")
        }

        let payload = ReactionUpsert(
            postID: postID,
            userID: userID,
            reactionType: reactionType
        )

        try await client
            .from("reactions")
            .upsert(payload, onConflict: "post_id,user_id", returning: .minimal)
            .execute()
    }

    func removeReaction(postID: UUID) async throws {
        let userID = try currentUserID()

        try await client
            .from("reactions")
            .delete()
            .eq("post_id", value: postID.uuidString)
            .eq("user_id", value: userID.uuidString)
            .execute()
    }

    private func currentUserID() throws -> UUID {
        guard let userID = client.auth.currentUser?.id else {
            throw PacificaServiceError.notSignedIn
        }
        return userID
    }
}

private struct FeedPostInsert: Encodable {
    let userID: UUID
    let transactionID: UUID?
    let spendingGoalID: UUID?
    let postType: String
    let caption: String?
    let merchant: String?
    let sharedAmount: Decimal?
    let hideAmount: Bool
    let hideMerchant: Bool
    let visibility: String

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case transactionID = "transaction_id"
        case spendingGoalID = "spending_goal_id"
        case postType = "post_type"
        case caption
        case merchant
        case sharedAmount = "shared_amount"
        case hideAmount = "hide_amount"
        case hideMerchant = "hide_merchant"
        case visibility
    }
}

private struct ReactionUpsert: Encodable {
    let postID: UUID
    let userID: UUID
    let reactionType: String

    enum CodingKeys: String, CodingKey {
        case postID = "post_id"
        case userID = "user_id"
        case reactionType = "reaction_type"
    }
}

private struct FeedPostPrivacyUpdate: Encodable {
    let hideAmount: Bool
    let hideMerchant: Bool
    let visibility: String

    enum CodingKeys: String, CodingKey {
        case hideAmount = "hide_amount"
        case hideMerchant = "hide_merchant"
        case visibility
    }
}

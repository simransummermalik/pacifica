import Foundation
import Supabase

struct ActivityService {
    private let client = SupabaseClientProvider.shared

    func syncGoalBreakUpdates() async throws {
        try await client
            .rpc("sync_goal_break_updates")
            .execute()
    }

    func fetchPosts(limit: Int = 50) async throws -> [ActivityPost] {
        try await client
            .from("feed_posts")
            .select("id, user_id, post_type, caption, merchant, shared_amount, visibility, created_at")
            .eq("visibility", value: "circle")
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    func fetchSpendingTransactions(limit: Int = 500) async throws -> [SpendingTransaction] {
        try await client
            .from("spending_transactions")
            .select("id, user_id, merchant, amount, category, spent_at, visibility, source_feed_post_id")
            .eq("visibility", value: "circle")
            .order("spent_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    func createSpendingTransaction(
        merchant: String,
        amount: Decimal,
        category: ReefCategory,
        spentAt: String? = nil,
        visibility: String = "circle"
    ) async throws -> SpendingTransaction {
        guard category != .all,
              !merchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              amount > 0,
              ["circle", "private"].contains(visibility) else {
            throw PacificaServiceError.invalidInput("Enter a merchant, category, and amount greater than zero.")
        }

        guard let userID = client.auth.currentUser?.id else {
            throw PacificaServiceError.notSignedIn
        }

        return try await client
            .from("spending_transactions")
            .insert(SpendingTransactionInsert(
                userID: userID,
                merchant: merchant.trimmingCharacters(in: .whitespacesAndNewlines),
                amount: amount,
                category: category.rawValue,
                spentAt: spentAt ?? Self.iso8601String(Date()),
                visibility: visibility
            ))
            .select()
            .single()
            .execute()
            .value
    }

    private static func iso8601String(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }

    func fetchProfiles() async throws -> [ActivityProfile] {
        try await client
            .from("profiles")
            .select("id, display_name, username")
            .order("username", ascending: true)
            .execute()
            .value
    }

    func fetchReactions() async throws -> [ActivityReaction] {
        try await client
            .from("reactions")
            .select("id, post_id, user_id, reaction_type")
            .execute()
            .value
    }

    func fetchComments() async throws -> [ActivityComment] {
        try await client
            .from("activity_comments")
            .select("id, post_id, user_id, body, created_at")
            .order("created_at", ascending: true)
            .execute()
            .value
    }

    func addComment(postID: UUID, body: String) async throws -> ActivityComment {
        let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedBody.isEmpty, trimmedBody.count <= 280 else {
            throw PacificaServiceError.invalidInput("Comments must be 1–280 characters.")
        }

        guard let userID = client.auth.currentUser?.id else {
            throw PacificaServiceError.notSignedIn
        }

        return try await client
            .from("activity_comments")
            .insert(
                ActivityCommentInsert(
                    postID: postID,
                    userID: userID,
                    body: trimmedBody
                )
            )
            .select()
            .single()
            .execute()
            .value
    }

    func setReaction(postID: UUID, reactionType: String) async throws {
        guard ["upvote", "downvote"].contains(reactionType) else {
            throw PacificaServiceError.invalidInput("Reaction type is invalid.")
        }

        guard let userID = client.auth.currentUser?.id else {
            throw PacificaServiceError.notSignedIn
        }

        try await client
            .from("reactions")
            .upsert(
                ReactionUpsert(
                    postID: postID,
                    userID: userID,
                    reactionType: reactionType
                ),
                onConflict: "post_id,user_id",
                returning: .minimal
            )
            .execute()
    }

    func removeReaction(postID: UUID) async throws {
        guard let userID = client.auth.currentUser?.id else {
            throw PacificaServiceError.notSignedIn
        }

        try await client
            .from("reactions")
            .delete()
            .eq("post_id", value: postID.uuidString)
            .eq("user_id", value: userID.uuidString)
            .execute()
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

private struct ActivityCommentInsert: Encodable {
    let postID: UUID
    let userID: UUID
    let body: String

    enum CodingKeys: String, CodingKey {
        case postID = "post_id"
        case userID = "user_id"
        case body
    }
}

private struct SpendingTransactionInsert: Encodable {
    let userID: UUID
    let merchant: String
    let amount: Decimal
    let category: String
    let spentAt: String?
    let visibility: String

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case merchant
        case amount
        case category
        case spentAt = "spent_at"
        case visibility
    }
}

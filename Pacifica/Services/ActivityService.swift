import Foundation
import Supabase

struct ActivityService {
    private let client = SupabaseClientProvider.shared

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

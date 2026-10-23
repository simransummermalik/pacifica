import Foundation

struct FriendService {
    private let client = SupabaseClientProvider.shared

    func fetchFriendships() async throws -> [Friendship] {
        try await client
            .from("friendships")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func sendFriendRequest(to recipientID: UUID) async throws -> Friendship {
        let currentUserID = try currentUserID()
        let payload = FriendshipInsert(
            requesterId: currentUserID,
            recipientId: recipientID,
            status: "pending"
        )

        return try await client
            .from("friendships")
            .insert(payload)
            .select()
            .single()
            .execute()
            .value
    }

    func respond(to friendshipID: UUID, status: String) async throws {
        guard ["accepted", "declined"].contains(status) else {
            throw PacificaServiceError.invalidInput("Friend request status is invalid.")
        }

        try await client
            .from("friendships")
            .update(["status": status])
            .eq("id", value: friendshipID.uuidString)
            .execute()
    }

    func remove(friendshipID: UUID) async throws {
        try await client
            .from("friendships")
            .delete()
            .eq("id", value: friendshipID.uuidString)
            .execute()
    }

    private func currentUserID() throws -> UUID {
        guard let userID = client.auth.currentUser?.id else {
            throw PacificaServiceError.notSignedIn
        }
        return userID
    }
}

private struct FriendshipInsert: Encodable {
    let requesterId: UUID
    let recipientId: UUID
    let status: String

    enum CodingKeys: String, CodingKey {
        case requesterId = "requester_id"
        case recipientId = "recipient_id"
        case status
    }
}

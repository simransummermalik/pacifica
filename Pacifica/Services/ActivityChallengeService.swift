import Foundation
import Supabase

struct ActivityChallengeService {
    private let client = SupabaseClientProvider.shared

    func currentUserID() throws -> UUID {
        guard let id = client.auth.currentUser?.id else {
            throw PacificaServiceError.notSignedIn
        }
        return id
    }

    func fetchChallenges() async throws -> [ActivityChallenge] {
        try await client
            .from("spending_challenges")
            .select()
            .eq("status", value: "open")
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func fetchEntries() async throws -> [ActivityChallengeEntry] {
        try await client
            .from("challenge_entries")
            .select()
            .execute()
            .value
    }

    func createChallenge(title: String, merchant: String) async throws -> ActivityChallenge {
        let creatorID = try currentUserID()
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !merchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PacificaServiceError.invalidInput("Enter a challenge title and merchant.")
        }

        return try await client
            .from("spending_challenges")
            .insert(ActivityChallengeInsert(
                creatorID: creatorID,
                title: title,
                merchant: merchant,
                stakeAmount: 2
            ))
            .select()
            .single()
            .execute()
            .value
    }

    func joinChallenge(challengeID: UUID, prediction: String) async throws {
        let userID = try currentUserID()
        let trimmed = prediction.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= 140 else {
            throw PacificaServiceError.invalidInput("Prediction must be 1–140 characters.")
        }

        try await client
            .from("challenge_entries")
            .upsert(
                ActivityChallengeEntryInsert(
                    challengeID: challengeID,
                    userID: userID,
                    prediction: trimmed,
                    stakeAmount: 2
                ),
                onConflict: "challenge_id,user_id",
                returning: .minimal
            )
            .execute()
    }
}

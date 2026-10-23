import Foundation
import Supabase

struct CircleMoneyService {
    private let client = SupabaseClientProvider.shared

    func currentUserID() throws -> UUID {
        guard let id = client.auth.currentUser?.id else {
            throw PacificaServiceError.notSignedIn
        }
        return id
    }

    func fetchGoals(userID: UUID) async throws -> [SpendingGoal] {
        try await client
            .from("spending_goals")
            .select()
            .eq("user_id", value: userID.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func createGoal(title: String, merchant: String, weeklyLimit: Decimal) async throws -> SpendingGoal {
        let userID = try currentUserID()
        return try await client
            .from("spending_goals")
            .insert(SpendingGoalInsert(
                userID: userID,
                title: title,
                merchant: merchant,
                weeklyLimit: weeklyLimit
            ))
            .select()
            .single()
            .execute()
            .value
    }

    func fetchPools() async throws -> [MoneyPool] {
        try await client
            .from("money_pools")
            .select()
            .eq("status", value: "open")
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func fetchPoolMembers() async throws -> [MoneyPoolMember] {
        try await client
            .from("money_pool_members")
            .select()
            .execute()
            .value
    }

    func createPool(title: String, purpose: String, targetAmount: Decimal) async throws -> MoneyPool {
        let creatorID = try currentUserID()
        return try await client
            .from("money_pools")
            .insert(MoneyPoolInsert(
                creatorID: creatorID,
                title: title,
                purpose: purpose,
                targetAmount: targetAmount
            ))
            .select()
            .single()
            .execute()
            .value
    }

    func pledge(poolID: UUID, amount: Decimal) async throws {
        let userID = try currentUserID()
        try await client
            .from("money_pool_members")
            .upsert(
                PoolPledgeUpsert(poolID: poolID, userID: userID, pledgedAmount: amount),
                onConflict: "pool_id,user_id",
                returning: .minimal
            )
            .execute()
    }

    func fetchChallenges() async throws -> [SpendingChallenge] {
        try await client
            .from("spending_challenges")
            .select()
            .eq("status", value: "open")
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func fetchChallengeEntries() async throws -> [ChallengeEntry] {
        try await client
            .from("challenge_entries")
            .select()
            .execute()
            .value
    }

    func createChallenge(title: String, merchant: String) async throws -> SpendingChallenge {
        let creatorID = try currentUserID()
        return try await client
            .from("spending_challenges")
            .insert(SpendingChallengeInsert(
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
        try await client
            .from("challenge_entries")
            .upsert(
                ChallengeEntryInsert(
                    challengeID: challengeID,
                    userID: userID,
                    prediction: prediction,
                    stakeAmount: 2
                ),
                onConflict: "challenge_id,user_id",
                returning: .minimal
            )
            .execute()
    }
}

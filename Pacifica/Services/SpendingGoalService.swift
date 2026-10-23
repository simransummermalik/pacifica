import Foundation

struct SpendingGoalService {
    private let client = SupabaseClientProvider.shared

    func fetchGoals() async throws -> [SpendingGoal] {
        try await client
            .from("spending_goals")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func createGoal(
        title: String,
        merchantOrCategory: String?,
        goalType: String,
        targetAmount: Decimal?,
        startDate: String,
        endDate: String
    ) async throws -> SpendingGoal {
        let userID = try currentUserID()
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PacificaServiceError.invalidInput("Goal title cannot be empty.")
        }
        guard ["merchant", "category", "general"].contains(goalType) else {
            throw PacificaServiceError.invalidInput("Goal type is invalid.")
        }

        let payload = SpendingGoalInsert(
            userID: userID,
            title: title,
            merchantOrCategory: merchantOrCategory,
            goalType: goalType,
            targetAmount: targetAmount,
            startDate: startDate,
            endDate: endDate,
            merchant: merchantOrCategory,
            weeklyLimit: targetAmount
        )

        return try await client
            .from("spending_goals")
            .insert(payload)
            .select()
            .single()
            .execute()
            .value
    }

    func setGoalActive(goalID: UUID, active: Bool) async throws {
        try await client
            .from("spending_goals")
            .update(["active": active])
            .eq("id", value: goalID.uuidString)
            .execute()
    }

    func deleteGoal(goalID: UUID) async throws {
        try await client
            .from("spending_goals")
            .delete()
            .eq("id", value: goalID.uuidString)
            .execute()
    }

    private func currentUserID() throws -> UUID {
        guard let userID = client.auth.currentUser?.id else {
            throw PacificaServiceError.notSignedIn
        }
        return userID
    }
}

private struct SpendingGoalInsert: Encodable {
    let userID: UUID
    let title: String
    let merchantOrCategory: String?
    let goalType: String
    let targetAmount: Decimal?
    let startDate: String
    let endDate: String
    let merchant: String?
    let weeklyLimit: Decimal?

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case title
        case merchantOrCategory = "merchant_or_category"
        case goalType = "goal_type"
        case targetAmount = "target_amount"
        case startDate = "start_date"
        case endDate = "end_date"
        case merchant
        case weeklyLimit = "weekly_limit"
    }
}

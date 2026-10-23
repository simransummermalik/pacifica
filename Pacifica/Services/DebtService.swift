import Foundation

struct DebtService {
    private let client = SupabaseClientProvider.shared

    func fetchDebts() async throws -> [Debt] {
        try await client
            .from("debts")
            .select()
            .order("created_at")
            .execute()
            .value
    }

    func createDebt(
        type: String,
        startingBalance: Decimal,
        annualInterestRate: Decimal = 0
    ) async throws -> Debt {
        let userID = try currentUserID()
        guard startingBalance > 0 else {
            throw PacificaServiceError.invalidInput("Starting debt must be greater than zero.")
        }

        let payload = DebtInsert(
            userID: userID,
            debtType: type,
            startingBalance: startingBalance,
            remainingBalance: startingBalance,
            annualInterestRate: annualInterestRate
        )

        return try await client
            .from("debts")
            .insert(payload)
            .select()
            .single()
            .execute()
            .value
    }

    func fetchPayments(debtID: UUID) async throws -> [DebtPayment] {
        try await client
            .from("debt_payments")
            .select()
            .eq("debt_id", value: debtID.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func recordPayment(
        debtID: UUID,
        amount: Decimal,
        idempotencyKey: UUID = UUID()
    ) async throws -> DebtPayment {
        guard amount > 0 else {
            throw PacificaServiceError.invalidInput("Debt payment must be greater than zero.")
        }

        let params = RecordDebtPaymentParameters(
            debtID: debtID,
            amount: amount,
            idempotencyKey: idempotencyKey
        )

        return try await client
            .rpc("record_debt_payment", params: params)
            .execute()
            .value
    }

    func deleteDebt(debtID: UUID) async throws {
        try await client
            .from("debts")
            .delete()
            .eq("id", value: debtID.uuidString)
            .execute()
    }

    private func currentUserID() throws -> UUID {
        guard let userID = client.auth.currentUser?.id else {
            throw PacificaServiceError.notSignedIn
        }
        return userID
    }
}

private struct DebtInsert: Encodable {
    let userID: UUID
    let debtType: String
    let startingBalance: Decimal
    let remainingBalance: Decimal
    let annualInterestRate: Decimal

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case debtType = "debt_type"
        case startingBalance = "starting_balance"
        case remainingBalance = "remaining_balance"
        case annualInterestRate = "annual_interest_rate"
    }
}

private struct RecordDebtPaymentParameters: Encodable {
    let debtID: UUID
    let amount: Decimal
    let idempotencyKey: UUID

    enum CodingKeys: String, CodingKey {
        case debtID = "p_debt_id"
        case amount = "p_amount"
        case idempotencyKey = "p_idempotency_key"
    }
}

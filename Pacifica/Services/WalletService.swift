import Foundation

struct WalletService {
    private let client = SupabaseClientProvider.shared

    func fetchWallet(userID: UUID) async throws -> Wallet {
        try await client
            .from("wallets")
            .select("user_id, demo_balance")
            .eq("user_id", value: userID.uuidString)
            .single()
            .execute()
            .value
    }

    func fetchTransactions(limit: Int = 50) async throws -> [Transaction] {
        try await client
            .from("transactions")
            .select("id, sender_id, recipient_id, amount, note, status, transaction_type, created_at")
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    func adjustDemoBalance(delta: Decimal) async throws -> Wallet {
        guard delta != 0 else {
            throw PacificaServiceError.invalidInput("Enter an amount greater than zero.")
        }

        return try await client
            .rpc("adjust_demo_balance", params: AdjustDemoBalanceParameters(delta: delta))
            .execute()
            .value
    }

    func sendMoney(
        to recipientID: UUID,
        amount: Decimal,
        note: String? = nil,
        idempotencyKey: UUID = UUID()
    ) async throws -> Transaction {
        guard amount > 0 else {
            throw PacificaServiceError.invalidInput("Payment amount must be greater than zero.")
        }

        let params = SendMoneyParameters(
            recipientID: recipientID,
            amount: amount,
            note: note,
            idempotencyKey: idempotencyKey
        )

        return try await client
            .rpc("send_money", params: params)
            .execute()
            .value
    }

    func fetchPaymentRequests() async throws -> [PaymentRequest] {
        try await client
            .from("payment_requests")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func createPaymentRequest(
        from recipientID: UUID,
        amount: Decimal,
        note: String? = nil,
        idempotencyKey: UUID = UUID()
    ) async throws -> PaymentRequest {
        let requesterID = try currentUserID()
        guard amount > 0 else {
            throw PacificaServiceError.invalidInput("Request amount must be greater than zero.")
        }

        let payload = PaymentRequestInsert(
            requesterID: requesterID,
            recipientID: recipientID,
            amount: amount,
            note: note,
            idempotencyKey: idempotencyKey
        )

        return try await client
            .from("payment_requests")
            .insert(payload)
            .select()
            .single()
            .execute()
            .value
    }

    func respondToPaymentRequest(
        requestID: UUID,
        action: String,
        idempotencyKey: UUID = UUID()
    ) async throws -> PaymentRequest {
        guard ["accepted", "declined"].contains(action) else {
            throw PacificaServiceError.invalidInput("Payment request action is invalid.")
        }

        let params = RespondToPaymentRequestParameters(
            requestID: requestID,
            action: action,
            idempotencyKey: idempotencyKey
        )

        return try await client
            .rpc("respond_to_payment_request", params: params)
            .execute()
            .value
    }

    private func currentUserID() throws -> UUID {
        guard let userID = client.auth.currentUser?.id else {
            throw PacificaServiceError.notSignedIn
        }
        return userID
    }
}

private struct SendMoneyParameters: Encodable {
    let recipientID: UUID
    let amount: Decimal
    let note: String?
    let idempotencyKey: UUID

    enum CodingKeys: String, CodingKey {
        case recipientID = "p_recipient_id"
        case amount = "p_amount"
        case note = "p_note"
        case idempotencyKey = "p_idempotency_key"
    }
}

private struct PaymentRequestInsert: Encodable {
    let requesterID: UUID
    let recipientID: UUID
    let amount: Decimal
    let note: String?
    let idempotencyKey: UUID

    enum CodingKeys: String, CodingKey {
        case requesterID = "requester_id"
        case recipientID = "recipient_id"
        case amount
        case note
        case idempotencyKey = "idempotency_key"
    }
}

private struct RespondToPaymentRequestParameters: Encodable {
    let requestID: UUID
    let action: String
    let idempotencyKey: UUID

    enum CodingKeys: String, CodingKey {
        case requestID = "p_request_id"
        case action = "p_action"
        case idempotencyKey = "p_idempotency_key"
    }
}

private struct AdjustDemoBalanceParameters: Encodable {
    let delta: Decimal

    enum CodingKeys: String, CodingKey {
        case delta = "p_delta"
    }
}

import Foundation
import Supabase

@MainActor
final class WalletViewModel: ObservableObject {
    @Published private(set) var balance: Decimal = 0
    @Published private(set) var transactions: [Transaction] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    var formattedBalance: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSDecimalNumber(decimal: balance)) ?? "$0.00"
    }

    func adjustBalance(delta: Decimal) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let wallet = try await WalletService().adjustDemoBalance(delta: delta)
            balance = wallet.demoBalance
            transactions = try await WalletService().fetchTransactions()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func sendMoney(
        to recipientID: UUID,
        amount: Decimal,
        note: String?
    ) async throws {
        _ = try await WalletService().sendMoney(
            to: recipientID,
            amount: amount,
            note: note
        )

        try await refresh(userID: SupabaseClientProvider.shared.auth.currentUser?.id)
    }

    func load(userID: UUID) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await refresh(userID: userID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func refresh(userID: UUID?) async throws {
        guard let userID else {
            throw PacificaServiceError.notSignedIn
        }

        let wallet: Wallet = try await SupabaseClientProvider.shared
            .from("wallets")
            .select("user_id, demo_balance")
            .eq("user_id", value: userID.uuidString)
            .single()
            .execute()
            .value

        balance = wallet.demoBalance

        transactions = try await SupabaseClientProvider.shared
            .from("transactions")
            .select("id, sender_id, recipient_id, amount, note, status, transaction_type, created_at")
            .order("created_at", ascending: false)
            .limit(20)
            .execute()
            .value
    }
}

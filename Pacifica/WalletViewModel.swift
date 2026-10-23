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

    func load(userID: UUID) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
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
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

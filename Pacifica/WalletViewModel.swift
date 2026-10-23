import Foundation
import Supabase

@MainActor
final class WalletViewModel: ObservableObject {
    @Published private(set) var balance: Decimal = 0
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
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

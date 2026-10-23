import Foundation
import Supabase

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

    func adjustDemoBalance(delta: Decimal) async throws -> Wallet {
        try await client
            .rpc("adjust_demo_balance", params: AdjustDemoBalanceParameters(delta: delta))
            .execute()
            .value
    }
}

private struct AdjustDemoBalanceParameters: Encodable {
    let delta: Decimal

    enum CodingKeys: String, CodingKey {
        case delta = "p_delta"
    }
}

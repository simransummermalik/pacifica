import Combine
import Foundation

@MainActor
final class HomeWalletViewModel: ObservableObject {
    let userID: UUID

    @Published private(set) var balance: Decimal = 0
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    init(userID: UUID) {
        self.userID = userID
    }

    var formattedBalance: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSDecimalNumber(decimal: balance)) ?? "$0.00"
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            balance = try await WalletService().fetchWallet(userID: userID).demoBalance
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func adjust(delta: Decimal) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            balance = try await WalletService().adjustDemoBalance(delta: delta).demoBalance
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}

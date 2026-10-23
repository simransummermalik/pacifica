import Foundation

struct Wallet: Decodable {
    let userId: UUID
    let demoBalance: Decimal

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case demoBalance = "demo_balance"
    }
}

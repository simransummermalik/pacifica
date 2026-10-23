import Foundation

struct Wallet: Decodable {
    let userID: UUID
    let demoBalance: Decimal

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case demoBalance = "demo_balance"
    }
}

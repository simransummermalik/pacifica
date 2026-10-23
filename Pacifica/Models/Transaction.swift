import Foundation

struct Transaction: Decodable, Identifiable {
    let id: UUID
    let senderId: UUID
    let recipientId: UUID
    let amount: Decimal
    let note: String?
    let status: String
    let transactionType: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case senderId = "sender_id"
        case recipientId = "recipient_id"
        case amount
        case note
        case status
        case transactionType = "transaction_type"
        case createdAt = "created_at"
    }

    func isIncoming(for userID: UUID) -> Bool {
        recipientId == userID
    }

    var title: String {
        if let note, !note.isEmpty {
            return note
        }
        return transactionType.capitalized
    }

    var formattedDate: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = formatter.date(from: createdAt) else {
            return createdAt
        }

        return date.formatted(date: .abbreviated, time: .shortened)
    }
}

import Foundation

enum PacificaServiceError: LocalizedError {
    case notSignedIn
    case invalidInput(String)
    case selfieCooldown(Date)
    case missingSelfie
    case financialDataUnavailable

    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "You must be signed in to do that."
        case .invalidInput(let message):
            return message
        case .selfieCooldown(let date):
            return "Your next selfie is available after \(date.formatted(date: .abbreviated, time: .shortened))."
        case .missingSelfie:
            return "No selfie was found."
        case .financialDataUnavailable:
            return "Financial data is not available right now."
        }
    }
}

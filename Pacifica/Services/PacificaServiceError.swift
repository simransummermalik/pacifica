import Foundation

enum PacificaServiceError: LocalizedError {
    case notSignedIn
    case invalidInput(String)
    case selfieCooldown(Date)
    case missingSelfie

    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            "You must be signed in to do that."
        case .invalidInput(let message):
            message
        case .selfieCooldown(let date):
            "Your next selfie is available after \(date.formatted(date: .abbreviated, time: .shortened))."
        case .missingSelfie:
            "No selfie was found."
        }
    }
}

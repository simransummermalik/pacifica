import Foundation

enum PacificaServiceError: LocalizedError {
    case notSignedIn
    case selfieCooldown(Date)
    case missingSelfie

    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            "You must be signed in to do that."
        case .selfieCooldown(let date):
            "Your next selfie is available after \(date.formatted(date: .abbreviated, time: .shortened))."
        case .missingSelfie:
            "No selfie was found."
        }
    }
}

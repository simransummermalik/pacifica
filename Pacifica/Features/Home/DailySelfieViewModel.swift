import Foundation
import Combine
import UIKit

@MainActor
final class DailySelfieViewModel: ObservableObject {
    let userID: UUID

    @Published private(set) var selfie: DailySelfie?
    @Published private(set) var image: UIImage?
    @Published private(set) var imagesByUserID: [UUID: UIImage] = [:]
    @Published private(set) var isLoading = false
    @Published private(set) var isSaving = false
    @Published var errorMessage: String?

    init(userID: UUID) {
        self.userID = userID
    }

    var isEligible: Bool {
        guard let expiresAt = expiryDate else { return true }
        return expiresAt <= Date()
    }

    var statusText: String {
        if let expiryDate, expiryDate > Date() {
            return "Your selfie is live until \(expiryDate.formatted(date: .omitted, time: .shortened))."
        }
        return "Take an optional selfie for your fish."
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let service = SelfieService()
            async let ownRequest = service.fetchLatestSelfie(userID: userID)
            async let activeRequest = service.fetchActiveSelfies()

            let own = try await ownRequest
            let active = try await activeRequest
            selfie = own

            var loadedImages: [UUID: UIImage] = [:]
            for activeSelfie in active {
                do {
                    let data = try await service.downloadSelfie(path: activeSelfie.storagePath)
                    if let image = UIImage(data: data) {
                        loadedImages[activeSelfie.userID] = image
                    }
                } catch {
                    // One inaccessible friend image should not hide the rest of the reef.
                    continue
                }
            }

            imagesByUserID = loadedImages
            image = loadedImages[userID]
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func save(image: UIImage) async -> Bool {
        guard let data = image.jpegData(compressionQuality: 0.85) else {
            errorMessage = "That photo could not be prepared."
            return false
        }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            selfie = try await SelfieService().uploadSelfie(imageData: data, userID: userID)
            self.image = image
            imagesByUserID[userID] = image
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func remove() async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            try await SelfieService().removeLatestSelfie(userID: userID)
            selfie = nil
            image = nil
            imagesByUserID[userID] = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private var expiryDate: Date? {
        guard let value = selfie?.expiresAt else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: value) ?? ISO8601DateFormatter().date(from: value)
    }
}

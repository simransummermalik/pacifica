import Foundation
import Supabase

struct SelfieService {
    private let client = SupabaseClientProvider.shared
    private let bucket = "daily-selfies"

    func fetchLatestSelfie(userID: UUID) async throws -> DailySelfie? {
        let selfies: [DailySelfie] = try await client
            .from("daily_selfies")
            .select()
            .eq("user_id", value: userID.uuidString)
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value

        return selfies.first
    }

    /// Returns the currently live selfie for every user the signed-in account can see.
    /// The database policy scopes this to the Pacifica circle.
    func fetchActiveSelfies() async throws -> [DailySelfie] {
        let selfies: [DailySelfie] = try await client
            .from("daily_selfies")
            .select()
            .gt("expires_at", value: iso8601String(Date()))
            .order("created_at", ascending: false)
            .execute()
            .value

        // Keep only the newest live selfie for each person.
        var newestByUser: [UUID: DailySelfie] = [:]
        for selfie in selfies where newestByUser[selfie.userID] == nil {
            newestByUser[selfie.userID] = selfie
        }
        return Array(newestByUser.values)
    }

    func uploadSelfie(imageData: Data, userID: UUID) async throws -> DailySelfie {
        guard let authenticatedUserID = client.auth.currentUser?.id else {
            throw PacificaServiceError.notSignedIn
        }

        // Use the authenticated ID for both the storage folder and database row.
        // This prevents an RLS rejection if a stale UI user ID is passed in.
        let ownerID = authenticatedUserID

        if let latest = try await fetchLatestSelfie(userID: ownerID),
           let expiresAt = parseDate(latest.expiresAt),
           expiresAt > Date()
        {
            throw PacificaServiceError.selfieCooldown(expiresAt)
        }

        let path = "\(ownerID.uuidString)/\(UUID().uuidString).jpg"
        let expiresAt = Date().addingTimeInterval(24 * 60 * 60)
        let payload = DailySelfieInsert(
            userID: ownerID,
            storagePath: path,
            expiresAt: iso8601String(expiresAt)
        )

        try await client.storage
            .from(bucket)
            .upload(
                path,
                data: imageData,
                options: FileOptions(
                    cacheControl: "86400",
                    contentType: "image/jpeg",
                    upsert: false
                )
            )

        do {
            return try await client
                .from("daily_selfies")
                .insert(payload)
                .select()
                .single()
                .execute()
                .value
        } catch {
            _ = try? await client.storage.from(bucket).remove(paths: [path])
            throw error
        }
    }

    func downloadSelfie(path: String) async throws -> Data {
        try await client.storage.from(bucket).download(path: path)
    }

    func removeLatestSelfie(userID: UUID) async throws {
        guard let selfie = try await fetchLatestSelfie(userID: userID) else {
            throw PacificaServiceError.missingSelfie
        }

        _ = try? await client.storage.from(bucket).remove(paths: [selfie.storagePath])
        try await client
            .from("daily_selfies")
            .delete()
            .eq("id", value: selfie.id.uuidString)
            .execute()
    }

    private func parseDate(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: value) ?? ISO8601DateFormatter().date(from: value)
    }

    private func iso8601String(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
}

private struct DailySelfieInsert: Encodable {
    let userID: UUID
    let storagePath: String
    let expiresAt: String

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case storagePath = "storage_path"
        case expiresAt = "expires_at"
    }
}

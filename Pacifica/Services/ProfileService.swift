import Foundation

struct ProfileService {
    private let client = SupabaseClientProvider.shared

    func fetchProfile(userID: UUID) async throws -> Profile {
        try await client
            .from("profiles")
            .select()
            .eq("id", value: userID.uuidString)
            .single()
            .execute()
            .value
    }

    func searchUsers(username: String) async throws -> [Profile] {
        try await client
            .from("profiles")
            .select()
            .ilike("username", pattern: "%\(username)%")
            .order("username")
            .limit(25)
            .execute()
            .value
    }

    func updateProfile(
        userID: UUID,
        displayName: String,
        username: String,
        avatarPath: String?,
        fishColor: String,
        fishType: String
    ) async throws -> Profile {
        let payload = ProfileUpdate(
            username: username,
            displayName: displayName,
            avatarPath: avatarPath,
            fishColor: fishColor,
            fishType: fishType
        )

        return try await client
            .from("profiles")
            .update(payload)
            .eq("id", value: userID.uuidString)
            .select()
            .single()
            .execute()
            .value
    }
}

private struct ProfileUpdate: Encodable {
    let username: String
    let displayName: String
    let avatarPath: String?
    let fishColor: String
    let fishType: String

    enum CodingKeys: String, CodingKey {
        case username
        case displayName = "display_name"
        case avatarPath = "avatar_path"
        case fishColor = "fish_color"
        case fishType = "fish_type"
    }
}

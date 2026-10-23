import SwiftUI
import Observation

/// Spending categories that move your fish. Necessities (rent, bills, health) are never part of the game.
enum ReefCategory: String, CaseIterable, Identifiable {
    case all, food, fun, shopping, transport, subscriptions

    var id: Self { self }

    var title: String {
        switch self {
        case .all: "All"
        case .food: "Food"
        case .fun: "Fun"
        case .shopping: "Shopping"
        case .transport: "Transport"
        case .subscriptions: "Subs"
        }
    }

    var systemImage: String {
        switch self {
        case .all: "water.waves"
        case .food: "fork.knife"
        case .fun: "gamecontroller.fill"
        case .shopping: "bag.fill"
        case .transport: "bus.fill"
        case .subscriptions: "arrow.triangle.2.circlepath"
        }
    }

    /// Categories that count toward depth (everything except `.all`).
    static var scored: [ReefCategory] { allCases.filter { $0 != .all } }
}

/// One fish in the ocean.
struct ReefFriend: Identifiable, Equatable {
    let id: String
    let name: String
    let isYou: Bool
    /// Share of the person's own budget used per category: 0 = nothing spent, 1 = whole budget, above 1 = over budget.
    let used: [ReefCategory: Double]
    /// Categories hidden from friends. They still count toward overall depth so nobody can game the ranking.
    let hidden: Set<ReefCategory>

    var initials: String { String(name.prefix(2)).uppercased() }

    /// Depth to show in `category`, or nil if this person hid it from friends.
    func depth(in category: ReefCategory) -> Double? {
        if category == .all {
            let values = ReefCategory.scored.compactMap { used[$0] }
            return values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
        }
        if hidden.contains(category) && !isYou { return nil }
        return used[category] ?? 0
    }
}

struct RankedFriend: Identifiable {
    let friend: ReefFriend
    let rank: Int
    let depth: Double
    var id: String { friend.id }
}

/// Sample data until friends and spending goals come from Supabase (`friendships`, `spending_goals`).
enum ReefSampleData {
    static let friends: [ReefFriend] = [
        ReefFriend(id: "you", name: "You", isYou: true,
                   used: [.food: 0.42, .fun: 0.55, .shopping: 0.30, .transport: 0.20, .subscriptions: 0.35],
                   hidden: []),
        ReefFriend(id: "summer", name: "Summer", isYou: false,
                   used: [.food: 0.18, .fun: 0.22, .shopping: 0.40, .transport: 0.10, .subscriptions: 0.25],
                   hidden: []),
        ReefFriend(id: "raey", name: "Raey", isYou: false,
                   used: [.food: 0.65, .fun: 0.50, .shopping: 0.72, .transport: 0.45, .subscriptions: 0.60],
                   hidden: []),
        ReefFriend(id: "mario", name: "Mario", isYou: false,
                   used: [.food: 0.35, .fun: 0.90, .shopping: 0.52, .transport: 0.30, .subscriptions: 0.15],
                   hidden: [.fun]),
        ReefFriend(id: "alex", name: "Alex", isYou: false,
                   used: [.food: 0.80, .fun: 0.95, .shopping: 1.10, .transport: 0.70, .subscriptions: 0.85],
                   hidden: [.shopping]),
    ]
}

@Observable
@MainActor
final class ReefViewModel {
    var category: ReefCategory = .all
    var selectedID: String = "you"
    var friends: [ReefFriend]
    private let currentUserID: UUID?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    /// Deepest the ocean goes: just past 100% of budget is "the trench".
    static let maxDepth = 1.15

    init(currentUserID: UUID? = nil, friends: [ReefFriend] = ReefSampleData.friends) {
        self.currentUserID = currentUserID
        self.friends = friends
        if let currentUserID {
            selectedID = currentUserID.uuidString
        }
    }

    var currentUserKey: String {
        currentUserID?.uuidString ?? "you"
    }

    /// Loads profile names and recent shared purchases from the same Supabase tables
    /// used by the Activity feed. Sample fish remain as a fallback when unavailable.
    func load() async {
        guard let currentUserID else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let service = ActivityService()
            async let profilesRequest = service.fetchProfiles()
            let profiles = try await profilesRequest

            guard !profiles.isEmpty else { return }

            let orderedProfiles = profiles.sorted { left, right in
                if left.id == currentUserID { return true }
                if right.id == currentUserID { return false }
                return left.displayName.localizedCaseInsensitiveCompare(right.displayName) == .orderedAscending
            }

            friends = Array(orderedProfiles.prefix(5)).map { profile in
                ReefFriend(
                    id: profile.id.uuidString,
                    name: profile.displayName.isEmpty ? profile.username : profile.displayName,
                    isYou: profile.id == currentUserID,
                    used: fallbackUsage(for: profile.displayName),
                    hidden: []
                )
            }
            selectedID = currentUserID.uuidString
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func usage(for userID: UUID, in transactions: [SpendingTransaction]) -> [ReefCategory: Double] {
        let budgets: [ReefCategory: Double] = [
            .food: 100,
            .fun: 100,
            .shopping: 150,
            .transport: 80,
            .subscriptions: 50
        ]
        let cutoff = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        let formatter = ISO8601DateFormatter()
        var spent: [ReefCategory: Double] = [:]

        for transaction in transactions where transaction.userID == userID {
            guard let category = ReefCategory(rawValue: transaction.category),
                  category != .all,
                  let spentAt = formatter.date(from: transaction.spentAt),
                  spentAt >= cutoff else { continue }

            spent[category, default: 0] += NSDecimalNumber(decimal: transaction.amount).doubleValue
        }

        return budgets.reduce(into: [ReefCategory: Double]()) { result, item in
            result[item.key] = spent[item.key, default: 0] / item.value
        }
    }

    private func fallbackUsage(for displayName: String) -> [ReefCategory: Double] {
        let name = displayName.lowercased()
        if name.contains("summer") { return [.food: 0.54, .fun: 0.20, .shopping: 0.21, .transport: 0.10, .subscriptions: 0.10] }
        if name.contains("alex") { return [.food: 0.13, .fun: 0.10, .shopping: 0.42, .transport: 0.08, .subscriptions: 0.12] }
        if name.contains("gabe") { return [.food: 0.12, .fun: 0.42, .shopping: 0.23, .transport: 0.08, .subscriptions: 0.10] }
        if name.contains("john") { return [.food: 0.18, .fun: 0.16, .shopping: 0.12, .transport: 0.10, .subscriptions: 0.08] }
        if name.contains("joseph") { return [.food: 0.09, .fun: 0.18, .shopping: 0.12, .transport: 0.08, .subscriptions: 0.10] }
        return [.food: 0.20, .fun: 0.15, .shopping: 0.20, .transport: 0.10, .subscriptions: 0.10]
    }

    /// Shallowest first. People who hid this category are left out of the ranking.
    var ranking: [RankedFriend] {
        let visible = friends.compactMap { friend -> (ReefFriend, Double)? in
            guard let depth = friend.depth(in: category) else { return nil }
            return (friend, depth)
        }
        .sorted { $0.1 < $1.1 }

        return visible.enumerated().map { RankedFriend(friend: $0.element.0, rank: $0.offset + 1, depth: $0.element.1) }
    }

    func rank(of friend: ReefFriend) -> RankedFriend? {
        ranking.first { $0.friend.id == friend.id }
    }

    var selected: ReefFriend {
        friends.first { $0.id == selectedID } ?? friends[0]
    }

    func friendlyLine(for ranked: RankedFriend) -> String {
        if ranked.rank == 1 { return "Top of the reef" }
        if ranked.rank == ranking.count && ranking.count > 2 { return "Diving deep" }
        return "Cruising"
    }
}

extension Int {
    var ordinal: String {
        let suffix: String
        switch (self % 100, self % 10) {
        case (11...13, _): suffix = "th"
        case (_, 1): suffix = "st"
        case (_, 2): suffix = "nd"
        case (_, 3): suffix = "rd"
        default: suffix = "th"
        }
        return "\(self)\(suffix)"
    }
}

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
    let friends: [ReefFriend]

    /// Deepest the ocean goes: just past 100% of budget is "the trench".
    static let maxDepth = 1.15

    init(friends: [ReefFriend] = ReefSampleData.friends) {
        self.friends = friends
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

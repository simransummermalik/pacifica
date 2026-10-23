import Foundation
import Observation
import SwiftUI

struct OceanConditionsCard: View {
    @State private var viewModel: OceanConditionsViewModel

    init(service: any BLSServiceProtocol = BLSService(), cache: OceanConditionsCache = .standard) {
        _viewModel = State(initialValue: OceanConditionsViewModel(service: service, cache: cache))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.text ?? OceanConditionsViewModel.fallbackText)
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)
            Text(Self.source)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Theme.translucentFill, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .redacted(reason: viewModel.text == nil ? .placeholder : [])
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .task { await viewModel.load() }
    }

    private static let source = "Source: U.S. Bureau of Labor Statistics"

    private var accessibilityLabel: String {
        guard let text = viewModel.text else { return "Loading ocean conditions" }
        return "\(text) \(Self.source)"
    }
}

@Observable
@MainActor
final class OceanConditionsViewModel {
    static let fallbackText = "🌊 Prices are rising everywhere. It's not just you."
    private static let maxCacheAge: TimeInterval = 24 * 60 * 60

    /// nil while loading.
    private(set) var text: String?

    private let service: any BLSServiceProtocol
    private let cache: OceanConditionsCache

    init(service: any BLSServiceProtocol, cache: OceanConditionsCache) {
        self.service = service
        self.cache = cache
    }

    func load() async {
        guard text == nil else { return }

        let cached = cache.load()
        if let cached, Date.now.timeIntervalSince(cached.date) < Self.maxCacheAge {
            text = cached.text
            return
        }

        do {
            let points = try await service.fetchDataPoints(seriesID: BLSService.groceriesSeriesID)
            guard let change = BLSYearOverYearChange(points: points),
                  let message = Self.message(for: change)
            else { throw URLError(.cannotParseResponse) }
            cache.save(message)
            text = message
        } catch {
            text = cached?.text ?? Self.fallbackText
        }
    }

    /// Returns nil for a 0.0% change, which has no matching copy.
    private static func message(for change: BLSYearOverYearChange) -> String? {
        let percent = abs(change.percent)
            .formatted(.number.precision(.fractionLength(1)).locale(Locale(identifier: "en_US")))
        if change.percent > 0 {
            return "🦐 In \(change.month), groceries cost \(percent)% more than a year ago. It's not just you."
        } else if change.percent < 0 {
            return "🦐 Good news: in \(change.month), groceries cost \(percent)% less than a year ago."
        }
        return nil
    }
}

/// Stores the last card text in UserDefaults; BLS v1 allows only 25 requests a day.
struct OceanConditionsCache {
    private static let textKey = "oceanConditions.text"
    private static let dateKey = "oceanConditions.date"

    let defaults: UserDefaults

    static var standard: OceanConditionsCache { OceanConditionsCache(defaults: .standard) }

    func load() -> (text: String, date: Date)? {
        guard let text = defaults.string(forKey: Self.textKey),
              let date = defaults.object(forKey: Self.dateKey) as? Date
        else { return nil }
        return (text, date)
    }

    func save(_ text: String, at date: Date = .now) {
        defaults.set(text, forKey: Self.textKey)
        defaults.set(date, forKey: Self.dateKey)
    }
}

#if DEBUG
extension OceanConditionsCache {
    /// An empty cache that doesn't touch the app's real defaults.
    static func ephemeral() -> OceanConditionsCache {
        OceanConditionsCache(defaults: UserDefaults(suiteName: "preview.\(UUID().uuidString)")!)
    }
}

#Preview("Prices up") {
    OceanConditionsCard(service: MockBLSService.up, cache: .ephemeral())
        .padding(20)
}

#Preview("Prices down") {
    OceanConditionsCard(service: MockBLSService.down, cache: .ephemeral())
        .padding(20)
}
#endif

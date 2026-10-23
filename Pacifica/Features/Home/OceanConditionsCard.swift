import Foundation
import Observation
import SwiftUI

struct OceanConditionsCard: View {
    let viewModel: OceanConditionsViewModel
    @State private var showsDetails = false

    var body: some View {
        Button {
            showsDetails = true
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.cardText ?? OceanConditionsViewModel.fallbackText)
                        .font(.title3.weight(.semibold))
                        .fixedSize(horizontal: false, vertical: true)
                    Text(OceanConditionsViewModel.source)
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(20)
            .contentShape(.rect(cornerRadius: Theme.cardRadius))
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: Theme.cardRadius))
        .redacted(reason: viewModel.cardText == nil ? .placeholder : [])
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Shows more price details")
        .sheet(isPresented: $showsDetails) {
            OceanConditionsDetailView(viewModel: viewModel)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .task { await viewModel.load() }
    }

    private var accessibilityLabel: String {
        guard let text = viewModel.cardText else { return "Loading ocean conditions" }
        return "\(text) \(OceanConditionsViewModel.source)"
    }
}

@Observable
@MainActor
final class OceanConditionsViewModel {
    enum State: Equatable {
        case loading
        case loaded(PriceReport)
        case unavailable
    }

    static let fallbackText = "Prices are rising everywhere. It's not just you."
    static let source = "Source: U.S. Bureau of Labor Statistics"
    private static let maxCacheAge: TimeInterval = 24 * 60 * 60

    private(set) var state: State

    private let service: any BLSServiceProtocol
    private let cache: OceanConditionsCache
    private var hasStartedLoading = false

    init(
        service: any BLSServiceProtocol = BLSService(),
        cache: OceanConditionsCache = .standard,
        initialState: State = .loading
    ) {
        self.service = service
        self.cache = cache
        self.state = initialState
    }

    /// nil while loading.
    var cardText: String? {
        switch state {
        case .loading: nil
        case .loaded(let report): report[.groceries]?.cardText ?? Self.fallbackText
        case .unavailable: Self.fallbackText
        }
    }

    /// Loads once; later calls (e.g. the card reappearing) are ignored.
    func load() async {
        guard case .loading = state, !hasStartedLoading else { return }
        hasStartedLoading = true

        let cached = cache.load()
        if let cached, Date.now.timeIntervalSince(cached.date) < Self.maxCacheAge {
            state = .loaded(cached.report)
            return
        }

        do {
            let series = try await service.fetchSeries(ids: PriceCategory.allCases.map(\.seriesID))
            guard let report = PriceReport(series: series) else { throw URLError(.cannotParseResponse) }
            cache.save(report)
            state = .loaded(report)
        } catch {
            state = cached.map { .loaded($0.report) } ?? .unavailable
        }
    }
}

// MARK: - Copy

extension CategoryPrices {
    private static let locale = Locale(identifier: "en_US")

    private var trend: Int { percentChange > 0 ? 1 : percentChange < 0 ? -1 : 0 }

    /// Absolute change, e.g. "2.5".
    var percentText: String {
        abs(percentChange).formatted(.number.precision(.fractionLength(1)).locale(Self.locale))
    }

    /// e.g. "+2.5%" or "−6.2%".
    var signedPercentText: String {
        switch trend {
        case 1: "+\(percentText)%"
        case -1: "−\(percentText)%"
        default: "\(percentText)%"
        }
    }

    var trendSymbol: String {
        switch trend {
        case 1: "arrow.up.right"
        case -1: "arrow.down.right"
        default: "arrow.right"
        }
    }

    /// Card copy; nil for a 0.0% change, which has no matching copy.
    var cardText: String? {
        let month = latest.periodName
        let subject = category.name.lowercased()
        switch trend {
        case 1: return "In \(month), \(subject) cost \(percentText)% more than a year ago. It's not just you."
        case -1: return "Good news: in \(month), \(subject) cost \(percentText)% less than a year ago."
        default: return nil
        }
    }

    var headline: String {
        let month = latest.periodName
        if category == .everything {
            switch trend {
            case 1: return "In \(month), prices overall were \(percentText)% higher than a year ago."
            case -1: return "In \(month), prices overall were \(percentText)% lower than a year ago."
            default: return "In \(month), prices overall were about the same as a year ago."
            }
        }
        let subject = category.name.lowercased()
        switch trend {
        case 1: return "In \(month), \(subject) cost \(percentText)% more than a year ago."
        case -1: return "In \(month), \(subject) cost \(percentText)% less than a year ago."
        default: return "In \(month), \(subject) cost about the same as a year ago."
        }
    }

    /// e.g. "Rent, up 4.1 percent from a year ago".
    var accessibilityDescription: String {
        switch trend {
        case 1: "\(category.name), up \(percentText) percent from a year ago"
        case -1: "\(category.name), down \(percentText) percent from a year ago"
        default: "\(category.name), unchanged from a year ago"
        }
    }
}

extension PriceReport {
    var takeaway: String {
        let fastest = categories
            .filter { $0.category != .everything }
            .max { $0.percentChange < $1.percentChange }
        if let fastest, let overall = self[.everything],
           fastest.percentChange > 0, fastest.percentChange > overall.percentChange {
            let verb = fastest.category == .groceries ? "are" : "is"
            return "\(fastest.category.name) \(verb) rising faster than prices overall. If it feels tight, that's why."
        }
        return "Prices are rising about as fast as usual this year."
    }
}

// MARK: - Cache

/// Stores the last report in UserDefaults; BLS v1 allows only 25 requests a day.
struct OceanConditionsCache {
    // v2: reports cached before October 2025's missing value was handled include it as 0.
    private static let reportKey = "oceanConditions.report.v2"
    private static let dateKey = "oceanConditions.reportDate"

    let defaults: UserDefaults

    static var standard: OceanConditionsCache { OceanConditionsCache(defaults: .standard) }

    func load() -> (report: PriceReport, date: Date)? {
        guard let data = defaults.data(forKey: Self.reportKey),
              let report = try? JSONDecoder().decode(PriceReport.self, from: data),
              let date = defaults.object(forKey: Self.dateKey) as? Date
        else { return nil }
        return (report, date)
    }

    func save(_ report: PriceReport, at date: Date = .now) {
        guard let data = try? JSONEncoder().encode(report) else { return }
        defaults.set(data, forKey: Self.reportKey)
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

#Preview("Loaded") {
    OceanConditionsCard(viewModel: OceanConditionsViewModel(service: MockBLSService.mixed, cache: .ephemeral()))
        .padding(16)
}

#Preview("Unavailable") {
    OceanConditionsCard(viewModel: OceanConditionsViewModel(service: MockBLSService.failing, cache: .ephemeral()))
        .padding(16)
}
#endif

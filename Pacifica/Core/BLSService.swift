import Foundation

// MARK: - API models

struct BLSRequest: Codable, Sendable {
    let seriesid: [String]
}

struct BLSResponse: Codable, Sendable {
    let status: String?
    let results: Results

    enum CodingKeys: String, CodingKey {
        case status
        case results = "Results"
    }

    struct Results: Codable, Sendable {
        let series: [Series]
    }

    struct Series: Codable, Sendable {
        let seriesID: String
        let data: [BLSDataPoint]
    }
}

struct BLSDataPoint: Codable, Sendable, Equatable {
    let year: String
    /// "M01"..."M12" for months, "M13" for the annual average.
    let period: String
    let periodName: String
    let value: String
}

// MARK: - Price report

enum PriceCategory: String, CaseIterable, Codable, Sendable, Identifiable {
    case groceries = "CUUR0000SAF11"
    case rent = "CUUR0000SEHA"
    case eatingOut = "CUUR0000SEFV"
    case gas = "CUUR0000SETB01"
    case electricity = "CUUR0000SEHF01"
    case everything = "CUUR0000SA0"

    var id: String { rawValue }
    var seriesID: String { rawValue }

    /// The series' data page on the BLS website.
    var sourceURL: URL {
        URL(string: "https://data.bls.gov/timeseries/\(seriesID)")!
    }

    var name: String {
        switch self {
        case .groceries: "Groceries"
        case .rent: "Rent"
        case .eatingOut: "Eating out"
        case .gas: "Gas"
        case .electricity: "Electricity"
        case .everything: "Everything"
        }
    }
}

/// One monthly value of a BLS series.
struct PricePoint: Codable, Sendable, Equatable, Identifiable {
    let year: Int
    let month: Int
    let periodName: String
    let value: Decimal

    /// Months since year 0, so consecutive months differ by 1.
    var monthIndex: Int { year * 12 + month - 1 }
    var id: Int { monthIndex }

    var date: Date {
        Calendar(identifier: .gregorian).date(from: DateComponents(year: year, month: month, day: 1)) ?? .distantPast
    }

    var doubleValue: Double { NSDecimalNumber(decimal: value).doubleValue }

    /// Returns nil for the annual average ("M13") and for months BLS didn't publish, which have the value "-".
    init?(_ point: BLSDataPoint) {
        // Decimal(string:) parses "-" as 0, so require digits first.
        guard point.period.hasPrefix("M"),
              let month = Int(point.period.dropFirst()), (1...12).contains(month),
              let year = Int(point.year),
              point.value.contains(where: \.isNumber),
              point.value.allSatisfy({ $0.isNumber || $0 == "." }),
              let value = Decimal(string: point.value, locale: Locale(identifier: "en_US_POSIX"))
        else { return nil }
        self.year = year
        self.month = month
        self.periodName = point.periodName
        self.value = value
    }

    init(year: Int, month: Int, periodName: String, value: Decimal) {
        self.year = year
        self.month = month
        self.periodName = periodName
        self.value = value
    }
}

struct CategoryPrices: Codable, Sendable, Equatable, Identifiable {
    let category: PriceCategory
    let latest: PricePoint
    /// Signed year-over-year percent change, rounded to 1 decimal place.
    let percentChange: Decimal
    /// The year-ago month through `latest`, oldest first, so the chart covers the same change as `percentChange`.
    /// Months BLS didn't publish are missing.
    let chartPoints: [PricePoint]

    var id: PriceCategory { category }

    /// Uses the newest month that has a value a year earlier, since BLS skipped some months (e.g. October 2025).
    /// Returns nil if no month has one.
    init?(category: PriceCategory, points: [BLSDataPoint]) {
        let monthly = points.compactMap(PricePoint.init).sorted { $0.monthIndex > $1.monthIndex }
        let pair = monthly.lazy.compactMap { point in
            monthly.first { $0.monthIndex == point.monthIndex - 12 && $0.value != 0 }.map { (latest: point, yearAgo: $0) }
        }.first
        guard let (latest, yearAgo) = pair else { return nil }

        var raw = (latest.value - yearAgo.value) / yearAgo.value * 100
        var rounded = Decimal()
        NSDecimalRound(&rounded, &raw, 1, .plain)

        self.category = category
        self.latest = latest
        self.percentChange = rounded
        self.chartPoints = monthly
            .filter { (yearAgo.monthIndex...latest.monthIndex).contains($0.monthIndex) }
            .reversed()
    }
}

struct PriceReport: Codable, Sendable, Equatable {
    /// In `PriceCategory.allCases` order; categories the API didn't return are left out.
    let categories: [CategoryPrices]

    /// Returns nil if no category could be computed.
    init?(series: [String: [BLSDataPoint]]) {
        let categories = PriceCategory.allCases.compactMap { category in
            series[category.seriesID].flatMap { CategoryPrices(category: category, points: $0) }
        }
        guard !categories.isEmpty else { return nil }
        self.categories = categories
    }

    subscript(category: PriceCategory) -> CategoryPrices? {
        categories.first { $0.category == category }
    }

    var latestPoint: PricePoint? { categories.first?.latest }
}

// MARK: - Service

protocol BLSServiceProtocol: Sendable {
    /// Fetches the given series in one request, returning each series' data points keyed by series ID.
    func fetchSeries(ids: [String]) async throws -> [String: [BLSDataPoint]]
}

struct BLSService: BLSServiceProtocol {
    private static let endpoint = URL(string: "https://api.bls.gov/publicAPI/v1/timeseries/data/")!

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchSeries(ids: [String]) async throws -> [String: [BLSDataPoint]] {
        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(BLSRequest(seriesid: ids))

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(BLSResponse.self, from: data)
        let series = Dictionary(
            decoded.results.series.map { ($0.seriesID, $0.data) },
            uniquingKeysWith: { first, _ in first }
        )
        guard !series.isEmpty else { throw URLError(.cannotParseResponse) }
        return series
    }
}

#if DEBUG
struct MockBLSService: BLSServiceProtocol {
    var series: [String: [BLSDataPoint]]
    var fails = false

    func fetchSeries(ids: [String]) async throws -> [String: [BLSDataPoint]] {
        if fails { throw URLError(.notConnectedToInternet) }
        return series
    }

    /// Mix of rising and falling categories, latest month September 2026.
    static let mixed = MockBLSService(series: [
        // Like the real data, every series but gas is missing October 2025.
        PriceCategory.groceries.seriesID: mockSeries(latest: 321.758, yearAgo: 313.912), // +2.5%
        PriceCategory.rent.seriesID: mockSeries(latest: 431.204, yearAgo: 414.221), // +4.1%
        PriceCategory.eatingOut.seriesID: mockSeries(latest: 382.517, yearAgo: 369.229), // +3.6%
        PriceCategory.gas.seriesID: mockSeries(latest: 301.433, yearAgo: 321.354, hasShutdownGap: false), // -6.2%
        PriceCategory.electricity.seriesID: mockSeries(latest: 297.840, yearAgo: 299.318), // -0.5%
        PriceCategory.everything.seriesID: mockSeries(latest: 330.108, yearAgo: 320.805), // +2.9%
    ])

    static let failing = MockBLSService(series: [:], fails: true)

    /// 24 monthly points ending September 2026 (newest first, like the API), plus an "M13" annual average.
    private static func mockSeries(latest: Double, yearAgo: Double, hasShutdownGap: Bool = true) -> [BLSDataPoint] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US")
        let monthNames = calendar.monthSymbols
        let slope = (latest - yearAgo) / 12
        var points = (0..<24).map { monthsAgo in
            let index = 2026 * 12 + 8 - monthsAgo
            let wiggle = sin(Double(monthsAgo) * .pi / 6) * latest * 0.003
            return BLSDataPoint(
                year: String(index / 12),
                period: String(format: "M%02d", index % 12 + 1),
                periodName: monthNames[index % 12],
                value: hasShutdownGap && index == 2025 * 12 + 9
                    ? "-"
                    : String(format: "%.3f", latest - slope * Double(monthsAgo) + wiggle)
            )
        }
        points.insert(BLSDataPoint(year: "2025", period: "M13", periodName: "Annual", value: "0"), at: 9)
        return points
    }
}

extension PriceReport {
    static let mock = PriceReport(series: MockBLSService.mixed.series)!
}
#endif

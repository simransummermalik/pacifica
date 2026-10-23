import Foundation

// MARK: - Models

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
        let seriesID: String?
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

/// Year-over-year change for the most recent month in a BLS series.
struct BLSYearOverYearChange: Sendable, Equatable {
    let month: String
    /// Signed percent change, rounded to 1 decimal place.
    let percent: Decimal

    /// Returns nil if the points don't contain the latest month and the same month a year earlier.
    init?(points: [BLSDataPoint]) {
        let monthly = points.filter { $0.period != "M13" }
        guard let latest = monthly.first,
              let latestYear = Int(latest.year),
              let lastYear = monthly.first(where: {
                  $0.period == latest.period && $0.year == String(latestYear - 1)
              }),
              let latestValue = Self.decimal(latest.value),
              let lastYearValue = Self.decimal(lastYear.value),
              lastYearValue != 0
        else { return nil }

        var raw = (latestValue - lastYearValue) / lastYearValue * 100
        var rounded = Decimal()
        NSDecimalRound(&rounded, &raw, 1, .plain)

        self.month = latest.periodName
        self.percent = rounded
    }

    private static func decimal(_ string: String) -> Decimal? {
        Decimal(string: string, locale: Locale(identifier: "en_US_POSIX"))
    }
}

// MARK: - Service

protocol BLSServiceProtocol: Sendable {
    /// Returns the series' data points, most recent first.
    func fetchDataPoints(seriesID: String) async throws -> [BLSDataPoint]
}

struct BLSService: BLSServiceProtocol {
    /// CPI for food at home (groceries), U.S. city average, not seasonally adjusted.
    static let groceriesSeriesID = "CUUR0000SAF11"

    private static let endpoint = URL(string: "https://api.bls.gov/publicAPI/v1/timeseries/data/")!

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchDataPoints(seriesID: String) async throws -> [BLSDataPoint] {
        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(BLSRequest(seriesid: [seriesID]))

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(BLSResponse.self, from: data)
        guard let points = decoded.results.series.first?.data, !points.isEmpty else {
            throw URLError(.cannotParseResponse)
        }
        return points
    }
}

#if DEBUG
struct MockBLSService: BLSServiceProtocol {
    var points: [BLSDataPoint]

    func fetchDataPoints(seriesID: String) async throws -> [BLSDataPoint] {
        points
    }

    static let up = MockBLSService(points: [
        BLSDataPoint(year: "2026", period: "M09", periodName: "September", value: "318.402"),
        BLSDataPoint(year: "2026", period: "M08", periodName: "August", value: "317.950"),
        BLSDataPoint(year: "2025", period: "M13", periodName: "Annual", value: "310.118"),
        BLSDataPoint(year: "2025", period: "M09", periodName: "September", value: "309.821"),
    ])

    static let down = MockBLSService(points: [
        BLSDataPoint(year: "2026", period: "M09", periodName: "September", value: "305.114"),
        BLSDataPoint(year: "2026", period: "M08", periodName: "August", value: "306.002"),
        BLSDataPoint(year: "2025", period: "M09", periodName: "September", value: "309.821"),
    ])
}
#endif

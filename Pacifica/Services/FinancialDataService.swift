import Foundation

struct FinancialInsight: Equatable {
    let source: String
    let seriesID: String
    let latestPeriod: String
    let latestValue: Decimal
    let yearOverYearPercent: Decimal?
}

struct FinancialDataService {
    private let client = SupabaseClientProvider.shared
    private let source = "BLS"

    func fetchConsumerPriceInsight(
        seriesID: String = "CUUR0000SA0"
    ) async throws -> FinancialInsight {
        let currentYear = Calendar.current.component(.year, from: Date())
        let endpoint = "https://api.bls.gov/publicAPI/v2/timeseries/data/\(seriesID)?startyear=\(currentYear - 2)&endyear=\(currentYear)"

        do {
            let (data, response) = try await URLSession.shared.data(from: URL(string: endpoint)!)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode)
            else {
                throw PacificaServiceError.financialDataUnavailable
            }

            let decoded = try JSONDecoder().decode(FDBLSResponse.self, from: data)
            guard let series = decoded.results.series.first else {
                throw PacificaServiceError.financialDataUnavailable
            }

            let points = series.data.compactMap { point -> BLSPoint? in
                guard let value = Decimal(string: point.value) else { return nil }
                return BLSPoint(
                    year: Int(point.year) ?? 0,
                    period: point.period,
                    observedPeriod: "\(point.year)-\(point.period)",
                    value: value
                )
            }
            .sorted {
                if $0.year == $1.year { return $0.period > $1.period }
                return $0.year > $1.year
            }

            guard let latest = points.first else {
                throw PacificaServiceError.financialDataUnavailable
            }

            let comparison = points.first {
                $0.year == latest.year - 1 && $0.period == latest.period
            }

            try await cache(points: [latest, comparison].compactMap { $0 }, seriesID: seriesID)

            return FinancialInsight(
                source: source,
                seriesID: seriesID,
                latestPeriod: latest.observedPeriod,
                latestValue: latest.value,
                yearOverYearPercent: percentageChange(from: comparison?.value, to: latest.value)
            )
        } catch {
            guard let cached = try? await loadCached(seriesID: seriesID),
                  let latest = cached.first
            else {
                throw error
            }

            let comparison = cached.dropFirst().first
            return FinancialInsight(
                source: source,
                seriesID: seriesID,
                latestPeriod: latest.observedPeriod,
                latestValue: latest.value,
                yearOverYearPercent: percentageChange(
                    from: comparison?.value,
                    to: latest.value
                )
            )
        }
    }

    private func cache(points: [BLSPoint], seriesID: String) async throws {
        for point in points {
            let payload = FinancialDataCacheInsert(
                source: source,
                seriesID: seriesID,
                observedPeriod: point.observedPeriod,
                value: point.value
            )

            try await client
                .from("financial_data_cache")
                .upsert(payload, onConflict: "source,series_id,observed_period", returning: .minimal)
                .execute()
        }
    }

    private func loadCached(seriesID: String) async throws -> [FinancialDataCache] {
        try await client
            .from("financial_data_cache")
            .select()
            .eq("source", value: source)
            .eq("series_id", value: seriesID)
            .order("observed_period", ascending: false)
            .limit(2)
            .execute()
            .value
    }

    private func percentageChange(from oldValue: Decimal?, to newValue: Decimal) -> Decimal? {
        guard let oldValue, oldValue != 0 else { return nil }
        let oldNumber = NSDecimalNumber(decimal: oldValue).doubleValue
        let newNumber = NSDecimalNumber(decimal: newValue).doubleValue
        return Decimal((newNumber - oldNumber) / oldNumber * 100)
    }
}

private struct FinancialDataCacheInsert: Encodable {
    let source: String
    let seriesID: String
    let observedPeriod: String
    let value: Decimal

    enum CodingKeys: String, CodingKey {
        case source
        case seriesID = "series_id"
        case observedPeriod = "observed_period"
        case value
    }
}

private struct FDBLSResponse: Decodable {
    let results: FDBLSResults
}

private struct FDBLSResults: Decodable {
    let series: [FDBLSSeries]
}

private struct FDBLSSeries: Decodable {
    let data: [FDBLSDataPoint]
}

private struct FDBLSDataPoint: Decodable {
    let year: String
    let period: String
    let value: String
}

private struct BLSPoint {
    let year: Int
    let period: String
    let observedPeriod: String
    let value: Decimal
}

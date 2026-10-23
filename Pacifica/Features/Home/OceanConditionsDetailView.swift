import Charts
import SwiftUI

struct OceanConditionsDetailView: View {
    let viewModel: OceanConditionsViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var selection: PriceCategory = .groceries

    var body: some View {
        ZStack {
            AppBackground()

            VStack(alignment: .leading, spacing: 16) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        switch viewModel.state {
                        case .loading:
                            ProgressView()
                                .frame(maxWidth: .infinity, minHeight: 200)
                        case .loaded(let report):
                            content(for: report)
                        case .unavailable:
                            unavailable
                        }
                    }
                    .padding(.bottom, 16)
                }
                .scrollIndicators(.hidden)
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Ocean Conditions")
                    .font(.title2.weight(.bold))
                if case .loaded(let report) = viewModel.state, let latest = report.latestPoint {
                    Text("\(latest.periodName) \(String(latest.year)) vs. a year ago")
                        .font(.title3)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.title3.weight(.semibold))
                    .frame(width: 52, height: 52)
                    .glassEffect(.regular.interactive(), in: .circle)
            }
            .foregroundStyle(Theme.text)
            .accessibilityLabel("Close")
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func content(for report: PriceReport) -> some View {
        if let current = report[selection] ?? report.categories.first {
            VStack(alignment: .leading, spacing: 24) {
                Text(current.headline)
                    .font(.title3.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.numericText())
                PriceChart(prices: current)
            }
            .padding(20)
            .glassEffect(.regular, in: .rect(cornerRadius: Theme.cardRadius))

            Text("Your everyday costs")
                .font(.headline)
                .foregroundStyle(Theme.textSecondary)
                .padding(.top, 8)

            VStack(spacing: 8) {
                ForEach(report.categories) { prices in
                    CategoryRow(prices: prices, isSelected: prices.category == current.category) {
                        withAnimation(.smooth) { selection = prices.category }
                    }
                }
            }

            Text(report.takeaway)
                .font(.title3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)

            source(for: current.category)
        }
    }

    private var unavailable: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Price details aren't available right now")
                .font(.title3.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
            Text("Check back a little later.")
                .font(.title3)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .glassEffect(.regular, in: .rect(cornerRadius: Theme.cardRadius))
        .accessibilityElement(children: .combine)
    }

    /// Opens the selected category's series on the BLS website.
    private func source(for category: PriceCategory) -> some View {
        Link(destination: category.sourceURL) {
            HStack(spacing: 4) {
                Text(OceanConditionsViewModel.source)
                    .underline()
                Image(systemName: "arrow.up.right")
                    .font(.footnote.weight(.semibold))
            }
            .font(.subheadline)
            .foregroundStyle(Theme.textSecondary)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
    }
}

// MARK: - Chart

private struct PriceChart: View {
    let prices: CategoryPrices

    private struct SegmentedPoint: Identifiable {
        let point: PricePoint
        /// Percent change since the first point (the year-ago month), so the line ends at the headline's change.
        let percent: Double
        /// Increments after each missing month, so the line breaks instead of bridging the gap.
        let segment: Int
        var id: Int { point.id }
    }

    private static let percentStyle = FloatingPointFormatStyle<Double>.Percent.percent
        .precision(.fractionLength(0...1))
        .sign(strategy: .always(includingZero: false))
        .locale(Locale(identifier: "en_US"))

    var body: some View {
        Chart {
            RuleMark(y: .value("Start", 0))
                .foregroundStyle(Theme.textSecondary)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))

            ForEach(segmentedPoints) { item in
                LineMark(
                    x: .value("Month", item.point.date, unit: .month),
                    y: .value("Change", item.percent),
                    series: .value("Segment", item.segment)
                )
                .foregroundStyle(Theme.accent)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                // Monotone doesn't overshoot the monthly values the way catmull-rom can.
                .interpolationMethod(.monotone)
            }
        }
        .chartYScale(domain: yDomain)
        .chartXAxis {
            AxisMarks(values: .stride(by: .month, count: 2)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let percent = value.as(Double.self) {
                        Text((percent / 100).formatted(Self.percentStyle))
                    }
                }
            }
        }
        .frame(height: 200)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    private var segmentedPoints: [SegmentedPoint] {
        guard let base = prices.chartPoints.first?.doubleValue, base != 0 else { return [] }
        var segment = 0
        var previous: PricePoint?
        return prices.chartPoints.map { point in
            if let previous, point.monthIndex - previous.monthIndex > 1 {
                segment += 1
            }
            previous = point
            return SegmentedPoint(point: point, percent: (point.doubleValue - base) / base * 100, segment: segment)
        }
    }

    /// Trimmed to the data so the trend is visible; always includes the 0% starting line.
    private var yDomain: ClosedRange<Double> {
        let values = segmentedPoints.map(\.percent) + [0]
        guard let low = values.min(), let high = values.max() else { return -1...1 }
        let padding = max((high - low) * 0.15, 0.5)
        return (low - padding)...(high + padding)
    }

    private var accessibilitySummary: String {
        let points = prices.chartPoints
        guard let first = points.first, let last = points.last, points.count > 1 else {
            return "\(prices.category.name) price chart"
        }
        let ending = prices.percentChange > 0 ? "ending \(prices.percentText) percent higher than they started"
            : prices.percentChange < 0 ? "ending \(prices.percentText) percent lower than they started"
            : "ending about where they started"
        var summary = "\(prices.category.name) prices from \(first.periodName) \(String(first.year)) "
            + "to \(last.periodName) \(String(last.year)), \(ending)."

        let published = Set(points.map(\.monthIndex))
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US")
        let monthNames = calendar.monthSymbols
        let missing = (first.monthIndex...last.monthIndex)
            .filter { !published.contains($0) }
            .map { "\(monthNames[$0 % 12]) \(String($0 / 12))" }
        if !missing.isEmpty {
            summary += " No data was published for \(missing.formatted(.list(type: .and)))."
        }
        return summary
    }
}

// MARK: - Category row

private struct CategoryRow: View {
    let prices: CategoryPrices
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        if isSelected {
            button
                .buttonStyle(.glassProminent)
                .tint(Theme.accent)
        } else {
            button
                .buttonStyle(.glass)
        }
    }

    private var button: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(prices.category.name)
                    .foregroundStyle(isSelected ? Color.white : Theme.text)
                Spacer()
                Group {
                    Text(prices.signedPercentText)
                        .monospacedDigit()
                    Image(systemName: prices.trendSymbol)
                }
                .foregroundStyle(changeColor)
            }
            .font(.title3.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonBorderShape(.capsule)
        .controlSize(.extraLarge)
        .accessibilityLabel(prices.accessibilityDescription)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// Rising prices use the highlight color, falling ones the accent; the arrow carries the meaning too.
    private var changeColor: Color {
        if isSelected { return .white }
        if prices.percentChange > 0 { return Theme.highlight }
        if prices.percentChange < 0 { return Theme.accent }
        return Theme.textSecondary
    }
}

#if DEBUG
#Preview("Loaded") {
    OceanConditionsDetailView(viewModel: OceanConditionsViewModel(initialState: .loaded(.mock)))
}

#Preview("Unavailable") {
    OceanConditionsDetailView(viewModel: OceanConditionsViewModel(initialState: .unavailable))
}
#endif

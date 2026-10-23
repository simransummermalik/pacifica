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
                    .padding(.horizontal, 16)

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
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                .scrollIndicators(.hidden)
                // Let the glass cards' shadows spill past the scroll view's edge instead of being cut off.
                .scrollClipDisabled()
            }
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

            source
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

    private var source: some View {
        Text(OceanConditionsViewModel.source)
            .font(.subheadline)
            .foregroundStyle(Theme.textSecondary)
    }
}

// MARK: - Chart

private struct PriceChart: View {
    let prices: CategoryPrices

    var body: some View {
        Chart(prices.lastTwelveMonths) { point in
            LineMark(
                x: .value("Month", point.date, unit: .month),
                y: .value("Index", point.doubleValue)
            )
            .foregroundStyle(Theme.accent)
            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            .interpolationMethod(.catmullRom)
        }
        .chartYScale(domain: yDomain)
        .chartXAxis {
            AxisMarks(values: .stride(by: .month, count: 2)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated))
            }
        }
        .frame(height: 200)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    /// Trimmed to the data so the trend is visible.
    private var yDomain: ClosedRange<Double> {
        let values = prices.lastTwelveMonths.map(\.doubleValue)
        guard let low = values.min(), let high = values.max() else { return 0...1 }
        let padding = max((high - low) * 0.2, 0.5)
        return (low - padding)...(high + padding)
    }

    private var accessibilitySummary: String {
        let points = prices.lastTwelveMonths
        guard let first = points.first, let last = points.last, points.count > 1 else {
            return "\(prices.category.name) price chart"
        }
        let trend = last.value > first.value ? "rising" : last.value < first.value ? "falling" : "flat"
        let format = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(1))
        return "\(prices.category.name) prices over the last \(points.count) months, \(trend) from "
            + "\(first.doubleValue.formatted(format)) in \(first.periodName) \(String(first.year)) to "
            + "\(last.doubleValue.formatted(format)) in \(last.periodName) \(String(last.year))."
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

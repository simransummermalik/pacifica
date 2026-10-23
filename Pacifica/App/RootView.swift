import SwiftUI

enum RootTab: CaseIterable, Hashable {
    case bank
    case pay
    case activity

    var systemImage: String {
        switch self {
        case .bank: "building.columns"
        case .pay: "dollarsign"
        case .activity: "clock"
        }
    }

    var title: String {
        switch self {
        case .bank: "Bank"
        case .pay: "Pay"
        case .activity: "Activity"
        }
    }
}

struct RootView: View {
    @State private var selection: RootTab = .pay
    @Namespace private var tabPill

    var body: some View {
        Group {
            switch selection {
            case .bank: HomeView()
            case .pay: PayView()
            case .activity: ActivityPlaceholderView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 0) { tabBar }
        .background(Theme.background.ignoresSafeArea())
        .foregroundStyle(Theme.ink)
        .tint(Theme.ink)
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(RootTab.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 6)
        .background(Theme.background.ignoresSafeArea(edges: .bottom))
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    private func tabButton(for tab: RootTab) -> some View {
        let isSelected = selection == tab
        return Button {
            withAnimation(.snappy(duration: 0.3)) { selection = tab }
        } label: {
            Image(systemName: tab.systemImage)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(isSelected ? Theme.background : Theme.ink)
                .frame(width: 64, height: 40)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(Theme.ink)
                            .matchedGeometryEffect(id: "pill", in: tabPill)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 48)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct ActivityPlaceholderView: View {
    var body: some View {
        Text("Activity")
            .font(.largeTitle.bold())
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    RootView()
}

struct RecentTransactionsView: View {

    var body: some View {

        VStack(alignment: .leading) {

            Text("Recent Activity")
                .font(.headline)
                .foregroundColor(.white)

            TransactionRow(
                icon: "cart.fill",
                title: "Amazon",
                amount: "-$34.99"
            )

            TransactionRow(
                icon: "cup.and.saucer.fill",
                title: "Starbucks",
                amount: "-$6.20"
            )

            TransactionRow(
                icon: "dollarsign.circle.fill",
                title: "Paycheck",
                amount: "+$1,200"
            )
        }
    }
}

struct TransactionRow: View {

    let icon: String
    let title: String
    let amount: String

    var body: some View {

        HStack {

            Image(systemName: icon)
                .font(.title2)

            Text(title)

            Spacer()

            Text(amount)
                .bold()
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(15)
    }
}

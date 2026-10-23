import SwiftUI

enum RootTab: CaseIterable, Hashable {
    case bank
    case activity
    case pay

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

/// Native tab bar: on iOS 26+ this is the floating Liquid Glass bar at the bottom.
struct RootView: View {
    let userID: UUID
    @State private var selection: RootTab = .activity

    var body: some View {
        TabView(selection: $selection) {
            Tab(RootTab.bank.title, systemImage: RootTab.bank.systemImage, value: .bank) {
                HomeView(userID: userID)
            }
            Tab(RootTab.activity.title, systemImage: RootTab.activity.systemImage, value: .activity) {
                ActivityPlaceholderView()
            }
            Tab(RootTab.pay.title, systemImage: RootTab.pay.systemImage, value: .pay) {
                PayView()
            }
        }
        .tint(Theme.text)
    }
}

private struct ActivityPlaceholderView: View {
    var body: some View {
        ZStack {
            AppBackground()
            Text("Activity")
                .font(.largeTitle.bold())
                .foregroundStyle(Theme.text)
        }
    }
}

#Preview {
    RootView(userID: UUID())
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

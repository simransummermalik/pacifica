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

/// Native tab bar: on iOS 26+ this is the floating Liquid Glass bar at the bottom.
struct RootView: View {
    @State private var selection: RootTab = .pay

    var body: some View {
        TabView(selection: $selection) {
            Tab(RootTab.bank.title, systemImage: RootTab.bank.systemImage, value: .bank) {
                HomeView()
            }
            Tab(RootTab.pay.title, systemImage: RootTab.pay.systemImage, value: .pay) {
                PayView()
            }
            Tab(RootTab.activity.title, systemImage: RootTab.activity.systemImage, value: .activity) {
                ActivityPlaceholderView()
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
    RootView()
}

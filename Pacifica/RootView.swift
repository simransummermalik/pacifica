import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            Tab("Bank", systemImage: "building.columns.fill") {
                HomeView()
            }
            Tab("Pay", systemImage: "dollarsign") {
                PlaceholderView(title: "Pay")
            }
            Tab("Activity", systemImage: "clock") {
                PlaceholderView(title: "Activity")
            }
        }
        .tint(Theme.accent)
    }
}

struct PlaceholderView: View {
    let title: String

    var body: some View {
        ZStack {
            AppBackground()
            Text(title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
        }
    }
}

#Preview {
    RootView()
}

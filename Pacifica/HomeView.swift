import SwiftUI

struct HomeView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                OceanConditionsCard()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Cash balance")
                        .font(.headline)
                    Text("$0.00")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                }

                HStack(spacing: 12) {
                    Button("Add money") {}
                        .buttonStyle(.borderedProminent)
                    Button("Withdraw") {}
                        .buttonStyle(.bordered)
                }
                .controlSize(.large)
                .buttonBorderShape(.capsule)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    HomeView()
}

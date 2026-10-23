import SwiftUI

struct HomeView: View {
    let userID: UUID
    @StateObject private var wallet = WalletViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cash balance")
                        .font(.headline)

                    if wallet.isLoading {
                        ProgressView()
                            .frame(height: 67)
                    } else {
                        Text(wallet.formattedBalance)
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                    }

                    if let errorMessage = wallet.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
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
        .task(id: userID) {
            await wallet.load(userID: userID)
        }
    }
}

#Preview {
    HomeView(userID: UUID())
}

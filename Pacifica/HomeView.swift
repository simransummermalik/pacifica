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

                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent activity")
                        .font(.title2.bold())

                    if wallet.isLoading {
                        ProgressView()
                    } else if wallet.transactions.isEmpty {
                        Text("No transactions yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(wallet.transactions) { transaction in
                            TransactionRow(transaction: transaction, userID: userID)
                        }
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .task(id: userID) {
            await wallet.load(userID: userID)
        }
    }
}

private struct TransactionRow: View {
    let transaction: Transaction
    let userID: UUID

    var body: some View {
        let isIncoming = transaction.isIncoming(for: userID)

        HStack(spacing: 12) {
            Image(systemName: isIncoming ? "arrow.down.left" : "arrow.up.right")
                .foregroundStyle(isIncoming ? .green : .orange)
                .frame(width: 28, height: 28)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.title)
                    .fontWeight(.medium)
                Text(transaction.formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(isIncoming ? "+" : "-")$\(NSDecimalNumber(decimal: transaction.amount).stringValue)")
                .fontWeight(.semibold)
                .foregroundStyle(isIncoming ? .green : .primary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HomeView(userID: UUID())
}

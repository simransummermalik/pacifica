import SwiftUI

struct HomeView: View {
    let userID: UUID
    @StateObject private var wallet = WalletViewModel()
    @State private var balanceAction: BalanceAction?

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
                    Button("Add money") {
                        balanceAction = .add
                    }
                        .buttonStyle(.borderedProminent)
                    Button("Withdraw") {
                        balanceAction = .withdraw
                    }
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
        .sheet(item: $balanceAction) { action in
            BalanceAdjustmentView(action: action) { amount in
                await wallet.adjustBalance(delta: action.delta(for: amount))
            }
        }
    }
}

private enum BalanceAction: String, Identifiable {
    case add
    case withdraw

    var id: String { rawValue }
    var title: String { self == .add ? "Add money" : "Withdraw" }
    var deltaSign: Decimal { self == .add ? 1 : -1 }

    func delta(for amount: Decimal) -> Decimal {
        amount * deltaSign
    }
}

private struct BalanceAdjustmentView: View {
    @Environment(\.dismiss) private var dismiss
    let action: BalanceAction
    let submit: (Decimal) async -> Bool

    @State private var amountText = "50"
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section(action.title) {
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    Button(action.title) {
                        Task { await save() }
                    }
                    .disabled(isSaving)
                }
            }
            .navigationTitle("Demo balance")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func save() async {
        guard let amount = Decimal(string: amountText), amount > 0 else {
            errorMessage = "Enter a valid amount."
            return
        }

        isSaving = true
        errorMessage = nil
        let succeeded = await submit(amount)
        isSaving = false

        if succeeded {
            dismiss()
        } else {
            errorMessage = "The balance could not be updated."
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

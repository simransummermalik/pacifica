import SwiftUI

/// Detail page for the cash balance: big balance, add/withdraw, and recent activity.
struct CashBalanceView: View {
    let userID: UUID
    @ObservedObject var wallet: WalletViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var moneySheet: MoneySheetView.Mode?

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 20) {
                header

                ScrollView {
                    GlassEffectContainer(spacing: 16) {
                        VStack(spacing: 24) {
                            balanceBlock
                            actions
                            activityCard
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }
                .scrollIndicators(.hidden)
                .scrollClipDisabled()
            }
            .padding(.top, 8)
        }
        .sheet(item: $moneySheet) { mode in
            MoneySheetView(mode: mode, wallet: wallet)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .task(id: userID) { await wallet.load(userID: userID) }
    }

    // MARK: - Pieces

    private var header: some View {
        HStack {
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
            Spacer()
            Text("Cash balance")
                .font(.headline)
            Spacer()
            Color.clear.frame(width: 52, height: 52)
        }
        .padding(.horizontal, 16)
    }

    private var balanceBlock: some View {
        VStack(spacing: 6) {
            Text(wallet.formattedBalance)
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .foregroundStyle(Theme.text)
                .redacted(reason: wallet.isLoading ? .placeholder : [])
            Text("Available to spend")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
            if let message = wallet.errorMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(Theme.coral)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private var actions: some View {
        HStack(spacing: 12) {
            Button { moneySheet = .add } label: {
                Text("Add money")
                    .font(.headline)
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.glassProminent)
            .tint(Theme.accent)

            Button { moneySheet = .withdraw } label: {
                Text("Withdraw")
                    .font(.headline)
                    .foregroundStyle(Theme.text)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.glass)
        }
        .buttonBorderShape(.capsule)
        .controlSize(.extraLarge)
    }

    private var activityCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Recent activity")
                .font(.title3.weight(.semibold))
                .padding(.bottom, 8)

            if wallet.isLoading && wallet.transactions.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else if wallet.transactions.isEmpty {
                emptyState
            } else {
                ForEach(wallet.transactions) { transaction in
                    ActivityRow(transaction: transaction, userID: userID)
                }
            }
        }
        .foregroundStyle(Theme.text)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .glassEffect(.regular, in: .rect(cornerRadius: Theme.cardRadius))
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "fish")
                .font(.system(size: 34))
                .foregroundStyle(Theme.accent)
            Text("No activity yet")
                .font(.headline)
            Text("Add money or pay a friend and it will show up here.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

private struct ActivityRow: View {
    let transaction: Transaction
    let userID: UUID

    private var isIncoming: Bool { transaction.isIncoming(for: userID) }

    private var amountText: String {
        let value = transaction.amount.formatted(.currency(code: "USD").locale(Locale(identifier: "en_US")))
        return (isIncoming ? "+" : "-") + value
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: isIncoming ? "arrow.down.left" : "arrow.up.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isIncoming ? Theme.accent : Theme.coral)
                .frame(width: 40, height: 40)
                .background(Theme.text.opacity(0.06), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.title)
                    .font(.body.weight(.medium))
                Text(transaction.formattedDate)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            Text(amountText)
                .font(.body.weight(.semibold))
                .foregroundStyle(isIncoming ? Theme.accent : Theme.text)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    CashBalanceView(userID: UUID(), wallet: WalletViewModel())
}

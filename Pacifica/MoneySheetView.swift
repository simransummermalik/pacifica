import SwiftUI

/// Sheet for moving money in or out of the cash balance. Confirming adjusts the demo balance
/// in Supabase through `WalletViewModel.adjustBalance`.
struct MoneySheetView: View {
    enum Mode: Identifiable {
        case add
        case withdraw

        var id: Self { self }
        var title: String { self == .add ? "Add money" : "Withdraw" }
        var accountLabel: String { self == .add ? "From" : "To" }
        var confirmVerb: String { self == .add ? "Add" : "Withdraw" }
    }

    let mode: Mode
    @ObservedObject var wallet: WalletViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var entry = PayViewModel()
    @State private var isSubmitting = false

    private var balance: Decimal { wallet.balance }

    private let quickAmounts = [25, 50, 100]

    private var exceedsBalance: Bool { mode == .withdraw && entry.amount > balance }
    private var canConfirm: Bool { !entry.isZero && !exceedsBalance && !isSubmitting }

    private var balanceText: String {
        balance.formatted(.currency(code: "USD").locale(Locale(identifier: "en_US")))
    }

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                header
                Spacer(minLength: 8)
                amountBlock
                Spacer(minLength: 8)
                quickPicks
                accountRow
                    .padding(.top, 16)
                KeypadView { entry.press($0) }
                    .padding(.vertical, 8)
                confirmButton
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .sensoryFeedback(.selection, trigger: entry.validInputCount)
        .sensoryFeedback(.warning, trigger: entry.invalidInputCount)
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
            Text(mode.title)
                .font(.headline)
            Spacer()
            Color.clear.frame(width: 52, height: 52)
        }
    }

    private var amountBlock: some View {
        VStack(spacing: 8) {
            Text(entry.displayText)
                .font(.system(size: 76, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .foregroundStyle(Theme.text)
                .accessibilityLabel("Amount")
                .accessibilityValue(entry.accessibilityAmount)

            if let message = wallet.errorMessage {
                Text(message)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.coral)
                    .multilineTextAlignment(.center)
            } else if exceedsBalance {
                Text("More than your balance")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.coral)
            } else if mode == .withdraw {
                Text("Available \(balanceText)")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            } else {
                Text("Goes into your cash balance")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    @ViewBuilder
    private var quickPicks: some View {
        HStack(spacing: 10) {
            if mode == .add {
                ForEach(quickAmounts, id: \.self) { amount in
                    chip("$\(amount)") { setAmount(String(amount)) }
                }
            } else {
                chip("Withdraw all") { setAmount(plainString(balance)) }
                    .disabled(balance <= 0)
            }
        }
    }

    private func chip(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.capsule)
        .foregroundStyle(Theme.text)
    }

    private var accountRow: some View {
        HStack(spacing: 14) {
            Image(systemName: "building.columns.fill")
                .font(.title3)
                .foregroundStyle(Theme.accent)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(mode.accountLabel)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                Text("Linked bank •••• 4821")
                    .font(.body.weight(.medium))
            }
            Spacer()
            Image(systemName: "chevron.up.chevron.down")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
        }
        .foregroundStyle(Theme.text)
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .glassEffect(.regular, in: .rect(cornerRadius: 24))
    }

    private var confirmButton: some View {
        Button {
            submit()
        } label: {
            Text(entry.isZero ? mode.title : "\(mode.confirmVerb) \(entry.displayText)")
                .font(.headline)
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.capsule)
        .controlSize(.extraLarge)
        .tint(Theme.accent)
        .disabled(!canConfirm)
    }

    // MARK: - Helpers

    private func submit() {
        let delta = mode == .add ? entry.amount : -entry.amount
        isSubmitting = true
        Task {
            let succeeded = await wallet.adjustBalance(delta: delta)
            isSubmitting = false
            if succeeded { dismiss() }
        }
    }

    /// Replaces the entry with `text` (digits and at most one decimal point) by backspacing, then typing.
    private func setAmount(_ text: String) {
        while entry.entry != "0" {
            entry.press(.backspace)
        }
        for character in text {
            if character == "." {
                entry.press(.decimal)
            } else if let digit = character.wholeNumberValue {
                entry.press(.digit(digit))
            }
        }
    }

    private func plainString(_ value: Decimal) -> String {
        var rounded = Decimal()
        var copy = value
        NSDecimalRound(&rounded, &copy, 2, .down)
        let string = NSDecimalNumber(decimal: rounded).stringValue
        return string.hasSuffix(".0") ? String(string.dropLast(2)) : string
    }
}

#Preview("Add") {
    MoneySheetView(mode: .add, wallet: WalletViewModel())
}

#Preview("Withdraw") {
    MoneySheetView(mode: .withdraw, wallet: WalletViewModel())
}

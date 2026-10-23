import Foundation
import SwiftUI

struct HomeView: View {
    let userID: UUID
    let askPacifica: AskPacificaViewModel

    @State private var hideBalance = false
    @State private var showsAskPacifica = false
    @State private var askDraft = ""
    @State private var showQR = false
    @State private var balanceAction: BalanceAction?
    @State private var oceanConditions = OceanConditionsViewModel()
    @StateObject private var wallet: HomeWalletViewModel
    @StateObject private var dailySelfie: DailySelfieViewModel

    init(userID: UUID, askPacifica: AskPacificaViewModel) {
        self.userID = userID
        self.askPacifica = askPacifica
        _wallet = StateObject(wrappedValue: HomeWalletViewModel(userID: userID))
        _dailySelfie = StateObject(wrappedValue: DailySelfieViewModel(userID: userID))
    }

    var body: some View {
        ZStack(alignment: .top) {
            AppBackground()

            ScrollView {
                GlassEffectContainer(spacing: 16) {
                    VStack(spacing: 16) {
                        TopBar(
                            onQRTap: { showQR = true },
                            askDraft: $askDraft,
                            onAsk: ask
                        )
                        DailySelfieView(viewModel: dailySelfie)
                        OceanConditionsCard(viewModel: oceanConditions)
                        BalanceCard(
                            hideBalance: $hideBalance,
                            balance: wallet.formattedBalance,
                            isLoading: wallet.isLoading,
                            errorMessage: wallet.errorMessage,
                            onAddMoney: { balanceAction = .add },
                            onWithdraw: { balanceAction = .withdraw }
                        )
                        SavingsCard()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 120)
            }
            .scrollIndicators(.hidden)
        }
        .fullScreenCover(isPresented: $showQR) {
            QRCodeView()
        }
        .task(id: userID) {
            await wallet.load()
        }
        .sheet(isPresented: $showsAskPacifica) {
            AskPacificaView(viewModel: askPacifica, priceContext: oceanConditions.priceContext)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $balanceAction) { action in
            BalanceAdjustmentView(action: action) { amount in
                await wallet.adjust(delta: action.delta(for: amount))
            }
        }
    }
}

extension HomeView {
    /// Opens Ask Pacifica. With a question typed, sends it right away and clears the pill;
    /// with an empty pill, just opens the chat (suggestion chips if there's no conversation yet).
    fileprivate func ask() {
        let question = askDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        askDraft = ""
        showsAskPacifica = true
        guard !question.isEmpty else { return }
        if askPacifica.isWaiting {
            // A reply is still on its way; leave the question in the chat's field instead of dropping it.
            askPacifica.draft = question
        } else {
            Task { await askPacifica.send(question, priceContext: oceanConditions.priceContext) }
        }
    }
}

// MARK: - Top bar

private struct TopBar: View {
    let onQRTap: () -> Void
    @Binding var askDraft: String
    let onAsk: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onQRTap) {
                CircleButton(systemImage: "qrcode")
            }
            .foregroundStyle(Theme.text)
            AskPacificaPill(draft: $askDraft, onAsk: onAsk)
            Image(systemName: "person.fill")
                .font(.title3)
                .foregroundStyle(Theme.surface)
                .frame(width: 52, height: 52)
                .glassEffect(.regular.tint(Theme.text).interactive(), in: .circle)
        }
        .padding(.top, 8)
    }
}

/// Search-style field that opens Ask Pacifica; same height and glass as the round top-bar buttons.
private struct AskPacificaPill: View {
    @Binding var draft: String
    let onAsk: () -> Void

    @FocusState private var isFocused: Bool

    private var hasText: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        HStack(spacing: 8) {
            Button(action: submit) {
                Image(systemName: "sparkles")
                    .font(.title3.weight(.semibold))
                    .frame(width: 32, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open Ask Pacifica")

            TextField("Ask Pacifica…", text: $draft)
                .font(.body)
                .submitLabel(.send)
                .focused($isFocused)
                .onSubmit(submit)
                .accessibilityLabel("Ask Pacifica, your money assistant")

            if hasText {
                Button(action: submit) {
                    Image(systemName: "arrow.up")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.surface)
                        .frame(width: 32, height: 32)
                        .background(Theme.text, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Send question")
                .transition(.scale.combined(with: .opacity))
            }
        }
        .foregroundStyle(Theme.text)
        .padding(.leading, 12)
        .padding(.trailing, 10)
        .frame(maxWidth: .infinity, minHeight: 52)
        .glassEffect(.regular.interactive(), in: .capsule)
        .animation(.easeOut(duration: 0.15), value: hasText)
    }

    private func submit() {
        isFocused = false
        onAsk()
    }
}

private struct CircleButton: View {
    let systemImage: String

    var body: some View {
        Image(systemName: systemImage)
            .font(.title3.weight(.semibold))
            .frame(width: 52, height: 52)
            .glassEffect(.regular.interactive(), in: .circle)
    }
}

// MARK: - Balance

private struct BalanceCard: View {
    @Binding var hideBalance: Bool
    let balance: String
    let isLoading: Bool
    let errorMessage: String?
    let onAddMoney: () -> Void
    let onWithdraw: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                HStack(spacing: 8) {
                    Text("Cash balance")
                        .font(.title3.weight(.semibold))
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                }
                Spacer()
                Button {
                    hideBalance.toggle()
                } label: {
                    Image(systemName: hideBalance ? "fish" : "fish.fill")
                        .font(.title3)
                        .foregroundStyle(Theme.text)
                }
            }

            if isLoading {
                ProgressView()
                    .frame(height: 92)
            } else {
                Text(hideBalance ? "$•••" : balance)
                    .font(.system(size: 76, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            HStack(spacing: 12) {
                Button(action: onAddMoney) {
                    Text("Add money")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.glassProminent)
                .tint(Theme.accent)
                Button(action: onWithdraw) {
                    Text("Withdraw")
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.glass)
            }
            .buttonBorderShape(.capsule)
            .controlSize(.extraLarge)
            .padding(.top, 40)
        }
        .padding(20)
        .glassEffect(.regular, in: .rect(cornerRadius: Theme.cardRadius))
    }
}

private enum BalanceAction: String, Identifiable {
    case add
    case withdraw

    var id: String { rawValue }
    var title: String { self == .add ? "Add money" : "Withdraw" }
    var sign: Decimal { self == .add ? 1 : -1 }

    func delta(for amount: Decimal) -> Decimal {
        amount * sign
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

// MARK: - Cards

private struct SavingsCard: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Savings")
                    .font(.title3.weight(.semibold))
                Text("$0.00")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                Text("0% APY today")
                    .font(.title3)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            AnchorIcon()
                .frame(width: 36, height: 36)
                .foregroundStyle(Theme.accent)
                .frame(width: 72, height: 72)
                .glassEffect(.regular, in: .circle)
        }
        .padding(24)
        .glassEffect(.regular, in: .rect(cornerRadius: Theme.cardRadius))
    }
}

#Preview {
    HomeView(userID: UUID(), askPacifica: AskPacificaViewModel())
}

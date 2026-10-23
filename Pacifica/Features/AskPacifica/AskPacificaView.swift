import SwiftUI

struct AskPacificaView: View {
    let viewModel: AskPacificaViewModel
    /// The BLS price headlines the app already loaded, sent along with each question.
    var priceContext: String?

    @FocusState private var isInputFocused: Bool

    private static let typingID = "typing"

    var body: some View {
        ZStack {
            AppBackground()

            VStack(alignment: .leading, spacing: 16) {
                header
                    .padding(.horizontal, 16)
                conversation
            }
            .padding(.top, 24)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { inputBar }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Ask Pacifica")
                    .font(.title2.weight(.bold))
                Text("Not financial advice. Uses your Pacifica data.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            CloseButton()
        }
    }

    // MARK: - Conversation

    private var conversation: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if viewModel.messages.isEmpty {
                        suggestions
                    }
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                    if viewModel.isWaiting {
                        TypingBubble()
                            .id(Self.typingID)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: viewModel.messages.count) { scrollToNewest(proxy) }
            .onChange(of: viewModel.isWaiting) { scrollToNewest(proxy) }
        }
    }

    private func scrollToNewest(_ proxy: ScrollViewProxy) {
        let target: AnyHashable? = viewModel.isWaiting ? AnyHashable(Self.typingID) : viewModel.messages.last.map { AnyHashable($0.id) }
        guard let target else { return }
        withAnimation(.smooth) { proxy.scrollTo(target, anchor: .bottom) }
    }

    private var suggestions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ask about your balance, spending, paydays or debts.")
                .font(.headline)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(AskPacificaViewModel.suggestions, id: \.self) { suggestion in
                Button {
                    Task { await viewModel.send(suggestion, priceContext: priceContext) }
                } label: {
                    Text(suggestion)
                        .font(.headline)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
                .foregroundStyle(Theme.text)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Input

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 12) {
            TextField("Ask a question", text: Bindable(viewModel).draft, axis: .vertical)
                .font(.body)
                .lineLimit(1...4)
                .focused($isInputFocused)
                .submitLabel(.send)
                .onSubmit(send)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .frame(minHeight: 52)
                .glassEffect(.regular, in: .rect(cornerRadius: Theme.cardRadius))

            Button(action: send) {
                Image(systemName: "arrow.up")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.surface)
                    .frame(width: 52, height: 52)
                    .background(Theme.text, in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canSend)
            .opacity(viewModel.canSend ? 1 : 0.4)
            .accessibilityLabel("Send message")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Theme.surface)
    }

    private func send() {
        guard viewModel.canSend else { return }
        Task { await viewModel.sendDraft(priceContext: priceContext) }
    }
}

// MARK: - Bubbles

private struct MessageBubble: View {
    let message: ChatMessage

    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 48) }
            bubble
            if !isUser { Spacer(minLength: 48) }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isUser ? "You said: \(message.text)" : "Pacifica said: \(message.text)")
    }

    /// The user's messages use the inverse fill (like Sign in); Pacifica's use the Home glass card style.
    @ViewBuilder
    private var bubble: some View {
        let text = Text(message.text)
            .font(.body)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        if isUser {
            text
                .foregroundStyle(Theme.surface)
                .background(Theme.text, in: RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        } else {
            text
                .foregroundStyle(Theme.text)
                .glassEffect(.regular, in: .rect(cornerRadius: Theme.cardRadius))
        }
    }
}

private struct TypingBubble: View {
    var body: some View {
        HStack {
            Text("typing…")
                .font(.body)
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .glassEffect(.regular, in: .rect(cornerRadius: Theme.cardRadius))
            Spacer(minLength: 48)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Pacifica is typing")
    }
}

#if DEBUG
#Preview("Empty") {
    AskPacificaView(viewModel: .preview())
}

#Preview("Conversation") {
    AskPacificaView(viewModel: .preview(messages: [
        ChatMessage(role: .user, text: "Can I afford $80 concert tickets?"),
        ChatMessage(
            role: .assistant,
            text: "You have $412.60 in Pacifica and your next paycheck lands Friday, so $80 fits. "
                + "It would leave about $330 until payday."
        ),
        ChatMessage(role: .user, text: "Which debt should I pay first?"),
        ChatMessage(
            role: .assistant,
            text: "Your credit card at 24.99% APR costs the most, so extra payments there save you the most."
        ),
    ]))
}

#Preview("Typing") {
    AskPacificaView(viewModel: .preview(
        messages: [ChatMessage(role: .user, text: "Why does this month feel tight?")],
        isWaiting: true
    ))
}
#endif

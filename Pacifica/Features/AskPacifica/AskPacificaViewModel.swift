import Foundation
import Observation

/// The Ask Pacifica conversation, kept in memory for the signed-in session.
@Observable
@MainActor
final class AskPacificaViewModel {
    static let suggestions = [
        "Can I afford $80 concert tickets?",
        "Why does this month feel tight?",
        "Which debt should I pay first?",
    ]
    static let offlineReply = "I can't connect right now. Check your connection and try again."

    private(set) var messages: [ChatMessage] = []
    private(set) var isWaiting = false
    var draft = ""

    private let service: any AskPacificaServiceProtocol

    init(service: any AskPacificaServiceProtocol = AskPacificaService()) {
        self.service = service
    }

    var canSend: Bool {
        !isWaiting && !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func sendDraft(priceContext: String?) async {
        await send(draft, priceContext: priceContext)
    }

    func send(_ text: String, priceContext: String?) async {
        let question = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !isWaiting, !question.isEmpty else { return }

        messages.append(ChatMessage(role: .user, text: question))
        draft = ""
        isWaiting = true
        defer { isWaiting = false }

        do {
            let reply = try await service.reply(to: messages, priceContext: priceContext)
            let trimmed = reply.trimmingCharacters(in: .whitespacesAndNewlines)
            messages.append(ChatMessage(role: .assistant, text: trimmed.isEmpty ? Self.offlineReply : trimmed))
        } catch {
            messages.append(ChatMessage(role: .assistant, text: Self.offlineReply))
        }
    }
}

#if DEBUG
extension AskPacificaViewModel {
    static func preview(messages: [ChatMessage] = [], isWaiting: Bool = false) -> AskPacificaViewModel {
        let viewModel = AskPacificaViewModel(service: MockAskPacificaService())
        viewModel.messages = messages
        viewModel.isWaiting = isWaiting
        return viewModel
    }
}
#endif

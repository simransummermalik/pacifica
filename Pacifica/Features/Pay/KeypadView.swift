import SwiftUI

enum KeypadKey: Hashable, Sendable {
    case digit(Int)
    case decimal
    case backspace

    var accessibilityLabel: String {
        switch self {
        case .digit(let digit): "\(digit)"
        case .decimal: "Decimal point"
        case .backspace: "Delete"
        }
    }
}

struct KeypadView: View {
    var onKey: (KeypadKey) -> Void

    private let rows: [[KeypadKey]] = [
        [.digit(1), .digit(2), .digit(3)],
        [.digit(4), .digit(5), .digit(6)],
        [.digit(7), .digit(8), .digit(9)],
        [.decimal, .digit(0), .backspace],
    ]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(rows.indices, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(rows[row], id: \.self) { key in
                        keyButton(for: key)
                    }
                }
            }
        }
    }

    private func keyButton(for key: KeypadKey) -> some View {
        Button {
            onKey(key)
        } label: {
            label(for: key)
                .font(.system(.largeTitle, design: .rounded, weight: .semibold))
                .frame(maxWidth: .infinity, minHeight: 52, maxHeight: 68)
                .contentShape(Rectangle())
        }
        .buttonStyle(KeyButtonStyle())
        .buttonRepeatBehavior(key == .backspace ? .enabled : .automatic)
        .accessibilityLabel(key.accessibilityLabel)
    }

    @ViewBuilder
    private func label(for key: KeypadKey) -> some View {
        switch key {
        case .digit(let digit):
            Text("\(digit)")
        case .decimal:
            Text(".")
        case .backspace:
            Image(systemName: "chevron.left")
        }
    }
}

private struct KeyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.4 : 1)
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

import SwiftUI

/// Round glass "xmark" button that dismisses the current sheet or cover.
struct CloseButton: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
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
    }
}

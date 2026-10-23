import SwiftUI

/// Full-width capsule button used on Pay (Pool, Request, Pay) and sign-in.
struct PillButtonStyle: ButtonStyle {
    let fill: Color
    let foreground: Color

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded))
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(fill, in: Capsule())
            .contentShape(Capsule())
            .opacity(isEnabled ? (configuration.isPressed ? 0.75 : 1) : 0.4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
            .animation(.easeOut(duration: 0.2), value: isEnabled)
    }
}

extension ButtonStyle where Self == PillButtonStyle {
    /// Black capsule, e.g. "Pay" and "Sign in".
    static var primaryPill: PillButtonStyle {
        PillButtonStyle(fill: Theme.primaryButtonFill, foreground: Theme.primaryButtonText)
    }

    /// Translucent capsule, e.g. "Pool" and "Request".
    static var translucentPill: PillButtonStyle {
        PillButtonStyle(fill: Theme.translucentFill, foreground: Theme.ink)
    }
}

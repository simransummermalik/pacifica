import SwiftUI

enum Theme {
    /// Pacifica teal, used as the full-screen background.
    static let background = Color(hex: 0x2DD4BF)
    /// Dark navy for text and icons.
    static let ink = Color(hex: 0x06121F)
    /// Translucent fill for secondary buttons.
    static let translucentFill = Color.white.opacity(0.15)
    static let primaryButtonFill = Color.black
    static let primaryButtonText = Color.white

    // MARK: Home / QR screens (adaptive light/dark, Liquid Glass)

    static let teal = Color(hex: 0x069494)
    static let coral = Color(hex: 0xE9724C)
    static let charcoal = Color(hex: 0x191716)

    /// Screen background for Home and QR: white in light mode, charcoal in dark mode.
    static let surface = Color(light: .white, dark: charcoal)
    static let text = Color(light: charcoal, dark: .white)
    static let textSecondary = text.opacity(0.55)
    static let accent = teal
    static let highlight = coral
    static let cardRadius: CGFloat = 28
}

/// Plain app background for Home and QR.
struct AppBackground: View {
    var body: some View {
        Theme.surface
            .ignoresSafeArea()
    }
}

extension Color {
    /// Color that switches between light and dark appearance.
    init(light: Color, dark: Color) {
        self.init(UIColor { traits in
            UIColor(traits.userInterfaceStyle == .dark ? dark : light)
        })
    }

    /// Creates a color from a 24-bit RGB hex value, e.g. `Color(hex: 0x2DD4BF)`.
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

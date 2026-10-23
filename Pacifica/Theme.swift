import SwiftUI

enum Theme {
    // Palette: teal, coral, ink (plus white)
    static let teal = Color(hex: 0x069494)
    static let coral = Color(hex: 0xE9724C)
    static let ink = Color(hex: 0x191716)

    // Adaptive colors: light mode / dark mode
    static let background = Color(light: .white, dark: ink)
    static let text = Color(light: ink, dark: .white)
    static let textSecondary = text.opacity(0.55)
    static let border = text.opacity(0.1)
    static let card = text.opacity(0.05)
    static let accent = teal
    static let highlight = coral
    static let cardRadius: CGFloat = 28
}

extension Color {
    init(light: Color, dark: Color) {
        self.init(UIColor { traits in
            UIColor(traits.userInterfaceStyle == .dark ? dark : light)
        })
    }

    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

/// Plain app background: white in light mode, ink in dark mode.
struct AppBackground: View {
    var body: some View {
        Theme.background
            .ignoresSafeArea()
    }
}

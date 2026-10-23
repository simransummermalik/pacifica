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
}

extension Color {
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

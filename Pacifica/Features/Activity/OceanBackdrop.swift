import SwiftUI

/// Shared ocean colors.
enum OceanPalette {
    /// Dark navy used for text on the lighter water near the top of the screen.
    static let ink = Color(hex: 0x06121F)
    /// Bottom of the screen.
    static let deep = Color(hex: 0x072A5C)
    /// The sky at the very top of the page, and where it meets the water (light blue by day, navy at night).
    static let skyTop = Color(light: Color(hex: 0xFAFDFF), dark: Color(hex: 0x0B2A4A))
    static let skyMid = Color(light: Color(hex: 0xBFE7FA), dark: Color(hex: 0x0F4A7A))
}

/// One blue ocean behind the whole Activity page, from the status bar down to under the tab bar,
/// so the header, the scrolling area and the "Your fish" card all sit on the same water.
/// Drawn once with no timers, so scrolling stays smooth.
struct OceanBackdrop: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: Color(hex: 0x3AA5E8), location: 0),
                .init(color: Color(hex: 0x1E7FD0), location: 0.35),
                .init(color: Color(hex: 0x0F4FA0), location: 0.65),
                .init(color: OceanPalette.deep, location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .accessibilityHidden(true)
    }
}

#Preview {
    OceanBackdrop()
        .ignoresSafeArea()
}

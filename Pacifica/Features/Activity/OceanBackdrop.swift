import SwiftUI

/// Shared ocean colors.
enum OceanPalette {
    /// Dark navy used for text on the lighter water near the top of the screen.
    static let ink = Color(hex: 0x06121F)
    /// Bottom of the screen.
    static let deep = Color(hex: 0x072A5C)
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

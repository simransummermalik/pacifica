import SwiftUI

/// Shared ocean colors so the sky, water and background all meet without a visible seam.
enum OceanPalette {
    /// Where the sky ends and the water begins.
    static let surface = Color(hex: 0x6AD0F5)
    /// The bottom of the trench; also the color behind the scroll view past the end of the ocean.
    static let deep = Color(hex: 0x072A5C)
    /// Very top of the sky: white in light mode, deep navy in dark mode.
    static let skyTop = Color(light: .white, dark: Color(hex: 0x0B1E33))
}

/// The water: one smooth blue gradient from the surface down into the trench.
/// Drawn once with no timers, so scrolling stays smooth.
struct OceanBackdrop: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: OceanPalette.surface, location: 0),
                .init(color: Color(hex: 0x2E9BE0), location: 0.2),
                .init(color: Color(hex: 0x1565B8), location: 0.5),
                .init(color: Color(hex: 0x0E4A98), location: 0.7),
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

import SwiftUI

/// The water: a plain blue depth gradient with a soft foam line at the surface.
/// Drawn once and never redrawn on a timer, so scrolling stays smooth.
struct OceanBackdrop: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: Color(hex: 0x6AD0F5), location: 0),
                .init(color: Color(hex: 0x2E9BE0), location: 0.22),
                .init(color: Color(hex: 0x1565B8), location: 0.58),
                .init(color: Color(hex: 0x0A2E66), location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(alignment: .top) {
            SurfaceWave()
                .stroke(.white.opacity(0.85), lineWidth: 2.5)
                .frame(height: 14)
        }
        .accessibilityHidden(true)
    }
}

/// A single gentle wave line.
private struct SurfaceWave: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let wavelength: CGFloat = 200
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        var x = rect.minX
        while x <= rect.maxX + 4 {
            let y = rect.midY + 4 * sin(x / wavelength * 2 * .pi)
            path.addLine(to: CGPoint(x: x, y: y))
            x += 4
        }
        return path
    }
}

#Preview {
    OceanBackdrop()
        .ignoresSafeArea()
}

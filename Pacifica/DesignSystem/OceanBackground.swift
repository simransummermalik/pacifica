import SwiftUI

/// Animated ocean: a teal gradient with slow, layered rolling waves.
/// Pauses (static waves) when Reduce Motion is on.
struct OceanBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct Wave {
        let baseline: CGFloat   // 0 = top, 1 = bottom
        let amplitude: CGFloat  // points
        let wavelength: CGFloat // points
        let speed: Double       // radians per second (negative flows the other way)
        let phase: Double
        let color: Color
    }

    private let waves: [Wave] = [
        Wave(baseline: 0.22, amplitude: 16, wavelength: 360, speed: 0.55, phase: 0.0, color: .white.opacity(0.10)),
        Wave(baseline: 0.42, amplitude: 22, wavelength: 300, speed: -0.45, phase: 1.7, color: .white.opacity(0.09)),
        Wave(baseline: 0.62, amplitude: 18, wavelength: 420, speed: 0.38, phase: 3.1, color: Theme.teal.opacity(0.22)),
        Wave(baseline: 0.80, amplitude: 24, wavelength: 340, speed: -0.60, phase: 4.6, color: Theme.teal.opacity(0.28)),
    ]

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate

                // Water gradient: light surface to deeper teal
                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .linearGradient(
                        Gradient(colors: [
                            Color(hex: 0x5EEAD4),
                            Color(hex: 0x2DD4BF),
                            Color(hex: 0x1BB8A8),
                        ]),
                        startPoint: .zero,
                        endPoint: CGPoint(x: 0, y: size.height)
                    )
                )

                for wave in waves {
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: size.height))
                    var x: CGFloat = 0
                    while x <= size.width + 4 {
                        let angle = (x / wave.wavelength) * 2 * .pi + t * wave.speed + wave.phase
                        let y = size.height * wave.baseline + wave.amplitude * CGFloat(sin(angle))
                        path.addLine(to: CGPoint(x: x, y: y))
                        x += 4
                    }
                    path.addLine(to: CGPoint(x: size.width, y: size.height))
                    path.closeSubpath()
                    context.fill(path, with: .color(wave.color))
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

#Preview {
    OceanBackground()
}

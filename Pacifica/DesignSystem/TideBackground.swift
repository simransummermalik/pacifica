import SwiftUI

/// A faint teal tide that rises from the bottom of the screen as `level` goes from 0 to 1.
/// `level` is animatable, so changes glide; the wave surface keeps rolling on its own.
/// With Reduce Motion on, the waves hold still but the level still moves.
struct TideBackground: View, @preconcurrency Animatable {
    var level: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var animatableData: CGFloat {
        get { level }
        set { level = newValue }
    }

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            Canvas { context, size in
                let t = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
                let clamped = min(max(level, 0), 1)
                // At level 0 the water sits just below the screen; at 1 it reaches the top.
                let travel = size.height + 24
                let surface = travel - clamped * travel

                func wave(offset: CGFloat, amplitude: CGFloat, wavelength: CGFloat,
                          speed: Double, phase: Double) -> Path {
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: size.height + 24))
                    var x: CGFloat = 0
                    while x <= size.width + 4 {
                        let angle = Double(x / wavelength) * 2 * .pi + t * speed + phase
                        path.addLine(to: CGPoint(x: x, y: surface + offset + amplitude * CGFloat(sin(angle))))
                        x += 4
                    }
                    path.addLine(to: CGPoint(x: size.width, y: size.height + 24))
                    path.closeSubpath()
                    return path
                }

                // Back wave, lighter and slower
                context.fill(
                    wave(offset: -6, amplitude: 9, wavelength: 300, speed: 0.7, phase: 0),
                    with: .color(Theme.teal.opacity(0.12))
                )
                // Front wave, a touch stronger and flowing the other way
                context.fill(
                    wave(offset: 4, amplitude: 7, wavelength: 220, speed: -1.0, phase: 2.0),
                    with: .color(Theme.teal.opacity(0.18))
                )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

#Preview {
    VStack {
        TideBackground(level: 0.5)
    }
}

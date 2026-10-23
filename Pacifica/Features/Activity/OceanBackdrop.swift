import SwiftUI

/// The water: a depth gradient, soft light rays from the surface, drifting bubbles and a rolling surface line.
/// Keeps animating on its own; with Reduce Motion on it holds still.
struct OceanBackdrop: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct Bubble {
        let x: Double       // 0...1 across the width
        let speed: Double   // fraction of height per second
        let size: Double
        let wobble: Double
        let seed: Double
    }

    private let bubbles: [Bubble] = (0..<22).map { i in
        let f = Double(i)
        return Bubble(
            x: (sin(f * 12.9898) * 43758.5453).truncatingRemainder(dividingBy: 1).magnitude,
            speed: 0.03 + (f.truncatingRemainder(dividingBy: 5)) * 0.012,
            size: 3 + (f.truncatingRemainder(dividingBy: 4)) * 2.2,
            wobble: 6 + (f.truncatingRemainder(dividingBy: 3)) * 5,
            seed: (f * 0.37).truncatingRemainder(dividingBy: 1)
        )
    }

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            Canvas { context, size in
                let t = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
                drawWater(&context, size: size)
                drawRays(&context, size: size, t: t)
                drawBubbles(&context, size: size, t: t)
                drawSurface(&context, size: size, t: t)
            }
        }
        .accessibilityHidden(true)
    }

    // MARK: - Layers

    private func drawWater(_ context: inout GraphicsContext, size: CGSize) {
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .linearGradient(
                Gradient(stops: [
                    .init(color: Color(hex: 0x4CC9BF), location: 0),
                    .init(color: Theme.teal, location: 0.28),
                    .init(color: Color(hex: 0x0A5560), location: 0.62),
                    .init(color: Color(hex: 0x082A33), location: 1),
                ]),
                startPoint: .zero,
                endPoint: CGPoint(x: 0, y: size.height)
            )
        )
    }

    private func drawRays(_ context: inout GraphicsContext, size: CGSize, t: Double) {
        let rayCount = 4
        for i in 0..<rayCount {
            let f = Double(i)
            let sway = sin(t * 0.25 + f * 1.7) * 18
            let topX = size.width * (0.1 + 0.25 * f) + sway
            let spread = 46.0 + f * 12
            var ray = Path()
            ray.move(to: CGPoint(x: topX - spread * 0.4, y: 0))
            ray.addLine(to: CGPoint(x: topX + spread * 0.4, y: 0))
            ray.addLine(to: CGPoint(x: topX + spread * 1.9 + 70, y: size.height * 0.72))
            ray.addLine(to: CGPoint(x: topX - spread * 1.9 + 70, y: size.height * 0.72))
            ray.closeSubpath()
            context.fill(
                ray,
                with: .linearGradient(
                    Gradient(colors: [.white.opacity(0.20), .white.opacity(0)]),
                    startPoint: CGPoint(x: topX, y: 0),
                    endPoint: CGPoint(x: topX, y: size.height * 0.72)
                )
            )
        }
    }

    private func drawBubbles(_ context: inout GraphicsContext, size: CGSize, t: Double) {
        for bubble in bubbles {
            let progress = (t * bubble.speed + bubble.seed).truncatingRemainder(dividingBy: 1)
            let y = size.height * (1 - progress)
            let x = size.width * bubble.x + sin(t * 0.8 + bubble.seed * 9) * bubble.wobble
            let rect = CGRect(x: x, y: y, width: bubble.size, height: bubble.size)
            let fade = min(progress * 5, 1) * min((1 - progress) * 3, 1)
            context.stroke(Path(ellipseIn: rect),
                           with: .color(.white.opacity(0.45 * fade)),
                           lineWidth: 1)
            context.fill(Path(ellipseIn: rect.insetBy(dx: bubble.size * 0.3, dy: bubble.size * 0.3)),
                         with: .color(.white.opacity(0.25 * fade)))
        }
    }

    /// Foam line and a lighter band where the water meets the sky.
    private func drawSurface(_ context: inout GraphicsContext, size: CGSize, t: Double) {
        func wave(baseline: CGFloat, amplitude: CGFloat, wavelength: CGFloat, speed: Double, phase: Double) -> Path {
            var path = Path()
            var x: CGFloat = 0
            path.move(to: CGPoint(x: 0, y: baseline))
            while x <= size.width + 4 {
                let angle = Double(x / wavelength) * 2 * .pi + t * speed + phase
                path.addLine(to: CGPoint(x: x, y: baseline + amplitude * CGFloat(sin(angle))))
                x += 4
            }
            return path
        }

        var band = wave(baseline: 6, amplitude: 5, wavelength: 220, speed: 0.9, phase: 0)
        band.addLine(to: CGPoint(x: size.width, y: 70))
        band.addLine(to: CGPoint(x: 0, y: 70))
        band.closeSubpath()
        context.fill(
            band,
            with: .linearGradient(Gradient(colors: [.white.opacity(0.35), .white.opacity(0)]),
                                  startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 0, y: 70))
        )

        context.stroke(wave(baseline: 8, amplitude: 5, wavelength: 220, speed: 0.9, phase: 0),
                       with: .color(.white.opacity(0.85)), lineWidth: 2.5)
        context.stroke(wave(baseline: 16, amplitude: 4, wavelength: 150, speed: -1.2, phase: 2),
                       with: .color(.white.opacity(0.35)), lineWidth: 1.5)
    }
}

#Preview {
    OceanBackdrop()
        .ignoresSafeArea()
}

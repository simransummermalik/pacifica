import SwiftUI

/// Illustration: a fishing bobber floating and bobbing on gentle waves, with ripples.
/// Fills whatever frame it is given and scales with its height; clip it to the card shape.
/// Drawn in code so it stays sharp, follows the palette and can animate. Static with Reduce Motion.
struct BobberScene: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            Canvas { context, size in
                let t = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
                draw(in: &context, size: size, t: t)
            }
        }
        .background(Theme.teal.opacity(0.12))
        .accessibilityHidden(true)
    }

    private func wavePath(size: CGSize, baseline: CGFloat, amplitude: CGFloat,
                          wavelength: CGFloat, phase: Double) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: size.height))
        var x: CGFloat = 0
        while x <= size.width + 2 {
            let y = baseline + amplitude * CGFloat(sin(Double(x / wavelength) * 2 * .pi + phase))
            path.addLine(to: CGPoint(x: x, y: y))
            x += 2
        }
        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.closeSubpath()
        return path
    }

    private func draw(in context: inout GraphicsContext, size: CGSize, t: Double) {
        let w = size.width, h = size.height
        let k = h / 96  // scale relative to the original 96pt-tall design
        let waterline = h * 0.62
        let centerX = w * 0.62

        // Back wave
        context.fill(
            wavePath(size: size, baseline: waterline - 2 * k, amplitude: 3 * k, wavelength: 56 * k, phase: t * 1.1),
            with: .color(Theme.teal.opacity(0.35))
        )

        // Ripples spreading from the bobber
        for i in 0..<2 {
            let cycle = (t / 2.4 + Double(i) * 0.5).truncatingRemainder(dividingBy: 1)
            let rx = (14 + CGFloat(cycle) * 26) * k
            let ry = rx * 0.28
            let rect = CGRect(x: centerX - rx, y: waterline - ry + 1, width: rx * 2, height: ry * 2)
            context.stroke(Path(ellipseIn: rect),
                           with: .color(Theme.teal.opacity(0.5 * (1 - cycle))),
                           lineWidth: 1.5 * k)
        }

        // Bobber: bobs up and down with a slight tilt
        let bob = CGFloat(sin(t * 2.0)) * 3 * k
        let tilt = Angle.degrees(sin(t * 1.3) * 5)
        let bodyR: CGFloat = 13 * k
        let bobberCenter = CGPoint(x: centerX, y: waterline - 6 * k + bob)

        var bobber = context
        bobber.translateBy(x: bobberCenter.x, y: bobberCenter.y)
        bobber.rotate(by: tilt)

        // Line from the top of the card down to the antenna
        var line = Path()
        line.move(to: CGPoint(x: 0, y: -bobberCenter.y))
        line.addLine(to: CGPoint(x: 0, y: -bodyR - 11 * k))
        bobber.stroke(line, with: .color(Theme.text.opacity(0.45)), lineWidth: k)

        // Antenna
        let antenna = Path(roundedRect: CGRect(x: -2 * k, y: -bodyR - 12 * k, width: 4 * k, height: 14 * k), cornerRadius: 2 * k)
        bobber.fill(antenna, with: .color(Theme.coral))

        // Body: coral top half, white bottom half
        let bodyRect = CGRect(x: -bodyR, y: -bodyR, width: bodyR * 2, height: bodyR * 2)
        var top = Path()
        top.addArc(center: .zero, radius: bodyR, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        top.closeSubpath()
        var bottom = Path()
        bottom.addArc(center: .zero, radius: bodyR, startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
        bottom.closeSubpath()
        bobber.fill(top, with: .color(Theme.coral))
        bobber.fill(bottom, with: .color(.white))
        bobber.stroke(Path(ellipseIn: bodyRect), with: .color(Theme.text.opacity(0.25)), lineWidth: k)

        // Front wave covers the lower part of the bobber
        context.fill(
            wavePath(size: size, baseline: waterline + 4 * k, amplitude: 4 * k, wavelength: 44 * k, phase: -t * 1.6 + 1.2),
            with: .color(Theme.teal.opacity(0.55))
        )
    }
}

#Preview {
    BobberScene()
        .frame(height: 260)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .padding()
}

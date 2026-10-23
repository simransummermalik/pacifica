import SwiftUI

// Custom icons for things SF Symbols doesn't have (e.g. the anchor). Draw in a unit square, scaled to the frame.

/// Anchor drawn as a stroke: ring, stock, shank and curved arms.
struct AnchorShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * w, y: rect.minY + y * h)
        }

        var path = Path()

        // Ring
        let ringR = 0.09 * w
        let ringCenter = pt(0.5, 0.14)
        path.addEllipse(in: CGRect(x: ringCenter.x - ringR, y: ringCenter.y - ringR,
                                   width: ringR * 2, height: ringR * 2))

        // Shank
        path.move(to: pt(0.5, 0.14 + 0.09))
        path.addLine(to: pt(0.5, 0.88))

        // Stock
        path.move(to: pt(0.32, 0.34))
        path.addLine(to: pt(0.68, 0.34))

        // Arms: a smile-shaped arc under the shank, ending in flukes
        path.move(to: pt(0.14, 0.60))
        path.addQuadCurve(to: pt(0.5, 0.88), control: pt(0.18, 0.88))
        path.addQuadCurve(to: pt(0.86, 0.60), control: pt(0.82, 0.88))

        // Fluke tips
        path.move(to: pt(0.14, 0.60))
        path.addLine(to: pt(0.06, 0.72))
        path.move(to: pt(0.14, 0.60))
        path.addLine(to: pt(0.27, 0.64))
        path.move(to: pt(0.86, 0.60))
        path.addLine(to: pt(0.94, 0.72))
        path.move(to: pt(0.86, 0.60))
        path.addLine(to: pt(0.73, 0.64))

        return path
    }
}

struct AnchorIcon: View {
    var body: some View {
        AnchorShape()
            .stroke(style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))
    }
}

#Preview {
    HStack(spacing: 24) {
        AnchorIcon().frame(width: 60, height: 60)
    }
    .padding()
}

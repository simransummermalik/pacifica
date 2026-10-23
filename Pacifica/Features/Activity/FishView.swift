import SwiftUI

/// A friendly fish. Drawn in code so it stays sharp, takes palette colors and can swim.
/// The graphic faces right by default; `facesRight: false` mirrors it (the label never flips).
struct FishView: View {
    let name: String
    let detail: String
    let width: CGFloat
    var isYou = false
    var isHidden = false
    var facesRight = true
    var isSelected = false
    var phase: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var height: CGFloat { width * 0.56 }
    private var bodyFill: Color { isYou ? Theme.coral : .white }
    private var tailFill: Color { isYou ? .white : Theme.coral }
    private var labelColor: Color { isYou ? .white : Theme.charcoal }

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            let t = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
            let sway = sin(t * 0.7 + phase) * 8
            let bob = sin(t * 1.1 + phase * 1.3) * 4
            let wag = sin(t * 6 + phase) * 14

            ZStack {
                fishGraphic(wag: wag)
                    .scaleEffect(x: facesRight ? 1 : -1)

                label
                    .offset(x: (facesRight ? 1 : -1) * width * 0.11)
            }
            .frame(width: width, height: height)
            .opacity(isHidden ? 0.5 : 1)
            .shadow(color: .white.opacity(isSelected ? 0.85 : 0), radius: 14)
            .offset(x: sway, y: bob)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name), \(detail)")
    }

    private func fishGraphic(wag: Double) -> some View {
        HStack(spacing: -width * 0.04) {
            FishTail()
                .fill(tailFill)
                .frame(width: width * 0.3, height: height * 0.78)
                .rotationEffect(.degrees(wag), anchor: .trailing)

            ZStack {
                Ellipse().fill(bodyFill)
                Ellipse()
                    .fill(LinearGradient(colors: [.white.opacity(0.4), .clear],
                                         startPoint: .top, endPoint: .center))
                if isHidden {
                    Ellipse().strokeBorder(.white.opacity(0.9), style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
                }
                if isSelected {
                    Ellipse().strokeBorder(.white, lineWidth: 3)
                }
            }
            .frame(width: width * 0.78, height: height)
            .overlay(alignment: .topTrailing) {
                Circle()
                    .fill(Theme.charcoal)
                    .frame(width: height * 0.11, height: height * 0.11)
                    .offset(x: -width * 0.1, y: height * 0.2)
            }
        }
    }

    private var label: some View {
        VStack(spacing: 1) {
            HStack(spacing: 3) {
                if isHidden {
                    Image(systemName: "lock.fill")
                        .font(.system(size: width * 0.1))
                }
                Text(name)
                    .font(.system(size: width * (isYou ? 0.18 : 0.16), weight: .bold, design: .rounded))
            }
            Text(detail)
                .font(.system(size: width * 0.1, weight: .semibold, design: .rounded))
                .opacity(0.7)
        }
        .foregroundStyle(labelColor)
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .frame(width: width * 0.55)
    }
}

/// Curved fan tail. The pointed end is on the right, where it joins the body.
private struct FishTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.minY),
                          control: CGPoint(x: rect.midX, y: rect.midY - rect.height * 0.1))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY),
                          control: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.midY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY),
                          control: CGPoint(x: rect.midX, y: rect.midY + rect.height * 0.1))
        path.closeSubpath()
        return path
    }
}

#Preview {
    ZStack {
        Color(red: 0.03, green: 0.45, blue: 0.5)
        VStack(spacing: 30) {
            FishView(name: "You", detail: "42%", width: 150, isYou: true, isSelected: true)
            FishView(name: "Summer", detail: "18%", width: 100, facesRight: false)
            FishView(name: "Mario", detail: "hidden", width: 100, isHidden: true)
        }
    }
}

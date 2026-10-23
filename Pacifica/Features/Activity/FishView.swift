import SwiftUI

/// A friend's fish, drawn with the `fish.fill` SF Symbol, plus a name tag.
/// The fish tilts nose-up near the surface and nose-down when deep, and wiggles as it swims.
struct FishView: View {
    let name: String
    let detail: String
    var isYou = false
    var isHidden = false
    var facesRight = true
    var isSelected = false
    /// 0 = surface, 1 = whole budget used. Drives the tilt.
    var depth: Double = 0.5
    var phase: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var symbolSize: CGFloat { isYou ? 58 : 40 }
    private var tilt: Double { (min(max(depth, 0), 1.15) - 0.5) * 50 }

    var body: some View {
        VStack(spacing: 8) {
            fish
            tag
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name), \(detail)")
    }

    private var fish: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            let t = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
            let wiggle = sin(t * 3.2 + phase) * 5
            let sway = sin(t * 0.8 + phase) * 4
            let bob = sin(t * 1.2 + phase * 1.3) * 3

            Image(systemName: isHidden ? "fish" : "fish.fill")
                .font(.system(size: symbolSize, weight: .regular))
                .foregroundStyle(isYou ? Theme.coral : Color.white)
                .opacity(isHidden ? 0.6 : 1)
                .shadow(color: .black.opacity(0.25), radius: 4, y: 3)
                .shadow(color: isSelected ? .white.opacity(0.9) : .clear, radius: 12)
                .rotationEffect(.degrees(tilt + wiggle))
                .scaleEffect(x: facesRight ? 1 : -1)
                .overlay(alignment: .topTrailing) {
                    if isHidden {
                        Image(systemName: "lock.fill")
                            .font(.system(size: symbolSize * 0.3))
                            .foregroundStyle(.white)
                            .padding(5)
                            .background(Theme.charcoal.opacity(0.7), in: Circle())
                            .offset(x: 8, y: -8)
                    }
                }
                .offset(x: sway, y: bob)
        }
        .frame(width: symbolSize * 1.4, height: symbolSize * 1.1)
    }

    private var tag: some View {
        VStack(spacing: 0) {
            Text(name)
                .font(.system(size: isYou ? 14 : 12, weight: .bold, design: .rounded))
            Text(detail)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .opacity(0.7)
        }
        .foregroundStyle(isYou ? Color.white : Theme.charcoal)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule().fill(isYou ? Theme.coral : Color.white.opacity(0.92))
        )
        .overlay {
            if isSelected { Capsule().strokeBorder(.white, lineWidth: 2) }
        }
        .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
    }
}

#Preview {
    ZStack {
        Color(red: 0.03, green: 0.45, blue: 0.5)
        HStack(spacing: 24) {
            FishView(name: "You", detail: "36%", isYou: true, isSelected: true, depth: 0.36)
            FishView(name: "Summer", detail: "23%", facesRight: false, depth: 0.23)
            FishView(name: "Mario", detail: "hidden", isHidden: true, depth: 0.55)
        }
    }
}

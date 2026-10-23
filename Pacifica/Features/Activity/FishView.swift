import SwiftUI

/// A friend's fish, drawn with the `fish.fill` SF Symbol, plus a name tag.
/// The fish tilts nose-up near the surface and nose-down when deep, and wiggles gently.
/// The wiggle uses one cheap repeating animation, not a per-frame timer.
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
    @State private var swimming = false

    private var symbolSize: CGFloat { isYou ? 58 : 40 }
    private var tilt: Double { (min(max(depth, 0), 1.15) - 0.5) * 50 }

    var body: some View {
        VStack(spacing: 8) {
            fish
            tag
        }
        .onAppear {
            if !reduceMotion { swimming = true }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name), \(detail)")
    }

    private var fish: some View {
        Image(systemName: isHidden ? "fish" : "fish.fill")
            .font(.system(size: symbolSize, weight: .regular))
            .foregroundStyle(isYou ? Theme.coral : Color.white)
            .opacity(isHidden ? 0.6 : 1)
            .rotationEffect(.degrees(tilt))
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
            .rotationEffect(.degrees(swimming ? 4 : -4))
            .offset(y: swimming ? 3 : -3)
            .animation(
                .easeInOut(duration: 1.6 + phase * 0.08).repeatForever(autoreverses: true),
                value: swimming
            )
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
        .background(Capsule().fill(isYou ? Theme.coral : Color.white.opacity(0.92)))
        .overlay {
            if isSelected { Capsule().strokeBorder(.white, lineWidth: 2) }
        }
    }
}

#Preview {
    ZStack {
        Color(red: 0.1, green: 0.4, blue: 0.7)
        HStack(spacing: 24) {
            FishView(name: "You", detail: "36%", isYou: true, isSelected: true, depth: 0.36)
            FishView(name: "Summer", detail: "23%", facesRight: false, depth: 0.23)
            FishView(name: "Mario", detail: "hidden", isHidden: true, depth: 0.55)
        }
    }
}

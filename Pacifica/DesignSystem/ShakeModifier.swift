import SwiftUI

extension View {
    /// Short horizontal shake each time `trigger` changes, used to reject input (Pay amount, sign-in fields).
    func shake<Trigger: Equatable>(trigger: Trigger) -> some View {
        keyframeAnimator(initialValue: CGFloat.zero, trigger: trigger) { content, offset in
            content.offset(x: offset)
        } keyframes: { _ in
            KeyframeTrack {
                LinearKeyframe(-12, duration: 0.05)
                LinearKeyframe(10, duration: 0.07)
                LinearKeyframe(-6, duration: 0.07)
                LinearKeyframe(3, duration: 0.06)
                SpringKeyframe(0, duration: 0.1)
            }
        }
    }
}

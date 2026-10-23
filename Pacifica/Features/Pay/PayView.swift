import SwiftUI

struct PayView: View {
    @State private var viewModel = PayViewModel()

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Spacer(minLength: 12)
            amountText
            Spacer(minLength: 12)
            KeypadView { viewModel.press($0) }
                .padding(.bottom, 16)
            actionButtons
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(Theme.ink)
        .background(Theme.background.ignoresSafeArea())
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .sensoryFeedback(.selection, trigger: viewModel.validInputCount)
        .sensoryFeedback(.warning, trigger: viewModel.invalidInputCount)
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            CircleIconButton(systemName: "face.smiling", accessibilityLabel: "Emoji") {}
            CircleIconButton(systemName: "qrcode.viewfinder", accessibilityLabel: "Scan QR code") {}
            Spacer()
            CircleIconButton(systemName: "magnifyingglass", accessibilityLabel: "Search") {}
            Button {} label: {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 40))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Profile")
        }
        .padding(.top, 8)
    }

    private var amountText: some View {
        Text(viewModel.displayText)
            .font(.system(size: 88, weight: .bold, design: .rounded))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.4)
            .contentTransition(.numericText())
            .animation(.snappy(duration: 0.25), value: viewModel.entry)
            .keyframeAnimator(initialValue: CGFloat.zero, trigger: viewModel.invalidInputCount) { content, offset in
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
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Amount")
            .accessibilityValue(viewModel.accessibilityAmount)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button("Pool") {}
                    .buttonStyle(PillButtonStyle(fill: Theme.translucentFill, foreground: Theme.ink))
                Button("Request") { viewModel.request() }
                    .buttonStyle(PillButtonStyle(fill: Theme.translucentFill, foreground: Theme.ink))
                    .disabled(viewModel.isZero)
            }
            Button("Pay") { viewModel.pay() }
                .buttonStyle(PillButtonStyle(fill: Theme.primaryButtonFill, foreground: Theme.primaryButtonText))
                .disabled(viewModel.isZero)
        }
    }
}

private struct CircleIconButton: View {
    let systemName: String
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 44, height: 44)
                .background(Theme.translucentFill, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

private struct PillButtonStyle: ButtonStyle {
    let fill: Color
    let foreground: Color

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded))
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(fill, in: Capsule())
            .contentShape(Capsule())
            .opacity(isEnabled ? (configuration.isPressed ? 0.75 : 1) : 0.4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
            .animation(.easeOut(duration: 0.2), value: isEnabled)
    }
}

#Preview {
    PayView()
}

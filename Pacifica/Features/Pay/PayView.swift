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
            .shake(trigger: viewModel.invalidInputCount)
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Amount")
            .accessibilityValue(viewModel.accessibilityAmount)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button("Pool") {}
                    .buttonStyle(.translucentPill)
                Button("Request") { viewModel.request() }
                    .buttonStyle(.translucentPill)
                    .disabled(viewModel.isZero)
            }
            Button("Pay") { viewModel.pay() }
                .buttonStyle(.primaryPill)
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

#Preview {
    PayView()
}

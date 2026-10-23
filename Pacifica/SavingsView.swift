import SwiftUI

/// Detail page for savings. There is no savings backend yet, so the numbers are placeholders
/// and the action buttons don't move money.
struct SavingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 20) {
                header

                ScrollView {
                    GlassEffectContainer(spacing: 16) {
                        VStack(spacing: 24) {
                            balanceBlock
                            actions
                            goalsCard
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }
                .scrollIndicators(.hidden)
                .scrollClipDisabled()
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Pieces

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.title3.weight(.semibold))
                    .frame(width: 52, height: 52)
                    .glassEffect(.regular.interactive(), in: .circle)
            }
            .foregroundStyle(Theme.text)
            .accessibilityLabel("Close")
            Spacer()
            Text("Savings")
                .font(.headline)
            Spacer()
            Color.clear.frame(width: 52, height: 52)
        }
        .padding(.horizontal, 16)
    }

    private var balanceBlock: some View {
        VStack(spacing: 14) {
            AnchorIcon()
                .frame(width: 44, height: 44)
                .foregroundStyle(Theme.accent)
                .frame(width: 96, height: 96)
                .glassEffect(.regular, in: .circle)

            VStack(spacing: 6) {
                Text("$0.00")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.text)
                Text("0% APY today")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private var actions: some View {
        HStack(spacing: 12) {
            Button {} label: {
                Text("Add to savings")
                    .font(.headline)
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.glassProminent)
            .tint(Theme.accent)

            Button {} label: {
                Text("Move to cash")
                    .font(.headline)
                    .foregroundStyle(Theme.text)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.glass)
        }
        .buttonBorderShape(.capsule)
        .controlSize(.extraLarge)
    }

    private var goalsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Savings goals")
                .font(.title3.weight(.semibold))

            VStack(spacing: 10) {
                Image(systemName: "sailboat")
                    .font(.system(size: 34))
                    .foregroundStyle(Theme.accent)
                Text("No goals yet")
                    .font(.headline)
                Text("Save up for something, like a fishing trip with friends.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)

            Button {} label: {
                Label("New goal", systemImage: "plus")
                    .font(.headline)
                    .foregroundStyle(Theme.text)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
        }
        .foregroundStyle(Theme.text)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .glassEffect(.regular, in: .rect(cornerRadius: Theme.cardRadius))
    }
}

#Preview {
    SavingsView()
}

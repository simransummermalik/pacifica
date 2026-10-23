import SwiftUI

struct HomeView: View {
    let userID: UUID
    @StateObject private var wallet = WalletViewModel()
    @State private var profile: Profile?
    @State private var hideBalance = false
    @State private var showQR = false
    @State private var showProfile = false
    @State private var moneySheet: MoneySheetView.Mode?
    @State private var oceanConditions = OceanConditionsViewModel()

    var body: some View {
        ZStack(alignment: .top) {
            AppBackground()

            ScrollView {
                GlassEffectContainer(spacing: 16) {
                    VStack(spacing: 16) {
                        TopBar(onQRTap: { showQR = true }, onProfileTap: { showProfile = true })
                        OceanConditionsCard(viewModel: oceanConditions)
                        BalanceCard(hideBalance: $hideBalance, wallet: wallet, onMoneyAction: { moneySheet = $0 })
                        SavingsCard()
                        FishingCard()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 120)
            }
            .scrollIndicators(.hidden)
        }
        .fullScreenCover(isPresented: $showQR) {
            QRCodeView(name: displayName, handle: handle)
        }
        .sheet(item: $moneySheet) { mode in
            MoneySheetView(mode: mode, balance: wallet.balance)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showProfile) {
            ProfileView(name: displayName, handle: handle)
        }
        .task(id: userID) {
            await wallet.load(userID: userID)
            profile = try? await ProfileService().fetchProfile(userID: userID)
        }
    }
}

extension HomeView {
    fileprivate var displayName: String { profile?.displayName ?? PlaceholderProfile.name }
    fileprivate var handle: String { profile.map { "@\($0.username)" } ?? PlaceholderProfile.handle }
}

// MARK: - Top bar

private struct TopBar: View {
    let onQRTap: () -> Void
    let onProfileTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onQRTap) {
                CircleButton(systemImage: "qrcode")
            }
            .foregroundStyle(Theme.text)
            Spacer()
            Button(action: onProfileTap) {
                Image(systemName: "fish.fill")
                    .font(.title3)
                    .foregroundStyle(Theme.surface)
                    .frame(width: 52, height: 52)
                    .glassEffect(.regular.tint(Theme.text).interactive(), in: .circle)
            }
            .accessibilityLabel("Profile")
        }
        .padding(.top, 8)
    }
}

private struct CircleButton: View {
    let systemImage: String

    var body: some View {
        Image(systemName: systemImage)
            .font(.title3.weight(.semibold))
            .frame(width: 52, height: 52)
            .glassEffect(.regular.interactive(), in: .circle)
    }
}

// MARK: - Balance

private struct BalanceCard: View {
    @Binding var hideBalance: Bool
    @ObservedObject var wallet: WalletViewModel
    let onMoneyAction: (MoneySheetView.Mode) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                HStack(spacing: 8) {
                    Text("Cash balance")
                        .font(.title3.weight(.semibold))
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                }
                Spacer()
                Button {
                    hideBalance.toggle()
                } label: {
                    Image(systemName: hideBalance ? "eye" : "eye.slash")
                        .font(.title3)
                        .foregroundStyle(Theme.text)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(hideBalance ? "$•••" : wallet.formattedBalance)
                    .font(.system(size: 76, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .redacted(reason: wallet.isLoading ? .placeholder : [])
                if let message = wallet.errorMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(Theme.coral)
                }
            }

            HStack(spacing: 12) {
                Button { onMoneyAction(.add) } label: {
                    Text("Add money")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.glassProminent)
                .tint(Theme.accent)
                Button { onMoneyAction(.withdraw) } label: {
                    Text("Withdraw")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Theme.text)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.glass)
            }
            .buttonBorderShape(.capsule)
            .controlSize(.extraLarge)
            .padding(.top, 40)
        }
        .padding(20)
        .glassEffect(.regular, in: .rect(cornerRadius: Theme.cardRadius))
    }
}

// MARK: - Cards

private struct SavingsCard: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Savings")
                    .font(.title3.weight(.semibold))
                Text("$0.00")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                Text("0% APY today")
                    .font(.title3)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            AnchorIcon()
                .frame(width: 36, height: 36)
                .foregroundStyle(Theme.accent)
                .frame(width: 72, height: 72)
                .glassEffect(.regular, in: .circle)
        }
        .padding(24)
        .glassEffect(.regular, in: .rect(cornerRadius: Theme.cardRadius))
    }
}

private struct FishingCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Friends")
                    .font(.title3.weight(.semibold))
                Text("Let's go fishing with your friends")
                    .font(.system(size: 36, weight: .bold))
            }
            .foregroundStyle(Theme.text)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)

            BobberScene()
                .frame(height: 260)
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
        .glassEffect(.regular, in: .rect(cornerRadius: Theme.cardRadius))
    }
}

#Preview {
    HomeView(userID: UUID())
}

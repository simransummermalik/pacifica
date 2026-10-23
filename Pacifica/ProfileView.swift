import SwiftUI

/// Placeholder account info until real accounts exist.
enum PlaceholderProfile {
    static let name = "Your Name"
    static let handle = "@yourname"
}

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showQR = false

    private struct SettingsRow: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
    }

    private let rows = [
        SettingsRow(icon: "person.text.rectangle", title: "Account details"),
        SettingsRow(icon: "creditcard", title: "Cards & banking"),
        SettingsRow(icon: "bell", title: "Notifications"),
        SettingsRow(icon: "lock", title: "Privacy & security"),
        SettingsRow(icon: "questionmark.circle", title: "Help"),
    ]

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 24) {
                header

                ScrollView {
                    GlassEffectContainer(spacing: 16) {
                        VStack(spacing: 24) {
                            identity
                            quickActions
                            settingsList
                            signOut
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
        .fullScreenCover(isPresented: $showQR) {
            QRCodeView()
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
            Text("Profile")
                .font(.headline)
            Spacer()
            Color.clear.frame(width: 52, height: 52)
        }
        .padding(.horizontal, 16)
    }

    private var identity: some View {
        VStack(spacing: 14) {
            Image(systemName: "fish.fill")
                .font(.system(size: 56))
                .foregroundStyle(Theme.surface)
                .frame(width: 132, height: 132)
                .glassEffect(.regular.tint(Theme.text), in: .circle)

            VStack(spacing: 4) {
                Text(PlaceholderProfile.name)
                    .font(.title.weight(.bold))
                Text(PlaceholderProfile.handle)
                    .font(.title3)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private var quickActions: some View {
        HStack(spacing: 12) {
            Button {
                showQR = true
            } label: {
                Label("My QR code", systemImage: "qrcode")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.glassProminent)
            .tint(Theme.accent)

            Button {} label: {
                Label("Edit", systemImage: "pencil")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.glass)
            .foregroundStyle(Theme.text)
        }
        .buttonBorderShape(.capsule)
        .controlSize(.extraLarge)
    }

    private var settingsList: some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                Button {} label: {
                    HStack(spacing: 14) {
                        Image(systemName: row.icon)
                            .font(.title3)
                            .foregroundStyle(Theme.accent)
                            .frame(width: 28)
                        Text(row.title)
                            .font(.body.weight(.medium))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.text)

                if index < rows.count - 1 {
                    Divider().padding(.leading, 62)
                }
            }
        }
        .glassEffect(.regular, in: .rect(cornerRadius: Theme.cardRadius))
    }

    private var signOut: some View {
        Button {} label: {
            Text("Sign out")
                .font(.headline)
                .foregroundStyle(Theme.coral)
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.capsule)
        .controlSize(.extraLarge)
    }
}

#Preview {
    ProfileView()
}

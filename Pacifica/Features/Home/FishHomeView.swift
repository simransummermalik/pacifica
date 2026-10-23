import SwiftUI
import UIKit
import Supabase

struct FishHomeView: View {
    let userID: UUID

    @State private var isFloating = false
    @State private var showsSelfiePrompt = false
    @State private var lastPromptToken: String?
    @State private var circleMembers: [ActivityProfile] = []
    @State private var selectedMember: ActivityProfile?
    @StateObject private var dailySelfie: DailySelfieViewModel
    @Environment(\.scenePhase) private var scenePhase

    init(userID: UUID) {
        self.userID = userID
        _dailySelfie = StateObject(wrappedValue: DailySelfieViewModel(userID: userID))
    }

    private let fish: [FloatingFish] = [
        FloatingFish(x: 0.22, y: 0.28, size: 64, color: Theme.coral, drift: 16, duration: 3.4, delay: 0.0, facesRight: true),
        FloatingFish(x: 0.72, y: 0.35, size: 52, color: Theme.accent, drift: 12, duration: 4.2, delay: 0.4, facesRight: false),
        FloatingFish(x: 0.48, y: 0.50, size: 82, color: Color.orange, drift: 20, duration: 3.8, delay: 0.8, facesRight: true),
        FloatingFish(x: 0.18, y: 0.68, size: 48, color: Color.indigo, drift: 14, duration: 4.6, delay: 0.2, facesRight: false),
        FloatingFish(x: 0.78, y: 0.76, size: 70, color: Color.mint, drift: 18, duration: 3.6, delay: 1.0, facesRight: true)
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0xD9FAF6), Color(hex: 0x8EDBD5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            GeometryReader { proxy in
                ForEach(Array(fish.enumerated()), id: \.element.id) { index, fish in
                    Button {
                        guard circleMembers.indices.contains(index) else { return }
                        if circleMembers[index].id == userID {
                            showsSelfiePrompt = true
                        } else {
                            selectedMember = circleMembers[index]
                        }
                    } label: {
                        FishAvatar(
                            fish: fish,
                            selfie: isCurrentUserFish(at: index) ? dailySelfie.image : nil
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(memberLabel(at: index))
                    .position(
                        x: proxy.size.width * fish.x,
                        y: proxy.size.height * fish.y
                    )
                    .offset(
                        x: isFloating ? fish.drift : -fish.drift,
                        y: isFloating ? -fish.drift / 2 : fish.drift / 2
                    )
                    .animation(
                        .easeInOut(duration: fish.duration)
                            .repeatForever(autoreverses: true)
                            .delay(fish.delay),
                        value: isFloating
                    )
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pacifica")
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.ink)
                        Text("Your circle is swimming by.")
                            .font(.title3.weight(.medium))
                            .foregroundStyle(Theme.ink.opacity(0.7))
                    }

                    Spacer()

                    Menu {
                        Button("Log out", role: .destructive) {
                            Task { await logOut() }
                        }
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Theme.ink)
                            .padding(12)
                            .background(.white.opacity(0.45), in: Circle())
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 34)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .onAppear {
            isFloating = true
        }
        .task(id: userID) {
            await loadCircleMembers()
            await refreshSelfiePrompt()

            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                await refreshSelfiePrompt()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { await refreshSelfiePrompt() }
        }
        .sheet(isPresented: $showsSelfiePrompt) {
            NavigationStack {
                ScrollView {
                    DailySelfieView(viewModel: dailySelfie)
                        .padding(16)
                }
                .navigationTitle("Selfie check-in")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Later") { showsSelfiePrompt = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Confirm") { showsSelfiePrompt = false }
                            .disabled(dailySelfie.image == nil || dailySelfie.isSaving)
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(item: $selectedMember) { member in
            CircleMemberSheet(member: member)
                .presentationDetents([.medium])
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Pacifica home with five floating fish")
    }

    private func refreshSelfiePrompt() async {
        await dailySelfie.load()
        guard dailySelfie.isEligible else { return }

        let token = dailySelfie.selfie?.expiresAt ?? "no-selfie"
        guard lastPromptToken != token else { return }

        lastPromptToken = token
        showsSelfiePrompt = true
    }

    private func logOut() async {
        try? await SupabaseClientProvider.shared.auth.signOut()
    }

    private func loadCircleMembers() async {
        guard let profiles = try? await ActivityService().fetchProfiles() else { return }

        var orderedProfiles = profiles.filter { $0.id != userID }
        if let currentUser = profiles.first(where: { $0.id == userID }) {
            orderedProfiles.insert(currentUser, at: 0)
        }
        circleMembers = Array(orderedProfiles.prefix(fish.count))
    }

    private func memberLabel(at index: Int) -> String {
        guard circleMembers.indices.contains(index) else { return "Swimming fish" }
        let member = circleMembers[index]
        if member.id == userID {
            return dailySelfie.image == nil ? "Open your selfie check-in" : "Open your selfie"
        }
        return "Open \(member.displayName)'s circle profile"
    }

    private func isCurrentUserFish(at index: Int) -> Bool {
        circleMembers.indices.contains(index) && circleMembers[index].id == userID
    }
}

private struct FishAvatar: View {
    let fish: FloatingFish
    let selfie: UIImage?

    var body: some View {
        ZStack {
            Image(systemName: "fish.fill")
                .font(.system(size: fish.size, weight: .semibold))
                .foregroundStyle(fish.color)

            if let selfie {
                Image(uiImage: selfie)
                    .resizable()
                    .scaledToFill()
                    .frame(width: fish.size * 0.72, height: fish.size * 0.72)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white.opacity(0.9), lineWidth: 2))
                    .offset(x: -fish.size * 0.08)
            }
        }
        .shadow(color: .black.opacity(0.12), radius: 8, y: 5)
        .scaleEffect(x: fish.facesRight ? 1 : -1, y: 1)
        .padding(18)
        .contentShape(Rectangle())
    }
}

private struct CircleMemberSheet: View {
    let member: ActivityProfile

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "fish.fill")
                .font(.system(size: 48))
                .foregroundStyle(Theme.accent)

            Text(member.displayName)
                .font(.title2.weight(.bold))
            Text("@\(member.username)")
                .foregroundStyle(.secondary)
            Text("Circle member")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
}

private struct FloatingFish: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let color: Color
    let drift: CGFloat
    let duration: Double
    let delay: Double
    let facesRight: Bool
}

#Preview {
    FishHomeView(userID: UUID())
}

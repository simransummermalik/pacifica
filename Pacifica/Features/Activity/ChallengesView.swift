import SwiftUI

@MainActor
private final class ChallengesViewModel: ObservableObject {
    let userID: UUID

    @Published private(set) var challenges: [ActivityChallenge] = []
    @Published private(set) var entries: [ActivityChallengeEntry] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    init(userID: UUID) {
        self.userID = userID
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let service = ActivityChallengeService()
            challenges = try await service.fetchChallenges()
            entries = try await service.fetchEntries()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func create(title: String, merchant: String) async -> Bool {
        do {
            let challenge = try await ActivityChallengeService().createChallenge(title: title, merchant: merchant)
            challenges.insert(challenge, at: 0)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func join(challengeID: UUID, prediction: String) async -> Bool {
        do {
            try await ActivityChallengeService().joinChallenge(challengeID: challengeID, prediction: prediction)
            await load()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func isJoined(_ challenge: ActivityChallenge) -> Bool {
        entries.contains { $0.challengeID == challenge.id && $0.userID == userID }
    }

    func entryCount(_ challenge: ActivityChallenge) -> Int {
        entries.filter { $0.challengeID == challenge.id }.count
    }
}

struct ChallengesView: View {
    let userID: UUID

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ChallengesViewModel
    @State private var showsCreateChallenge = false
    @State private var selectedChallenge: ActivityChallenge?

    init(userID: UUID) {
        self.userID = userID
        _viewModel = StateObject(wrappedValue: ChallengesViewModel(userID: userID))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.challenges.isEmpty {
                    ProgressView("Loading challenges…")
                } else if viewModel.challenges.isEmpty {
                    ContentUnavailableView(
                        "No challenges yet",
                        systemImage: "trophy",
                        description: Text("Make a friendly $2 prediction with your circle.")
                    )
                } else {
                    List(viewModel.challenges) { challenge in
                        ChallengeCard(
                            challenge: challenge,
                            entryCount: viewModel.entryCount(challenge),
                            isJoined: viewModel.isJoined(challenge)
                        ) {
                            selectedChallenge = challenge
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Challenges")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showsCreateChallenge = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Create challenge")
                }
            }
            .overlay(alignment: .bottom) {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(12)
                        .background(.thinMaterial, in: Capsule())
                        .padding()
                }
            }
            .task {
                await viewModel.load()
            }
            .refreshable {
                await viewModel.load()
            }
            .sheet(isPresented: $showsCreateChallenge) {
                CreateChallengeView { title, merchant in
                    await viewModel.create(title: title, merchant: merchant)
                }
            }
            .sheet(item: $selectedChallenge) { challenge in
                JoinChallengeView(challenge: challenge) { prediction in
                    await viewModel.join(challengeID: challenge.id, prediction: prediction)
                }
            }
        }
    }
}

private struct ChallengeCard: View {
    let challenge: ActivityChallenge
    let entryCount: Int
    let isJoined: Bool
    let join: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(challenge.title, systemImage: "trophy.fill")
                    .font(.headline)
                Spacer()
                Text("$2 demo")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.accent)
            }

            Text("Will someone spend at \(challenge.merchant) this week?")
                .foregroundStyle(.secondary)

            HStack {
                Label("\(entryCount) joined", systemImage: "person.2.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(isJoined ? "Joined" : "Make prediction", action: join)
                    .buttonStyle(.borderedProminent)
                    .disabled(isJoined)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }
}

private struct CreateChallengeView: View {
    @Environment(\.dismiss) private var dismiss
    let create: (String, String) async -> Bool

    @State private var title = "Who is buying coffee this week?"
    @State private var merchant = "Starbucks"
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                TextField("Challenge title", text: $title)
                TextField("Merchant", text: $merchant)
                Text("Everyone stakes $2 demo dollars. This does not move real money.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button("Create challenge") {
                    Task { await save() }
                }
                .disabled(isSaving)
            }
            .navigationTitle("New challenge")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func save() async {
        isSaving = true
        let succeeded = await create(title, merchant)
        isSaving = false
        if succeeded { dismiss() }
    }
}

private struct JoinChallengeView: View {
    @Environment(\.dismiss) private var dismiss
    let challenge: ActivityChallenge
    let join: (String) async -> Bool

    @State private var prediction = ""
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section(challenge.title) {
                    Text("Predict what happens at \(challenge.merchant). The stake is $2 demo dollars.")
                    TextField("Your prediction", text: $prediction, axis: .vertical)
                }
                Button("Join challenge") {
                    Task { await save() }
                }
                .disabled(isSaving || prediction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .navigationTitle("Make a prediction")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func save() async {
        isSaving = true
        let succeeded = await join(prediction)
        isSaving = false
        if succeeded { dismiss() }
    }
}

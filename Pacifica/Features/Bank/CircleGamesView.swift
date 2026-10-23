import SwiftUI

@MainActor
final class CircleGamesViewModel: ObservableObject {
    @Published private(set) var pools: [MoneyPool] = []
    @Published private(set) var poolMembers: [MoneyPoolMember] = []
    @Published private(set) var challenges: [SpendingChallenge] = []
    @Published private(set) var challengeEntries: [ChallengeEntry] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    let currentUserID: UUID

    init(currentUserID: UUID) {
        self.currentUserID = currentUserID
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let service = CircleMoneyService()
            pools = try await service.fetchPools()
            poolMembers = try await service.fetchPoolMembers()
            challenges = try await service.fetchChallenges()
            challengeEntries = try await service.fetchChallengeEntries()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createPool(title: String, purpose: String, targetAmount: Decimal) async -> Bool {
        do {
            let pool = try await CircleMoneyService().createPool(
                title: title,
                purpose: purpose,
                targetAmount: targetAmount
            )
            pools.insert(pool, at: 0)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func pledge(poolID: UUID) async -> Bool {
        do {
            try await CircleMoneyService().pledge(poolID: poolID, amount: 2)
            await load()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func createChallenge(title: String, merchant: String) async -> Bool {
        do {
            let challenge = try await CircleMoneyService().createChallenge(
                title: title,
                merchant: merchant
            )
            challenges.insert(challenge, at: 0)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func joinChallenge(challengeID: UUID, prediction: String) async -> Bool {
        do {
            try await CircleMoneyService().joinChallenge(
                challengeID: challengeID,
                prediction: prediction
            )
            await load()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func pledgedTotal(for pool: MoneyPool) -> Decimal {
        poolMembers
            .filter { $0.poolID == pool.id }
            .reduce(0) { $0 + $1.pledgedAmount }
    }

    func isPledged(to pool: MoneyPool) -> Bool {
        poolMembers.contains {
            $0.poolID == pool.id && $0.userID == currentUserID && $0.pledgedAmount > 0
        }
    }

    func entryCount(for challenge: SpendingChallenge) -> Int {
        challengeEntries.filter { $0.challengeID == challenge.id }.count
    }

    func isJoined(_ challenge: SpendingChallenge) -> Bool {
        challengeEntries.contains {
            $0.challengeID == challenge.id && $0.userID == currentUserID
        }
    }
}

struct CircleGamesView: View {
    @StateObject private var viewModel: CircleGamesViewModel
    @State private var showsCreatePool = false
    @State private var showsCreateChallenge = false
    @State private var selectedChallenge: SpendingChallenge?

    init(userID: UUID) {
        _viewModel = StateObject(wrappedValue: CircleGamesViewModel(currentUserID: userID))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.pools.isEmpty && viewModel.challenges.isEmpty {
                    ProgressView("Loading circle games…")
                } else {
                    List {
                        Section {
                            Button {
                                showsCreateChallenge = true
                            } label: {
                                Label("Start a $2 challenge", systemImage: "trophy")
                            }

                            ForEach(viewModel.challenges) { challenge in
                                ChallengeCard(
                                    challenge: challenge,
                                    entryCount: viewModel.entryCount(for: challenge),
                                    isJoined: viewModel.isJoined(challenge)
                                ) {
                                    selectedChallenge = challenge
                                }
                            }
                        } header: {
                            Text("Weekly challenges")
                        }

                        Section {
                            Button {
                                showsCreatePool = true
                            } label: {
                                Label("Start a bill pool", systemImage: "person.3.fill")
                            }

                            ForEach(viewModel.pools) { pool in
                                PoolCard(
                                    pool: pool,
                                    pledged: viewModel.pledgedTotal(for: pool),
                                    isPledged: viewModel.isPledged(to: pool)
                                ) {
                                    Task { await viewModel.pledge(poolID: pool.id) }
                                }
                            }
                        } header: {
                            Text("Bill pools")
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Circle games")
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
            .sheet(isPresented: $showsCreatePool) {
                CreatePoolView { title, purpose, target in
                    await viewModel.createPool(title: title, purpose: purpose, targetAmount: target)
                }
            }
            .sheet(isPresented: $showsCreateChallenge) {
                CreateChallengeView { title, merchant in
                    await viewModel.createChallenge(title: title, merchant: merchant)
                }
            }
            .sheet(item: $selectedChallenge) { challenge in
                JoinChallengeView(challenge: challenge) { prediction in
                    await viewModel.joinChallenge(challengeID: challenge.id, prediction: prediction)
                }
            }
        }
    }
}

private struct ChallengeCard: View {
    let challenge: SpendingChallenge
    let entryCount: Int
    let isJoined: Bool
    let join: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(challenge.title)
                    .font(.headline)
                Spacer()
                Text("$2 demo")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.accent)
            }
            Text("Predict who spends on \(challenge.merchant) this week. Winner takes the demo pot.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack {
                Label("\(entryCount) playing", systemImage: "person.2.fill")
                    .font(.caption)
                Spacer()
                Button(isJoined ? "Update prediction" : "Join") { join() }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accent)
            }
        }
        .padding(.vertical, 6)
    }
}

private struct PoolCard: View {
    let pool: MoneyPool
    let pledged: Decimal
    let isPledged: Bool
    let pledge: () -> Void

    private var progress: Double {
        let target = Double(truncating: NSDecimalNumber(decimal: pool.targetAmount))
        let total = Double(truncating: NSDecimalNumber(decimal: pledged))
        return min(total / max(target, 0.01), 1)
    }

    private var targetText: String {
        pool.targetAmount.formatted(.currency(code: "USD"))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(pool.title)
                    .font(.headline)
                Spacer()
                Text(pledged.formatted(.currency(code: "USD")))
                    .font(.headline)
            }
            Text(pool.purpose)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            ProgressView(value: progress)
                .tint(Theme.accent)
            HStack {
                Text("Goal: \(targetText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(isPledged ? "Pledged $2" : "Pledge $2") { pledge() }
                    .buttonStyle(.bordered)
                    .disabled(isPledged)
            }
        }
        .padding(.vertical, 6)
    }
}

private struct CreatePoolView: View {
    @Environment(\.dismiss) private var dismiss

    let create: (String, String, Decimal) async -> Bool

    @State private var title = "Friday dinner pool"
    @State private var purpose = "Chip in for the group dinner."
    @State private var target = "60"
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                TextField("Pool name", text: $title)
                TextField("What is it for?", text: $purpose)
                TextField("Target amount", text: $target)
                    .keyboardType(.decimalPad)
                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }
                Button(isSaving ? "Creating…" : "Create pool") {
                    Task { await save() }
                }
                .disabled(isSaving)
            }
            .navigationTitle("New bill pool")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func save() async {
        guard let amount = Decimal(string: target), amount > 0 else {
            errorMessage = "Enter a positive target amount."
            return
        }
        isSaving = true
        let succeeded = await create(title, purpose, amount)
        isSaving = false
        if succeeded { dismiss() }
    }
}

private struct CreateChallengeView: View {
    @Environment(\.dismiss) private var dismiss

    let create: (String, String) async -> Bool

    @State private var title = "Who is buying coffee this week?"
    @State private var merchant = "Starbucks"
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                TextField("Challenge", text: $title)
                TextField("Merchant or category", text: $merchant)
                Text("Everyone joins with $2 demo credits. The winner takes the demo pot.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }
                Button(isSaving ? "Creating…" : "Create challenge") {
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
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !merchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            errorMessage = "Enter a challenge and merchant."
            return
        }
        isSaving = true
        let succeeded = await create(title, merchant)
        isSaving = false
        if succeeded { dismiss() }
    }
}

private struct JoinChallengeView: View {
    @Environment(\.dismiss) private var dismiss

    let challenge: SpendingChallenge
    let join: (String) async -> Bool

    @State private var prediction = ""
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section(challenge.title) {
                    Text("Who do you think will spend on \(challenge.merchant) this week?")
                    TextField("Your prediction", text: $prediction)
                    Button(isSaving ? "Joining…" : "Join for $2 demo") {
                        Task { await save() }
                    }
                    .disabled(isSaving || prediction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Join challenge")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func save() async {
        isSaving = true
        if await join(prediction.trimmingCharacters(in: .whitespacesAndNewlines)) {
            dismiss()
        }
        isSaving = false
    }
}

#Preview {
    CircleGamesView(userID: UUID())
}

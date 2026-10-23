import SwiftUI

@MainActor
final class GoalsViewModel: ObservableObject {
    let userID: UUID

    @Published private(set) var goals: [SpendingGoal] = []
    @Published private(set) var spentByGoal: [UUID: Decimal] = [:]
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
            let fetchedGoals = try await CircleMoneyService().fetchGoals(userID: userID)
            let posts = try await ActivityService().fetchPosts()
            goals = fetchedGoals
            spentByGoal = Dictionary(uniqueKeysWithValues: fetchedGoals.map { goal in
                (goal.id, spending(for: goal, in: posts))
            })
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createGoal(title: String, merchant: String, weeklyLimit: Decimal) async -> Bool {
        do {
            let goal = try await CircleMoneyService().createGoal(
                title: title,
                merchant: merchant,
                weeklyLimit: weeklyLimit
            )
            goals.insert(goal, at: 0)
            spentByGoal[goal.id] = 0
            try? await ActivityService().syncGoalBreakUpdates()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func spending(for goal: SpendingGoal, in posts: [ActivityPost]) -> Decimal {
        let cutoff = Date.now.addingTimeInterval(-7 * 24 * 60 * 60)
        let formatter = ISO8601DateFormatter()

        return posts
            .filter { post in
                guard post.userID == userID,
                      post.postType == "purchase",
                      let merchant = post.merchant,
                      merchant.localizedCaseInsensitiveContains(goal.merchant),
                      let amount = post.sharedAmount,
                      let createdAt = formatter.date(from: post.createdAt)
                else { return false }
                return createdAt >= cutoff && amount > 0
            }
            .reduce(0) { $0 + ($1.sharedAmount ?? 0) }
    }
}

struct GoalsView: View {
    let userID: UUID

    @StateObject private var viewModel: GoalsViewModel
    @State private var showsCreateGoal = false

    init(userID: UUID) {
        self.userID = userID
        _viewModel = StateObject(wrappedValue: GoalsViewModel(userID: userID))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.goals.isEmpty {
                    ProgressView("Loading goals…")
                } else if viewModel.goals.isEmpty {
                    ContentUnavailableView(
                        "No goals yet",
                        systemImage: "target",
                        description: Text("Make a tiny spending goal and let your circle keep you honest.")
                    )
                } else {
                    List(viewModel.goals) { goal in
                        GoalCard(
                            goal: goal,
                            spent: viewModel.spentByGoal[goal.id] ?? 0
                        )
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Goals")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showsCreateGoal = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Create goal")
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
            .sheet(isPresented: $showsCreateGoal) {
                CreateGoalView { title, merchant, limit in
                    await viewModel.createGoal(title: title, merchant: merchant, weeklyLimit: limit)
                }
            }
        }
    }
}

private struct GoalCard: View {
    let goal: SpendingGoal
    let spent: Decimal

    private var spentValue: Double {
        Double(truncating: NSDecimalNumber(decimal: spent))
    }

    private var limitValue: Double {
        max(Double(truncating: NSDecimalNumber(decimal: goal.weeklyLimit)), 0.01)
    }

    private var progress: Double {
        min(spentValue / limitValue, 1)
    }

    private var limitText: String {
        goal.weeklyLimit.formatted(.currency(code: "USD"))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(goal.title, systemImage: "target")
                    .font(.headline)
                Spacer()
                Text(goal.merchant)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.accent)
            }

            HStack(alignment: .firstTextBaseline) {
                Text(spent.formatted(.currency(code: "USD")))
                    .font(.title2.weight(.bold))
                Text("of \(limitText) this week")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: progress)
                .tint(progress >= 1 ? .red : Theme.accent)

            Text(progress >= 1 ? "Goal crossed — your circle can call you out." : "You are still on track.")
                .font(.caption)
                .foregroundStyle(progress >= 1 ? .red : .secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }
}

private struct CreateGoalView: View {
    @Environment(\.dismiss) private var dismiss

    let create: (String, String, Decimal) async -> Bool

    @State private var title = "No Starbucks this week"
    @State private var merchant = "Starbucks"
    @State private var limit = "20"
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Your goal") {
                    TextField("Goal title", text: $title)
                    TextField("Merchant", text: $merchant)
                    TextField("Weekly limit", text: $limit)
                        .keyboardType(.decimalPad)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Button(isSaving ? "Saving…" : "Create goal") {
                    Task { await save() }
                }
                .disabled(isSaving)
            }
            .navigationTitle("New goal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func save() async {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !merchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let amount = Decimal(string: limit), amount > 0
        else {
            errorMessage = "Enter a title, merchant, and positive limit."
            return
        }

        isSaving = true
        let didCreate = await create(title, merchant, amount)
        isSaving = false
        if didCreate { dismiss() }
    }
}

#Preview {
    GoalsView(userID: UUID())
}

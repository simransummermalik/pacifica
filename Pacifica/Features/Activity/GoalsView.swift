import SwiftUI

@MainActor
private final class ActivityGoalsViewModel: ObservableObject {
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
            let fetchedGoals = try await SpendingGoalService().fetchGoals()
            let transactions = try await ActivityService().fetchSpendingTransactions()
            goals = fetchedGoals
            spentByGoal = Dictionary(uniqueKeysWithValues: fetchedGoals.map { goal in
                (goal.id, spending(for: goal, in: transactions))
            })
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createGoal(title: String, merchant: String, weeklyLimit: Decimal) async -> Bool {
        let start = Self.dateFormatter.string(from: Date())
        let end = Self.dateFormatter.string(from: Date().addingTimeInterval(7 * 24 * 60 * 60))

        do {
            _ = try await SpendingGoalService().createGoal(
                title: title,
                merchantOrCategory: merchant,
                goalType: "merchant",
                targetAmount: weeklyLimit,
                startDate: start,
                endDate: end
            )
            await load()
            try? await ActivityService().syncGoalBreakUpdates()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func spending(for goal: SpendingGoal, in transactions: [SpendingTransaction]) -> Decimal {
        guard goal.active,
              goal.goalType == "merchant",
              let merchant = goal.merchantOrCategory,
              let startDate = Self.dateFormatter.date(from: goal.startDate),
              let endDate = Self.dateFormatter.date(from: goal.endDate)
        else { return 0 }

        let endOfGoal = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate
        let formatter = ISO8601DateFormatter()

        return transactions
            .filter { transaction in
                guard transaction.userID == userID,
                      transaction.merchant.localizedCaseInsensitiveContains(merchant),
                      let spentAt = formatter.date(from: transaction.spentAt)
                else { return false }
                return spentAt >= startDate && spentAt <= endOfGoal && transaction.amount > 0
            }
            .reduce(0) { $0 + $1.amount }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

struct GoalsView: View {
    let userID: UUID

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ActivityGoalsViewModel
    @State private var showsCreateGoal = false

    init(userID: UUID) {
        self.userID = userID
        _viewModel = StateObject(wrappedValue: ActivityGoalsViewModel(userID: userID))
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
                        ActivityGoalCard(
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
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
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
                CreateActivityGoalView { title, merchant, limit in
                    await viewModel.createGoal(title: title, merchant: merchant, weeklyLimit: limit)
                }
            }
        }
    }
}

private struct ActivityGoalCard: View {
    let goal: SpendingGoal
    let spent: Decimal

    private var target: Double {
        max(Double(truncating: NSDecimalNumber(decimal: goal.targetAmount ?? 0)), 0.01)
    }

    private var progress: Double {
        min(Double(truncating: NSDecimalNumber(decimal: spent)) / target, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(goal.title, systemImage: "target")
                    .font(.headline)
                Spacer()
                Text(goal.merchantOrCategory ?? "General")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.accent)
            }

            Text("\(spent.formatted(.currency(code: "USD"))) of \((goal.targetAmount ?? 0).formatted(.currency(code: "USD")))")
                .font(.title3.weight(.bold))

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

private struct CreateActivityGoalView: View {
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

                Button("Save goal") {
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
        guard let amount = Decimal(string: limit), amount > 0 else {
            errorMessage = "Enter a weekly limit greater than zero."
            return
        }
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !merchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Enter a title and merchant."
            return
        }

        isSaving = true
        let succeeded = await create(title, merchant, amount)
        isSaving = false
        if succeeded { dismiss() }
    }
}

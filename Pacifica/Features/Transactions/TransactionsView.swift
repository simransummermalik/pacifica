import SwiftUI

struct TransactionsView: View {
    @StateObject private var viewModel: TransactionsViewModel
    @Environment(\.dismiss) private var dismiss

    init(userID: UUID) {
        _viewModel = StateObject(wrappedValue: TransactionsViewModel(currentUserID: userID))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.posts.isEmpty {
                    ProgressView("Loading transactions…")
                } else if viewModel.posts.isEmpty {
                    ContentUnavailableView(
                        "No transactions yet",
                        systemImage: "bubble.left.and.bubble.right",
                        description: Text("Shared circle activity will appear here.")
                    )
                } else {
                    List {
                        CircleScoreCard(stats: viewModel.circleStats)
                            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)

                        if let goalBreak = viewModel.latestGoalBreak {
                            GoalBreakBanner(
                                post: goalBreak,
                                profile: viewModel.profile(for: goalBreak),
                                counts: viewModel.counts(for: goalBreak),
                                selectedVote: viewModel.myVotes[goalBreak.id],
                                onVote: { type in
                                    Task { await viewModel.toggleVote(postID: goalBreak.id, type: type) }
                                }
                            )
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 10, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }

                        ForEach(viewModel.posts.filter { $0.postType != "goal_break" }) { post in
                            ActivityPostCard(
                                post: post,
                                profile: viewModel.profile(for: post),
                                counts: viewModel.counts(for: post),
                                selectedVote: viewModel.myVotes[post.id],
                                comments: viewModel.comments(for: post),
                                profiles: viewModel.profiles,
                                onVote: { type in
                                    Task { await viewModel.toggleVote(postID: post.id, type: type) }
                                },
                                onComment: { body in
                                    Task { await viewModel.addComment(postID: post.id, body: body) }
                                }
                            )
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .scrollIndicators(.visible)
                    .scrollDismissesKeyboard(.interactively)
                    .refreshable {
                        await viewModel.load()
                    }
                }
            }
            .background(AppBackground())
            .navigationTitle("Transactions")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .overlay(alignment: .bottom) {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(Theme.highlight)
                        .padding(12)
                        .glassEffect(.regular, in: .capsule)
                        .padding(.bottom, 8)
                }
            }
            .task {
                await viewModel.load()
            }
        }
    }
}

private struct GoalBreakBanner: View {
    let post: ActivityPost
    let profile: ActivityProfile?
    let counts: VoteCounts
    let selectedVote: String?
    let onVote: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Goal crossed", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(Theme.highlight)

            Text("\(profile?.displayName ?? "Someone") broke a spending goal")
                .font(.title3.weight(.bold))

            if let caption = post.caption {
                Text(caption)
                    .foregroundStyle(Theme.textSecondary)
            }

            HStack(spacing: 16) {
                VoteButton(
                    title: "Applaud",
                    systemImage: "hand.thumbsup.fill",
                    count: counts.upvotes,
                    isSelected: selectedVote == "upvote"
                ) {
                    onVote("upvote")
                }
                VoteButton(
                    title: "Downvote",
                    systemImage: "hand.thumbsdown.fill",
                    count: counts.downvotes,
                    isSelected: selectedVote == "downvote"
                ) {
                    onVote("downvote")
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(Theme.highlight.opacity(0.25)), in: .rect(cornerRadius: Theme.cardRadius))
    }
}

private struct CircleScoreCard: View {
    let stats: CircleStats

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Circle score", systemImage: "sparkles")
                    .font(.headline)
                Spacer()
                Text("Level \(stats.level)")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Theme.accent.opacity(0.16), in: Capsule())
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(stats.points)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                Text("points")
                    .foregroundStyle(Theme.textSecondary)
            }

            ProgressView(value: stats.progress)
                .tint(Theme.accent)

            Text("Circle challenge: leave 3 comments")
                .font(.subheadline.weight(.medium))

            HStack(spacing: 8) {
                StatPill(text: "\(stats.commentsWritten)/3 comments", systemImage: "bubble.left.fill")
                StatPill(text: "\(stats.votesReceived) reactions", systemImage: "hand.thumbsup.fill")
            }

            if stats.commentsWritten >= 3 {
                Label("Comment champion unlocked", systemImage: "medal.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.accent)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: Theme.cardRadius))
    }
}

private struct StatPill: View {
    let text: String
    let systemImage: String

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption)
            .foregroundStyle(Theme.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Theme.subtleFill, in: Capsule())
    }
}

private struct ActivityPostCard: View {
    let post: ActivityPost
    let profile: ActivityProfile?
    let counts: VoteCounts
    let selectedVote: String?
    let comments: [ActivityComment]
    let profiles: [UUID: ActivityProfile]
    let onVote: (String) -> Void
    let onComment: (String) -> Void

    @State private var commentText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(profile?.displayName ?? "Pacifica user")
                        .font(.headline)
                    Text("@\(profile?.username ?? "unknown")")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Text(post.postType.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }

            if let merchant = post.merchant {
                Text(merchant)
                    .font(.title3.weight(.semibold))
            }

            if let caption = post.caption {
                Text(caption)
                    .foregroundStyle(Theme.textSecondary)
            }

            if let amount = post.sharedAmount {
                Text(amount.formatted(.currency(code: "USD")))
                    .font(.title3.weight(.semibold))
            }

            HStack(spacing: 16) {
                VoteButton(
                    title: "Applaud",
                    systemImage: "hand.thumbsup.fill",
                    count: counts.upvotes,
                    isSelected: selectedVote == "upvote"
                ) {
                    onVote("upvote")
                }
                VoteButton(
                    title: "Downvote",
                    systemImage: "hand.thumbsdown.fill",
                    count: counts.downvotes,
                    isSelected: selectedVote == "downvote"
                ) {
                    onVote("downvote")
                }
            }

            Divider()

            ForEach(comments) { comment in
                HStack(alignment: .top, spacing: 6) {
                    Text("@\(profiles[comment.userID]?.username ?? "user")")
                        .fontWeight(.semibold)
                    Text(comment.body)
                }
                .font(.caption)
            }

            HStack(spacing: 8) {
                TextField("Add a comment", text: $commentText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Theme.subtleFill, in: Capsule())
                    .onSubmit { submitComment() }

                Button("Post") {
                    submitComment()
                }
                .disabled(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: Theme.cardRadius))
    }

    private func submitComment() {
        let body = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return }
        onComment(body)
        commentText = ""
    }
}

private struct VoteButton: View {
    let title: String
    let systemImage: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("\(title) \(count)", systemImage: systemImage)
                .foregroundStyle(isSelected ? Theme.accent : Theme.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    isSelected ? Theme.accent.opacity(0.14) : Theme.subtleFill,
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), \(count)")
    }
}

#Preview {
    TransactionsView(userID: UUID())
}

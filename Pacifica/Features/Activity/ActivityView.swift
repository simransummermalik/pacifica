import SwiftUI

struct ActivityView: View {
    @StateObject private var viewModel: ActivityViewModel

    init(userID: UUID) {
        _viewModel = StateObject(wrappedValue: ActivityViewModel(currentUserID: userID))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.posts.isEmpty {
                    ProgressView("Loading activity…")
                } else if viewModel.posts.isEmpty {
                    ContentUnavailableView(
                        "No activity yet",
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
                    .scrollIndicators(.visible)
                    .scrollDismissesKeyboard(.interactively)
                    .refreshable {
                        await viewModel.load()
                    }
                }
            }
            .navigationTitle("Activity")
            .overlay(alignment: .bottom) {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(12)
                        .background(.thinMaterial, in: Capsule())
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
                .foregroundStyle(.red)

            Text("\(profile?.displayName ?? "Someone") broke a spending goal")
                .font(.title3.weight(.bold))

            if let caption = post.caption {
                Text(caption)
                    .foregroundStyle(.secondary)
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
        .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
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
                    .foregroundStyle(.secondary)
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
        .background(Theme.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
    }
}

private struct StatPill: View {
    let text: String
    let systemImage: String

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.thinMaterial, in: Capsule())
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
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(post.postType.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let merchant = post.merchant {
                Text(merchant)
                    .font(.title3.weight(.semibold))
            }

            if let caption = post.caption {
                Text(caption)
                    .foregroundStyle(.secondary)
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
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { submitComment() }

                Button("Post") {
                    submitComment()
                }
                .disabled(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
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
                .foregroundStyle(isSelected ? Theme.accent : Color.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    isSelected ? Theme.accent.opacity(0.14) : Color.secondary.opacity(0.08),
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), \(count)")
    }
}

#Preview {
    ActivityView(userID: UUID())
}

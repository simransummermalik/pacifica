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
                        .tint(Theme.accent)
                } else if viewModel.posts.isEmpty {
                    ContentUnavailableView(
                        "No transactions yet",
                        systemImage: "bubble.left.and.bubble.right",
                        description: Text("Shared circle activity will appear here.")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            CircleScoreCard(stats: viewModel.circleStats)

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
                            }

                            SectionLabel(title: "Recent")

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
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                    }
                    .scrollIndicators(.hidden)
                    .scrollDismissesKeyboard(.interactively)
                    .refreshable {
                        await viewModel.load()
                    }
                }
            }
            .background {
                ZStack(alignment: .top) {
                    AppBackground()
                    LinearGradient(
                        colors: [Theme.teal.opacity(0.28), Theme.teal.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 320)
                    .ignoresSafeArea()
                }
            }
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

private struct SectionLabel: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.caption.weight(.bold))
            .tracking(1.2)
            .foregroundStyle(Theme.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 6)
            .padding(.top, 6)
    }
}

private struct Avatar: View {
    let name: String
    var size: CGFloat = 44

    var body: some View {
        Text(String(name.prefix(2)).uppercased())
            .font(.system(size: size * 0.36, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                LinearGradient(colors: [Theme.teal, Color(hex: 0x2DD4BF)], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: Circle()
            )
    }
}

private struct GoalBreakBanner: View {
    let post: ActivityPost
    let profile: ActivityProfile?
    let counts: VoteCounts
    let selectedVote: String?
    let onVote: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                Text("GOAL CROSSED")
                    .tracking(1.2)
            }
            .font(.caption.weight(.heavy))
            .foregroundStyle(Theme.highlight)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Theme.highlight.opacity(0.15), in: Capsule())

            Text("\(profile?.displayName ?? "Someone") broke a spending goal")
                .font(.title3.weight(.bold))

            if let caption = post.caption {
                Text(caption)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            }

            HStack(spacing: 10) {
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
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Theme.highlight.opacity(0.22), Theme.highlight.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: .rect(cornerRadius: Theme.cardRadius)
        )
        .glassEffect(.regular.tint(Theme.highlight.opacity(0.15)), in: .rect(cornerRadius: Theme.cardRadius))
    }
}

private struct CircleScoreCard: View {
    let stats: CircleStats

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Circle score", systemImage: "sparkles")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text("Level \(stats.level)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.teal, in: Capsule())
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(stats.points)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                Text("points")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(Theme.textSecondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.subtleFill)
                        Capsule()
                            .fill(LinearGradient(colors: [Theme.teal, Color(hex: 0x2DD4BF)], startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(10, geo.size.width * stats.progress))
                    }
                }
                .frame(height: 10)
                Text("\(Int(stats.progress * 50))/50 to level \(stats.level + 1)")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }

            Divider().opacity(0.5)

            Text("Circle challenge: leave 3 comments")
                .font(.subheadline.weight(.semibold))

            HStack(spacing: 8) {
                StatPill(text: "\(stats.commentsWritten)/3 comments", systemImage: "bubble.left.fill")
                StatPill(text: "\(stats.votesReceived) reactions", systemImage: "hand.thumbsup.fill")
            }

            if stats.commentsWritten >= 3 {
                Label("Comment champion unlocked", systemImage: "medal.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.yellow)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Theme.teal.opacity(0.18), Theme.teal.opacity(0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: .rect(cornerRadius: Theme.cardRadius)
        )
        .glassEffect(.regular, in: .rect(cornerRadius: Theme.cardRadius))
    }
}

private struct StatPill: View {
    let text: String
    let systemImage: String

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.medium))
            .foregroundStyle(Theme.accent)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Theme.accent.opacity(0.12), in: Capsule())
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

    private var canPost: Bool {
        !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Avatar(name: profile?.displayName ?? "P")
                VStack(alignment: .leading, spacing: 2) {
                    Text(profile?.displayName ?? "Pacifica user")
                        .font(.headline)
                    Text("@\(profile?.username ?? "unknown")")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Text(post.postType.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Theme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Theme.accent.opacity(0.12), in: Capsule())
            }

            if post.merchant != nil || post.sharedAmount != nil {
                HStack(alignment: .firstTextBaseline) {
                    if let merchant = post.merchant {
                        Text(merchant)
                            .font(.title3.weight(.semibold))
                    }
                    Spacer()
                    if let amount = post.sharedAmount {
                        Text(amount.formatted(.currency(code: "USD")))
                            .font(.title2.weight(.bold))
                            .fontDesign(.rounded)
                    }
                }
            }

            if let caption = post.caption {
                Text(caption)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            }

            HStack(spacing: 10) {
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

            if !comments.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(comments) { comment in
                        HStack(alignment: .top, spacing: 6) {
                            Text("@\(profiles[comment.userID]?.username ?? "user")")
                                .fontWeight(.semibold)
                                .foregroundStyle(Theme.accent)
                            Text(comment.body)
                        }
                        .font(.footnote)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.subtleFill, in: .rect(cornerRadius: 16))
            }

            HStack(spacing: 8) {
                TextField("Add a comment", text: $commentText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Theme.subtleFill, in: Capsule())
                    .onSubmit { submitComment() }

                Button {
                    submitComment()
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(canPost ? Theme.teal : Theme.text.opacity(0.2), in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(!canPost)
                .accessibilityLabel("Post comment")
            }
        }
        .padding(18)
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
                .font(.footnote.weight(.semibold))
                .foregroundStyle(isSelected ? .white : Theme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Theme.teal : Theme.subtleFill, in: Capsule())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
        .accessibilityLabel("\(title), \(count)")
    }
}

#Preview {
    TransactionsView(userID: UUID())
}

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
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.posts) { post in
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
                        .padding(16)
                    }
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
                    systemImage: "arrow.up",
                    count: counts.upvotes,
                    isSelected: selectedVote == "upvote"
                ) {
                    onVote("upvote")
                }
                VoteButton(
                    systemImage: "arrow.down",
                    count: counts.downvotes,
                    isSelected: selectedVote == "downvote"
                ) {
                    onVote("downvote")
                }
            }

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
    let systemImage: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("\(count)", systemImage: systemImage)
                .foregroundStyle(isSelected ? Theme.accent : Color.secondary)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ActivityView(userID: UUID())
}

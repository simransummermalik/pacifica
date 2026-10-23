import Combine
import Foundation

@MainActor
final class ActivityViewModel: ObservableObject {
    let currentUserID: UUID

    @Published private(set) var posts: [ActivityPost] = []
    @Published private(set) var profiles: [UUID: ActivityProfile] = [:]
    @Published private(set) var voteCounts: [UUID: VoteCounts] = [:]
    @Published private(set) var myVotes: [UUID: String] = [:]
    @Published private(set) var comments: [UUID: [ActivityComment]] = [:]
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    init(currentUserID: UUID) {
        self.currentUserID = currentUserID
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let service = ActivityService()
            let fetchedPosts = try await service.fetchPosts()
            let fetchedProfiles = try await service.fetchProfiles()
            let fetchedReactions = try await service.fetchReactions()
            let fetchedComments = try await service.fetchComments()

            self.posts = fetchedPosts
            self.profiles = Dictionary(
                uniqueKeysWithValues: fetchedProfiles.map { ($0.id, $0) }
            )
            rebuildVotes(fetchedReactions)
            rebuildComments(fetchedComments)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleVote(postID: UUID, type: String) async {
        do {
            let service = ActivityService()
            if myVotes[postID] == type {
                try await service.removeReaction(postID: postID)
            } else {
                try await service.setReaction(postID: postID, reactionType: type)
            }

            let reactions = try await service.fetchReactions()
            rebuildVotes(reactions)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addComment(postID: UUID, body: String) async {
        do {
            let service = ActivityService()
            _ = try await service.addComment(postID: postID, body: body)
            rebuildComments(try await service.fetchComments())
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func profile(for post: ActivityPost) -> ActivityProfile? {
        profiles[post.userID]
    }

    func counts(for post: ActivityPost) -> VoteCounts {
        voteCounts[post.id] ?? VoteCounts()
    }

    func comments(for post: ActivityPost) -> [ActivityComment] {
        comments[post.id] ?? []
    }

    private func rebuildVotes(_ reactions: [ActivityReaction]) {
        var counts: [UUID: VoteCounts] = [:]
        var mine: [UUID: String] = [:]

        for reaction in reactions {
            var postCounts = counts[reaction.postID] ?? VoteCounts()
            if reaction.reactionType == "upvote" {
                postCounts.upvotes += 1
            } else if reaction.reactionType == "downvote" {
                postCounts.downvotes += 1
            }
            counts[reaction.postID] = postCounts

            if reaction.userID == currentUserID {
                mine[reaction.postID] = reaction.reactionType
            }
        }

        voteCounts = counts
        myVotes = mine
    }

    private func rebuildComments(_ comments: [ActivityComment]) {
        self.comments = Dictionary(grouping: comments, by: \.postID)
    }
}

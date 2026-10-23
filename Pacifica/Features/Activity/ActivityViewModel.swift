import Combine
import Foundation

@MainActor
final class ActivityViewModel: ObservableObject {
    let currentUserID: UUID

    @Published private(set) var posts: [ActivityPost] = []
    @Published private(set) var latestGoalBreak: ActivityPost?
    @Published private(set) var profiles: [UUID: ActivityProfile] = [:]
    @Published private(set) var voteCounts: [UUID: VoteCounts] = [:]
    @Published private(set) var myVotes: [UUID: String] = [:]
    @Published private(set) var comments: [UUID: [ActivityComment]] = [:]
    @Published private(set) var circleStats = CircleStats.empty
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private var cachedReactions: [ActivityReaction] = []

    init(currentUserID: UUID) {
        self.currentUserID = currentUserID
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let service = ActivityService()
            // The sync is best-effort so Activity still loads if the migration
            // has not been run in Supabase yet.
            try? await service.syncGoalBreakUpdates()
            let fetchedPosts = try await service.fetchPosts()
            let fetchedProfiles = try await service.fetchProfiles()
            let fetchedReactions = try await service.fetchReactions()
            let fetchedComments = try await service.fetchComments()

            self.posts = fetchedPosts
            latestGoalBreak = fetchedPosts.first { $0.postType == "goal_break" }
            self.profiles = Dictionary(
                uniqueKeysWithValues: fetchedProfiles.map { ($0.id, $0) }
            )
            cachedReactions = fetchedReactions
            rebuildVotes(fetchedReactions)
            rebuildComments(fetchedComments)
            rebuildStats(reactions: fetchedReactions, comments: fetchedComments)
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
            cachedReactions = reactions
            rebuildVotes(reactions)
            rebuildStats(reactions: reactions, comments: comments.values.flatMap { $0 })
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addComment(postID: UUID, body: String) async {
        do {
            let service = ActivityService()
            _ = try await service.addComment(postID: postID, body: body)
            let fetchedComments = try await service.fetchComments()
            rebuildComments(fetchedComments)
            rebuildStats(reactions: cachedReactions, comments: fetchedComments)
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

    private func rebuildStats(reactions: [ActivityReaction], comments: [ActivityComment]) {
        let myPostIDs = Set(posts.filter { $0.userID == currentUserID }.map(\.id))
        let commentsWritten = comments.filter { $0.userID == currentUserID }.count
        let votesGiven = reactions.filter { $0.userID == currentUserID }.count
        let votesReceived = reactions.filter { myPostIDs.contains($0.postID) }.count
        let points = (myPostIDs.count * 10) + (commentsWritten * 5) + (votesGiven * 2) + (votesReceived * 3)
        let level = (points / 50) + 1

        circleStats = CircleStats(
            points: points,
            level: level,
            progress: Double(points % 50) / 50.0,
            commentsWritten: commentsWritten,
            votesGiven: votesGiven,
            votesReceived: votesReceived
        )
    }
}

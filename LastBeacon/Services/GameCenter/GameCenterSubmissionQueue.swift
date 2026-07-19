import Foundation

@MainActor
struct GameCenterSubmissionQueue {
    private(set) var pending: [PendingScore]
    private var authenticationRequested = false

    init(pending: [PendingScore] = []) {
        self.pending = pending
    }

    mutating func enqueue(leaderboardID: String, value: Int) {
        guard pending.contains(where: {
            $0.leaderboardID == leaderboardID && $0.value == value
        }) == false else { return }
        pending.append(PendingScore(id: UUID(), leaderboardID: leaderboardID, value: value))
    }

    mutating func flush(using service: any GameCenterServing) async {
        guard pending.isEmpty == false else { return }
        if service.authenticated == false, authenticationRequested == false {
            authenticationRequested = true
            _ = await service.authenticate()
        }
        guard service.authenticated else { return }

        var retained: [PendingScore] = []
        for score in pending {
            if await service.submit(score: score.value, leaderboardID: score.leaderboardID) == false {
                retained.append(score)
            }
        }
        pending = retained
    }
}

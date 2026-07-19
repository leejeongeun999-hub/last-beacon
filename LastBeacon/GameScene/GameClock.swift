import Foundation

struct GameClock: Equatable, Sendable {
    var isPaused = false
    let maximumCatchUp: TimeInterval

    init(maximumCatchUp: TimeInterval = 0.25) {
        self.maximumCatchUp = max(0, maximumCatchUp)
    }

    mutating func consume(elapsed: TimeInterval) -> TimeInterval {
        guard isPaused == false, elapsed.isFinite, elapsed > 0 else { return 0 }
        return min(elapsed, maximumCatchUp)
    }
}


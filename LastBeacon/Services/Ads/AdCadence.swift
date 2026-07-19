import Foundation

struct AdCadence: Codable, Equatable, Sendable {
    private(set) var completedRuns: Int
    private(set) var lastInterstitialRun: Int

    init(completedRuns: Int = 0, lastInterstitialRun: Int = 0) {
        self.completedRuns = max(0, completedRuns)
        self.lastInterstitialRun = max(0, lastInterstitialRun)
    }

    mutating func recordCompletedRun(wasTutorial: Bool) -> Bool {
        completedRuns += 1
        guard wasTutorial == false,
              completedRuns > 1,
              completedRuns - lastInterstitialRun >= 2 else { return false }
        lastInterstitialRun = completedRuns
        return true
    }
}

struct RewardGrantGate: Equatable, Sendable {
    let runID: UUID
    private(set) var consumed = false

    mutating func consumeReward() -> Bool {
        guard consumed == false else { return false }
        consumed = true
        return true
    }
}


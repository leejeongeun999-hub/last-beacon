import XCTest
@testable import LastBeacon

final class ProgressionTests: XCTestCase {
    func testVictoryAwardsThreeIndependentStars() {
        var progression = Progression()
        let result = RunResult(
            missionID: "sector-1-mission-1",
            victory: true,
            beaconHealth: 80,
            beaconMaximumHealth: 100,
            optionalConditionMet: true,
            salvage: 500
        )

        progression.apply(result: result)

        XCTAssertEqual(progression.stars(for: result.missionID), 3)
        XCTAssertEqual(progression.totalStars, 3)
    }

    func testReplayNeverReducesBestStars() {
        var progression = Progression()
        progression.apply(result: RunResult(
            missionID: "sector-1-mission-1", victory: true,
            beaconHealth: 100, beaconMaximumHealth: 100,
            optionalConditionMet: true, salvage: 500
        ))
        progression.apply(result: RunResult(
            missionID: "sector-1-mission-1", victory: true,
            beaconHealth: 10, beaconMaximumHealth: 100,
            optionalConditionMet: false, salvage: 100
        ))

        XCTAssertEqual(progression.stars(for: "sector-1-mission-1"), 3)
        XCTAssertEqual(progression.bestSalvage(for: "sector-1-mission-1"), 500)
    }

    func testSectorAndEndlessUnlockThresholds() {
        var progression = Progression()
        for mission in 1...2 {
            progression.apply(result: perfectResult(mission: mission))
        }
        XCTAssertTrue(progression.isSectorUnlocked(2))
        XCTAssertFalse(progression.isSectorUnlocked(3))
        XCTAssertFalse(progression.endlessUnlocked)

        for mission in 3...6 {
            progression.apply(result: perfectResult(mission: mission))
        }
        XCTAssertTrue(progression.isSectorUnlocked(3))
        XCTAssertTrue(progression.endlessUnlocked)
    }

    private func perfectResult(mission: Int) -> RunResult {
        RunResult(
            missionID: "sector-\(((mission - 1) / 4) + 1)-mission-\(((mission - 1) % 4) + 1)",
            victory: true,
            beaconHealth: 100,
            beaconMaximumHealth: 100,
            optionalConditionMet: true,
            salvage: mission * 100
        )
    }
}

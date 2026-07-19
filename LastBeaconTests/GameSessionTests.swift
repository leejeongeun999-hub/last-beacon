import XCTest
@testable import LastBeacon

@MainActor
final class GameSessionTests: XCTestCase {
    func testSessionForwardsPlayerCommandsAndCreatesResult() {
        let mission = MissionDefinition(
            id: "session-test",
            sector: 1,
            startingEnergy: 100,
            beaconHealth: 20,
            waves: [WaveDefinition(spawns: [
                EnemySpawn(time: 0, kind: .sectorBoss, lane: 0, progress: 0.99)
            ])]
        )
        let session = GameSessionModel(mission: mission, seed: 5)

        session.build(.pulse, at: 0)
        XCTAssertEqual(session.snapshot.energy, 80)
        session.startWave()
        session.tick(elapsed: 0.25)
        session.tick(elapsed: 0.25)

        XCTAssertEqual(session.snapshot.phase, .defeat)
        XCTAssertEqual(session.result.salvage, 0)
        XCTAssertFalse(session.result.victory)
    }

    func testSelectingUpgradeClearsOfferAndUpdatesSnapshot() {
        let mission = ContentCatalog.launch.missions[0]
        let session = GameSessionModel(mission: mission, seed: 10)
        session.offerUpgrades()
        let upgrade = try! XCTUnwrap(session.offeredUpgrades.first)

        session.choose(upgrade)

        XCTAssertTrue(session.offeredUpgrades.isEmpty)
        XCTAssertEqual(session.snapshot.appliedUpgradeIDs, [upgrade.id])
    }

    func testStoreScreenshotFixturesAreDeterministicAndPopulated() {
        let mission = ContentCatalog.launch.missions[0]
        let active = GameSessionModel(
            mission: mission,
            seed: 4_242,
            screenshotFixture: .active
        )
        let upgrade = GameSessionModel(
            mission: mission,
            seed: 4_242,
            screenshotFixture: .upgrade
        )

        XCTAssertEqual(active.snapshot.towers.count, 3)
        XCTAssertFalse(active.snapshot.enemies.isEmpty)
        XCTAssertEqual(upgrade.offeredUpgrades.count, 3)
    }

    func testPausedSessionDoesNotAdvanceActiveWave() {
        let mission = MissionDefinition(
            id: "pause-test",
            sector: 1,
            startingEnergy: 100,
            beaconHealth: 100,
            waves: [WaveDefinition(spawns: [
                EnemySpawn(time: 0, kind: .drone, lane: 0)
            ])]
        )
        let session = GameSessionModel(mission: mission, seed: 5)
        session.startWave()
        session.tick(elapsed: 0.1)
        let beforePause = session.snapshot

        session.setPaused(true)
        session.tick(elapsed: 1)

        XCTAssertEqual(session.snapshot, beforePause)
    }

    func testOptionalConditionFailsAfterChoosingThreeUpgrades() {
        let session = GameSessionModel(mission: ContentCatalog.launch.missions[0], seed: 10)
        for _ in 0..<3 {
            session.offerUpgrades()
            let upgrade = try! XCTUnwrap(session.offeredUpgrades.first)
            session.choose(upgrade)
        }

        XCTAssertFalse(session.result.optionalConditionMet)
    }

    func testTowerCommandsReportWhetherTheyChangedTheRun() {
        let session = GameSessionModel(mission: ContentCatalog.launch.missions[0], seed: 10)

        XCTAssertTrue(session.build(.pulse, at: 0))
        XCTAssertFalse(session.build(.pulse, at: 0))
        XCTAssertTrue(session.upgrade(at: 0))
        XCTAssertTrue(session.sell(at: 0))
        XCTAssertFalse(session.sell(at: 0))
    }
}

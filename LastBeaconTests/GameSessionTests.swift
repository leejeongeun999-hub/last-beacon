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
}

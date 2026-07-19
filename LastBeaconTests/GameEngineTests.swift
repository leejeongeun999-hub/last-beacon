import XCTest
@testable import LastBeacon

final class GameEngineTests: XCTestCase {
    func testLaserIgnoresArmor() {
        var engine = makeEngine(enemy: .armoredFrigate, startingEnergy: 100)
        engine.send(.build(kind: .laser, socket: 0))
        engine.send(.startWave)
        engine.advance(by: 1.3)

        XCTAssertLessThan(engine.snapshot.enemies[0].health, 100)
        XCTAssertEqual(engine.snapshot.enemies[0].health, 70, accuracy: 0.001)
    }

    func testPulseDamageIsReducedByArmor() {
        var engine = makeEngine(enemy: .armoredFrigate, startingEnergy: 100)
        engine.send(.build(kind: .pulse, socket: 0))
        engine.send(.startWave)
        engine.advance(by: 0.4)

        XCTAssertEqual(engine.snapshot.enemies[0].health, 98, accuracy: 0.001)
    }

    func testGravitySlowsEnemiesInItsLane() {
        var normal = makeEngine(enemy: .drone, startingEnergy: 100)
        var slowed = makeEngine(enemy: .drone, startingEnergy: 100)
        slowed.send(.build(kind: .gravity, socket: 0))
        normal.send(.startWave)
        slowed.send(.startWave)

        normal.advance(by: 1)
        slowed.advance(by: 1)

        XCTAssertLessThan(slowed.snapshot.enemies[0].progress, normal.snapshot.enemies[0].progress)
    }

    func testSellingReturnsSeventyPercent() {
        var engine = makeEngine(startingEnergy: 100)
        engine.send(.build(kind: .pulse, socket: 0))
        engine.send(.sell(socket: 0))

        XCTAssertEqual(engine.snapshot.energy, 94)
        XCTAssertTrue(engine.snapshot.towers.isEmpty)
    }

    func testShieldRegeneratesAfterThreeSecondsWithoutDamage() {
        var engine = makeEngine(enemy: .shieldVessel, startingEnergy: 100)
        engine.send(.build(kind: .laser, socket: 0))
        engine.send(.startWave)
        engine.advance(by: 1.3)
        engine.send(.sell(socket: 0))
        let damagedShield = engine.snapshot.enemies[0].shield
        XCTAssertLessThan(damagedShield, 40)

        engine.advance(by: 2.9)
        XCTAssertEqual(engine.snapshot.enemies[0].shield, damagedShield, accuracy: 0.001)
        engine.advance(by: 0.2)
        XCTAssertGreaterThan(engine.snapshot.enemies[0].shield, damagedShield)
    }

    func testSplitterCreatesTwoDronesWhenDestroyed() {
        var engine = makeEngine(enemy: .splitter, startingEnergy: 100)
        engine.send(.build(kind: .laser, socket: 0))
        engine.send(.startWave)
        engine.advance(by: 1.3)

        XCTAssertEqual(engine.snapshot.enemies.count, 2)
        XCTAssertTrue(engine.snapshot.enemies.allSatisfy { $0.kind == .drone })
    }

    func testBeaconDamageCanEndRun() {
        let spawn = EnemySpawn(time: 0, kind: .sectorBoss, lane: 0, progress: 0.99)
        var engine = GameEngine(mission: mission(spawns: [spawn], beaconHealth: 20), seed: 7)
        engine.send(.startWave)
        engine.advance(by: 1)

        XCTAssertEqual(engine.snapshot.phase, .defeat)
        XCTAssertEqual(engine.snapshot.beaconHealth, 0)
    }

    func testSameSeedAndCommandsProduceSameSnapshot() {
        let definition = mission(spawns: [
            EnemySpawn(time: 0, kind: .splitter, lane: 0),
            EnemySpawn(time: 0.2, kind: .armoredFrigate, lane: 1)
        ])
        var first = GameEngine(mission: definition, seed: 42)
        var second = GameEngine(mission: definition, seed: 42)

        for command in [GameCommand.build(kind: .pulse, socket: 0), .startWave] {
            first.send(command)
            second.send(command)
        }
        first.advance(by: 2)
        second.advance(by: 2)

        XCTAssertEqual(first.snapshot, second.snapshot)
    }

    func testPulseUpgradeImprovesDamageAndAppearsInSnapshot() {
        var engine = makeEngine(enemy: .armoredFrigate, startingEnergy: 100)
        engine.send(.chooseUpgrade("pulse-capacitors"))
        engine.send(.build(kind: .pulse, socket: 0))
        engine.send(.startWave)
        engine.advance(by: 0.4)

        XCTAssertLessThan(engine.snapshot.enemies[0].health, 98)
        XCTAssertEqual(engine.snapshot.appliedUpgradeIDs, ["pulse-capacitors"])
    }

    func testRewardedReviveRestoresFortyPercentOnlyOnce() {
        let spawn = EnemySpawn(time: 0, kind: .sectorBoss, lane: 0, progress: 0.99)
        var engine = GameEngine(mission: mission(spawns: [spawn], beaconHealth: 20), seed: 7)
        engine.send(.startWave)
        engine.advance(by: 1)
        XCTAssertEqual(engine.snapshot.phase, .defeat)

        engine.send(.reviveBeacon)
        XCTAssertEqual(engine.snapshot.phase, .active)
        XCTAssertEqual(engine.snapshot.beaconHealth, 8)
        XCTAssertTrue(engine.snapshot.didUseRevive)

        engine.send(.reviveBeacon)
        XCTAssertEqual(engine.snapshot.beaconHealth, 8)
    }

    func testEndlessMissionCyclesWithoutVictory() {
        let endless = MissionDefinition(
            id: "endless",
            sector: 1,
            startingEnergy: 100,
            beaconHealth: 100,
            waves: [WaveDefinition(spawns: [])]
        )
        var engine = GameEngine(mission: endless, seed: 1)

        for expectedWave in 1...3 {
            engine.send(.startWave)
            engine.advance(by: 0.1)
            XCTAssertEqual(engine.snapshot.phase, .planning)
            XCTAssertEqual(engine.snapshot.waveIndex, expectedWave)
        }
    }

    func testSectorModifiersCreateDistinctBossBehavior() {
        func spawnedBoss(sector: Int) -> Enemy {
            let definition = MissionDefinition(
                id: "sector-\(sector)-mission-4",
                sector: sector,
                startingEnergy: 100,
                beaconHealth: 100,
                waves: [WaveDefinition(spawns: [EnemySpawn(time: 0, kind: .sectorBoss, lane: 0)])]
            )
            var engine = GameEngine(mission: definition, seed: 1)
            engine.send(.startWave)
            engine.advance(by: 0.05)
            return engine.snapshot.enemies[0]
        }

        let solarBoss = spawnedBoss(sector: 1)
        let ionBoss = spawnedBoss(sector: 2)
        let darkBoss = spawnedBoss(sector: 3)

        XCTAssertGreaterThan(solarBoss.progress, ionBoss.progress)
        XCTAssertGreaterThan(ionBoss.maximumShield, solarBoss.maximumShield)
        XCTAssertGreaterThan(darkBoss.maximumHealth, ionBoss.maximumHealth)
    }
}

private extension GameEngineTests {
    func makeEngine(enemy: EnemyKind? = nil, startingEnergy: Int = 100) -> GameEngine {
        let spawns = enemy.map { [EnemySpawn(time: 0, kind: $0, lane: 0)] } ?? []
        return GameEngine(mission: mission(spawns: spawns, startingEnergy: startingEnergy), seed: 1)
    }

    func mission(
        spawns: [EnemySpawn],
        startingEnergy: Int = 100,
        beaconHealth: Int = 100
    ) -> MissionDefinition {
        MissionDefinition(
            id: "test",
            sector: 1,
            startingEnergy: startingEnergy,
            beaconHealth: beaconHealth,
            waves: [WaveDefinition(spawns: spawns)]
        )
    }
}

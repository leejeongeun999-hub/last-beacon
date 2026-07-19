import Foundation

struct GameState: Equatable, Sendable {
    let mission: MissionDefinition
    let seed: UInt64
    var phase: GamePhase
    var waveIndex: Int
    var waveElapsed: TimeInterval
    var spawnCursor: Int
    var energy: Int
    var beaconHealth: Int
    var towers: [Tower]
    var enemies: [Enemy]
    var nextTowerID: Int
    var nextEnemyID: Int
    var accumulator: TimeInterval
    var random: SeededGenerator
    var appliedUpgradeIDs: [String]
    var damageMultipliers: [TowerKind: Double]
    var gravitySlowFactor: Double
    var didUseRevive: Bool

    init(mission: MissionDefinition, seed: UInt64) {
        self.mission = mission
        self.seed = seed
        phase = .planning
        waveIndex = 0
        waveElapsed = 0
        spawnCursor = 0
        energy = mission.startingEnergy
        beaconHealth = mission.beaconHealth
        towers = []
        enemies = []
        nextTowerID = 1
        nextEnemyID = 1
        accumulator = 0
        random = SeededGenerator(seed: seed)
        appliedUpgradeIDs = []
        damageMultipliers = [.pulse: 1, .laser: 1, .gravity: 1]
        gravitySlowFactor = 0.6
        didUseRevive = false
    }

    var snapshot: GameSnapshot {
        GameSnapshot(
            missionID: mission.id,
            seed: seed,
            phase: phase,
            waveIndex: waveIndex,
            energy: energy,
            beaconHealth: beaconHealth,
            towers: towers.sorted { $0.socket < $1.socket },
            enemies: enemies.sorted { $0.id < $1.id },
            appliedUpgradeIDs: appliedUpgradeIDs,
            didUseRevive: didUseRevive
        )
    }
}

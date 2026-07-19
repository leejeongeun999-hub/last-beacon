import Foundation

enum TowerKind: String, Codable, CaseIterable, Sendable {
    case pulse
    case laser
    case gravity

    var buildCost: Int {
        switch self {
        case .pulse: 20
        case .laser: 35
        case .gravity: 30
        }
    }

    var cooldown: TimeInterval {
        switch self {
        case .pulse: 0.35
        case .laser: 1.2
        case .gravity: .infinity
        }
    }

    var damage: Double {
        switch self {
        case .pulse: 10
        case .laser: 30
        case .gravity: 0
        }
    }
}

enum EnemyKind: String, Codable, CaseIterable, Sendable {
    case drone
    case swarm
    case armoredFrigate
    case shieldVessel
    case splitter
    case sectorBoss

    var baseHealth: Double {
        switch self {
        case .drone: 30
        case .swarm: 15
        case .armoredFrigate: 100
        case .shieldVessel: 70
        case .splitter: 30
        case .sectorBoss: 500
        }
    }

    var armor: Double { self == .armoredFrigate ? 8 : 0 }
    var maximumShield: Double { self == .shieldVessel ? 40 : 0 }

    var speed: Double {
        switch self {
        case .swarm: 0.11
        case .sectorBoss: 0.025
        default: 0.08
        }
    }

    var beaconDamage: Int { self == .sectorBoss ? 20 : 10 }
    var energyReward: Int { self == .sectorBoss ? 50 : 5 }
}

struct EnemySpawn: Codable, Equatable, Sendable {
    let time: TimeInterval
    let kind: EnemyKind
    let lane: Int
    let progress: Double

    init(time: TimeInterval, kind: EnemyKind, lane: Int, progress: Double = 0) {
        self.time = time
        self.kind = kind
        self.lane = lane
        self.progress = progress
    }
}

struct WaveDefinition: Codable, Equatable, Sendable {
    let spawns: [EnemySpawn]
}

struct MissionDefinition: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let sector: Int
    let startingEnergy: Int
    let beaconHealth: Int
    let waves: [WaveDefinition]

    var isEndless: Bool { id == "endless" }
}

enum GamePhase: String, Codable, Equatable, Sendable {
    case planning
    case active
    case victory
    case defeat
}

enum GameCommand: Equatable, Sendable {
    case build(kind: TowerKind, socket: Int)
    case upgrade(socket: Int)
    case sell(socket: Int)
    case startWave
    case chooseUpgrade(String)
    case reviveBeacon
}

struct Tower: Codable, Equatable, Identifiable, Sendable {
    let id: Int
    let kind: TowerKind
    let socket: Int
    var level: Int
    var cooldownRemaining: TimeInterval
    var energySpent: Int

    var lane: Int { socket % 3 }
}

struct Enemy: Codable, Equatable, Identifiable, Sendable {
    let id: Int
    let kind: EnemyKind
    let lane: Int
    var progress: Double
    var health: Double
    let maximumHealth: Double
    var shield: Double
    let maximumShield: Double
    var timeSinceDamage: TimeInterval
}

struct GameSnapshot: Codable, Equatable, Sendable {
    let missionID: String
    let seed: UInt64
    let phase: GamePhase
    let waveIndex: Int
    let energy: Int
    let beaconHealth: Int
    let towers: [Tower]
    let enemies: [Enemy]
    let appliedUpgradeIDs: [String]
    let didUseRevive: Bool
}

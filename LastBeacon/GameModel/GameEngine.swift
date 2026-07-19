import Foundation

struct GameEngine: Sendable {
    private static let fixedStep: TimeInterval = 1.0 / 60.0
    private var state: GameState

    init(mission: MissionDefinition, seed: UInt64) {
        state = GameState(mission: mission, seed: seed)
    }

    var snapshot: GameSnapshot { state.snapshot }

    mutating func send(_ command: GameCommand) {
        guard state.phase != .victory, state.phase != .defeat else { return }

        switch command {
        case let .build(kind, socket):
            guard (0..<6).contains(socket),
                  state.towers.contains(where: { $0.socket == socket }) == false,
                  state.energy >= kind.buildCost else { return }
            state.energy -= kind.buildCost
            state.towers.append(Tower(
                id: state.nextTowerID,
                kind: kind,
                socket: socket,
                level: 1,
                cooldownRemaining: kind.cooldown,
                energySpent: kind.buildCost
            ))
            state.nextTowerID += 1

        case let .upgrade(socket):
            guard let index = state.towers.firstIndex(where: { $0.socket == socket }),
                  state.towers[index].level < 3 else { return }
            let cost = state.towers[index].kind.buildCost * state.towers[index].level
            guard state.energy >= cost else { return }
            state.energy -= cost
            state.towers[index].level += 1
            state.towers[index].energySpent += cost

        case let .sell(socket):
            guard let index = state.towers.firstIndex(where: { $0.socket == socket }) else { return }
            state.energy += Int(Double(state.towers[index].energySpent) * 0.7)
            state.towers.remove(at: index)

        case .startWave:
            guard state.phase == .planning,
                  state.waveIndex < state.mission.waves.count else { return }
            state.phase = .active

        case let .chooseUpgrade(id):
            guard let upgrade = UpgradeDefinition.launch.first(where: { $0.id == id }) else { return }
            let existingTier = state.appliedUpgradeIDs.filter { $0 == id }.count
            guard existingTier < upgrade.maximumTier else { return }
            state.appliedUpgradeIDs.append(id)
            switch upgrade.category {
            case .pulse:
                state.damageMultipliers[.pulse, default: 1] *= 1.25
            case .laser:
                state.damageMultipliers[.laser, default: 1] *= 1.25
            case .gravity:
                state.gravitySlowFactor = max(0.35, state.gravitySlowFactor - 0.08)
            case .beacon:
                state.beaconHealth = min(state.mission.beaconHealth, state.beaconHealth + 10)
            case .economy:
                state.energy += 15
            case .synergy:
                for kind in TowerKind.allCases {
                    state.damageMultipliers[kind, default: 1] *= 1.1
                }
            }
        }
    }

    mutating func advance(by elapsed: TimeInterval) {
        guard elapsed > 0, state.phase == .active else { return }
        state.accumulator += min(elapsed, 10)
        while state.accumulator + 0.000_000_1 >= Self.fixedStep,
              state.phase == .active {
            step(Self.fixedStep)
            state.accumulator -= Self.fixedStep
        }
    }

    private mutating func step(_ delta: TimeInterval) {
        state.waveElapsed += delta
        spawnReadyEnemies()
        regenerateShields(delta)
        moveEnemies(delta)
        guard state.phase == .active else { return }
        fireTowers(delta)
        resolveDestroyedEnemies()
        finishWaveIfNeeded()
    }

    private mutating func spawnReadyEnemies() {
        let spawns = state.mission.waves[state.waveIndex].spawns
        while state.spawnCursor < spawns.count,
              spawns[state.spawnCursor].time <= state.waveElapsed {
            let spawn = spawns[state.spawnCursor]
            state.enemies.append(Enemy(
                id: state.nextEnemyID,
                kind: spawn.kind,
                lane: min(max(spawn.lane, 0), 2),
                progress: min(max(spawn.progress, 0), 1),
                health: spawn.kind.baseHealth,
                maximumHealth: spawn.kind.baseHealth,
                shield: spawn.kind.maximumShield,
                maximumShield: spawn.kind.maximumShield,
                timeSinceDamage: 0
            ))
            state.nextEnemyID += 1
            state.spawnCursor += 1
        }
    }

    private mutating func regenerateShields(_ delta: TimeInterval) {
        for index in state.enemies.indices where state.enemies[index].maximumShield > 0 {
            state.enemies[index].timeSinceDamage += delta
            if state.enemies[index].timeSinceDamage > 3 {
                state.enemies[index].shield = min(
                    state.enemies[index].maximumShield,
                    state.enemies[index].shield + (10 * delta)
                )
            }
        }
    }

    private mutating func moveEnemies(_ delta: TimeInterval) {
        let slowedLanes = Set(state.towers.filter { $0.kind == .gravity }.map(\.lane))
        for index in state.enemies.indices {
            let multiplier = slowedLanes.contains(state.enemies[index].lane) ? state.gravitySlowFactor : 1
            state.enemies[index].progress += state.enemies[index].kind.speed * multiplier * delta
        }

        let arrivals = state.enemies.filter { $0.progress >= 1 }
        guard arrivals.isEmpty == false else { return }
        state.beaconHealth = max(0, state.beaconHealth - arrivals.reduce(0) { $0 + $1.kind.beaconDamage })
        let arrivedIDs = Set(arrivals.map(\.id))
        state.enemies.removeAll { arrivedIDs.contains($0.id) }
        if state.beaconHealth == 0 {
            state.phase = .defeat
        }
    }

    private mutating func fireTowers(_ delta: TimeInterval) {
        for towerIndex in state.towers.indices {
            guard state.towers[towerIndex].kind != .gravity else { continue }
            state.towers[towerIndex].cooldownRemaining -= delta
            guard state.towers[towerIndex].cooldownRemaining <= 0,
                  let targetIndex = state.enemies.indices
                    .filter({ state.enemies[$0].lane == state.towers[towerIndex].lane })
                    .max(by: { state.enemies[$0].progress < state.enemies[$1].progress }) else { continue }

            let tower = state.towers[towerIndex]
            let damage = tower.kind.damage
                * (1 + Double(tower.level - 1) * 0.5)
                * state.damageMultipliers[tower.kind, default: 1]
            apply(damage: damage, ignoresArmor: tower.kind == .laser, to: targetIndex)
            state.towers[towerIndex].cooldownRemaining += tower.kind.cooldown
        }
    }

    private mutating func apply(damage: Double, ignoresArmor: Bool, to index: Int) {
        var remaining = damage
        if state.enemies[index].shield > 0 {
            let absorbed = min(state.enemies[index].shield, remaining)
            state.enemies[index].shield -= absorbed
            remaining -= absorbed
        }
        if remaining > 0 {
            let armor = ignoresArmor ? 0 : state.enemies[index].kind.armor
            state.enemies[index].health -= max(1, remaining - armor)
        }
        state.enemies[index].timeSinceDamage = 0
    }

    private mutating func resolveDestroyedEnemies() {
        let destroyed = state.enemies.filter { $0.health <= 0 }
        guard destroyed.isEmpty == false else { return }
        let destroyedIDs = Set(destroyed.map(\.id))
        state.enemies.removeAll { destroyedIDs.contains($0.id) }

        for enemy in destroyed {
            state.energy += enemy.kind.energyReward
            guard enemy.kind == .splitter else { continue }
            for offset in [-0.01, 0.01] {
                state.enemies.append(Enemy(
                    id: state.nextEnemyID,
                    kind: .drone,
                    lane: enemy.lane,
                    progress: max(0, enemy.progress + offset),
                    health: EnemyKind.drone.baseHealth,
                    maximumHealth: EnemyKind.drone.baseHealth,
                    shield: 0,
                    maximumShield: 0,
                    timeSinceDamage: 0
                ))
                state.nextEnemyID += 1
            }
        }
    }

    private mutating func finishWaveIfNeeded() {
        let wave = state.mission.waves[state.waveIndex]
        guard state.spawnCursor == wave.spawns.count, state.enemies.isEmpty else { return }
        state.waveIndex += 1
        if state.waveIndex == state.mission.waves.count {
            state.phase = .victory
        } else {
            state.phase = .planning
            state.waveElapsed = 0
            state.spawnCursor = 0
        }
    }
}

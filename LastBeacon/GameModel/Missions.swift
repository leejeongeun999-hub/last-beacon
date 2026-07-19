import Foundation

enum SectorModifier: String, Codable, CaseIterable, Sendable {
    case solarWind
    case ionStorm
    case darkMatter
}

enum LaunchMissions {
    static let endless = makeEndlessMission()

    static let all: [MissionDefinition] = (1...3).flatMap { sector in
        (1...4).map { mission in
            makeMission(sector: sector, mission: mission)
        }
    }

    private static func makeMission(sector: Int, mission: Int) -> MissionDefinition {
        let difficulty = ((sector - 1) * 4) + mission
        let waves = (1...8).map { wave in
            makeWave(sector: sector, mission: mission, wave: wave, difficulty: difficulty)
        }
        return MissionDefinition(
            id: "sector-\(sector)-mission-\(mission)",
            sector: sector,
            startingEnergy: mission == 1 && sector == 1 ? 100 : 80,
            beaconHealth: 100,
            waves: waves
        )
    }

    private static func makeWave(
        sector: Int,
        mission: Int,
        wave: Int,
        difficulty: Int
    ) -> WaveDefinition {
        var spawns: [EnemySpawn] = []
        let regularCount = min(3 + wave + (difficulty / 3), 14)
        for index in 0..<regularCount {
            let kind = enemyKind(sector: sector, wave: wave, index: index)
            spawns.append(EnemySpawn(
                time: Double(index) * max(0.35, 0.9 - Double(difficulty) * 0.03),
                kind: kind,
                lane: (index + wave + mission) % 3
            ))
        }
        if wave == 8 {
            spawns.append(EnemySpawn(
                time: (spawns.last?.time ?? 0) + 1.2,
                kind: .sectorBoss,
                lane: (sector + mission) % 3
            ))
        }
        return WaveDefinition(spawns: spawns)
    }

    private static func enemyKind(sector: Int, wave: Int, index: Int) -> EnemyKind {
        if sector >= 3, wave >= 5, index.isMultiple(of: 5) { return .splitter }
        if sector >= 2, wave >= 4, index.isMultiple(of: 4) { return .shieldVessel }
        if wave >= 3, index.isMultiple(of: 3) { return .armoredFrigate }
        if index.isMultiple(of: 2) { return .swarm }
        return .drone
    }

    private static func makeEndlessMission() -> MissionDefinition {
        let waves = (1...120).map { wave in
            let regularCount = min(5 + (wave / 2), 24)
            let interval = max(0.22, 0.75 - (Double(min(wave, 60)) * 0.008))
            var spawns = (0..<regularCount).map { index in
                EnemySpawn(
                    time: Double(index) * interval,
                    kind: endlessEnemyKind(wave: wave, index: index),
                    lane: (wave + index) % 3
                )
            }
            if wave.isMultiple(of: 8) {
                spawns.append(EnemySpawn(
                    time: (spawns.last?.time ?? 0) + 0.8,
                    kind: .sectorBoss,
                    lane: wave % 3
                ))
            }
            return WaveDefinition(spawns: spawns)
        }
        return MissionDefinition(
            id: "endless",
            sector: 1,
            startingEnergy: 100,
            beaconHealth: 100,
            waves: waves
        )
    }

    private static func endlessEnemyKind(wave: Int, index: Int) -> EnemyKind {
        if wave >= 9, index.isMultiple(of: 6) { return .splitter }
        if wave >= 6, index.isMultiple(of: 5) { return .shieldVessel }
        if wave >= 4, index.isMultiple(of: 4) { return .armoredFrigate }
        return index.isMultiple(of: 2) ? .swarm : .drone
    }
}

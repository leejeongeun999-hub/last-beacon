import Foundation

enum ContentValidationError: Error, Equatable {
    case duplicateMissionID(String)
    case duplicateUpgradeID(String)
    case missingWaves(missionID: String)
    case unsortedSpawnTimes(missionID: String)
    case invalidLane(missionID: String, lane: Int)
    case invalidUpgradeLocalization(upgradeID: String)
}

struct ContentCatalog: Sendable {
    let missions: [MissionDefinition]
    let upgrades: [UpgradeDefinition]
    let sectorModifiers: [SectorModifier]

    static let launch = ContentCatalog(
        missions: LaunchMissions.all,
        upgrades: UpgradeDefinition.launch,
        sectorModifiers: [.solarWind, .ionStorm, .darkMatter]
    )

    func validate() throws {
        if let duplicate = duplicate(in: missions.map(\.id)) {
            throw ContentValidationError.duplicateMissionID(duplicate)
        }
        if let duplicate = duplicate(in: upgrades.map(\.id)) {
            throw ContentValidationError.duplicateUpgradeID(duplicate)
        }

        for mission in missions {
            guard mission.waves.isEmpty == false else {
                throw ContentValidationError.missingWaves(missionID: mission.id)
            }
            for wave in mission.waves {
                let times = wave.spawns.map(\.time)
                guard times == times.sorted() else {
                    throw ContentValidationError.unsortedSpawnTimes(missionID: mission.id)
                }
                if let invalid = wave.spawns.first(where: { (0...2).contains($0.lane) == false }) {
                    throw ContentValidationError.invalidLane(missionID: mission.id, lane: invalid.lane)
                }
            }
        }

        if let upgrade = upgrades.first(where: {
            $0.nameKey.isEmpty || $0.descriptionKey.isEmpty || $0.maximumTier < 1
        }) {
            throw ContentValidationError.invalidUpgradeLocalization(upgradeID: upgrade.id)
        }
    }

    private func duplicate(in values: [String]) -> String? {
        var seen = Set<String>()
        return values.first { seen.insert($0).inserted == false }
    }
}


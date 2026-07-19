import Foundation

struct RunResult: Codable, Equatable, Sendable {
    let missionID: String
    let victory: Bool
    let beaconHealth: Int
    let beaconMaximumHealth: Int
    let optionalConditionMet: Bool
    let salvage: Int
}

struct MissionProgress: Codable, Equatable, Sendable {
    var stars: Int
    var bestSalvage: Int
}

struct Progression: Codable, Equatable, Sendable {
    private(set) var missions: [String: MissionProgress] = [:]

    var totalStars: Int { missions.values.reduce(0) { $0 + $1.stars } }
    var endlessUnlocked: Bool { stars(for: "sector-1-mission-4") > 0 }

    mutating func apply(result: RunResult) {
        let existing = missions[result.missionID] ?? MissionProgress(stars: 0, bestSalvage: 0)
        var earned = 0
        if result.victory {
            earned += 1
            if result.beaconMaximumHealth > 0,
               Double(result.beaconHealth) / Double(result.beaconMaximumHealth) >= 0.6 {
                earned += 1
            }
            if result.optionalConditionMet { earned += 1 }
        }
        missions[result.missionID] = MissionProgress(
            stars: max(existing.stars, earned),
            bestSalvage: max(existing.bestSalvage, result.salvage)
        )
    }

    func stars(for missionID: String) -> Int {
        missions[missionID]?.stars ?? 0
    }

    func bestSalvage(for missionID: String) -> Int {
        missions[missionID]?.bestSalvage ?? 0
    }

    func isSectorUnlocked(_ sector: Int) -> Bool {
        switch sector {
        case ...1: true
        case 2: totalStars >= 6
        default: totalStars >= 18
        }
    }
}

import Foundation

enum UpgradeCategory: String, Codable, CaseIterable, Sendable {
    case pulse
    case laser
    case gravity
    case beacon
    case economy
    case synergy
}

struct UpgradeDefinition: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let nameKey: String
    let descriptionKey: String
    let category: UpgradeCategory
    let maximumTier: Int
}

enum UpgradeOffering {
    static func make(
        from upgrades: [UpgradeDefinition],
        seed: UInt64,
        count: Int = 3
    ) -> [UpgradeDefinition] {
        guard upgrades.isEmpty == false, count > 0 else { return [] }
        var generator = SeededGenerator(seed: seed)
        var shuffled = upgrades
        for index in shuffled.indices.dropLast() {
            let distance = shuffled.count - index
            let offset = Int(generator.next() % UInt64(distance))
            shuffled.swapAt(index, index + offset)
        }
        return Array(shuffled.prefix(min(count, shuffled.count)))
    }
}

extension UpgradeDefinition {
    static let launch: [UpgradeDefinition] = [
        make("pulse-capacitors", .pulse, 2),
        make("burst-sync", .pulse, 2),
        make("pulse-overclock", .pulse, 1),
        make("cascade-rounds", .pulse, 1),
        make("laser-focus", .laser, 2),
        make("armor-piercer", .laser, 1),
        make("heat-sink", .laser, 2),
        make("beam-split", .laser, 1),
        make("gravity-depth", .gravity, 2),
        make("wide-field", .gravity, 2),
        make("time-dilation", .gravity, 1),
        make("singularity", .gravity, 1),
        make("repair-nanites", .beacon, 2),
        make("shield-pulse", .beacon, 1),
        make("emergency-power", .beacon, 1),
        make("hardened-core", .beacon, 2),
        make("salvage-protocol", .economy, 2),
        make("efficient-build", .economy, 1),
        make("recycling", .economy, 2),
        make("wave-bonus", .economy, 1),
        make("crossfire", .synergy, 1),
        make("resonance", .synergy, 1),
        make("triad", .synergy, 1),
        make("last-stand", .synergy, 1)
    ]

    private static func make(
        _ id: String,
        _ category: UpgradeCategory,
        _ maximumTier: Int
    ) -> UpgradeDefinition {
        UpgradeDefinition(
            id: id,
            nameKey: "upgrade.\(id).name",
            descriptionKey: "upgrade.\(id).description",
            category: category,
            maximumTier: maximumTier
        )
    }
}


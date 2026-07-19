import Foundation

enum TutorialStep: String, Codable, Equatable, Sendable {
    case welcome
    case buildPulse
    case startWave
    case upgradePulse
    case complete
}

enum TutorialAction: Equatable, Sendable {
    case acknowledged
    case builtTower(TowerKind)
    case startedWave
    case upgradedTower(TowerKind)
}

struct TutorialCoordinator: Equatable, Sendable {
    private(set) var step: TutorialStep = .welcome
    var isComplete: Bool { step == .complete }

    mutating func handle(_ action: TutorialAction) {
        switch (step, action) {
        case (.welcome, .acknowledged):
            step = .buildPulse
        case (.buildPulse, .builtTower(.pulse)):
            step = .startWave
        case (.startWave, .startedWave):
            step = .upgradePulse
        case (.upgradePulse, .upgradedTower(.pulse)):
            step = .complete
        default:
            break
        }
    }
}

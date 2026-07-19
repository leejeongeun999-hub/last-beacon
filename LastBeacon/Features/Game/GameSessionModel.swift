import Foundation

enum StoreScreenshotFixture: String, Sendable {
    case active
    case upgrade
}

@MainActor
final class GameSessionModel: ObservableObject {
    @Published private(set) var snapshot: GameSnapshot
    @Published private(set) var offeredUpgrades: [UpgradeDefinition] = []
    @Published var selectedSocket: Int?
    @Published private(set) var tutorial: TutorialCoordinator?

    let mission: MissionDefinition
    private let seed: UInt64
    private var engine: GameEngine
    private var clock = GameClock()
    private var offeredWaveIndices = Set<Int>()

    lazy var scene = BattlefieldScene { [weak self] elapsed in
        guard let self else { return nil }
        self.tick(elapsed: elapsed)
        return self.snapshot
    }

    init(
        mission: MissionDefinition,
        seed: UInt64,
        tutorialEnabled: Bool = false,
        screenshotFixture: StoreScreenshotFixture? = nil
    ) {
        self.mission = mission
        self.seed = seed
        engine = GameEngine(mission: mission, seed: seed)
        snapshot = engine.snapshot
        tutorial = tutorialEnabled ? TutorialCoordinator() : nil
        if let screenshotFixture {
            configure(screenshotFixture)
        }
    }

    var result: RunResult {
        RunResult(
            missionID: mission.id,
            victory: snapshot.phase == .victory,
            beaconHealth: snapshot.beaconHealth,
            beaconMaximumHealth: mission.beaconHealth,
            optionalConditionMet: snapshot.appliedUpgradeIDs.count < 3,
            salvage: snapshot.waveIndex * 100
        )
    }

    func tick(elapsed: TimeInterval) {
        let accepted = clock.consume(elapsed: elapsed)
        guard accepted > 0 else { return }
        let previousPhase = snapshot.phase
        engine.advance(by: accepted)
        snapshot = engine.snapshot
        if previousPhase == .active,
           snapshot.phase == .planning,
           [2, 4, 6].contains(snapshot.waveIndex),
           offeredWaveIndices.contains(snapshot.waveIndex) == false {
            offerUpgrades()
        }
    }

    func setPaused(_ paused: Bool) {
        clock.isPaused = paused
    }

    @discardableResult
    func build(_ kind: TowerKind, at socket: Int) -> Bool {
        let previousSnapshot = snapshot
        engine.send(.build(kind: kind, socket: socket))
        snapshot = engine.snapshot
        let changed = snapshot != previousSnapshot
        if changed { handleTutorial(.builtTower(kind)) }
        return changed
    }

    @discardableResult
    func upgrade(at socket: Int) -> Bool {
        let previousSnapshot = snapshot
        let kind = snapshot.towers.first(where: { $0.socket == socket })?.kind
        engine.send(.upgrade(socket: socket))
        snapshot = engine.snapshot
        let changed = snapshot != previousSnapshot
        if changed, let kind { handleTutorial(.upgradedTower(kind)) }
        return changed
    }

    @discardableResult
    func sell(at socket: Int) -> Bool {
        let previousSnapshot = snapshot
        engine.send(.sell(socket: socket))
        snapshot = engine.snapshot
        return snapshot != previousSnapshot
    }

    func startWave() {
        guard offeredUpgrades.isEmpty else { return }
        engine.send(.startWave)
        snapshot = engine.snapshot
        handleTutorial(.startedWave)
    }

    func offerUpgrades() {
        let offerSeed = seed ^ UInt64(snapshot.waveIndex &* 7_919)
        offeredUpgrades = UpgradeOffering.make(
            from: ContentCatalog.launch.upgrades,
            seed: offerSeed,
            appliedIDs: snapshot.appliedUpgradeIDs
        )
        offeredWaveIndices.insert(snapshot.waveIndex)
    }

    func choose(_ upgrade: UpgradeDefinition) {
        guard offeredUpgrades.contains(upgrade) else { return }
        engine.send(.chooseUpgrade(upgrade.id))
        offeredUpgrades = []
        snapshot = engine.snapshot
    }

    func revive() {
        engine.send(.reviveBeacon)
        snapshot = engine.snapshot
    }

    func acknowledgeTutorial() { handleTutorial(.acknowledged) }
    func dismissTutorial() { tutorial = nil }

    private func handleTutorial(_ action: TutorialAction) {
        guard var coordinator = tutorial else { return }
        coordinator.handle(action)
        tutorial = coordinator
    }

    private func configure(_ fixture: StoreScreenshotFixture) {
        engine.send(.build(kind: .pulse, socket: 0))
        engine.send(.build(kind: .laser, socket: 1))
        engine.send(.build(kind: .gravity, socket: 2))
        switch fixture {
        case .active:
            engine.send(.startWave)
            engine.advance(by: 0.2)
            snapshot = engine.snapshot
        case .upgrade:
            snapshot = engine.snapshot
            offerUpgrades()
        }
    }
}

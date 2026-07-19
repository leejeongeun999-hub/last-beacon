import Foundation

enum AppRoute: Equatable {
    case home
    case missions
    case game(MissionDefinition)
    case results(RunResult)
    case settings
}

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var route: AppRoute = .home
    @Published private(set) var document: SaveDocument = .default
    @Published private(set) var forceTutorial = false
    let catalog: ContentCatalog
    private let dependencies: AppDependencies
    private var adInitializationGate = AdInitializationGate()
    private var scoreQueue = GameCenterSubmissionQueue()

    init(
        dependencies: AppDependencies,
        catalog: ContentCatalog = .launch
    ) {
        self.dependencies = dependencies
        self.catalog = catalog
    }

    func load() async {
        document = await dependencies.saveStore.load()
        dependencies.audioService.apply(settings: document.settings)
        dependencies.hapticService.apply(settings: document.settings)
        var loadedQueue = GameCenterSubmissionQueue(pending: document.pendingScores)
        await loadedQueue.flush(using: dependencies.gameCenterService)
        scoreQueue = loadedQueue
        document.pendingScores = scoreQueue.pending
        try? await dependencies.saveStore.save(document)
    }

    func startAdvertising() async {
        await dependencies.consentManager.refresh()
        await synchronizeAdvertisingState()
    }

    private func synchronizeAdvertisingState() async {
        document.consentCache.privacyOptionsRequired = dependencies.consentManager.privacyOptionsRequired
        document.consentCache.lastRefresh = Date()
        try? await dependencies.saveStore.save(document)
        if dependencies.consentManager.canRequestAds {
            if adInitializationGate.claimIfAllowed(canRequestAds: true) {
                await dependencies.adService.prepare()
            }
        } else {
            adInitializationGate.reset()
            await dependencies.adService.disable()
        }
    }

    func showMissions() { route = .missions }
    func showSettings() { route = .settings }
    func goHome() { route = .home }

    func startEndless() {
        guard document.progression.endlessUnlocked else { return }
        forceTutorial = false
        route = .game(LaunchMissions.endless)
    }

    func start(mission: MissionDefinition) {
        guard isMissionUnlocked(mission) else { return }
        forceTutorial = false
        route = .game(mission)
    }

    func replayTutorial() {
        guard let firstMission = catalog.missions.first else { return }
        forceTutorial = true
        route = .game(firstMission)
    }

    func complete(result: RunResult) async {
        var cadence = AdCadence(
            completedRuns: document.completedRunCount,
            lastInterstitialRun: document.lastInterstitialRun
        )
        let previousInterstitialRun = document.lastInterstitialRun
        let wasTutorial = document.completedRunCount == 0
            && result.missionID == "sector-1-mission-1"
        let shouldPresentInterstitial = cadence.recordCompletedRun(wasTutorial: wasTutorial)
        if result.missionID == LaunchMissions.endless.id {
            await submitEndlessScore(result.salvage)
        } else {
            document.progression.apply(result: result)
        }
        document.completedRunCount = cadence.completedRuns
        document.lastInterstitialRun = cadence.lastInterstitialRun
        document.statistics.totalRuns += 1
        document.statistics.totalSalvage += result.salvage
        if result.victory { document.statistics.victories += 1 }
        dependencies.audioService.play(result.victory ? .victory : .defeat)
        dependencies.hapticService.play(result.victory ? .success : .failure)
        try? await dependencies.saveStore.save(document)
        route = .results(result)
        if shouldPresentInterstitial {
            let presented = await dependencies.adService.presentInterstitial()
            if presented == false {
                document.lastInterstitialRun = previousInterstitialRun
                try? await dependencies.saveStore.save(document)
            }
        }
    }

    func updateSettings(_ update: (inout GameSettings) -> Void) async {
        update(&document.settings)
        dependencies.audioService.apply(settings: document.settings)
        dependencies.hapticService.apply(settings: document.settings)
        try? await dependencies.saveStore.save(document)
    }

    func submitEndlessScore(_ score: Int) async {
        document.endlessHighScore = max(document.endlessHighScore, score)
        var updatedQueue = scoreQueue
        updatedQueue.enqueue(leaderboardID: "last_beacon_endless", value: score)
        await updatedQueue.flush(using: dependencies.gameCenterService)
        scoreQueue = updatedQueue
        document.pendingScores = scoreQueue.pending
        try? await dependencies.saveStore.save(document)
    }

    func markTutorialCompleted() async {
        forceTutorial = false
        document.tutorialCompleted = true
        try? await dependencies.saveStore.save(document)
    }

    func requestRewardedRevive() async -> Bool {
        await dependencies.adService.presentRewardedRevive()
    }

    func playTowerActionFeedback() {
        dependencies.audioService.play(.tower)
        dependencies.hapticService.play(.action)
    }

    func presentPrivacyOptions() async {
        await dependencies.consentManager.presentPrivacyOptions()
        await synchronizeAdvertisingState()
    }

    func isMissionUnlocked(_ mission: MissionDefinition) -> Bool {
        guard document.progression.isSectorUnlocked(mission.sector) else { return false }
        guard let index = catalog.missions.firstIndex(where: { $0.id == mission.id }) else { return false }
        let sectorIndex = index % 4
        guard sectorIndex > 0 else { return true }
        return document.progression.stars(for: catalog.missions[index - 1].id) > 0
    }
}

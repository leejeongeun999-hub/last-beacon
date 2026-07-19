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
    let catalog: ContentCatalog
    private let dependencies: AppDependencies

    init(
        dependencies: AppDependencies,
        catalog: ContentCatalog = .launch
    ) {
        self.dependencies = dependencies
        self.catalog = catalog
    }

    func load() async {
        document = await dependencies.saveStore.load()
    }

    func showMissions() { route = .missions }
    func showSettings() { route = .settings }
    func goHome() { route = .home }

    func start(mission: MissionDefinition) {
        guard isMissionUnlocked(mission) else { return }
        route = .game(mission)
    }

    func complete(result: RunResult) async {
        document.progression.apply(result: result)
        document.completedRunCount += 1
        document.statistics.totalRuns += 1
        document.statistics.totalSalvage += result.salvage
        if result.victory { document.statistics.victories += 1 }
        try? await dependencies.saveStore.save(document)
        route = .results(result)
    }

    func updateSettings(_ update: (inout GameSettings) -> Void) async {
        update(&document.settings)
        try? await dependencies.saveStore.save(document)
    }

    func markTutorialCompleted() async {
        document.tutorialCompleted = true
        try? await dependencies.saveStore.save(document)
    }

    func isMissionUnlocked(_ mission: MissionDefinition) -> Bool {
        guard document.progression.isSectorUnlocked(mission.sector) else { return false }
        guard let index = catalog.missions.firstIndex(where: { $0.id == mission.id }) else { return false }
        let sectorIndex = index % 4
        guard sectorIndex > 0 else { return true }
        return document.progression.stars(for: catalog.missions[index - 1].id) > 0
    }
}

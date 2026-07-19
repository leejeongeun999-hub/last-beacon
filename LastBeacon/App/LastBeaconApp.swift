import SwiftUI

enum AppConfiguration {
    static let productName = "Last Beacon: Orbit Defense"
    static let bundleIdentifier = "com.limeunkyu.lastbeacon"
}

@main
struct LastBeaconApp: App {
    @StateObject private var model = AppModel(dependencies: .live)

    var body: some Scene {
        WindowGroup {
            RootView(model: model)
                .task { await model.load() }
        }
    }
}

private struct RootView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        switch model.route {
        case .home:
            HomeView(model: model)
        case .missions:
            MissionSelectView(model: model)
        case let .game(mission):
            GameHostView(
                mission: mission,
                tutorialEnabled: mission.id == "sector-1-mission-1" && model.document.tutorialCompleted == false,
                onFinish: { result in
                    Task { @MainActor in await model.complete(result: result) }
                },
                onTutorialComplete: {
                    Task { @MainActor in await model.markTutorialCompleted() }
                }
            )
        case let .results(result):
            ResultsView(model: model, result: result)
        case .settings:
            SettingsView(model: model)
        }
    }
}

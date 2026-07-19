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
                .task {
                    await model.load()
                    if ProcessInfo.processInfo.environment["LAST_BEACON_SCREENSHOT_STATE"] == nil {
                        await model.startAdvertising()
                    }
                }
        }
    }
}

private struct RootView: View {
    @ObservedObject var model: AppModel

    private var screenshotFixture: StoreScreenshotFixture? {
        ProcessInfo.processInfo.environment["LAST_BEACON_SCREENSHOT_STATE"]
            .flatMap(StoreScreenshotFixture.init(rawValue:))
    }

    @ViewBuilder
    var body: some View {
        if let screenshotFixture {
            GameHostView(
                mission: model.catalog.missions[0],
                tutorialEnabled: false,
                seed: 4_242,
                screenshotFixture: screenshotFixture,
                onFinish: { _ in },
                onTutorialComplete: { },
                requestRewardedRevive: { false }
            )
        } else {
            routedContent
        }
    }

    @ViewBuilder
    private var routedContent: some View {
        switch model.route {
        case .home:
            HomeView(model: model)
        case .missions:
            MissionSelectView(model: model)
        case let .game(mission):
            GameHostView(
                mission: mission,
                tutorialEnabled: model.forceTutorial || (
                    mission.id == "sector-1-mission-1" && model.document.tutorialCompleted == false
                ),
                reduceMotion: model.document.settings.reduceMotion,
                onTowerAction: model.playTowerActionFeedback,
                onFinish: { result in
                    Task { @MainActor in await model.complete(result: result) }
                },
                onTutorialComplete: {
                    Task { @MainActor in await model.markTutorialCompleted() }
                },
                requestRewardedRevive: {
                    await model.requestRewardedRevive()
                }
            )
        case let .results(result):
            ResultsView(model: model, result: result)
        case .settings:
            SettingsView(model: model)
        }
    }
}

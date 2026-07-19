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
            GamePendingView(model: model, mission: mission)
        case let .results(result):
            ResultsView(model: model, result: result)
        case .settings:
            SettingsView(model: model)
        }
    }
}

private struct GamePendingView: View {
    @ObservedObject var model: AppModel
    let mission: MissionDefinition

    var body: some View {
        VStack(spacing: 24) {
            Text("app.title").font(.largeTitle.bold())
            Text(mission.id).foregroundStyle(.secondary)
            ProgressView().tint(NeonTheme.cyan)
            Button("common.back") { model.showMissions() }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .neonBackground()
    }
}

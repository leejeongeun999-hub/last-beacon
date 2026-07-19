import SwiftUI

struct ResultsView: View {
    @ObservedObject var model: AppModel
    let result: RunResult

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: result.victory ? "dot.radiowaves.up.forward" : "antenna.radiowaves.left.and.right.slash")
                .font(.system(size: 76, weight: .thin))
                .foregroundStyle(result.victory ? NeonTheme.cyan : NeonTheme.magenta)
            Text(result.victory ? "results.victory" : "results.defeat")
                .font(.largeTitle.bold())
                .accessibilityIdentifier("results.title")
            Text(String(format: String(localized: "results.salvage"), Int64(result.salvage)))
            Text(String(
                format: String(localized: "results.stars"),
                Int64(model.document.progression.stars(for: result.missionID))
            ))
            Spacer()
            Button("common.retry") {
                if result.missionID == LaunchMissions.endless.id {
                    model.startEndless()
                } else if let mission = model.catalog.missions.first(where: { $0.id == result.missionID }) {
                    model.start(mission: mission)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(NeonTheme.cyan)
            Button("common.home") { model.goHome() }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .neonBackground()
    }
}

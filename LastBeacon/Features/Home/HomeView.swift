import SwiftUI

struct HomeView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 82, weight: .thin))
                .foregroundStyle(NeonTheme.cyan)
                .shadow(color: NeonTheme.cyan.opacity(0.8), radius: 18)
                .accessibilityHidden(true)

            Text("app.title")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("home.title")

            Text("home.subtitle")
                .font(.headline)
                .foregroundStyle(.secondary)

            Spacer()

            Button("home.start") { model.showMissions() }
                .buttonStyle(.borderedProminent)
                .tint(NeonTheme.cyan)
                .controlSize(.large)
                .accessibilityIdentifier("home.start")

            Button("home.endless") { }
                .buttonStyle(.bordered)
                .disabled(model.document.progression.endlessUnlocked == false)
                .accessibilityIdentifier("home.endless")

            Button("home.settings") { model.showSettings() }
                .buttonStyle(.plain)
                .accessibilityIdentifier("home.settings")
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .neonBackground()
    }
}

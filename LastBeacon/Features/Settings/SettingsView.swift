import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        NavigationStack {
            Form {
                Toggle("settings.music", isOn: setting(\.musicEnabled))
                Toggle("settings.effects", isOn: setting(\.effectsEnabled))
                Toggle("settings.haptics", isOn: setting(\.hapticsEnabled))
                Toggle("settings.reduceMotion", isOn: setting(\.reduceMotion))
                Button("settings.tutorial") { model.replayTutorial() }
                    .accessibilityIdentifier("settings.tutorial")
                if model.document.consentCache.privacyOptionsRequired {
                    Button("settings.privacy") {
                        Task { @MainActor in await model.presentPrivacyOptions() }
                    }
                        .accessibilityIdentifier("settings.privacy")
                }
            }
            .scrollContentBackground(.hidden)
            .background(NeonTheme.background)
            .navigationTitle(String(localized: "settings.title"))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("common.back") { model.goHome() }
                        .accessibilityIdentifier("settings.back")
                }
            }
        }
        .tint(NeonTheme.cyan)
    }

    private func setting(_ keyPath: WritableKeyPath<GameSettings, Bool>) -> Binding<Bool> {
        Binding(
            get: { model.document.settings[keyPath: keyPath] },
            set: { newValue in
                Task { @MainActor in
                    await model.updateSettings { $0[keyPath: keyPath] = newValue }
                }
            }
        )
    }
}

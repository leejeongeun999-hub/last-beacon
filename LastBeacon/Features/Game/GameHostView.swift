import SpriteKit
import SwiftUI

struct GameHostView: View {
    @StateObject private var session: GameSessionModel
    @State private var didFinish = false
    @State private var showingDefeatChoice = false
    @State private var adUnavailable = false
    let onFinish: (RunResult) -> Void
    let onTutorialComplete: () -> Void
    let requestRewardedRevive: () async -> Bool

    init(
        mission: MissionDefinition,
        tutorialEnabled: Bool,
        seed: UInt64 = UInt64.random(in: 1...UInt64.max),
        screenshotFixture: StoreScreenshotFixture? = nil,
        onFinish: @escaping (RunResult) -> Void,
        onTutorialComplete: @escaping () -> Void,
        requestRewardedRevive: @escaping () async -> Bool
    ) {
        _session = StateObject(wrappedValue: GameSessionModel(
            mission: mission,
            seed: seed,
            tutorialEnabled: tutorialEnabled,
            screenshotFixture: screenshotFixture
        ))
        self.onFinish = onFinish
        self.onTutorialComplete = onTutorialComplete
        self.requestRewardedRevive = requestRewardedRevive
    }

    var body: some View {
        ZStack {
            NeonTheme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                hud
                ZStack {
                    SpriteView(
                        scene: session.scene,
                        preferredFramesPerSecond: 60,
                        options: [.allowsTransparency]
                    )
                    socketControls
                }
                bottomControls
            }

            if session.offeredUpgrades.isEmpty == false {
                UpgradeOfferView(session: session)
            }
            if let tutorial = session.tutorial {
                TutorialOverlay(
                    tutorial: tutorial,
                    acknowledge: session.acknowledgeTutorial,
                    complete: {
                        session.dismissTutorial()
                        onTutorialComplete()
                    }
                )
            }
            if showingDefeatChoice {
                DefeatChoiceOverlay(
                    adUnavailable: adUnavailable,
                    revive: {
                        Task { @MainActor in
                            if await requestRewardedRevive() {
                                session.revive()
                                showingDefeatChoice = false
                            } else {
                                adUnavailable = true
                            }
                        }
                    },
                    finish: {
                        showingDefeatChoice = false
                        didFinish = true
                        onFinish(session.result)
                    }
                )
            }
        }
        .foregroundStyle(.white)
        .sheet(isPresented: selectedSocketBinding) {
            if let socket = session.selectedSocket {
                TowerControlSheet(session: session, socket: socket)
                    .presentationDetents([.height(280)])
                    .presentationDragIndicator(.visible)
            }
        }
        .onChange(of: session.snapshot.phase) { _, phase in
            guard didFinish == false else { return }
            if phase == .defeat, session.snapshot.didUseRevive == false {
                showingDefeatChoice = true
            } else if phase == .victory || phase == .defeat {
                didFinish = true
                onFinish(session.result)
            }
        }
    }

    private var hud: some View {
        HStack {
            Label("\(session.snapshot.waveIndex + 1)/\(session.mission.waves.count)", systemImage: "waveform.path")
            Spacer()
            Label("\(session.snapshot.energy)", systemImage: "bolt.fill")
                .foregroundStyle(NeonTheme.amber)
            Spacer()
            Label("\(session.snapshot.beaconHealth)", systemImage: "antenna.radiowaves.left.and.right")
                .foregroundStyle(NeonTheme.cyan)
        }
        .font(.subheadline.bold())
        .padding(.horizontal, 18)
        .frame(height: 50)
        .background(NeonTheme.panel)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("game.hud")
    }

    private var socketControls: some View {
        GeometryReader { proxy in
            ForEach(0..<6, id: \.self) { socket in
                let point = BattlefieldLayout.socketPoint(socket, in: proxy.size)
                Button {
                    session.selectedSocket = socket
                } label: {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 52, height: 52)
                        .contentShape(Circle())
                }
                .position(x: point.x, y: proxy.size.height - point.y)
                .accessibilityLabel(socketLabel(socket))
                .accessibilityHint(session.snapshot.towers.contains { $0.socket == socket } ? "game.upgrade" : "game.build")
                .accessibilityIdentifier("game.socket.\(socket)")
            }
        }
    }

    @ViewBuilder
    private var bottomControls: some View {
        if session.snapshot.phase == .planning, session.offeredUpgrades.isEmpty {
            Button("game.startWave") { session.startWave() }
                .buttonStyle(.borderedProminent)
                .tint(NeonTheme.magenta)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .frame(height: 66)
                .background(NeonTheme.panel)
                .accessibilityIdentifier("game.startWave")
        } else {
            Text(String(
                format: String(localized: "game.wave"),
                Int64(min(session.snapshot.waveIndex + 1, session.mission.waves.count)),
                Int64(session.mission.waves.count)
            ))
            .frame(maxWidth: .infinity)
            .frame(height: 66)
            .background(NeonTheme.panel)
        }
    }

    private var selectedSocketBinding: Binding<Bool> {
        Binding(
            get: { session.selectedSocket != nil },
            set: { if $0 == false { session.selectedSocket = nil } }
        )
    }

    private func socketLabel(_ socket: Int) -> String {
        if let tower = session.snapshot.towers.first(where: { $0.socket == socket }) {
            return String(localized: String.LocalizationValue(tower.kind.titleKey))
        }
        return String(localized: "game.build")
    }
}

private struct DefeatChoiceOverlay: View {
    let adUnavailable: Bool
    let revive: () -> Void
    let finish: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Text("results.defeat").font(.title.bold())
            if adUnavailable {
                Text("ad.unavailable")
                    .font(.caption)
                    .multilineTextAlignment(.center)
            } else {
                Button("ad.revive", action: revive)
                    .buttonStyle(.borderedProminent)
                    .tint(NeonTheme.cyan)
                    .accessibilityIdentifier("ad.revive")
            }
            Button("common.continue", action: finish)
                .buttonStyle(.bordered)
                .accessibilityIdentifier("defeat.finish")
        }
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
        .padding(24)
    }
}

private struct TowerControlSheet: View {
    @ObservedObject var session: GameSessionModel
    let socket: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 14) {
            if let tower = session.snapshot.towers.first(where: { $0.socket == socket }) {
                Text(String(localized: String.LocalizationValue(tower.kind.titleKey)))
                    .font(.title2.bold())
                HStack {
                    Button("game.upgrade") {
                        session.upgrade(at: socket)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(tower.level >= 3)
                    .accessibilityIdentifier("tower.upgrade")
                    Button("game.sell") {
                        session.sell(at: socket)
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("tower.sell")
                }
            } else {
                Text("game.build").font(.title2.bold())
                ForEach(TowerKind.allCases, id: \.self) { kind in
                    Button {
                        session.build(kind, at: socket)
                        dismiss()
                    } label: {
                        HStack {
                            Text(String(localized: String.LocalizationValue(kind.titleKey)))
                            Spacer()
                            Text("⚡︎\(kind.buildCost)")
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(session.snapshot.energy < kind.buildCost)
                    .accessibilityIdentifier("build.\(kind.rawValue)")
                }
            }
        }
        .padding(24)
    }
}

private struct UpgradeOfferView: View {
    @ObservedObject var session: GameSessionModel

    var body: some View {
        VStack(spacing: 18) {
            Text("game.chooseUpgrade").font(.title2.bold())
            ForEach(session.offeredUpgrades) { upgrade in
                Button {
                    session.choose(upgrade)
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(String(localized: String.LocalizationValue(upgrade.nameKey))).font(.headline)
                        Text(String(localized: String.LocalizationValue(upgrade.descriptionKey)))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(NeonTheme.panel, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
        .padding(22)
        .accessibilityIdentifier("game.upgradeOffer")
    }
}

private struct TutorialOverlay: View {
    let tutorial: TutorialCoordinator
    let acknowledge: () -> Void
    let complete: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text(String(localized: String.LocalizationValue(tutorial.step.messageKey)))
                .font(.headline)
                .multilineTextAlignment(.center)
            if tutorial.step == .welcome {
                Button("common.continue", action: acknowledge)
                    .buttonStyle(.borderedProminent)
            } else if tutorial.step == .complete {
                Button("common.continue", action: complete)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(22)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding(24)
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, 56)
    }
}

private extension TowerKind {
    var titleKey: String { "tower.\(rawValue).name" }
}

private extension TutorialStep {
    var messageKey: String {
        switch self {
        case .welcome: "tutorial.welcome"
        case .buildPulse: "tutorial.buildPulse"
        case .startWave: "tutorial.startWave"
        case .upgradePulse: "tutorial.upgradePulse"
        case .complete: "tutorial.complete"
        }
    }
}

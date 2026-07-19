import UIKit

enum GameHaptic: Sendable {
    case action
    case success
    case failure
}

@MainActor
protocol HapticServing: AnyObject {
    func apply(settings: GameSettings)
    func play(_ haptic: GameHaptic)
}

@MainActor
final class NoopHapticService: HapticServing {
    func apply(settings: GameSettings) { }
    func play(_ haptic: GameHaptic) { }
}

@MainActor
final class LiveHapticService: HapticServing {
    private var enabled = true

    func apply(settings: GameSettings) {
        enabled = settings.hapticsEnabled
    }

    func play(_ haptic: GameHaptic) {
        guard enabled else { return }
        switch haptic {
        case .action:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .failure:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}

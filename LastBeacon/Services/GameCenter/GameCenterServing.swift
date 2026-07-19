import Foundation
@preconcurrency import GameKit
import UIKit

@MainActor
protocol GameCenterServing: AnyObject {
    var authenticated: Bool { get }
    func authenticate() async -> Bool
    func submit(score: Int, leaderboardID: String) async -> Bool
}

@MainActor
final class NoopGameCenterService: GameCenterServing {
    let authenticated = false
    func authenticate() async -> Bool { false }
    func submit(score: Int, leaderboardID: String) async -> Bool { false }
}

@MainActor
final class LiveGameCenterService: GameCenterServing {
    var authenticated: Bool { GKLocalPlayer.local.isAuthenticated }

    func authenticate() async -> Bool {
        guard authenticated == false else { return true }
        return await withCheckedContinuation { continuation in
            var completed = false
            GKLocalPlayer.local.authenticateHandler = { viewController, _ in
                if let viewController {
                    Self.topViewController()?.present(viewController, animated: true)
                    return
                }
                guard completed == false else { return }
                completed = true
                continuation.resume(returning: GKLocalPlayer.local.isAuthenticated)
            }
        }
    }

    func submit(score: Int, leaderboardID: String) async -> Bool {
        guard authenticated else { return false }
        do {
            try await GKLeaderboard.submitScore(
                score,
                context: 0,
                player: GKLocalPlayer.local,
                leaderboardIDs: [leaderboardID]
            )
            return true
        } catch {
            return false
        }
    }

    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        var controller = scene?.windows.first(where: \.isKeyWindow)?.rootViewController
        while let presented = controller?.presentedViewController {
            controller = presented
        }
        return controller
    }
}

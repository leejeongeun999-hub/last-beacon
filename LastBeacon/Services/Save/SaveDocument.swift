import Foundation

struct GameSettings: Codable, Equatable, Sendable {
    var musicEnabled = true
    var effectsEnabled = true
    var hapticsEnabled = true
    var reduceMotion = false
}

struct GameStatistics: Codable, Equatable, Sendable {
    var totalRuns = 0
    var victories = 0
    var enemiesDestroyed = 0
    var totalSalvage = 0
}

struct PendingScore: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let leaderboardID: String
    let value: Int
}

struct ConsentCache: Codable, Equatable, Sendable {
    var privacyOptionsRequired = false
    var lastRefresh: Date?
}

struct SaveDocument: Codable, Equatable, Sendable {
    static let currentVersion = 1

    var schemaVersion: Int
    var progression: Progression
    var settings: GameSettings
    var tutorialCompleted: Bool
    var statistics: GameStatistics
    var consentCache: ConsentCache
    var pendingScores: [PendingScore]
    var endlessHighScore: Int
    var completedRunCount: Int
    var lastInterstitialRun: Int

    static let `default` = SaveDocument(
        schemaVersion: currentVersion,
        progression: Progression(),
        settings: GameSettings(),
        tutorialCompleted: false,
        statistics: GameStatistics(),
        consentCache: ConsentCache(),
        pendingScores: [],
        endlessHighScore: 0,
        completedRunCount: 0,
        lastInterstitialRun: 0
    )
}

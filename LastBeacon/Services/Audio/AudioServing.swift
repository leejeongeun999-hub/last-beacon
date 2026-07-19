import AVFoundation

enum GameSoundEffect: String, Sendable {
    case tower
    case victory
    case defeat
}

@MainActor
protocol AudioServing: AnyObject {
    func apply(settings: GameSettings)
    func play(_ effect: GameSoundEffect)
}

@MainActor
final class NoopAudioService: AudioServing {
    func apply(settings: GameSettings) { }
    func play(_ effect: GameSoundEffect) { }
}

@MainActor
final class LiveAudioService: AudioServing {
    private var ambientPlayer: AVAudioPlayer?
    private var effectPlayers: [GameSoundEffect: AVAudioPlayer] = [:]
    private var musicEnabled = true
    private var effectsEnabled = true

    init(bundle: Bundle = .main) {
        ambientPlayer = Self.player(named: "ambient_loop", bundle: bundle)
        ambientPlayer?.numberOfLoops = -1
        for effect in [GameSoundEffect.tower, .victory, .defeat] {
            effectPlayers[effect] = Self.player(named: effect.rawValue, bundle: bundle)
        }
    }

    func apply(settings: GameSettings) {
        musicEnabled = settings.musicEnabled
        effectsEnabled = settings.effectsEnabled
        if musicEnabled {
            ambientPlayer?.volume = 0.22
            ambientPlayer?.play()
        } else {
            ambientPlayer?.pause()
        }
        if effectsEnabled == false {
            effectPlayers.values.forEach { $0.stop() }
        }
    }

    func play(_ effect: GameSoundEffect) {
        guard effectsEnabled, let player = effectPlayers[effect] else { return }
        player.currentTime = 0
        player.play()
    }

    private static func player(named name: String, bundle: Bundle) -> AVAudioPlayer? {
        guard let url = bundle.url(forResource: name, withExtension: "wav") else { return nil }
        return try? AVAudioPlayer(contentsOf: url)
    }
}

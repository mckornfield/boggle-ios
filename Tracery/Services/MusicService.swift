import AVFoundation

@Observable
class MusicService {
    private var homePlayer: AVAudioPlayer?
    private var gameplayPlayers: [AVAudioPlayer] = []
    private var gameplayIndex = 0

    private var currentPlayer: AVAudioPlayer?
    private var fadeTimer: Timer?

    private(set) var isMuted = true

    private static let fadeSteps = 20
    private static let fadeDuration: TimeInterval = 1.0
    private static let stepInterval: TimeInterval = fadeDuration / Double(fadeSteps)

    // File naming convention:
    //   Home:     music_home.mp4 / .mp3 / .m4a
    //   Gameplay: music_gameplay_1.mp4, music_gameplay_2.mp4, ... (any count)
    private static let audioExtensions = ["mp4", "mp3", "m4a"]

    init() {
        configureAudioSession()
        homePlayer = loadPlayer(named: "music_home")
        // Load as many numbered gameplay tracks as exist in the bundle
        var index = 1
        while let player = loadPlayer(named: "music_gameplay_\(index)") {
            gameplayPlayers.append(player)
            index += 1
        }
        if gameplayPlayers.isEmpty {
            print("[MusicService] No gameplay tracks found (expected music_gameplay_1, music_gameplay_2, ...)")
        }
    }

    // MARK: - Public API

    func play(_ track: Track) {
        switch track {
        case .home:
            crossfade(to: homePlayer)
        case .gameplay:
            guard !gameplayPlayers.isEmpty else { return }
            let next = gameplayPlayers[gameplayIndex % gameplayPlayers.count]
            gameplayIndex += 1
            crossfade(to: next)
        }
    }

    func stop() {
        fadeTimer?.invalidate()
        fadeTimer = nil
        currentPlayer?.stop()
        currentPlayer = nil
    }

    func toggleMute() {
        isMuted.toggle()
        currentPlayer?.volume = isMuted ? 0 : 1
    }

    /// Quietly lower volume during results/lobby screens.
    func duck() {
        guard !isMuted else { return }
        currentPlayer?.setVolume(0.25, fadeDuration: 0.8)
    }

    /// Restore full volume when gameplay resumes.
    func unduck() {
        guard !isMuted else { return }
        currentPlayer?.setVolume(1.0, fadeDuration: 0.8)
    }

    enum Track { case home, gameplay }

    // MARK: - Private

    private func configureAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    private func loadPlayer(named name: String) -> AVAudioPlayer? {
        for ext in Self.audioExtensions {
            if let url = Bundle.main.url(forResource: name, withExtension: ext),
               let player = try? AVAudioPlayer(contentsOf: url) {
                player.numberOfLoops = -1
                player.volume = 0
                player.prepareToPlay()
                return player
            }
        }
        return nil
    }

    private func crossfade(to inPlayer: AVAudioPlayer?) {
        guard inPlayer !== currentPlayer else { return }
        fadeTimer?.invalidate()

        let outPlayer = currentPlayer
        currentPlayer = inPlayer

        inPlayer?.volume = 0
        inPlayer?.play()

        var step = 0
        fadeTimer = Timer.scheduledTimer(withTimeInterval: Self.stepInterval, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            step += 1
            let fraction = Float(step) / Float(Self.fadeSteps)
            inPlayer?.volume = isMuted ? 0 : fraction
            outPlayer?.volume = isMuted ? 0 : (1.0 - fraction)
            if step >= Self.fadeSteps {
                timer.invalidate()
                self.fadeTimer = nil
                outPlayer?.stop()
                outPlayer?.volume = 1.0  // reset for next use
            }
        }
    }
}

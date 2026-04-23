import AVFoundation

@Observable
final class SoundManager {
    static let shared = SoundManager()
    var isEnabled: Bool = true
    var selectedBGM: String = DataStore.loadSelectedBGM()

    static let bgmList: [(name: String, label: String, isLocked: Bool)] = [
        ("bgm_battle",    NSLocalizedString("model_bgm_battle", comment: ""),    false),
        ("bgm_glimmer_0", NSLocalizedString("model_bgm_glimmer_0", comment: ""), false),
        ("bgm_glimmer_1", NSLocalizedString("model_bgm_glimmer_1", comment: ""), false),
        ("bgm_glimmer_2", NSLocalizedString("model_bgm_glimmer_2", comment: ""), false),
        ("bgm_glimmer_3", NSLocalizedString("model_bgm_glimmer_3", comment: ""), false),
        ("bgm_locked_1",  "???", true),
        ("bgm_locked_2",  "???", true),
        ("bgm_locked_3",  "???", true),
    ]

    // MARK: - SFX (AVAudioPlayer)

    private var sfx: [String: AVAudioPlayer] = [:]

    // MARK: - BGM (AVAudioPlayer)

    private var bgmPlayer: AVAudioPlayer?
    private let bgmVolume: Float = 0.2
    private var fadeTimer: Timer?

    // MARK: - Init

    private init() {
        isEnabled = DataStore.loadPlayerData().soundEnabled

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, options: .mixWithOthers)
        try? session.setActive(true)

        // SFX の読み込み（m4a優先、wavフォールバック）
        let sfxFiles = ["sfx_correct1", "sfx_correct2", "sfx_correct3",
                        "sfx_correct4", "sfx_correct5",
                        "sfx_defeat", "sfx_wrong",
                        "sfx_combo", "sfx_boss_appear", "sfx_levelup",
                        "sfx_tap1", "sfx_tap2", "sfx_result",
                        "Boom", "Pickup", "sfx_boss_victory"]
        for name in sfxFiles {
            let url = Bundle.main.url(forResource: name, withExtension: "m4a")
                   ?? Bundle.main.url(forResource: name, withExtension: "wav")
            if let url {
                sfx[name] = try? AVAudioPlayer(contentsOf: url)
                sfx[name]?.prepareToPlay()
                if name == "sfx_defeat" || name.hasPrefix("sfx_correct") {
                    sfx[name]?.volume = 1.0
                } else {
                    sfx[name]?.volume = 0.8
                }
            }
        }
    }

    // MARK: - BGM Public API

    func playBGM(_ name: String, loop: Bool = true) {
        guard isEnabled else { return }
        stopBGMInternal()
        guard let url = Bundle.main.url(forResource: name, withExtension: "m4a")
                      ?? Bundle.main.url(forResource: name, withExtension: "wav") else { return }
        bgmPlayer = try? AVAudioPlayer(contentsOf: url)
        bgmPlayer?.numberOfLoops = loop ? -1 : 0
        bgmPlayer?.volume = bgmVolume
        bgmPlayer?.prepareToPlay()
        bgmPlayer?.play()
    }

    func playBGMTitle()  { playBGM("bgm_glimmer_0") }
    func playBGMBattle(override: String? = nil) {
        playBGM(override ?? selectedBGM)
        // バトル中はBGMを控えめに（正解SEとのコントラスト強化）
        bgmPlayer?.volume = bgmVolume * 0.5
    }

    /// まちがいおにバトル用BGM（2曲ランダム）
    func playBGMMistakeBoss() {
        let tracks = ["bgm_mistake_boss_1", "bgm_mistake_boss_2"]
        playBGM(tracks.randomElement()!)
    }

    func selectBGM(_ name: String) {
        print("✅ [SoundManager] selectBGM -> \(name)")
        selectedBGM = name
        DataStore.saveSelectedBGM(name)
        if bgmPlayer?.isPlaying == true { playBGM(name) }
    }

    func previewBGM(_ name: String) {
        stopBGMInternal()
        guard let url = Bundle.main.url(forResource: name, withExtension: "m4a")
                      ?? Bundle.main.url(forResource: name, withExtension: "wav") else { return }
        bgmPlayer = try? AVAudioPlayer(contentsOf: url)
        bgmPlayer?.numberOfLoops = 0
        bgmPlayer?.volume = bgmVolume
        bgmPlayer?.prepareToPlay()
        bgmPlayer?.play()
    }

    func stopBGM() {
        stopBGMInternal()
        bgmPlayer = nil
    }

    private func stopBGMInternal() {
        fadeTimer?.invalidate()
        fadeTimer = nil
        bgmPlayer?.stop()
    }

    func fadeBGM(duration: Double = 1.0) {
        guard let player = bgmPlayer else { return }
        let steps = 20
        let interval = duration / Double(steps)
        let volumeStep = bgmVolume / Float(steps)
        var currentStep = 0

        fadeTimer?.invalidate()
        fadeTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            currentStep += 1
            let newVolume = self.bgmVolume - volumeStep * Float(currentStep)
            player.volume = max(0, newVolume)
            if currentStep >= steps {
                timer.invalidate()
                self.fadeTimer = nil
                self.stopBGM()
            }
        }
    }

    /// BGMを一時的にフェードアウト（停止はしない・resumeBGMで復帰）
    func fadeOutBGM(duration: Double = 1.0) {
        bgmPlayer?.setVolume(0, fadeDuration: duration)
    }

    /// フェードアウトしたBGMを元の音量に復帰
    func resumeBGM() {
        bgmPlayer?.setVolume(bgmVolume, fadeDuration: 0.5)
    }

    // MARK: - BGM Rate (no-op: AVAudioPlayerではレート変更しない)

    func updateBGMRate(forCombo combo: Int) {}
    func resetBGMRate() {}

    // MARK: - SFX

    func playCorrect() {
        let n = Int.random(in: 1...5)
        play("sfx_correct\(n)")
    }
    func playIncorrect()  { play("sfx_wrong") }
    func playDefeat()     { play("sfx_defeat") }
    func playCombo()      { play("sfx_combo") }
    func playBossAppear() { play("sfx_boss_appear") }
    func playLevelUp()    { play("sfx_levelup") }
    func playGameOver()   { play("sfx_defeat") }
    func playTap() {
        let n = Int.random(in: 1...2)
        play("sfx_tap\(n)")
    }
    func playResult()     { play("sfx_result") }
    func playRockBreak()    { play("Boom") }
    func playDiamond()      { play("Pickup") }
    func playBossVictory()  { play("sfx_boss_victory") }

    private func play(_ name: String) {
        guard isEnabled else { return }
        sfx[name]?.currentTime = 0
        sfx[name]?.play()
    }

    /// 音量を指定して再生（0.0〜1.0）
    func play(_ name: String, volume: Float) {
        guard isEnabled else { return }
        let original = sfx[name]?.volume ?? 0.8
        sfx[name]?.volume = volume
        sfx[name]?.currentTime = 0
        sfx[name]?.play()
        // 再生後に元の音量に戻す
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.sfx[name]?.volume = original
        }
    }

    // MARK: - おうえんボイス

    private var voicePlayer: AVAudioPlayer?

    /// 録音済みボイスからランダムに1つ再生
    func playParentVoice() {
        guard isEnabled else { return }
        let count = DataStore.parentVoiceCount()
        guard count > 0 else { return }
        let index = Int.random(in: 0..<count)
        let url = DataStore.parentVoiceURL(index: index)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        voicePlayer = try? AVAudioPlayer(contentsOf: url)
        voicePlayer?.volume = 1.0
        voicePlayer?.prepareToPlay()
        voicePlayer?.play()
    }

    // MARK: - Toggle

    func toggle() {
        isEnabled.toggle()
        if !isEnabled {
            bgmPlayer?.pause()
        } else {
            if bgmPlayer != nil {
                bgmPlayer?.play()
            } else {
                playBGM(selectedBGM)
            }
        }
        var p = DataStore.loadPlayerData()
        p.soundEnabled = isEnabled
        DataStore.savePlayerData(p)
    }
}

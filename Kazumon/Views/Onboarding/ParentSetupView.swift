import SwiftUI
import AVFoundation

/// 初回起動時の親向け設定画面（年齢選択 + 名前入力を統合）
struct ParentSetupView: View {
    let onComplete: () -> Void

    enum SetupStep: Int {
        case intro, ageSelect, nameInput, voiceRecord, complete
    }

    @State private var step: SetupStep = .intro
    @State private var selectedAge: AgeGroup? = nil
    @State private var selectedColor: Int = DataStore.loadProfiles().count
    @State private var name = NSLocalizedString("default_player_name", comment: "")
    @State private var charBounce: CGFloat = 0
    @State private var charPopScale: CGFloat = 0
    @State private var showFlash = false
    @State private var pulseScale: CGFloat = 1.0
    @FocusState private var nameFocused: Bool
    @State private var isRecording = false
    @State private var hasRecorded = false
    @State private var recorder: AVAudioRecorder?
    @State private var player: AVAudioPlayer?
    @State private var recordPulse: CGFloat = 1.0

    private let maxNameLength = 8

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                // 戻るボタン
                if step != .intro {
                    HStack {
                        Button {
                            HapticsManager.tap()
                            withAnimation(.easeInOut(duration: 0.35)) {
                                step = SetupStep(rawValue: step.rawValue - 1) ?? .intro
                            }
                        } label: {
                            Text("older_back_button")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }

                Spacer()

                // ステップコンテンツ
                Group {
                    switch step {
                    case .intro: introContent
                    case .ageSelect: ageSelectContent
                    case .nameInput: nameInputContent
                    case .voiceRecord: voiceRecordContent
                    case .complete: completeContent
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

                Spacer()
                Spacer()
            }

            // 白フラッシュ
            Color.white.ignoresSafeArea()
                .opacity(showFlash ? 1 : 0)
                .allowsHitTesting(false)
        }
        .animation(.easeInOut(duration: 0.35), value: step)
    }

    // MARK: - STEP 1: 保護者への説明

    private var introContent: some View {
        VStack(spacing: 24) {
            KennyCharacterView(
                appearance: CharacterAppearanceFactory.appearance(for: 1),
                size: 120
            )
            .allowsHitTesting(false)
            .offset(y: charBounce)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    charBounce = -6
                }
            }

            Text("setup_intro_title")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)

            Text("setup_intro_body")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 32)

            Button {
                HapticsManager.tap()
                AnalyticsManager.logSetupStart()
                withAnimation { step = .ageSelect }
            } label: {
                Text("setup_intro_button")
                    .font(.zenMaru(22, weight: .black))
                    .foregroundColor(.white)
                    .frame(width: 220, height: 60)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color.green))
                    .shadow(color: .green.opacity(0.4), radius: 8, y: 4)
                    .scaleEffect(pulseScale)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(0.3)) {
                    pulseScale = 1.05
                }
            }
        }
    }

    // MARK: - STEP 2: 年齢選択

    private var ageSelectContent: some View {
        VStack(spacing: 20) {
            Text("setup_age_title")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)

            VStack(spacing: 12) {
                ageButton(.young4, title: "setup_age_young4", sub: "setup_age_young4_sub", delay: 0)
                ageButton(.young, title: "setup_age_young", sub: "setup_age_young_sub", delay: 0.12)
                ageButton(.older, title: "setup_age_older", sub: "setup_age_older_sub", delay: 0.24)
            }
            .padding(.horizontal, 32)

            Text("setup_age_note")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private func ageButton(_ group: AgeGroup, title: String, sub: String, delay: Double) -> some View {
        Button {
            HapticsManager.tap()
            selectedAge = group
            AnalyticsManager.logAgeSelected(ageGroup: group.rawValue)
            print("🎮 [ParentSetup] ageButton tapped: \(group)")
            withAnimation { step = .nameInput }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(NSLocalizedString(title, comment: ""))
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.primary)
                    Text(NSLocalizedString(sub, comment: ""))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                Spacer()
                KennyCharacterView(
                    appearance: CharacterAppearanceFactory.appearance(for: group.characterLevel),
                    size: 40
                )
                .allowsHitTesting(false)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1.5))
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - STEP 3: 名前入力

    private var nameInputContent: some View {
        VStack(spacing: 24) {
            Text("setup_name_title")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)

            TextField(
                NSLocalizedString("setup_name_placeholder", comment: ""),
                text: $name
            )
            .font(.zenMaru(24, weight: .bold))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .focused($nameFocused)
            .onChange(of: name) { _, v in
                if v.count > maxNameLength { name = String(v.prefix(maxNameLength)) }
            }
            .padding(.horizontal, 40)
            .onAppear { nameFocused = true }

            Button {
                HapticsManager.tap()
                nameFocused = false
                withAnimation { step = .voiceRecord }
            } label: {
                Text("setup_name_button")
                    .font(.zenMaru(20, weight: .black))
                    .foregroundColor(.white)
                    .frame(width: 200, height: 56)
                    .background(RoundedRectangle(cornerRadius: 16)
                        .fill(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.green))
                    .shadow(color: .green.opacity(0.3), radius: 6, y: 3)
            }
            .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    // MARK: - STEP 3.5: おうえんボイス録音

    private var voiceRecordContent: some View {
        VStack(spacing: 24) {
            Text("🎤")
                .font(.system(size: 56))

            Text(NSLocalizedString("setup_voice_title", comment: ""))
                .font(.zenMaru(20, weight: .black))
                .multilineTextAlignment(.center)

            Text(NSLocalizedString("setup_voice_desc", comment: ""))
                .font(.zenMaru(14, weight: .bold))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                HapticsManager.tap(); SoundManager.shared.playTap()
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(isRecording ? Color.red : Color.orange)
                        .frame(width: 80, height: 80)
                        .scaleEffect(recordPulse)
                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)
                }
            }

            if hasRecorded {
                Button {
                    playRecording()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                        Text(NSLocalizedString("setup_voice_play", comment: ""))
                            .font(.zenMaru(14, weight: .bold))
                    }
                    .foregroundColor(.blue)
                }
            }

            Text(NSLocalizedString("setup_voice_hint", comment: ""))
                .font(.zenMaru(11, weight: .regular))
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                Button {
                    HapticsManager.tap(); SoundManager.shared.playTap()
                    withAnimation { step = .complete }
                } label: {
                    Text(NSLocalizedString("setup_voice_skip", comment: ""))
                        .font(.zenMaru(16, weight: .bold))
                        .foregroundColor(.secondary)
                }

                if hasRecorded {
                    Button {
                        HapticsManager.tap(); SoundManager.shared.playTap()
                        withAnimation { step = .complete }
                    } label: {
                        Text(NSLocalizedString("setup_voice_done", comment: ""))
                            .font(.zenMaru(18, weight: .black))
                            .foregroundColor(.white)
                            .frame(width: 160, height: 50)
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color.green))
                            .shadow(color: .green.opacity(0.3), radius: 6, y: 3)
                    }
                }
            }
        }
    }

    private func startRecording() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default)
        try? session.setActive(true)

        let url = DataStore.parentVoiceURL(index: 0)
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        recorder = try? AVAudioRecorder(url: url, settings: settings)
        recorder?.record(forDuration: 3.0)
        isRecording = true
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            recordPulse = 1.15
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if isRecording { stopRecording() }
        }
    }

    private func stopRecording() {
        recorder?.stop()
        recorder = nil
        isRecording = false
        hasRecorded = true
        withAnimation { recordPulse = 1.0 }
    }

    private func playRecording() {
        let url = DataStore.parentVoiceURL(index: 0)
        player = try? AVAudioPlayer(contentsOf: url)
        player?.play()
    }

    // MARK: - STEP 4: 設定完了

    private var completeContent: some View {
        VStack(spacing: 20) {
            KennyCharacterView(
                appearance: CharacterAppearanceFactory.appearance(for: 1),
                size: 120
            )
            .allowsHitTesting(false)
            .scaleEffect(charPopScale)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.4)) {
                    charPopScale = 1.0
                }
            }

            Text(String(format: NSLocalizedString("setup_complete_title", comment: ""),
                         DataStore.loadPlayerData().playerName))
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            Text("setup_complete_sub")
                .font(.system(size: 16))
                .foregroundColor(.secondary)

            Button {
                HapticsManager.tap()
                showFlash = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.easeOut(duration: 0.2)) { showFlash = false }
                }
                // プロフィール作成 → activeId変更 → データ再保存
                let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                let finalName = trimmedName.isEmpty ? NSLocalizedString("default_player_name", comment: "") : trimmedName
                let age = selectedAge ?? .young
                print("🎮 [ParentSetup] selectedAge=\(String(describing: selectedAge)) → age=\(age)")
                let profile = PlayerProfile.newProfile(
                    name: finalName,
                    ageGroup: age,
                    colorIndex: selectedColor
                )
                DataStore.addProfile(profile)
                // 新しいactiveProfileIdでデータを再保存
                DataStore.saveAgeGroup(age)
                DataStore.savePlayerName(finalName)
                if age == .young4 {
                    DataStore.saveBeforeTestResult(score: 0, total: 0, level: 1)
                }
                DataStore.markSetupComplete()
                AnalyticsManager.logSetupComplete(ageGroup: age.rawValue)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onComplete()
                }
            } label: {
                Text("setup_complete_button")
                    .font(.zenMaru(22, weight: .black))
                    .foregroundColor(.white)
                    .frame(width: 260, height: 64)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color.green))
                    .shadow(color: .green.opacity(0.4), radius: 8, y: 4)
                    .scaleEffect(pulseScale)
            }
        }
    }
}

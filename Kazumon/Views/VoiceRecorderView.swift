import SwiftUI
import AVFoundation

struct VoiceRecorderView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var recorder: AVAudioRecorder?
    @State private var player: AVAudioPlayer?
    @State private var isRecording = false
    @State private var recordingSlot: Int = -1  // 録音中のスロット
    @State private var isPlaying = false
    @State private var playingSlot: Int = -1
    @State private var recordingTime: Double = 0
    @State private var timer: Timer?
    @State private var showPermissionAlert = false
    @State private var blink = false
    @State private var slotExists: [Bool] = [false, false, false]

    private let maxDuration: Double = 3.0
    private let slotCount = 3

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()

                Text("voice_recorder_title")
                    .font(.zenMaru(20, weight: .black))
                    .foregroundStyle(.primary)

                Text("voice_recorder_desc_combo")
                    .font(.zenMaru(14, weight: .bold))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                // 3スロット
                ForEach(0..<slotCount, id: \.self) { i in
                    slotRow(index: i)
                }

                Spacer()

                // 全削除
                if slotExists.contains(true) {
                    Button {
                        HapticsManager.tap()
                        DataStore.deleteAllParentVoices()
                        refreshSlots()
                    } label: {
                        Text("voice_recorder_delete_all")
                            .font(.zenMaru(14, weight: .bold))
                            .foregroundColor(.red.opacity(0.7))
                    }
                }

                Spacer().frame(height: 30)
            }
            .navigationTitle(NSLocalizedString("voice_recorder_nav_title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("view_title_bgm_close", comment: "")) {
                        stopRecording()
                        player?.stop()
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            DataStore.migrateParentVoiceIfNeeded()
            refreshSlots()
        }
        .onDisappear {
            timer?.invalidate()
            recorder?.stop()
            player?.stop()
        }
        .alert("voice_recorder_permission_title", isPresented: $showPermissionAlert) {
            Button("voice_recorder_permission_settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("common_ok", role: .cancel) {}
        } message: {
            Text("voice_recorder_permission_message")
        }
    }

    // MARK: - スロット行

    @ViewBuilder
    private func slotRow(index: Int) -> some View {
        HStack(spacing: 12) {
            // スロット番号
            Text("\(index + 1)")
                .font(.zenMaru(18, weight: .black))
                .foregroundStyle(.secondary)
                .frame(width: 30)

            if isRecording && recordingSlot == index {
                // 録音中
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                        .opacity(blink ? 0.3 : 1.0)
                    Text(String(format: "%.1f / %.1f", recordingTime, maxDuration))
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(.red)
                    Spacer()
                    Button {
                        HapticsManager.tap()
                        stopRecording()
                    } label: {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.red)
                            .frame(width: 44, height: 44)
                    }
                }
            } else if slotExists[index] {
                // 録音済み
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("voice_recorder_done")
                        .font(.zenMaru(14, weight: .bold))
                        .foregroundStyle(.primary)
                    Spacer()
                    // 再生
                    Button {
                        HapticsManager.tap()
                        playSlot(index)
                    } label: {
                        Image(systemName: playingSlot == index ? "speaker.wave.2.fill" : "play.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.blue)
                            .frame(width: 44, height: 44)
                    }
                    // 再録音
                    Button {
                        HapticsManager.tap()
                        requestAndRecord(slot: index)
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 16))
                            .foregroundColor(.orange)
                            .frame(width: 44, height: 44)
                    }
                }
            } else {
                // 未録音
                Button {
                    HapticsManager.tap()
                    requestAndRecord(slot: index)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "mic.fill")
                            .foregroundColor(.white)
                        Text("voice_recorder_tap")
                            .font(.zenMaru(14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity).frame(height: 44)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.blue))
                }
            }
        }
        .padding(.horizontal, 24)
        .frame(height: 50)
    }

    // MARK: - 録音

    private func requestAndRecord(slot: Int) {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            startRecording(slot: slot)
        case .denied:
            showPermissionAlert = true
        case .undetermined:
            AVAudioApplication.requestRecordPermission { granted in
                if granted { startRecording(slot: slot) }
            }
        @unknown default:
            break
        }
    }

    private func startRecording(slot: Int) {
        player?.stop()
        let url = DataStore.parentVoiceURL(index: slot)
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try session.setActive(true)

            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.record()
            isRecording = true
            recordingSlot = slot
            recordingTime = 0

            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                recordingTime += 0.1
                if recordingTime >= maxDuration {
                    stopRecording()
                }
            }

            withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                blink = true
            }
        } catch {
            print("Recording failed: \(error)")
        }
    }

    private func stopRecording() {
        guard isRecording else { return }
        let slot = recordingSlot
        recorder?.stop()
        recorder = nil
        isRecording = false
        recordingSlot = -1
        timer?.invalidate()
        timer = nil
        blink = false

        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
        try? AVAudioSession.sharedInstance().setActive(true)

        refreshSlots()

        // スロット数を更新
        let count = (0..<slotCount).filter { slotExists[$0] }.count
        DataStore.setParentVoiceCount(count)
    }

    // MARK: - 再生

    private func playSlot(_ index: Int) {
        let url = DataStore.parentVoiceURL(index: index)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        player?.stop()
        player = try? AVAudioPlayer(contentsOf: url)
        player?.volume = 1.0
        player?.play()
        playingSlot = index
        let duration = player?.duration ?? 3.0
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.1) {
            playingSlot = -1
        }
    }

    // MARK: - ユーティリティ

    private func refreshSlots() {
        for i in 0..<slotCount {
            slotExists[i] = FileManager.default.fileExists(atPath: DataStore.parentVoiceURL(index: i).path)
        }
    }
}

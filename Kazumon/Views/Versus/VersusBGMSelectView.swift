import SwiftUI

/// 対戦前のBGM選択画面
struct VersusBGMSelectView: View {
    let onSelect: (String) -> Void
    let onBack: () -> Void

    @State private var selectedBGM: String = "bgm_versus_1"
    @State private var showContent = false

    private let tracks: [(id: String, label: String)] = [
        ("bgm_versus_1", NSLocalizedString("versus_bgm_1", comment: "")),
        ("bgm_versus_2", NSLocalizedString("versus_bgm_2", comment: "")),
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.45, green: 0.40, blue: 0.80),
                    Color(red: 0.30, green: 0.25, blue: 0.65)
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                // 戻るボタン
                HStack {
                    Button {
                        HapticsManager.tap()
                        SoundManager.shared.stopBGM()
                        onBack()
                    } label: {
                        Text("older_back_button")
                            .font(.zenMaru(14, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Spacer()

                Text("versus_bgm_title")
                    .font(.zenMaru(24, weight: .black))
                    .foregroundStyle(.white)

                // ステップインジケーター（● ●）
                HStack(spacing: 16) {
                    ForEach(0..<2, id: \.self) { i in
                        Circle()
                            .fill(i <= 1 ? Color.white : Color.white.opacity(0.3))
                            .frame(width: i == 1 ? 14 : 10, height: i == 1 ? 14 : 10)
                            .shadow(color: i == 1 ? .white.opacity(0.6) : .clear, radius: 4)
                    }
                }
                .padding(.top, 4).padding(.bottom, 4)

                Text("versus_bgm_subtitle")
                    .font(.zenMaru(14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.6))

                // BGM選択カード
                VStack(spacing: 14) {
                    ForEach(tracks, id: \.id) { track in
                        Button {
                            HapticsManager.tap()
                            selectedBGM = track.id
                            SoundManager.shared.previewBGM(track.id)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: selectedBGM == track.id ? "music.note" : "music.note")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(selectedBGM == track.id ? .yellow : .white.opacity(0.5))
                                    .frame(width: 32)

                                Text(track.label)
                                    .font(.zenMaru(18, weight: .bold))
                                    .foregroundStyle(selectedBGM == track.id ? .white : .white.opacity(0.6))

                                Spacer()

                                if selectedBGM == track.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundStyle(.yellow)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(selectedBGM == track.id
                                        ? Color.white.opacity(0.15)
                                        : Color.white.opacity(0.05))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(selectedBGM == track.id ? Color.yellow : Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                // 開始ボタン
                Button {
                    HapticsManager.tap()
                    SoundManager.shared.stopBGM()
                    onSelect(selectedBGM)
                } label: {
                    Text("versus_bgm_start")
                        .font(.zenMaru(22, weight: .black))
                        .foregroundColor(.white)
                        .frame(width: 260, height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(red: 0.50, green: 0.47, blue: 0.87))
                        )
                        .shadow(color: Color(red: 0.50, green: 0.47, blue: 0.87).opacity(0.5), radius: 8, y: 4)
                }

                Spacer().frame(height: 50)
            }
            .opacity(showContent ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) { showContent = true }
            // デフォルトBGMをプレビュー
            SoundManager.shared.previewBGM(selectedBGM)
        }
    }
}

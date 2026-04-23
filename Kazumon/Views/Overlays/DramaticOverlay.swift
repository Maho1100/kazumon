import SwiftUI

// MARK: - 汎用インパクト演出オーバーレイ
//
// ボス登場・レベルアップ・勝利など、
// 一時的なインパクト演出に再利用できる。
//
// 演出シーケンス:
//   0.0s  背景暗転 + フラッシュ開始
//   0.2s  フラッシュ消滅
//   0.1s  テキスト拡大開始 (0.3x → 1.1x)
//   0.4s  テキスト安定 (1.1x → 1.0x)
//   1.0s  全体フェードアウト開始
//   1.5s  完全に消滅
//
// 使い方:
//   DramaticOverlay(
//       message: "ボスとうじょう！",
//       subMessage: "ボスゴブリン",
//       flashColor: .red,
//       glowColor: .red
//   )

struct DramaticOverlay: View {

    // MARK: - パラメータ（呼び出し側で調整可能）

    /// メインテキスト（例: "ボスとうじょう！"）
    let message: String

    /// サブテキスト（例: モンスター名。nil なら非表示）
    var subMessage: String? = nil

    /// フラッシュの色
    var flashColor: Color = .red

    /// テキストの発光色
    var glowColor: Color = .red

    /// 演出全体の長さ（秒）
    var totalDuration: Double = 1.5

    // MARK: - 内部アニメーション状態

    @State private var flashOpacity: Double = 0
    @State private var bgOpacity: Double = 0
    @State private var textScale: CGFloat = 0.3
    @State private var textOpacity: Double = 0
    @State private var wholeOpacity: Double = 1.0

    var body: some View {
        ZStack {
            // ── 背景暗転 ──
            Color.black.opacity(bgOpacity * 0.6)
                .ignoresSafeArea()

            // ── 赤フラッシュ ──
            flashColor.opacity(flashOpacity * 0.35)
                .ignoresSafeArea()

            // ── テキスト演出 ──
            VStack(spacing: 12) {
                // メインメッセージ
                Text(message)
                    .font(.zenMaru(36, weight: .black))
                    .foregroundColor(.white)
                    // 発光感: 多重シャドウ
                    .shadow(color: glowColor.opacity(0.9), radius: 20)
                    .shadow(color: glowColor.opacity(0.6), radius: 40)
                    .shadow(color: .black.opacity(0.5), radius: 4, y: 2)

                // サブメッセージ
                if let sub = subMessage {
                    Text(sub)
                        .font(.zenMaru(20, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                        .shadow(color: .black.opacity(0.4), radius: 4, y: 2)
                }
            }
            .scaleEffect(textScale)
            .opacity(textOpacity)
        }
        .opacity(wholeOpacity)
        .onAppear { runSequence() }
    }

    // MARK: - 演出シーケンス

    private func runSequence() {
        // 0.0s: 背景暗転 + フラッシュ点灯
        withAnimation(.easeOut(duration: 0.15)) {
            bgOpacity = 1.0
            flashOpacity = 1.0
        }

        // 0.2s: フラッシュ消滅
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeOut(duration: 0.2)) {
                flashOpacity = 0
            }
        }

        // 0.1s: テキスト拡大 (0.3x → 1.1x)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                textScale = 1.1
                textOpacity = 1.0
            }
        }

        // 0.4s: テキスト安定 (1.1x → 1.0x)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.15)) {
                textScale = 1.0
            }
        }

        // 1.0s: 全体フェードアウト
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration - 0.5) {
            withAnimation(.easeIn(duration: 0.5)) {
                wholeOpacity = 0
            }
        }
    }
}

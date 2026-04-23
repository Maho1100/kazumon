import SwiftUI

/// WEB版準拠のレベルアップ演出
/// 半透明黒背景 + 金色テキストのバウンドアニメーション → 約1.5秒で自動クローズ
struct LevelUpOverlayView: View {
    let newLevel: Int
    let onDismiss: () -> Void

    private let goldColor = Color(red: 0.93, green: 0.79, blue: 0.30)

    // アニメーション状態
    @State private var phase = 0        // 0→1→2→3→4 の5段階
    @State private var overlayOpacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.5 * overlayOpacity)
                .ignoresSafeArea()

            Text(String(format: NSLocalizedString("view_overlay_level_up", comment: ""), newLevel))
                .font(.zenMaru(32, weight: .black))
                .foregroundColor(goldColor)
                .shadow(color: goldColor.opacity(0.8), radius: 12)
                .shadow(color: goldColor.opacity(0.5), radius: 24)
                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                .scaleEffect(currentScale)
                .offset(y: currentOffsetY)
                .opacity(currentOpacity)
        }
        .onAppear {
            HapticsManager.correct()
            runAnimation()
        }
    }

    // MARK: - 各フェーズの値

    private var currentScale: CGFloat {
        switch phase {
        case 0: return 0.3    // 開始: 小さい
        case 1: return 1.2    // 大きく跳ねる
        case 2: return 0.95   // 少し縮む
        case 3: return 1.05   // 軽くもう一回跳ねる
        default: return 1.0   // 自然に収まる
        }
    }

    private var currentOffsetY: CGFloat {
        switch phase {
        case 0: return 20
        case 1: return -10
        case 2: return 0
        case 3: return -5
        default: return 0
        }
    }

    private var currentOpacity: Double {
        phase == 0 ? 0 : 1
    }

    // MARK: - アニメーション実行

    private func runAnimation() {
        // phase 0 → 1: 小さく下から → 大きく跳ねる (0.25s)
        withAnimation(.easeOut(duration: 0.25)) {
            phase = 1
            overlayOpacity = 1
        }

        // phase 1 → 2: 少し縮む (0.15s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeInOut(duration: 0.15)) {
                phase = 2
            }
        }

        // phase 2 → 3: 軽くもう一回跳ねる (0.15s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.40) {
            withAnimation(.easeInOut(duration: 0.15)) {
                phase = 3
            }
        }

        // phase 3 → 4: 自然に収まる (0.2s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            withAnimation(.easeInOut(duration: 0.2)) {
                phase = 4
            }
        }

        // 1.5秒後にフェードアウトして閉じる
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.25)) {
                overlayOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                onDismiss()
            }
        }
    }
}

import SwiftUI

/// まちがいおにフルスクリーン登場演出
struct MistakeOniAppearView: View {
    let onFight: () -> Void

    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var showButton = false
    @State private var bgOpacity: Double = 0

    var body: some View {
        ZStack {
            // 完全な黒背景
            Color.black
                .ignoresSafeArea()
                .opacity(bgOpacity)

            VStack(spacing: 32) {
                Spacer()

                // 「まってたぞ…」
                Text("mistake_boss_entrance_title")
                    .font(.zenMaru(40, weight: .black))
                    .foregroundStyle(.white)
                    .opacity(showTitle ? 1 : 0)

                // 「にがてもんだいに ちょうせんしろ」
                Text("mistake_boss_entrance_subtitle")
                    .font(.zenMaru(20, weight: .bold))
                    .foregroundStyle(.white.opacity(0.8))
                    .opacity(showSubtitle ? 1 : 0)

                Spacer()

                // 「たたかう」ボタン
                Button {
                    HapticsManager.tap()
                    onFight()
                } label: {
                    Text("mistake_boss_fight_button")
                        .font(.zenMaru(24, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 200, height: 56)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white, lineWidth: 2)
                        )
                }
                .opacity(showButton ? 1 : 0)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            // BGMフェードアウト → ボスBGM開始
            SoundManager.shared.fadeOutBGM(duration: 0.8)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                SoundManager.shared.playBGM("bgm_mistake_boss")
            }

            // アニメーションシーケンス
            withAnimation(.easeIn(duration: 0.8)) {
                bgOpacity = 1
            }
            withAnimation(.easeIn(duration: 0.5).delay(0.8)) {
                showTitle = true
            }
            withAnimation(.easeIn(duration: 0.5).delay(2.8)) {
                showSubtitle = true
            }
            withAnimation(.easeIn(duration: 0.5).delay(3.8)) {
                showButton = true
            }
        }
    }
}

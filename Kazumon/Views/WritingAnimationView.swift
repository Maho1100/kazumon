import SwiftUI

/// ちょうせんじょうを書く演出（1.5秒・自動進行）
struct WritingAnimationView: View {
    let recipient: FamilyMember
    let monster: MonsterChoice
    let difficulty: Difficulty
    let problemType: ProblemType
    let onComplete: () -> Void

    @State private var letterIn = false
    @State private var charIn = false
    @State private var titleAppear = false
    @State private var monsterAppear = false
    @State private var difficultyAppear = false
    @State private var stampAppear = false
    @State private var penAngle: Double = -10
    @State private var penOffset: CGFloat = -60

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.65, green: 0.85, blue: 1.00),
                    Color(red: 0.85, green: 0.92, blue: 1.00),
                    Color(red: 1.00, green: 0.92, blue: 0.85)
                ],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            VStack(spacing: 12) {
                Spacer()

                Text(NSLocalizedString("writing_text", comment: ""))
                    .font(.zenMaru(18, weight: .black))
                    .foregroundColor(Color(red: 0.30, green: 0.20, blue: 0.15))
                    .opacity(charIn ? 1 : 0)

                ZStack {
                    // 手紙
                    Image("letter_paper")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 280, height: 380)

                    // 内容（順次フェードイン）
                    VStack(spacing: 10) {
                        Spacer().frame(height: 30)
                        Text(String(format: NSLocalizedString("writing_recipient", comment: ""), recipient.label))
                            .font(.zenMaru(20, weight: .black))
                            .foregroundColor(Color(red: 0.30, green: 0.20, blue: 0.15))
                            .opacity(titleAppear ? 1 : 0)

                        Image(monster.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .opacity(monsterAppear ? 1 : 0)
                            .scaleEffect(monsterAppear ? 1 : 0.3)

                        HStack(spacing: 4) {
                            ForEach(0..<difficulty.starCount, id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.orange)
                            }
                        }
                        .opacity(difficultyAppear ? 1 : 0)

                        Text(problemType == .addition
                             ? NSLocalizedString("versus_course_addition", comment: "")
                             : NSLocalizedString("versus_course_normal", comment: ""))
                            .font(.zenMaru(13, weight: .bold))
                            .foregroundColor(Color(red: 0.40, green: 0.30, blue: 0.25))
                            .opacity(difficultyAppear ? 1 : 0)

                        Spacer()
                    }
                    .frame(width: 240, height: 360)

                    // ちょうせんじょうハンコ
                    Image("stamp_quest")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(15))
                        .offset(x: 90, y: -150)
                        .scaleEffect(stampAppear ? 1 : 0)
                        .opacity(stampAppear ? 1 : 0)

                    // ペン
                    Image(systemName: "pencil.tip")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(Color(red: 0.85, green: 0.40, blue: 0.20))
                        .rotationEffect(.degrees(penAngle))
                        .offset(x: penOffset, y: -100)
                        .opacity(letterIn && !stampAppear ? 1 : 0)
                }
                .scaleEffect(letterIn ? 1 : 0.7)
                .opacity(letterIn ? 1 : 0)

                Spacer()
            }
        }
        .onAppear {
            // 手紙が登場
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                letterIn = true
                charIn = true
            }
            // ペンが書く動き
            withAnimation(.easeInOut(duration: 0.8).delay(0.3)) {
                penOffset = 60
                penAngle = 10
            }
            // 宛名が浮かぶ
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeIn(duration: 0.3)) { titleAppear = true }
            }
            // モンスターが浮かぶ
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { monsterAppear = true }
            }
            // 難易度が浮かぶ
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
                withAnimation(.easeIn(duration: 0.25)) { difficultyAppear = true }
            }
            // ハンコがポンッと押される
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) { stampAppear = true }
                HapticsManager.tap()
                SoundManager.shared.playTap()
            }
            // 自動進行
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.65) {
                onComplete()
            }
        }
    }
}

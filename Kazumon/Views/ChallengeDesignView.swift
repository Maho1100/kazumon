import SwiftUI

/// 「どんな ちょうせん？」挑戦内容設計画面
/// モンスター・難易度・問題タイプを子供が選んで挑戦状の中身を決める
struct ChallengeDesignView: View {
    let recipient: FamilyMember
    let onComplete: (MonsterChoice, Difficulty, ProblemType) -> Void
    let onBack: () -> Void

    @State private var selectedMonster: MonsterChoice = .slime
    @State private var selectedDifficulty: Difficulty = .normal
    @State private var selectedProblemType: ProblemType = .addition
    @State private var fadeIn: Double = 0
    @State private var donePressed = false

    var body: some View {
        ZStack {
            // 背景: パステル空グラデ
            LinearGradient(
                colors: [
                    Color(red: 0.65, green: 0.85, blue: 1.00),
                    Color(red: 0.85, green: 0.92, blue: 1.00),
                    Color(red: 1.00, green: 0.92, blue: 0.85)
                ],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            VStack(spacing: 14) {
                // ヘッダー
                HStack {
                    Button {
                        HapticsManager.tap()
                        onBack()
                    } label: {
                        Text(NSLocalizedString("battle_shop_back", comment: ""))
                            .font(.zenMaru(15, weight: .black))
                            .foregroundColor(Color(red: 0.30, green: 0.20, blue: 0.15))
                            .padding(.horizontal, 18).padding(.vertical, 6)
                            .background(Capsule().fill(Color.white.opacity(0.7)))
                    }
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.top, 12)

                // タイトル
                Text(NSLocalizedString("design_title", comment: ""))
                    .font(.zenMaru(22, weight: .black))
                    .foregroundColor(Color(red: 0.30, green: 0.20, blue: 0.15))
                    .shadow(color: .white.opacity(0.7), radius: 2, y: 0)

                ScrollView {
                    VStack(spacing: 16) {
                        // ① モンスター選択
                        sectionLabel(text: NSLocalizedString("design_monster", comment: ""))
                        monsterPicker

                        // ② 難易度
                        sectionLabel(text: NSLocalizedString("design_difficulty", comment: ""))
                        difficultyPicker

                        // ③ 問題タイプ
                        sectionLabel(text: NSLocalizedString("design_problem_type", comment: ""))
                        problemTypePicker

                        // プレビュー
                        previewCard
                            .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }

                // できた！ボタン
                Button {
                    HapticsManager.tap()
                    onComplete(selectedMonster, selectedDifficulty, selectedProblemType)
                } label: {
                    Text(NSLocalizedString("design_done_button", comment: ""))
                        .kazumonFixedButton(color: KazumonTheme.grass)
                }
                .scaleEffect(donePressed ? 0.93 : 1.0)
                .onLongPressGesture(minimumDuration: .infinity, pressing: { p in
                    withAnimation(.easeInOut(duration: 0.1)) { donePressed = p }
                }, perform: {})
                .padding(.bottom, 24)
            }
        }
        .opacity(fadeIn)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) { fadeIn = 1 }
        }
    }

    // MARK: - セクションラベル

    @ViewBuilder
    private func sectionLabel(text: String) -> some View {
        HStack {
            Text(text)
                .font(.zenMaru(14, weight: .black))
                .foregroundColor(Color(red: 0.30, green: 0.20, blue: 0.15))
                .padding(.horizontal, 14).padding(.vertical, 5)
                .background(Capsule().fill(Color.white.opacity(0.85)))
            Spacer()
        }
    }

    // MARK: - モンスター選択

    private var monsterPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(MonsterChoice.allCases) { choice in
                    Button {
                        HapticsManager.tap()
                        selectedMonster = choice
                    } label: {
                        VStack(spacing: 2) {
                            monsterIcon(for: choice, size: 56)
                            Text(choice.label)
                                .font(.zenMaru(11, weight: .black))
                                .foregroundColor(.white)
                            HStack(spacing: 1) {
                                ForEach(0..<choice.starCount, id: \.self) { _ in
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 7))
                                        .foregroundColor(.yellow)
                                }
                            }
                        }
                        .frame(width: 84, height: 110)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(selectedMonster == choice
                                      ? Color(red: 0.95, green: 0.55, blue: 0.30)
                                      : Color(red: 0.40, green: 0.50, blue: 0.65).opacity(0.7))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(selectedMonster == choice ? Color.yellow : Color.white.opacity(0.5),
                                        lineWidth: selectedMonster == choice ? 3 : 1.5)
                        )
                    }
                }
            }
        }
    }

    // MARK: - 難易度選択

    private var difficultyPicker: some View {
        HStack(spacing: 10) {
            ForEach(Difficulty.allCases, id: \.self) { diff in
                Button {
                    HapticsManager.tap()
                    selectedDifficulty = diff
                } label: {
                    VStack(spacing: 2) {
                        Text(diff.label)
                            .font(.zenMaru(13, weight: .black))
                            .foregroundColor(.white)
                        HStack(spacing: 1) {
                            ForEach(0..<diff.starCount, id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity).frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedDifficulty == diff
                                  ? Color(red: 0.95, green: 0.55, blue: 0.30)
                                  : Color(red: 0.40, green: 0.50, blue: 0.65).opacity(0.7))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedDifficulty == diff ? Color.yellow : Color.white.opacity(0.5),
                                    lineWidth: selectedDifficulty == diff ? 3 : 1.5)
                    )
                }
            }
        }
    }

    // MARK: - 問題タイプ選択

    private var problemTypePicker: some View {
        HStack(spacing: 10) {
            problemTypeButton(type: .addition, label: NSLocalizedString("versus_course_addition", comment: ""))
            problemTypeButton(type: .mixed, label: NSLocalizedString("versus_course_normal", comment: ""))
        }
    }

    @ViewBuilder
    private func problemTypeButton(type: ProblemType, label: String) -> some View {
        Button {
            HapticsManager.tap()
            selectedProblemType = type
        } label: {
            Text(label)
                .font(.zenMaru(15, weight: .black))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity).frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(selectedProblemType == type
                              ? Color(red: 0.95, green: 0.55, blue: 0.30)
                              : Color(red: 0.40, green: 0.50, blue: 0.65).opacity(0.7))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(selectedProblemType == type ? Color.yellow : Color.white.opacity(0.5),
                                lineWidth: selectedProblemType == type ? 3 : 1.5)
                )
        }
    }

    // MARK: - プレビューカード

    private var previewCard: some View {
        ZStack {
            Image("letter_paper")
                .resizable()
                .scaledToFit()
                .frame(height: 200)

            VStack(spacing: 6) {
                Text(String(format: NSLocalizedString("design_preview_title", comment: ""), recipient.label))
                    .font(.zenMaru(15, weight: .black))
                    .foregroundColor(Color(red: 0.30, green: 0.20, blue: 0.15))

                monsterIcon(for: selectedMonster, size: 60)

                HStack(spacing: 4) {
                    ForEach(0..<selectedDifficulty.starCount, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.orange)
                    }
                }

                Text(selectedProblemType == .addition
                     ? NSLocalizedString("versus_course_addition", comment: "")
                     : NSLocalizedString("versus_course_normal", comment: ""))
                    .font(.zenMaru(11, weight: .bold))
                    .foregroundColor(Color(red: 0.40, green: 0.30, blue: 0.25))

                Text(NSLocalizedString("design_preview_message", comment: ""))
                    .font(.zenMaru(10, weight: .bold))
                    .foregroundColor(Color(red: 0.40, green: 0.30, blue: 0.25))
                    .padding(.top, 2)
            }
            .frame(width: 160)
        }
    }

    /// モンスター選択アイコン（スライムは SlimeView、他はスプライトシートのKennyキャラ）
    @ViewBuilder
    private func monsterIcon(for choice: MonsterChoice, size: CGFloat) -> some View {
        if choice == .slime {
            SlimeView(color: SlimeView.palette[0], size: size)
                .allowsHitTesting(false)
        } else {
            KennyCharacterView(
                appearance: .forFloor(choice.bossFloor),
                size: size
            )
            .allowsHitTesting(false)
        }
    }
}

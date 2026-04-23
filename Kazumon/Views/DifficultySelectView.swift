import SwiftUI

struct DifficultySelectView: View {
    @Binding var selectedDifficulty: Difficulty
    @Binding var selectedProblemType: ProblemType
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("difficulty_select_title")
                .font(.zenMaru(18, weight: .bold))
                .padding(.top, 24)

            // 問題タイプ選択
            HStack(spacing: 8) {
                ForEach(ProblemType.allCases) { type in
                    Button {
                        HapticsManager.tap()
                        SoundManager.shared.playTap()
                        selectedProblemType = type
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: type.icon)
                                .font(.system(size: 18))
                            Text(type.label)
                                .font(.zenMaru(11, weight: .bold))
                        }
                        .foregroundColor(selectedProblemType == type ? .white : .white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedProblemType == type ? Color.orange : Color.white.opacity(0.15))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)

            ForEach(Difficulty.allCases, id: \.self) { diff in
                Button {
                    HapticsManager.tap()
                    SoundManager.shared.playTap()
                    selectedDifficulty = diff
                    DataStore.saveDifficulty(diff)
                    AnalyticsManager.logDifficultySelected(difficulty: diff.rawValue)
                    onStart()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: diff.icon)
                            .font(.system(size: 20))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(diff.label)
                                .font(.zenMaru(17, weight: .bold))
                            Text(String(format: NSLocalizedString("difficulty_goal_format", comment: ""), diff.goalFloor))
                                .font(.zenMaru(12, weight: .regular))
                                .opacity(0.7)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .opacity(0.4)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(diff.color)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

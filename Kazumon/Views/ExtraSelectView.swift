import SwiftUI

struct ExtraSelectView: View {
    @Bindable var extraVM: ExtraViewModel
    @Bindable var gameVM: GameViewModel

    private let bestFloor = DataStore.loadPlayerData().bestFloor

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.10, blue: 0.25),
                    Color(red: 0.08, green: 0.06, blue: 0.18)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                // Header
                HStack {
                    Button {
                        HapticsManager.tap()
                        SoundManager.shared.playTap()
                        gameVM.screen = .island
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)

                Text("extra_title")
                    .font(.zenMaru(28, weight: .black))
                    .foregroundColor(.yellow)
                    .shadow(color: .orange.opacity(0.6), radius: 8)

                Text("extra_subtitle")
                    .font(.zenMaru(14, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(ExtraBossStage.allStages) { stage in
                            stageCell(stage)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .padding(.top, 8)
        }
    }

    @ViewBuilder
    private func stageCell(_ stage: ExtraBossStage) -> some View {
        let unlocked = stage.isUnlocked(bestFloor: bestFloor)
        let monster = Monster.forFloor(stage.floor)

        HStack(spacing: 14) {
            // Boss emoji & name
            VStack(spacing: 4) {
                Text(monster.emoji)
                    .font(.system(size: 36))
                Text(monster.name)
                    .font(.zenMaru(13, weight: .bold))
                    .foregroundColor(unlocked ? .white : .gray)
                    .lineLimit(1)
            }
            .frame(width: 70)

            VStack(alignment: .leading, spacing: 4) {
                Text("STAGE \(stage.id)")
                    .font(.zenMaru(16, weight: .black))
                    .foregroundColor(unlocked ? .yellow : .gray)

                if unlocked {
                    let best = stage.bestCorrect
                    let thresholds = [5, 10, 18, 25, 30]
                    let stars = thresholds.filter { best >= $0 }.count
                    HStack(spacing: 2) {
                        ForEach(0..<5, id: \.self) { i in
                            Image(systemName: i < stars ? "star.fill" : "star")
                                .font(.zenMaru(14, weight: .bold))
                                .foregroundColor(i < stars ? .yellow : .gray.opacity(0.4))
                        }
                    }
                }
            }

            Spacer()

            if unlocked {
                Button {
                    HapticsManager.tap()
                    SoundManager.shared.playTap()
                    extraVM.selectStage(stage)
                    extraVM.startBattle()
                    gameVM.screen = .extraBattle
                } label: {
                    Text("extra_challenge")
                        .font(.zenMaru(14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } else {
                VStack(spacing: 2) {
                    Text("🔒")
                        .font(.system(size: 20))
                    Text(String(format: NSLocalizedString("extra_locked", comment: ""), stage.requiredFloor))
                        .font(.zenMaru(11))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(unlocked
                    ? Color.white.opacity(0.1)
                    : Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(unlocked ? Color.yellow.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

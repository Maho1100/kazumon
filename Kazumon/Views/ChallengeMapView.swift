import SwiftUI

struct ChallengeMapView: View {
    let challenge: DataStore.ChallengeData
    let onStartDay: (Int) -> Void
    let onClose: () -> Void

    private var progress: Double {
        Double(challenge.completedDays.count) / 30.0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // ヘッダー
                    VStack(spacing: 8) {
                        Text("mastery_map_title")
                            .font(.zenMaru(22, weight: .black))

                        Text("Day \(challenge.currentDay) / 30")
                            .font(.zenMaru(16, weight: .bold))
                            .foregroundStyle(.secondary)

                        // 現在のフェーズ
                        if challenge.currentDay <= 30 {
                            Text(ChallengeConfig.phaseProgress(for: challenge.currentDay))
                                .font(.zenMaru(14, weight: .bold))
                                .foregroundStyle(.orange)
                        }

                        VStack(spacing: 4) {
                            ProgressView(value: progress)
                                .tint(.orange)
                                .scaleEffect(y: 2)

                            Text(String(format: NSLocalizedString("challenge_progress_pct", comment: ""), Int(progress * 100)))
                                .font(.zenMaru(12, weight: .regular))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 32)
                    }
                    .padding(.top, 16)

                    // 4フェーズのロードマップ
                    VStack(spacing: 12) {
                        ForEach(MasteryPhase.allCases, id: \.rawValue) { phase in
                            phaseSection(phase: phase)
                        }
                    }
                    .padding(.horizontal, 16)

                    // 今日のステージへボタン
                    if challenge.isActive && challenge.currentDay <= 30 &&
                       !challenge.completedDays.contains(challenge.currentDay) {
                        Button {
                            onStartDay(challenge.currentDay)
                        } label: {
                            HStack {
                                Image(systemName: "play.fill")
                                Text(String(format: NSLocalizedString("mastery_map_start_day", comment: ""), challenge.currentDay))
                                    .font(.zenMaru(18, weight: .bold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(LinearGradient(
                                        colors: [.orange, .red],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ))
                            )
                        }
                        .padding(.horizontal, 24)
                    }

                    // 全クリ
                    if challenge.completedDays.count >= 30 {
                        VStack(spacing: 8) {
                            Text("mastery_map_complete")
                                .font(.zenMaru(20, weight: .black))
                                .foregroundStyle(.orange)
                            Text("mastery_map_complete_sub")
                                .font(.zenMaru(14, weight: .regular))
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                    }

                    Spacer().frame(height: 40)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { onClose() } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
    }

    // MARK: - フェーズセクション

    private func phaseDescKey(_ phase: MasteryPhase) -> String {
        switch phase {
        case .addition:           return "challenge_phase1_desc"
        case .carryAddition:      return "challenge_phase2_desc"
        case .subtraction:        return "challenge_phase3_desc"
        case .borrowSubtraction:  return "challenge_phase4_desc"
        }
    }

    private func phaseSection(phase: MasteryPhase) -> some View {
        let days = phase.days
        let completedInPhase = days.filter { challenge.completedDays.contains($0) }.count
        let totalInPhase = days.count
        let isPhaseComplete = completedInPhase >= totalInPhase

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(phase.icon) \(phase.label)")
                    .font(.zenMaru(16, weight: .bold))
                Spacer()
                if isPhaseComplete {
                    Text("✅")
                        .font(.system(size: 14))
                } else {
                    Text("\(completedInPhase)/\(totalInPhase)")
                        .font(.zenMaru(12, weight: .bold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.leading, 4)

            Text(NSLocalizedString(phaseDescKey(phase), comment: ""))
                .font(.zenMaru(11, weight: .regular))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                ForEach(Array(days), id: \.self) { day in
                    dayCell(day: day)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }

    private func dayCell(day: Int) -> some View {
        let isCompleted = challenge.completedDays.contains(day)
        let isCurrent = day == challenge.currentDay && !isCompleted
        let isLocked = day > challenge.currentDay && !isCompleted

        return VStack(spacing: 2) {
            if isCompleted {
                Text("★")
                    .font(.system(size: 20))
                    .foregroundStyle(.yellow)
            } else if isCurrent {
                Text("→")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.orange)
            } else {
                Text("□")
                    .font(.system(size: 20))
                    .foregroundStyle(.gray.opacity(0.4))
            }
            Text("\(day)")
                .font(.zenMaru(10, weight: .bold))
                .foregroundStyle(isCompleted ? Color.primary : (isCurrent ? Color.orange : Color.secondary))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCurrent ? Color.orange.opacity(0.15) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isCurrent ? Color.orange : Color.clear, lineWidth: 2)
                )
        )
        .opacity(isLocked ? 0.5 : 1.0)
    }
}

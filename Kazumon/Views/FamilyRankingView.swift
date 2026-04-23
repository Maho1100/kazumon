import SwiftUI

/// 家族ランキング画面
/// - リザルト後に強制表示
/// - 島の看板からも閲覧可能
struct FamilyRankingView: View {
    /// 直前にプレイしたメンバー（ハイライト用、nil可）
    let highlightedMember: FamilyMember?
    /// このバトルでベスト更新したか（演出用）
    let didUpdateBest: Bool
    let onClose: () -> Void

    @State private var fadeIn: Double = 0
    @State private var rowsVisible: [Bool] = []
    @State private var celebrate = false

    private var rankedMembers: [FamilyMember] {
        let members = DataStore.loadFamilyMembers()
        return members.sorted { a, b in
            let sa = DataStore.loadFamilyScore(for: a).bestScore
            let sb = DataStore.loadFamilyScore(for: b).bestScore
            return sa > sb
        }
    }

    var body: some View {
        ZStack {
            // 祝福の空グラデ（朝焼け→空）
            LinearGradient(
                colors: [
                    Color(red: 1.00, green: 0.85, blue: 0.55),  // 暖かい金
                    Color(red: 0.95, green: 0.70, blue: 0.75),  // 桜色
                    Color(red: 0.65, green: 0.80, blue: 1.00),  // 空色
                    Color(red: 0.45, green: 0.60, blue: 0.95)   // 深い空
                ],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            // ふわふわ星パーティクル
            ForEach(0..<12, id: \.self) { i in
                Image(systemName: "sparkle")
                    .font(.system(size: CGFloat.random(in: 8...18)))
                    .foregroundColor(.white.opacity(0.7))
                    .position(
                        x: CGFloat.random(in: 20...UIScreen.main.bounds.width-20),
                        y: CGFloat.random(in: 60...UIScreen.main.bounds.height-100)
                    )
                    .opacity(celebrate ? 0.9 : 0.3)
                    .animation(
                        .easeInOut(duration: Double.random(in: 1.5...2.8))
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.15),
                        value: celebrate
                    )
            }

            VStack(spacing: 16) {
                Spacer().frame(height: 30)

                // タイトル
                Text("🏆")
                    .font(.system(size: 56))
                    .scaleEffect(celebrate ? 1.15 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: celebrate)

                Text(NSLocalizedString("family_ranking_title", comment: ""))
                    .font(.zenMaru(28, weight: .black))
                    .foregroundColor(.white)
                    .shadow(color: Color(red: 0.30, green: 0.20, blue: 0.15).opacity(0.6), radius: 4, y: 2)
                    .shadow(color: .black.opacity(0.2), radius: 8, y: 3)

                if didUpdateBest, let m = highlightedMember {
                    Text(String(format: NSLocalizedString("family_ranking_new_best", comment: ""), m.label))
                        .font(.zenMaru(15, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 18).padding(.vertical, 8)
                        .background(
                            Capsule().fill(Color(red: 0.95, green: 0.45, blue: 0.30))
                        )
                        .shadow(color: .black.opacity(0.18), radius: 6, y: 3)
                        .transition(.scale.combined(with: .opacity))
                }

                // ランキングリスト
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(Array(rankedMembers.enumerated()), id: \.element) { index, member in
                            rankRow(rank: index + 1, member: member)
                                .opacity(rowsVisible.indices.contains(index) && rowsVisible[index] ? 1 : 0)
                                .offset(y: rowsVisible.indices.contains(index) && rowsVisible[index] ? 0 : 30)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }

                Button {
                    HapticsManager.tap()
                    onClose()
                } label: {
                    Text(NSLocalizedString("family_ranking_close", comment: ""))
                        .kazumonFixedButton(color: KazumonTheme.purple)
                }
                .padding(.bottom, 40)
            }
        }
        .opacity(fadeIn)
        .onAppear {
            AnalyticsManager.logViewFamilyRanking(didUpdateBest: didUpdateBest)
            let count = rankedMembers.count
            rowsVisible = Array(repeating: false, count: count)
            withAnimation(.easeOut(duration: 0.3)) { fadeIn = 1 }
            celebrate = true
            for i in 0..<count {
                let delay = 0.3 + Double(i) * 0.12
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                        if rowsVisible.indices.contains(i) {
                            rowsVisible[i] = true
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func rankRow(rank: Int, member: FamilyMember) -> some View {
        let score = DataStore.loadFamilyScore(for: member).bestScore
        let isHighlighted = (member == highlightedMember)
        HStack(spacing: 14) {
            Text(rankBadge(rank))
                .font(.system(size: 28, weight: .black))
                .foregroundColor(Color(red: 0.30, green: 0.20, blue: 0.15))
                .frame(width: 44)

            Text(member.emoji)
                .font(.system(size: 36))

            VStack(alignment: .leading, spacing: 2) {
                Text(member.label)
                    .font(.zenMaru(18, weight: .black))
                    .foregroundColor(Color(red: 0.30, green: 0.20, blue: 0.15))
                    .shadow(color: .white.opacity(0.6), radius: 1, y: 0)
                if isHighlighted && didUpdateBest {
                    Text(NSLocalizedString("family_ranking_updated", comment: ""))
                        .font(.zenMaru(11, weight: .bold))
                        .foregroundColor(Color(red: 0.90, green: 0.30, blue: 0.20))
                }
            }

            Spacer()

            Text("\(score)")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(Color(red: 0.95, green: 0.45, blue: 0.10))
                .shadow(color: .white.opacity(0.7), radius: 2, y: 1)
        }
        .padding(.horizontal, 18).padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isHighlighted
                      ? Color.white.opacity(0.85)
                      : Color.white.opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isHighlighted
                        ? Color(red: 0.95, green: 0.65, blue: 0.20)
                        : Color.white.opacity(0.6),
                        lineWidth: isHighlighted ? 3 : 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
    }

    private func rankBadge(_ rank: Int) -> String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "\(rank)"
        }
    }
}

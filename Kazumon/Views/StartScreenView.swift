import SwiftUI

struct StartScreenView: View {
    let gameVM: GameViewModel

    @State private var pulseScale: CGFloat = 1.0
@State private var logoOffset: CGFloat = -20
    @State private var logoOpacity: Double = 0
    @State private var logoSway: Double = 0
    @State private var islandFloat: CGFloat = 0
    @State private var cloudX1: CGFloat = -80
    @State private var cloudX2: CGFloat = -120

    // クローズアップアニメーション
    @State private var zoomScale: CGFloat = 1.0
    @State private var zoomOpacity: Double = 1.0
    @State private var buttonTapped = false

    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                colors: [
                    Color(red: 0.53, green: 0.81, blue: 0.98),
                    Color(red: 0.40, green: 0.70, blue: 0.95),
                    Color(red: 0.30, green: 0.60, blue: 0.90)
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // ロゴ
                Text(NSLocalizedString("start_screen_title", comment: ""))
                    .font(.zenMaru(56, weight: .black))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 10, y: 4)
                    .rotationEffect(.degrees(logoSway), anchor: .bottom)
                    .offset(y: logoOffset)
                    .opacity(logoOpacity)

                Spacer().frame(height: 20)

                // 島ミニプレビュー
                islandPreview
                    .offset(y: islandFloat)
                    .opacity(logoOpacity)

                Spacer()

                // ストリーク & 習慣バッジ
                HStack(spacing: 12) {
                    streakBadge
                    weeklyChallengeLabel
                }
                .opacity(logoOpacity)
                .padding(.bottom, 16)

                // 島に行くボタン
                Button {
                    guard !buttonTapped else { return }
                    buttonTapped = true
                    HapticsManager.tap()
                    SoundManager.shared.playBossAppear()

                    withAnimation(.easeIn(duration: 0.5)) {
                        zoomScale = 8.0
                        zoomOpacity = 0
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                        gameVM.screen = .island
                    }
                } label: {
                    Text(NSLocalizedString("start_screen_go", comment: ""))
                        .font(.zenMaru(26, weight: .black))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                        .frame(maxWidth: .infinity)
                        .frame(height: 72)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(LinearGradient(
                                    colors: [
                                        Color(red: 0.15, green: 0.75, blue: 0.35),
                                        Color(red: 0.3, green: 0.85, blue: 0.45),
                                        Color(red: 0.2, green: 0.75, blue: 0.7)
                                    ],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                        )
                        .shadow(color: .black.opacity(0.18), radius: 6, y: 3)
                        .scaleEffect(pulseScale)
                }
                .padding(.horizontal, 48)

                Spacer().frame(height: 100)
            }

            // 白フラッシュ
            Color.white.ignoresSafeArea()
                .opacity(buttonTapped ? 1 - zoomOpacity : 0)
                .allowsHitTesting(false)
        }
        .scaleEffect(zoomScale)
        .opacity(zoomOpacity)
        .onAppear {
            AnalyticsManager.logViewStartScreen()
            AnalyticsManager.trackScreenEnter("start_screen")
            zoomScale = 1.0
            zoomOpacity = 1.0
            buttonTapped = false

            withAnimation(.easeOut(duration: 0.8)) {
                logoOffset = 0
                logoOpacity = 1
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                logoSway = 3
            }
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                islandFloat = -8
            }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                pulseScale = 1.05
            }
            // 雲アニメ
            cloudX1 = -80; cloudX2 = -120
            withAnimation(.linear(duration: 15).repeatForever(autoreverses: false)) { cloudX1 = 300 }
            withAnimation(.linear(duration: 22).repeatForever(autoreverses: false)) { cloudX2 = 300 }
        }
    }

    @ViewBuilder
    private var streakBadge: some View {
        let player = DataStore.loadPlayerData()
        let streak = player.streakDays
        if streak > 0 {
            VStack(spacing: 2) {
                HStack(spacing: 4) {
                    Text("🔥")
                    Text(String(format: NSLocalizedString("view_title_streak_days", comment: ""), streak))
                        .font(.zenMaru(13, weight: .black))
                        .foregroundColor(.white)
                }
                if player.bestStreak > streak {
                    Text(String(format: NSLocalizedString("island_best_streak", comment: ""), player.bestStreak))
                        .font(.zenMaru(9, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(
                LinearGradient(colors: [Color.orange, Color.red.opacity(0.8)],
                               startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.3), radius: 3, y: 1)
        }
    }

    private var weeklyChallengeLabel: some View {
        let days = DataStore.loadWeeklyPlayDays()
        let goal = DataStore.weeklyGoalDays
        let complete = days >= goal
        return HStack(spacing: 4) {
            Text("📆")
            Text(complete
                 ? NSLocalizedString("island_weekly_complete", comment: "")
                 : String(format: NSLocalizedString("island_weekly_progress", comment: ""), days, goal))
                .font(.zenMaru(11, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(Capsule().fill(complete ? Color.green.opacity(0.7) : Color.purple.opacity(0.6)))
    }

    // MARK: - 島ミニプレビュー

    private var islandPreview: some View {
        ZStack {
            // 島の地面
            Ellipse()
                .fill(RadialGradient(
                    colors: [
                        Color(red: 0.45, green: 0.78, blue: 0.36),
                        Color(red: 0.35, green: 0.65, blue: 0.28),
                        Color(red: 0.28, green: 0.55, blue: 0.22)
                    ],
                    center: .center, startRadius: 5, endRadius: 80
                ))
                .frame(width: 200, height: 120)
                .shadow(color: Color(red: 0.2, green: 0.4, blue: 0.15).opacity(0.3), radius: 10, y: 5)

            // 木
            Image("island_tree")
                .resizable().scaledToFit()
                .frame(height: 30)
                .offset(x: -60, y: -10)

            Image("island_tree")
                .resizable().scaledToFit()
                .frame(height: 24)
                .offset(x: 55, y: 10)

            // 火山（山+赤光+雲、IslandWorldViewと同じ構成）
            StartScreenVolcano()
                .offset(x: 65, y: -35)

            // 建物（小さく）
            Image("island_battle")
                .resizable().scaledToFit()
                .frame(height: 45)
                .offset(x: 10, y: -5)

            // 雲（島の前面）
            CloudShape()
                .fill(Color.white.opacity(0.7))
                .frame(width: 50, height: 16)
                .offset(x: cloudX1, y: -30)

            CloudShape()
                .fill(Color.white.opacity(0.5))
                .frame(width: 35, height: 12)
                .offset(x: cloudX2, y: -15)
        }
        .frame(width: 220, height: 160)
    }
}

// 雲Shape（IslandWorldView と同じ）
private struct CloudShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width; let h = rect.height
        path.addEllipse(in: CGRect(x: 0, y: h * 0.3, width: w * 0.5, height: h * 0.7))
        path.addEllipse(in: CGRect(x: w * 0.2, y: 0, width: w * 0.55, height: h))
        path.addEllipse(in: CGRect(x: w * 0.45, y: h * 0.25, width: w * 0.55, height: h * 0.75))
        return path
    }
}


// MARK: - スタート画面用の火山（山+赤光+雲のミニ版）

private struct StartScreenVolcano: View {
    @State private var scaleAnim: CGFloat = 1.0
    @State private var stretch: CGFloat = 1.0
    @State private var glowScale: CGFloat = 0.5
    @State private var glowOpacity: Double = 0.7
    @State private var smokeY: CGFloat = 0
    @State private var smokeOpacity: Double = 1.0
    @State private var smokeScale: CGFloat = 0.5

    var body: some View {
        ZStack {
            // 山（画像）
            Image("island_mountain")
                .resizable().scaledToFit()
                .frame(height: 40)
                .scaleEffect(x: scaleAnim, y: scaleAnim * stretch, anchor: .bottom)
                .offset(y: 6)

            // 赤光の波紋
            Circle()
                .fill(RadialGradient(colors: [
                    Color.red.opacity(0.5),
                    Color.orange.opacity(0.2),
                    Color.red.opacity(0)
                ], center: .center, startRadius: 3, endRadius: 28))
                .frame(width: 50, height: 34)
                .scaleEffect(glowScale)
                .opacity(glowOpacity)
                .blendMode(.plusLighter)

            // 雲（噴煙、上に上がっていく）
            Image("island_volcano")
                .resizable().scaledToFit()
                .frame(height: 30)
                .scaleEffect(smokeScale, anchor: .bottom)
                .opacity(smokeOpacity)
                .offset(y: -14 + smokeY)
        }
        .frame(width: 60, height: 60)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                scaleAnim = 1.06; stretch = 1.10
            }
            glowScale = 0.4; glowOpacity = 0.7
            withAnimation(.easeOut(duration: 2.0).repeatForever(autoreverses: false)) {
                glowScale = 1.6; glowOpacity = 0
            }
            smokeY = 0; smokeOpacity = 1.0; smokeScale = 0.5
            withAnimation(.easeOut(duration: 4.0).repeatForever(autoreverses: false)) {
                smokeY = -35; smokeOpacity = 0; smokeScale = 1.3
            }
        }
    }
}

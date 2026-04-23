import SwiftUI

/// youngモード（4〜7さい）用リザルト画面 — ヒカキン流演出
struct YoungResultView: View {
    @Bindable var gameVM: GameViewModel

    @State private var shareItems: [Any] = []
    @State private var showShareSheet = false
    @State private var showMistakeOniWarning = false
    @State private var showTimeBossWarning = false

    // ── 段階演出 ──
    @State private var phase = 0
    @State private var bgRevealed = false
    @State private var showFlash = false
    @State private var floorScale: CGFloat = 4.0
    @State private var floorOpacity: Double = 0
    @State private var amazingScale: CGFloat = 3.0
    @State private var amazingOpacity: Double = 0
    @State private var starsRevealed = 0
    @State private var praiseOpacity: Double = 0
    @State private var charScale: CGFloat = 0.3
    @State private var charOpacity: Double = 0
    @State private var charFloat: CGFloat = 0
    @State private var buttonOpacity: Double = 0
    @State private var confettiVisible = false
    @State private var shakeOffset: CGFloat = 0
    @State private var recordScale: CGFloat = 0.5
    @State private var recordOpacity: Double = 0

    private var floorCount: Int { gameVM.floor - 1 }
    private var isYoung4: Bool { DataStore.loadAgeGroup() == .young4 }

    private var praiseLines: [String] {
        var lines = [
            NSLocalizedString("young_praise_stronger", comment: ""),
            NSLocalizedString("young_praise_hero", comment: ""),
            NSLocalizedString("young_praise_tomorrow", comment: ""),
            NSLocalizedString("young_praise_cool", comment: ""),
        ]
        if !isYoung4 {
            lines.insert(String(format: NSLocalizedString("young_praise_floor", comment: ""), floorCount), at: 0)
        }
        return lines
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if bgRevealed {
                LinearGradient(
                    colors: [Color(red: 1.0, green: 0.6, blue: 0.2), Color(red: 1.0, green: 0.3, blue: 0.3)],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()
                .transition(.opacity)
            }

            if confettiVisible {
                ResultConfettiView().allowsHitTesting(false)
            }

            VStack(spacing: 14) {
                Spacer()

                // Phase 1: キャラ ボヨーン
                if phase >= 1 {
                    KennyCharacterView(
                        appearance: gameVM.playerAppearance,
                        size: 80
                    )
                    .scaleEffect(charScale)
                    .opacity(charOpacity)
                    .offset(y: charFloat + 40)  // リザルト画面のキャラ位置を下げる
                }

                // Phase 0: 「すごい！」ドーン
                if phase >= 0 {
                    Text("young_result_amazing")
                        .font(.zenMaru(42, weight: .black))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 12, y: 2)
                        .scaleEffect(amazingScale)
                        .opacity(amazingOpacity)
                }

                Spacer().frame(height: 4)

                // Phase 2: フロア数 ドドーン / young4は正解数を表示
                if phase >= 2 {
                    if isYoung4 {
                        Text("\(gameVM.correctInSession)/\(gameVM.totalInSession)")
                            .font(.system(size: 80, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.4), radius: 16, y: 4)
                            .scaleEffect(floorScale)
                            .opacity(floorOpacity)
                    } else {
                        Text("\(floorCount)F")
                            .font(.system(size: 120, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.4), radius: 16, y: 4)
                            .scaleEffect(floorScale)
                            .opacity(floorOpacity)
                    }
                }

                // Phase 3: 星 1つずつ
                if phase >= 3 {
                    let starCount = FloorRank.stars(correctCount: gameVM.correctInSession, totalCount: gameVM.totalInSession)
                    HStack(spacing: 6) {
                        ForEach(0..<3, id: \.self) { i in
                            Image(systemName: i < starsRevealed ? "star.fill" : "star")
                                .font(.system(size: 32))
                                .foregroundStyle(i < starsRevealed ? .yellow : .white.opacity(0.3))
                                .shadow(color: i < starsRevealed ? .yellow.opacity(0.5) : .clear, radius: 6)
                                .scaleEffect(i < starsRevealed ? 1.0 : 0.6)
                        }
                    }
                }

                // Phase 4: 褒め
                if phase >= 4 {
                    Text(praiseLines.randomElement() ?? praiseLines[0])
                        .font(.zenMaru(18, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .opacity(praiseOpacity)

                    // NEW RECORD
                    if gameVM.isNewRecord {
                        Text("young_result_new_record")
                            .font(.zenMaru(24, weight: .black))
                            .foregroundStyle(.yellow)
                            .shadow(color: .yellow.opacity(0.6), radius: 12)
                            .scaleEffect(recordScale)
                            .opacity(recordOpacity)
                    }
                }

                Spacer()

                // Phase 5: 次の敵シルエット
                if phase >= 5 && !isYoung4 {
                    Text("result_next_enemy")
                        .font(.zenMaru(14, weight: .bold))
                        .foregroundStyle(.white.opacity(0.7))
                    KennyCharacterView(
                        appearance: .forFloor(floorCount + 1),
                        size: 50
                    )
                    .allowsHitTesting(false)
                    .colorMultiply(.black)
                    .opacity(0.4)
                }

                // Phase 6: ボタン
                if phase >= 5 {
                    youngActionButtons
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                        .opacity(buttonOpacity)
                }
            }
            .offset(x: shakeOffset)

            // 白フラッシュ
            Color.white.ignoresSafeArea()
                .opacity(showFlash ? 1 : 0)
                .allowsHitTesting(false)
        }
        .onAppear { runSequence() }
        .sheet(isPresented: $showShareSheet) { ShareSheet(items: shareItems) }
        .fullScreenCover(isPresented: $showMistakeOniWarning) {
            MistakeOniWarningView { showMistakeOniWarning = false; gameVM.returnToTitle() }
        }
        .fullScreenCover(isPresented: $showTimeBossWarning) {
            TimeBossWarningView { showTimeBossWarning = false; gameVM.returnToTitle() }
        }
    }

    // MARK: - ヒカキン流シーケンス

    private func runSequence() {
        // 0.0s: 「すごい！」バウンスイン + 背景
        SoundManager.shared.playBossAppear()
        HapticsManager.incorrect()
        withAnimation(.easeOut(duration: 0.2)) { bgRevealed = true }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            amazingScale = 1.0; amazingOpacity = 1
        }

        // 0.8s: キャラ ボヨーン
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            phase = 1
            withAnimation(.spring(response: 0.4, dampingFraction: 0.4)) {
                charScale = 1.0; charOpacity = 1
            }
            HapticsManager.tap()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) { charFloat = -8 }
            }
        }

        // 1.5s: フロア数 ドドーン + フラッシュ + シェイク
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            phase = 2
            showFlash = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.2)) { showFlash = false }
            }
            withAnimation(.spring(response: 0.25, dampingFraction: 0.45)) {
                floorScale = 1.0; floorOpacity = 1
            }
            SoundManager.shared.playBossVictory()
            HapticsManager.incorrect()
            runShake()
            confettiVisible = true
        }

        // 2.5s: 星 1つずつ
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            phase = 3
            let starCount = FloorRank.stars(correctCount: gameVM.correctInSession, totalCount: gameVM.totalInSession)
            for i in 0..<starCount {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.3) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) { starsRevealed = i + 1 }
                    SoundManager.shared.playCorrect()
                    HapticsManager.tap()
                }
            }
        }

        // 3.5s: 褒め + NEW RECORD
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            phase = 4
            withAnimation(.easeOut(duration: 0.4)) { praiseOpacity = 1 }
            if gameVM.isNewRecord {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                        recordScale = 1.0; recordOpacity = 1
                    }
                    HapticsManager.tap()
                }
            }
        }

        // 4.3s: ボタン
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.3) {
            phase = 5
            SoundManager.shared.playResult()
            withAnimation(.easeOut(duration: 0.4)) { buttonOpacity = 1 }
        }

    }

    private func runShake() {
        let steps: [(CGFloat, Double)] = [(10,0),(-10,0.04),(8,0.08),(-8,0.12),(6,0.16),(-4,0.20),(0,0.24)]
        for (o, d) in steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + d) {
                withAnimation(.linear(duration: 0.03)) { shakeOffset = o }
            }
        }
    }

    // MARK: - ボタン

    @ViewBuilder
    private var youngActionButtons: some View {
        let canContinue = PurchaseManager.shared.isPro ||
            gameVM.dailyMission.playCount < PurchaseManager.maxFreePlayCount

        VStack(spacing: 12) {
            if canContinue {
                HStack(spacing: 16) {
                    Button {
                        HapticsManager.tap()
                        if gameVM.shouldShowTimeBossWarning { showTimeBossWarning = true }
                        else if gameVM.shouldShowMistakeWarning { showMistakeOniWarning = true }
                        else { gameVM.startGame() }
                    } label: {
                        HStack(spacing: 6) {
                            Text("young_result_retry").font(.zenMaru(22, weight: .black))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 60)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.green))
                        .shadow(color: .green.opacity(0.4), radius: 8, y: 4)
                    }

                    Button {
                        HapticsManager.tap()
                        if gameVM.shouldShowTimeBossWarning { showTimeBossWarning = true }
                        else if gameVM.shouldShowMistakeWarning { showMistakeOniWarning = true }
                        else { gameVM.returnToTitle() }
                    } label: {
                        Text("young_result_done").font(.zenMaru(18, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 100, height: 50)
                            .background(Color.white.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.4), lineWidth: 2))
                    }
                }
            } else {
                Button {
                    HapticsManager.tap()
                    if gameVM.shouldShowTimeBossWarning { showTimeBossWarning = true }
                    else if gameVM.shouldShowMistakeWarning { showMistakeOniWarning = true }
                    else { gameVM.returnToTitle() }
                } label: {
                    Text("young_result_done").font(.zenMaru(22, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 60)
                        .background(Color.white.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.4), lineWidth: 2))
                }
            }
        }
    }

    @MainActor
    private func generateShareImage() {
        let name = gameVM.playerData.playerName
        let floor = floorCount
        let reachedText = String(format: NSLocalizedString("young_share_reached", comment: ""), name, floor)
        let logoText = NSLocalizedString("young_share_logo", comment: "")
        let content = ZStack {
            LinearGradient(colors: [Color(red: 1.0, green: 0.6, blue: 0.2), Color(red: 1.0, green: 0.3, blue: 0.3)], startPoint: .top, endPoint: .bottom)
            VStack(spacing: 12) {
                Text("\(floor)F").font(.system(size: 80, weight: .black, design: .rounded)).foregroundColor(.white)
                Text(reachedText).font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                Text(logoText).font(.system(size: 14, weight: .bold)).foregroundColor(.white.opacity(0.6))
            }
        }.frame(width: 300, height: 250)
        let renderer = ImageRenderer(content: content)
        renderer.scale = UIScreen.main.scale
        if let image = renderer.uiImage {
            shareItems = [image]; showShareSheet = true
        } else {
            let text = String(format: NSLocalizedString("young_share_reached", comment: ""), name, floor)
            shareItems = [text]; showShareSheet = true
        }
    }
}

// MARK: - 共通紙吹雪

struct ResultConfettiView: View {
    @State private var particles: [(id: Int, x: CGFloat, color: Color, size: CGFloat)] = []
    private let colors: [Color] = [.yellow, .orange, .red, .pink, .green, .blue, .purple, .cyan]

    var body: some View {
        ZStack {
            ForEach(particles, id: \.id) { p in
                ResultConfettiParticle(color: p.color, size: p.size).offset(x: p.x)
            }
        }
        .onAppear {
            particles = (0..<35).map { i in
                (id: i, x: CGFloat.random(in: -200...200), color: colors.randomElement()!, size: CGFloat.random(in: 6...14))
            }
        }
    }
}

private struct ResultConfettiParticle: View {
    let color: Color; let size: CGFloat
    @State private var yOffset: CGFloat = -120
    @State private var xDrift: CGFloat = 0
    @State private var opacity: Double = 1

    var body: some View {
        Circle().fill(color).frame(width: size, height: size)
            .offset(x: xDrift, y: yOffset).opacity(opacity)
            .onAppear {
                xDrift = CGFloat.random(in: -20...20)
                withAnimation(.easeIn(duration: Double.random(in: 2...4.5))) {
                    yOffset = CGFloat.random(in: 500...900)
                    xDrift += CGFloat.random(in: -50...50)
                    opacity = 0
                }
            }
    }
}

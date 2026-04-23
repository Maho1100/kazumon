import SwiftUI
import AVFoundation

/// ボス撃破演出
///
/// 演出シーケンス（合計 約2.0秒）:
///   0.00s  白フラッシュ点灯 + 稲妻表示 + パーティクル発射 + 効果音再生
///   0.15s  白フラッシュ消滅
///   0.20s  テキスト「⚡ BOSS DEFEATED! ⚡」拡大表示
///   0.40s  稲妻フェードアウト開始
///   1.00s  テキスト上方スライド開始
///   1.50s  全体フェードアウト開始
///   2.00s  完全消滅
struct BossDefeatedOverlay: View {

    // MARK: - Animation State

    @State private var flashOpacity: Double = 0
    @State private var bgOpacity: Double = 0
    @State private var boltOpacity: Double = 1.0
    @State private var boltScale: CGFloat = 0.6
    @State private var textScale: CGFloat = 0.3
    @State private var textOpacity: Double = 0
    @State private var textOffsetY: CGFloat = 0
    @State private var wholeOpacity: Double = 1.0

    // パーティクル
    @State private var particles: [StarParticle] = []

    // 効果音
    @State private var sfxPlayer: AVAudioPlayer?

    // 稲妻パス（初回生成して固定）
    @State private var boltPaths: [BoltPath] = []

    var body: some View {
        ZStack {
            // ── 背景暗転 ──
            Color.black.opacity(bgOpacity * 0.5)
                .ignoresSafeArea()

            // ── 白フラッシュ ──
            Color.white.opacity(flashOpacity * 0.8)
                .ignoresSafeArea()

            // ── 稲妻 ──
            GeometryReader { geo in
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                Canvas { context, size in
                    for bolt in boltPaths {
                        var path = Path()
                        let points = bolt.points(from: center, length: min(size.width, size.height) * 0.45)
                        guard let first = points.first else { continue }
                        path.move(to: first)
                        for pt in points.dropFirst() {
                            path.addLine(to: pt)
                        }
                        context.stroke(
                            path,
                            with: .linearGradient(
                                Gradient(colors: [.yellow, .orange]),
                                startPoint: center,
                                endPoint: points.last ?? center
                            ),
                            lineWidth: bolt.width
                        )
                        // 内側に細い白ライン（光芯）
                        context.stroke(
                            path,
                            with: .color(.white.opacity(0.7)),
                            lineWidth: bolt.width * 0.3
                        )
                    }
                }
                .scaleEffect(boltScale)
                .opacity(boltOpacity)
            }
            .ignoresSafeArea()

            // ── パーティクル（⭐） ──
            ForEach(particles) { p in
                Text("⭐")
                    .font(.system(size: p.size))
                    .offset(x: p.currentX, y: p.currentY)
                    .opacity(p.opacity)
                    .rotationEffect(.degrees(p.rotation))
            }

            // ── テキスト ──
            Text("⚡ BOSS DEFEATED! ⚡")
                .font(.zenMaru(36, weight: .black))
                .foregroundColor(.yellow)
                .shadow(color: .orange.opacity(0.9), radius: 20)
                .shadow(color: .orange.opacity(0.6), radius: 40)
                .shadow(color: .black.opacity(0.7), radius: 4, y: 2)
                .scaleEffect(textScale)
                .opacity(textOpacity)
                .offset(y: textOffsetY)
        }
        .opacity(wholeOpacity)
        .allowsHitTesting(false)
        .onAppear {
            boltPaths = BoltPath.generate(count: 5)
            particles = StarParticle.generate(count: 8)
            playSFX()
            runSequence()
        }
    }

    // MARK: - 演出シーケンス

    private func runSequence() {
        // 0.00s: 背景暗転 + 白フラッシュ + 稲妻拡大
        withAnimation(.easeOut(duration: 0.1)) {
            bgOpacity = 1.0
            flashOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.25)) {
            boltScale = 1.0
        }

        // 0.15s: フラッシュ消滅
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeOut(duration: 0.15)) {
                flashOpacity = 0
            }
        }

        // 0.10s: パーティクル発射
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            animateParticles()
        }

        // 0.20s: テキスト拡大表示
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                textScale = 1.1
                textOpacity = 1.0
            }
        }

        // 0.45s: テキスト安定
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            withAnimation(.easeOut(duration: 0.15)) {
                textScale = 1.0
            }
        }

        // 0.40s: 稲妻フェードアウト
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.4)) {
                boltOpacity = 0
                boltScale = 1.3
            }
        }

        // 1.0s: テキスト上方スライド
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeIn(duration: 0.5)) {
                textOffsetY = -60
                textOpacity = 0
            }
        }

        // 1.5s: 全体フェードアウト
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeIn(duration: 0.5)) {
                wholeOpacity = 0
            }
        }
    }

    // MARK: - パーティクルアニメーション

    private func animateParticles() {
        for i in particles.indices {
            withAnimation(.easeOut(duration: Double.random(in: 0.6...1.0))) {
                particles[i].currentX = particles[i].targetX
                particles[i].currentY = particles[i].targetY
                particles[i].rotation = Double.random(in: 180...720)
            }
            withAnimation(.easeIn(duration: 0.4).delay(Double.random(in: 0.5...0.8))) {
                particles[i].opacity = 0
            }
        }
    }

    // MARK: - 効果音

    private func playSFX() {
        guard SoundManager.shared.isEnabled,
              let url = Bundle.main.url(forResource: "boss_defeat", withExtension: "wav") else { return }
        sfxPlayer = try? AVAudioPlayer(contentsOf: url)
        sfxPlayer?.volume = 1.0
        sfxPlayer?.play()
    }
}

// MARK: - 稲妻パスデータ

private struct BoltPath: Identifiable {
    let id = UUID()
    let angle: Double      // 放射角度（ラジアン）
    let segments: [CGFloat] // 各セグメントの横ズレ比率
    let width: CGFloat

    func points(from center: CGPoint, length: CGFloat) -> [CGPoint] {
        let segCount = segments.count
        var pts: [CGPoint] = [center]
        for i in 0..<segCount {
            let progress = CGFloat(i + 1) / CGFloat(segCount)
            let baseX = center.x + cos(angle) * length * progress
            let baseY = center.y + sin(angle) * length * progress
            let perpX = -sin(angle) * segments[i] * length * 0.12
            let perpY = cos(angle) * segments[i] * length * 0.12
            pts.append(CGPoint(x: baseX + perpX, y: baseY + perpY))
        }
        return pts
    }

    static func generate(count: Int) -> [BoltPath] {
        (0..<count).map { i in
            let baseAngle = (Double(i) / Double(count)) * 2.0 * .pi
            let angle = baseAngle + Double.random(in: -0.2...0.2)
            let segCount = Int.random(in: 5...8)
            let segments = (0..<segCount).map { _ in CGFloat.random(in: -1.0...1.0) }
            let width = CGFloat.random(in: 2.5...4.0)
            return BoltPath(angle: angle, segments: segments, width: width)
        }
    }
}

// MARK: - 星パーティクルデータ

private struct StarParticle: Identifiable {
    let id = UUID()
    let size: CGFloat
    var currentX: CGFloat = 0
    var currentY: CGFloat = 0
    let targetX: CGFloat
    let targetY: CGFloat
    var opacity: Double = 1.0
    var rotation: Double = 0

    static func generate(count: Int) -> [StarParticle] {
        (0..<count).map { _ in
            let angle = Double.random(in: 0...(2.0 * .pi))
            let dist = CGFloat.random(in: 80...180)
            return StarParticle(
                size: CGFloat.random(in: 14...24),
                targetX: cos(angle) * dist,
                targetY: sin(angle) * dist
            )
        }
    }
}

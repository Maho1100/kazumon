import SwiftUI

struct RadarChartView: View {
    var stats: PlayerStats
    var previousStats: PlayerStats? = nil
    var size: CGFloat = 160
    var showLegend: Bool = true
    var showDelta: Bool = true

    private var labels: [String] {
        ["radar_speed", "radar_strength", "radar_combo", "radar_daily"].map {
            NSLocalizedString($0, comment: "")
        }
    }
    private let axisCount = 4
    private let accentColor = Color(red: 0.42, green: 0.36, blue: 0.90)       // より鮮やかな紫
    private let accentDark  = Color(red: 0.33, green: 0.29, blue: 0.72)       // #534AB7
    private let prevColor   = Color(red: 0.60, green: 0.60, blue: 0.65)       // 薄いグレー
    private let badgeBg     = Color(red: 0.93, green: 0.93, blue: 0.996)      // #EEEDFE

    @State private var glowPhase: CGFloat = 0
    @State private var ringScale: CGFloat = 0.6

    private var center: CGPoint { CGPoint(x: size / 2, y: size / 2) }
    private var radius: CGFloat { size / 2 - 20 }

    private var values: [Double] {
        [stats.speedScore, stats.floorScore, stats.comboScore, stats.daysScore]
    }

    private var previousValues: [Double]? {
        guard let p = previousStats else { return nil }
        return [p.speedScore, p.floorScore, p.comboScore, p.daysScore]
    }

    var body: some View {
        VStack(spacing: 6) {
            // 凡例（先週データがある場合のみ）
            if showLegend && previousStats != nil {
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(accentColor)
                            .frame(width: 20, height: 3)
                        Text("radar_this_week")
                            .font(.zenMaru(11, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(prevColor.opacity(0.3))
                            .frame(width: 20, height: 3)
                        Text("radar_last_week")
                            .font(.zenMaru(11, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                }
            }

            // チャート本体
            ZStack {
                // グリッド（3段階）
                ForEach([0.33, 0.66, 1.0], id: \.self) { scale in
                    polygonPath(scale: scale)
                        .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                }

                // 軸線
                ForEach(0..<axisCount, id: \.self) { i in
                    Path { path in
                        path.move(to: center)
                        path.addLine(to: point(index: i, scale: 1.0))
                    }
                    .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                }

                // 先週の多角形（あれば）— 薄いグレー塗りつぶし
                if let prev = previousValues {
                    previousDataPath(prev)
                        .fill(prevColor.opacity(0.15))
                    previousDataPath(prev)
                        .stroke(prevColor.opacity(0.3), lineWidth: 1.5)
                }

                // 今週のデータ多角形（鮮やか紫＋パルス）
                dataPath
                    .fill(accentColor.opacity(0.22 + glowPhase * 0.08))
                dataPath
                    .stroke(accentColor.opacity(0.9 + glowPhase * 0.1), lineWidth: 3.0)

                // データ頂点のドット + リングアニメーション
                ForEach(0..<axisCount, id: \.self) { i in
                    let grew = grewFromPrevious(index: i)
                    ZStack {
                        if grew {
                            // 外側リング（パルス）
                            Circle()
                                .stroke(accentColor, lineWidth: 2)
                                .frame(width: 14, height: 14)
                                .opacity(0.6 * (1.0 - ringScale * 0.3))
                                .scaleEffect(0.6 + ringScale * 0.4)
                            // 内側ドット
                            Circle()
                                .fill(accentDark)
                                .frame(width: 8, height: 8)
                        } else {
                            Circle()
                                .fill(accentColor)
                                .frame(width: 5, height: 5)
                        }
                    }
                    .position(point(index: i, scale: max(values[i], 0.05)))
                }

                // ラベル + デルタバッジ
                ForEach(0..<axisCount, id: \.self) { i in
                    VStack(spacing: 2) {
                        Text(labels[i])
                            .font(.zenMaru(10, weight: .regular))
                            .foregroundColor(.secondary)
                        if showDelta {
                            deltaLabel(index: i)
                        }
                    }
                    .position(labelPosition(index: i))
                }
            }
            .frame(width: size, height: size)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                    glowPhase = 1.0
                }
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    ringScale = 1.0
                }
            }
        }
    }

    // MARK: - Delta Label

    @ViewBuilder
    private func deltaLabel(index: Int) -> some View {
        if let prev = previousValues {
            let cur = values[index]
            let prv = prev[index]
            if cur == 0 && prv == 0 {
                // データなし
            } else {
                let delta = cur - prv
                if delta > 0.05 {
                    let pct = Int(delta * 100)
                    Text("✦ +\(pct)%")
                        .font(.zenMaru(8, weight: .regular))
                        .foregroundColor(accentDark)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(badgeBg)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                } else if delta < -0.05 {
                    let pct = Int(abs(delta) * 100)
                    Text("✦ -\(pct)%")
                        .font(.zenMaru(8, weight: .regular))
                        .foregroundColor(.red.opacity(0.7))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.red.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
        }
    }

    // MARK: - Helpers

    private func grewFromPrevious(index: Int) -> Bool {
        guard let prev = previousValues else { return false }
        return values[index] - prev[index] > 0.05
    }

    private func angle(index: Int) -> Double {
        let start = -Double.pi / 2
        return start + (2 * .pi / Double(axisCount)) * Double(index)
    }

    private func point(index: Int, scale: Double) -> CGPoint {
        let a = angle(index: index)
        let r = radius * scale
        return CGPoint(
            x: center.x + CGFloat(cos(a)) * r,
            y: center.y + CGFloat(sin(a)) * r
        )
    }

    private func labelPosition(index: Int) -> CGPoint {
        let a = angle(index: index)
        let r = radius + 16
        var x = center.x + CGFloat(cos(a)) * r
        let y = center.y + CGFloat(sin(a)) * r
        // 個別X調整：まいにち(3)を左に、つよさ(1)を右に
        if index == 3 { x -= 10 }  // まいにち：左にずらす
        if index == 1 { x += 15 }  // つよさ：右にずらす
        return CGPoint(x: x, y: y)
    }

    private func polygonPath(scale: Double) -> Path {
        Path { path in
            for i in 0..<axisCount {
                let p = point(index: i, scale: scale)
                if i == 0 { path.move(to: p) }
                else { path.addLine(to: p) }
            }
            path.closeSubpath()
        }
    }

    private var dataPath: Path {
        Path { path in
            for i in 0..<axisCount {
                let p = point(index: i, scale: max(values[i], 0.05))
                if i == 0 { path.move(to: p) }
                else { path.addLine(to: p) }
            }
            path.closeSubpath()
        }
    }

    private func previousDataPath(_ prev: [Double]) -> Path {
        Path { path in
            for i in 0..<axisCount {
                let p = point(index: i, scale: max(prev[i], 0.05))
                if i == 0 { path.move(to: p) }
                else { path.addLine(to: p) }
            }
            path.closeSubpath()
        }
    }
}

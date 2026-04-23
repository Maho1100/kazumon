import SwiftUI

struct StatusIconRowView: View {
    let stats: PlayerStats
    var animated: Bool = false

    private struct Axis {
        let icon: String
        let color: Color
        let displayValue: String
        let barValue: Double
    }

    private var axes: [Axis] {
        [
            Axis(icon: "⚡",  color: Color(red: 0.114, green: 0.620, blue: 0.459),
                 displayValue: "\(Int(stats.speed * 100))", barValue: stats.speedScore),
            Axis(icon: "🏆", color: Color(red: 0.498, green: 0.467, blue: 0.867),
                 displayValue: "F\(stats.topFloor)", barValue: stats.floorScore),
            Axis(icon: "💥", color: Color(red: 0.847, green: 0.353, blue: 0.188),
                 displayValue: "\(stats.maxCombo)", barValue: stats.comboScore),
            Axis(icon: "🔥", color: Color(red: 0.937, green: 0.624, blue: 0.153),
                 displayValue: String(format: NSLocalizedString("status_days", comment: ""), stats.playDays), barValue: stats.daysScore),
        ]
    }

    @State private var barProgress: [Double] = [0, 0, 0, 0]
    @State private var showValues = false

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<4, id: \.self) { i in
                let axis = axes[i]
                VStack(spacing: 3) {
                    Text(axis.icon)
                        .font(.system(size: 16))
                    Text(showValues ? axis.displayValue : "—")
                        .font(.zenMaru(13, weight: .bold))
                        .foregroundColor(axis.color)
                        .monospacedDigit()
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(axis.color.opacity(0.15))
                                .frame(height: 3)
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(axis.color)
                                .frame(width: geo.size.width * barProgress[i], height: 3)
                        }
                    }
                    .frame(height: 3)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .onChange(of: animated) { _, isAnimated in
            guard isAnimated else { return }
            showValues = true
            let values = axes.map { $0.barValue }
            for (i, v) in values.enumerated() {
                withAnimation(.easeOut(duration: 0.8).delay(Double(i) * 0.1)) {
                    barProgress[i] = v
                }
            }
        }
    }
}

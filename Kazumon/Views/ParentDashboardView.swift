import SwiftUI

struct ParentDashboardView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var player = DataStore.loadPlayerData()
    @State private var sessions: [SessionRecord] = []
    @State private var mistakes: [MistakeEntry] = []
    @State private var statsCurrent = PlayerStats(speed: 0, topFloor: 0, maxCombo: 0, playDays: 0)
    @State private var statsPrevious = PlayerStats(speed: 0, topFloor: 0, maxCombo: 0, playDays: 0)
    @State private var masteryAnimated: Double = 0

    private let accentPurple = Color(red: 0.50, green: 0.47, blue: 0.87)
    private let greenColor = Color(red: 0.114, green: 0.620, blue: 0.459)
    private let orangeColor = Color(red: 0.847, green: 0.353, blue: 0.188)
    private let fireColor = Color(red: 0.937, green: 0.624, blue: 0.153)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // MARK: - AIひとこと
                    HStack(spacing: 8) {
                        Text("💡")
                            .font(.system(size: 18))
                        Text(aiComment)
                            .font(.zenMaru(13, weight: .bold))
                            .foregroundColor(Color(red: 0.33, green: 0.29, blue: 0.72))
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(red: 0.93, green: 0.93, blue: 0.996))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    // MARK: - マスター度
                    masteryCard
                        .padding(.horizontal, 20)

                    // MARK: - 今週のようす（4カード）
                    Text("dashboard_this_week")
                        .font(.zenMaru(16, weight: .bold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)

                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        dashCard(
                            icon: "⚡",
                            label: NSLocalizedString("dashboard_speed_label", comment: ""),
                            value: statsCurrent.topFloor > 0
                                ? String(format: "%.1fs", statsCurrent.avgSeconds)
                                : "—",
                            diff: speedDiffText,
                            diffPositive: statsCurrent.speed > statsPrevious.speed,
                            sub: statsPrevious.topFloor > 0
                                ? String(format: NSLocalizedString("dashboard_last_week", comment: ""), String(format: "%.1fs", statsPrevious.avgSeconds))
                                : nil,
                            color: greenColor
                        )
                        dashCard(
                            icon: "🏆",
                            label: NSLocalizedString("dashboard_top_floor", comment: ""),
                            value: statsCurrent.topFloor > 0 ? "F\(statsCurrent.topFloor)" : "—",
                            diff: floorDiff != 0 ? (floorDiff > 0 ? "▲F\(floorDiff)" : "▼F\(abs(floorDiff))") : nil,
                            diffPositive: floorDiff > 0,
                            sub: statsPrevious.topFloor > 0
                                ? String(format: NSLocalizedString("dashboard_last_week", comment: ""), "F\(statsPrevious.topFloor)")
                                : nil,
                            color: accentPurple
                        )
                        dashCard(
                            icon: "💥",
                            label: NSLocalizedString("dashboard_max_combo", comment: ""),
                            value: statsCurrent.maxCombo > 0 ? "\(statsCurrent.maxCombo)x" : "—",
                            diff: comboDiff != 0 ? (comboDiff > 0 ? "▲\(comboDiff)" : "▼\(abs(comboDiff))") : nil,
                            diffPositive: comboDiff > 0,
                            sub: statsPrevious.maxCombo > 0
                                ? String(format: NSLocalizedString("dashboard_last_week", comment: ""), "\(statsPrevious.maxCombo)x")
                                : nil,
                            color: orangeColor
                        )
                        dashCard(
                            icon: "🔥",
                            label: NSLocalizedString("dashboard_play_days", comment: ""),
                            value: statsCurrent.playDays > 0 ? "\(statsCurrent.playDays)" : "—",
                            diff: nil,
                            diffPositive: true,
                            sub: statsPrevious.playDays > 0
                                ? String(format: NSLocalizedString("dashboard_last_week", comment: ""), "\(statsPrevious.playDays)")
                                : nil,
                            color: fireColor
                        )
                    }
                    .padding(.horizontal, 20)

                    // MARK: - 回答速さの4週間グラフ
                    weeklySpeedChart
                        .padding(.horizontal, 20)

                    // MARK: - 正答率の4週間グラフ
                    weeklyAccuracyChart
                        .padding(.horizontal, 20)

                    // MARK: - Before/After比較
                    if DataStore.hasCompletedBeforeTest() {
                        beforeAfterCard
                            .padding(.horizontal, 20)
                    }

                    // MARK: - カテゴリ別弱点
                    if !mistakes.isEmpty {
                        categoryWeaknessCard
                            .padding(.horizontal, 20)
                    }

                    // MARK: - にがてな もんだい
                    VStack(alignment: .leading, spacing: 12) {
                        Text("dashboard_weak_problems")
                            .font(.zenMaru(16, weight: .bold))
                            .padding(.horizontal, 20)

                        if mistakes.isEmpty {
                            Text("dashboard_no_mistakes")
                                .font(.zenMaru(14, weight: .regular))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                        } else {
                            let sorted = mistakeRanking
                            ForEach(Array(sorted.enumerated()), id: \.element.id) { index, entry in
                                if index < 2 {
                                    mistakeRow(rank: index + 1, entry: entry)
                                } else if PurchaseManager.shared.isPro {
                                    mistakeRow(rank: index + 1, entry: entry)
                                }
                            }

                            if !PurchaseManager.shared.isPro && sorted.count > 2 {
                                ZStack {
                                    VStack(spacing: 4) {
                                        ForEach(2..<min(5, sorted.count), id: \.self) { i in
                                            mistakeRow(rank: i + 1, entry: sorted[i])
                                        }
                                    }
                                    .blur(radius: 3)

                                    Button {
                                        Task { try? await PurchaseManager.shared.purchase() }
                                    } label: {
                                        HStack(spacing: 6) {
                                            Text("🔒")
                                            Text("dashboard_pro_unlock")
                                                .font(.zenMaru(14, weight: .bold))
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(
                                                    LinearGradient(
                                                        colors: [.orange, .pink],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                        )
                                    }
                                }
                            }
                        }
                    }

                    // MARK: - プレイカレンダー
                    playCalendarCard
                        .padding(.horizontal, 20)

                    // MARK: - ママの声ヒント
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Text("🎤")
                                .font(.system(size: 24))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(NSLocalizedString("dashboard_voice_title", comment: ""))
                                    .font(.zenMaru(13, weight: .bold))
                                Text(NSLocalizedString("dashboard_voice_desc", comment: ""))
                                    .font(.zenMaru(11, weight: .regular))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(NSLocalizedString("dashboard_voice_where", comment: ""))
                                .font(.zenMaru(10, weight: .bold))
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(14)
                    .background(Color.blue.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)

                    Spacer(minLength: 40)
                }
            }
            .navigationTitle(NSLocalizedString("dashboard_title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("dashboard_close", comment: "")) { dismiss() }
                }
            }
        }
        .onAppear {
            player = DataStore.loadPlayerData()
            sessions = DataStore.loadSessionHistory()
            mistakes = DataStore.loadMistakeLog()
            let result = PlayerStats.calculate(player: player, sessions: sessions, mistakes: mistakes)
            statsCurrent = result.current
            statsPrevious = result.previous
            // マスター度アニメーション
            masteryAnimated = 0
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                masteryAnimated = Double(DataStore.totalMasteryPercent())
            }
        }
    }

    // MARK: - Computed

    private var aiComment: String {
        if statsCurrent.speed - statsPrevious.speed > 0.1 {
            return String(format: NSLocalizedString("dashboard_ai_speed", comment: ""), String(format: "%.1f", statsCurrent.avgSeconds))
        } else if statsCurrent.topFloor > statsPrevious.topFloor {
            return String(format: NSLocalizedString("dashboard_ai_floor", comment: ""), statsCurrent.topFloor)
        } else if statsCurrent.maxCombo > statsPrevious.maxCombo {
            return String(format: NSLocalizedString("dashboard_ai_combo", comment: ""), statsCurrent.maxCombo)
        } else if statsCurrent.playDays > statsPrevious.playDays {
            return String(format: NSLocalizedString("dashboard_ai_days", comment: ""), statsCurrent.playDays)
        } else {
            return NSLocalizedString("dashboard_ai_default", comment: "")
        }
    }

    private var speedDiffText: String? {
        guard statsPrevious.topFloor > 0 else { return nil }
        let diff = statsPrevious.avgSeconds - statsCurrent.avgSeconds
        guard abs(diff) > 0.1 else { return nil }
        return diff > 0
            ? String(format: NSLocalizedString("dashboard_speed_faster", comment: ""), String(format: "%.1f", diff))
            : "▼\(String(format: "%.1f", abs(diff)))s"
    }

    private var floorDiff: Int {
        statsCurrent.topFloor - statsPrevious.topFloor
    }

    private var comboDiff: Int {
        statsCurrent.maxCombo - statsPrevious.maxCombo
    }

    private var mistakeRanking: [MistakeEntry] {
        mistakes.sorted { $0.reviewCount < $1.reviewCount }
    }

    // MARK: - カテゴリ別弱点

    private enum MathCat: String, CaseIterable {
        case addBasic = "dashboard_cat_add_basic"
        case addCarry = "dashboard_cat_add_carry"
        case subBasic = "dashboard_cat_sub_basic"
        case subBorrow = "dashboard_cat_sub_borrow"
    }

    private func categorize(_ e: MistakeEntry) -> MathCat {
        if e.answer == e.a + e.b {
            return e.answer > 10 ? .addCarry : .addBasic
        } else {
            return e.a > 10 ? .subBorrow : .subBasic
        }
    }

    private var beforeAfterCard: some View {
        let before = DataStore.loadBeforeTestScore()
        let hasAfter = DataStore.hasCompletedAfterTest()
        let after = hasAfter ? DataStore.loadAfterTestScore() : 0
        let diff = after - before

        return VStack(alignment: .leading, spacing: 10) {
            Text(NSLocalizedString("dashboard_before_after_title", comment: ""))
                .font(.zenMaru(14, weight: .bold))

            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text(NSLocalizedString("dashboard_before_label", comment: ""))
                        .font(.zenMaru(10, weight: .regular))
                        .foregroundColor(.secondary)
                    Text("\(before)%")
                        .font(.zenMaru(24, weight: .black))
                        .foregroundColor(.orange)
                }
                .frame(maxWidth: .infinity)

                Image(systemName: "arrow.right")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(hasAfter ? .green : .secondary)

                VStack(spacing: 4) {
                    Text(NSLocalizedString("dashboard_after_label", comment: ""))
                        .font(.zenMaru(10, weight: .regular))
                        .foregroundColor(.secondary)
                    if hasAfter {
                        Text("\(after)%")
                            .font(.zenMaru(24, weight: .black))
                            .foregroundColor(.green)
                    } else {
                        Text("—")
                            .font(.zenMaru(24, weight: .black))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
            }

            if hasAfter && diff > 0 {
                Text(String(format: NSLocalizedString("dashboard_growth", comment: ""), diff))
                    .font(.zenMaru(12, weight: .bold))
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    private var categoryWeaknessCard: some View {
        let grouped = Dictionary(grouping: mistakes, by: { categorize($0) })
        let cats: [(MathCat, Int)] = MathCat.allCases.compactMap { cat in
            guard let entries = grouped[cat], !entries.isEmpty else { return nil }
            return (cat, entries.count)
        }.sorted { $0.1 > $1.1 }
        let maxCount = cats.first?.1 ?? 1

        return VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("dashboard_cat_title", comment: ""))
                .font(.zenMaru(14, weight: .bold))

            ForEach(cats, id: \.0) { cat, count in
                HStack(spacing: 8) {
                    Text(NSLocalizedString(cat.rawValue, comment: ""))
                        .font(.zenMaru(12, weight: .bold))
                        .frame(width: 110, alignment: .leading)
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(count == maxCount ? Color.red.opacity(0.7) : Color.orange.opacity(0.5))
                            .frame(width: geo.size.width * CGFloat(count) / CGFloat(maxCount))
                    }
                    .frame(height: 12)
                    Text("\(count)")
                        .font(.zenMaru(11, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(width: 28, alignment: .trailing)
                }
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    // MARK: - マスター度

    private var totalMastery: Int { DataStore.totalMasteryPercent() }

    private func barColor(for pct: Int) -> LinearGradient {
        if pct <= 50 {
            return LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)
        } else if pct <= 80 {
            return LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing)
        } else {
            return LinearGradient(colors: [.yellow, .green], startPoint: .leading, endPoint: .trailing)
        }
    }

    private var masteryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            // ヘッダー + 全体%
            HStack {
                HStack(spacing: 6) {
                    Text("📚")
                        .font(.system(size: 16))
                    Text("dashboard_mastery_title")
                        .font(.zenMaru(14, weight: .bold))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("\(totalMastery)%")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(totalMastery >= 100 ? greenColor : accentPurple)
            }

            // 全体プログレスバー
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.15))
                    RoundedRectangle(cornerRadius: 6)
                        .fill(barColor(for: totalMastery))
                        .frame(width: geo.size.width * max(0, masteryAnimated / 100.0))
                }
            }
            .frame(height: 14)

            // カテゴリ別
            ForEach(MathCategory.allCases, id: \.rawValue) { cat in
                let pct = DataStore.masteryPercent(for: cat)
                let count = DataStore.masteryCount(for: cat)
                HStack(spacing: 8) {
                    Text(cat.label)
                        .font(.zenMaru(12, weight: .bold))
                        .frame(width: 100, alignment: .leading)
                        .lineLimit(1)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.gray.opacity(0.12))
                            RoundedRectangle(cornerRadius: 3)
                                .fill(barColor(for: pct))
                                .frame(width: geo.size.width * Double(pct) / 100.0)
                        }
                    }
                    .frame(height: 8)
                    Text("\(count)/\(MathCategory.masteryThreshold)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                        .frame(width: 40, alignment: .trailing)
                    if pct >= 100 {
                        Text("✅")
                            .font(.system(size: 12))
                    }
                }
            }

            // サブテキスト
            if totalMastery >= 100 {
                Text("dashboard_mastery_complete")
                    .font(.zenMaru(13, weight: .bold))
                    .foregroundColor(greenColor)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    // MARK: - 4週間グラフ

    private var weeklySpeedChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("dashboard_speed_chart")
                .font(.zenMaru(14, weight: .bold))
            Text("dashboard_speed_hint")
                .font(.zenMaru(10, weight: .regular))
                .foregroundColor(.secondary)

            let weeklyData = weeklySpeedData
            if weeklyData.allSatisfy({ $0 == 0 }) {
                Text("dashboard_no_chart_data")
                    .font(.zenMaru(12, weight: .regular))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                let maxVal = max(weeklyData.max() ?? 1, 1)
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(0..<4, id: \.self) { i in
                        let val = weeklyData[i]
                        VStack(spacing: 4) {
                            if val > 0 {
                                Text(String(format: "%.1f", val))
                                    .font(.zenMaru(10, weight: .bold))
                                    .foregroundColor(greenColor)
                            }
                            RoundedRectangle(cornerRadius: 4)
                                .fill(greenColor.opacity(0.3 + Double(i) * 0.2))
                                .frame(height: val > 0 ? CGFloat(val / maxVal) * 80 : 4)
                            Text(weekLabels[i])
                                .font(.zenMaru(10, weight: .regular))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 120)
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    private var weeklyAccuracyChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(NSLocalizedString("dashboard_accuracy_chart", comment: ""))
                    .font(.zenMaru(14, weight: .bold))
                Spacer()
                if let delta = accuracyDelta {
                    Text(delta)
                        .font(.zenMaru(11, weight: .bold))
                        .foregroundColor(delta.hasPrefix("▲") ? .green : .red)
                }
            }
            Text(NSLocalizedString("dashboard_accuracy_hint", comment: ""))
                .font(.zenMaru(10, weight: .regular))
                .foregroundColor(.secondary)

            let weeklyData = weeklyAccuracyData
            if weeklyData.allSatisfy({ $0 == 0 }) {
                Text(NSLocalizedString("dashboard_no_chart_data", comment: ""))
                    .font(.zenMaru(12, weight: .regular))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(0..<4, id: \.self) { i in
                        let val = weeklyData[i]
                        VStack(spacing: 4) {
                            if val > 0 {
                                Text("\(Int(val))%")
                                    .font(.zenMaru(10, weight: .bold))
                                    .foregroundColor(accentPurple)
                            }
                            RoundedRectangle(cornerRadius: 4)
                                .fill(accentPurple.opacity(0.3 + Double(i) * 0.2))
                                .frame(height: val > 0 ? CGFloat(val / 100) * 80 : 4)
                            Text(weekLabels[i])
                                .font(.zenMaru(10, weight: .regular))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 120)
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    private var weeklyAccuracyData: [Double] {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        let now = Date()

        return (0..<4).map { weekIndex in
            let start = TimeInterval((3 - weekIndex) * 7 + 7) * 86400
            let end = TimeInterval((3 - weekIndex) * 7) * 86400
            let weekSessions = sessions.filter { s in
                guard let d = f.date(from: s.date) else { return false }
                let interval = now.timeIntervalSince(d)
                return interval > end && interval <= start
            }
            let totalCorrect = weekSessions.reduce(0) { $0 + $1.correctCount }
            let totalCount = weekSessions.reduce(0) { $0 + $1.totalCount }
            return totalCount > 0 ? Double(totalCorrect) / Double(totalCount) * 100 : 0
        }
    }

    private var playCalendarCard: some View {
        let playedDates = Set(sessions.map { $0.date })
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        let today = Date()
        let days: [(String, Bool)] = (0..<28).reversed().map { i in
            let date = Calendar.current.date(byAdding: .day, value: -i, to: today)!
            let str = f.string(from: date)
            return (str, playedDates.contains(str))
        }
        let dayF = DateFormatter()
        dayF.dateFormat = "d"

        return VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("dashboard_calendar_title", comment: ""))
                .font(.zenMaru(14, weight: .bold))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(days, id: \.0) { dateStr, played in
                    let day = dateStr.suffix(2).trimmingCharacters(in: CharacterSet(charactersIn: "0"))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(played ? Color.green.opacity(0.7) : Color.gray.opacity(0.15))
                        .frame(height: 28)
                        .overlay(
                            Text(day)
                                .font(.system(size: 9, weight: played ? .bold : .regular))
                                .foregroundColor(played ? .white : .secondary)
                        )
                }
            }

            let playedCount = days.filter { $0.1 }.count
            Text(String(format: NSLocalizedString("dashboard_calendar_summary", comment: ""), playedCount, 28))
                .font(.zenMaru(11, weight: .regular))
                .foregroundColor(.secondary)
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    private var accuracyDelta: String? {
        let data = weeklyAccuracyData
        let thisWeek = data[3]
        let lastWeek = data[2]
        guard thisWeek > 0, lastWeek > 0 else { return nil }
        let diff = thisWeek - lastWeek
        guard abs(diff) >= 1 else { return nil }
        return diff > 0 ? "▲+\(Int(diff))%" : "▼\(Int(diff))%"
    }

    private var weekLabels: [String] {
        ["dashboard_week_4ago", "dashboard_week_3ago", "dashboard_week_last", "dashboard_week_this"].map {
            NSLocalizedString($0, comment: "")
        }
    }

    private var weeklySpeedData: [Double] {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        let now = Date()

        return (0..<4).map { weekIndex in
            let start = TimeInterval((3 - weekIndex) * 7 + 7) * 86400
            let end = TimeInterval((3 - weekIndex) * 7) * 86400
            let weekSessions = sessions.filter { s in
                guard let d = f.date(from: s.date) else { return false }
                let interval = now.timeIntervalSince(d)
                return interval > end && interval <= start
            }
            let times = weekSessions.flatMap { $0.answerTimeLogs.map { $0.elapsedSeconds } }
            return times.isEmpty ? 0 : times.reduce(0, +) / Double(times.count)
        }
    }

    // MARK: - Sub Views

    private func dashCard(
        icon: String, label: String, value: String,
        diff: String?, diffPositive: Bool, sub: String?, color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Text(icon).font(.system(size: 14))
                Text(label)
                    .font(.zenMaru(11, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Text(value)
                .font(.zenMaru(22, weight: .black))
                .foregroundColor(value == "—" ? .secondary : color)
            if let diff {
                Text(diff)
                    .font(.zenMaru(11, weight: .bold))
                    .foregroundColor(diffPositive ? greenColor : .red.opacity(0.7))
            }
            if let sub {
                Text(sub)
                    .font(.zenMaru(10, weight: .regular))
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    private func mistakeRow(rank: Int, entry: MistakeEntry) -> some View {
        HStack {
            Text("\(rank).")
                .font(.zenMaru(14, weight: .bold))
                .foregroundColor(.secondary)
                .frame(width: 24)
            Text("\(entry.a) + \(entry.b) = \(entry.answer)")
                .font(.zenMaru(16, weight: .bold))
            Spacer()
            Text(String(format: NSLocalizedString("dashboard_mistake_format", comment: ""), entry.wrongAnswer))
                .font(.zenMaru(11, weight: .regular))
                .foregroundColor(.red.opacity(0.7))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
    }
}

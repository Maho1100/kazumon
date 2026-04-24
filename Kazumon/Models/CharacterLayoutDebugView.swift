#if DEBUG
import SwiftUI

// MARK: - パーツ位置デバッグ調整ビュー
//
// 主人公（進化段階別）または敵キャラを選択して
// eyes / mouth / detail / nose / arm / leg の offset をリアルタイムで微調整できる DEBUG 専用パネル。
//
// 調整が終わったら、表示される値を
// CharacterPartOffsets.registry にコピーして固定化する。

// MARK: - キャラクター種別

private enum DebugCharacterCategory: String, CaseIterable {
    case hero    = "主人公"
    case monster = "敵"
}

private struct HeroEntry: Identifiable {
    let id: CharacterEvolutionStage
    let label: String
    let appearance: CharacterAppearance
}

private struct MonsterEntry: Identifiable {
    let id: String
    let label: String
    let appearance: CharacterAppearance
}

// MARK: - CharacterLayoutDebugView

struct CharacterLayoutDebugView: View {
    @Environment(\.dismiss) private var dismiss

    // ── キャラクター選択 ──
    @State private var category: DebugCharacterCategory = .hero
    @State private var selectedHeroStage: CharacterEvolutionStage = .base
    @State private var selectedMonsterID: String = "slime"

    // ── 表情テスト ──
    @State private var selectedMood: KennyCharacterView.IdleMood = .normal
    @State private var moodBlushX: CGFloat = 0.32
    @State private var moodBlushY: CGFloat = -0.34
    @State private var moodBlushSize: CGFloat = 0.14
    @State private var moodBlushOpacity: CGFloat = 0.33
    @State private var moodSmirkX: CGFloat = 0.01
    @State private var moodSmirkY: CGFloat = -0.07
    @State private var moodSmirkW: CGFloat = 0.14
    @State private var moodSmirkH: CGFloat = 0.07
    @State private var moodSquintW: CGFloat = 0.83
    @State private var moodSquintH: CGFloat = 0.04
    @State private var moodSquintSpread: CGFloat = 1.41
    @State private var moodLeftEyeScale: CGFloat = 1.0
    @State private var moodRightEyeScale: CGFloat = 1.0
    @State private var moodSurprisedX: CGFloat = 0.25
    @State private var moodSurprisedY: CGFloat = 0.10
    @State private var moodSurprisedScale: CGFloat = 0.25

    // ── パーツオフセット ──
    @State private var bodyScale: CGFloat = 1.0
    @State private var eyesX: CGFloat = 0
    @State private var eyesY: CGFloat = 0
    @State private var eyeScale: CGFloat = 1.0
    @State private var eyeSpreadVal: CGFloat = 0
    @State private var mouthX: CGFloat = 0
    @State private var mouthY: CGFloat = 0
    @State private var detailX: CGFloat = 0
    @State private var detailY: CGFloat = 0
    @State private var detailRotation: CGFloat = 0
    @State private var detail2X: CGFloat = 0
    @State private var detail2Y: CGFloat = 0
    @State private var detail2Rotation: CGFloat = 0
    @State private var detail3X: CGFloat = 0
    @State private var detail3Y: CGFloat = 0
    @State private var detail3Rotation: CGFloat = 0
    @State private var detailSpread: CGFloat = 0
    @State private var selectedDetail2: String = "detail_none"
    @State private var selectedDetail3: String = "detail_none"
    @State private var noseX: CGFloat = 0
    @State private var noseY: CGFloat = 0

    // 腕
    @State private var armOffsetX: CGFloat = 0
    @State private var armOffsetY: CGFloat = 0
    @State private var armScale:   CGFloat = 1.0
    @State private var armRotation: CGFloat = 0
    @State private var leftArmRotation: CGFloat = 0
    @State private var rightArmRotation: CGFloat = 0
    @State private var leftArmOffsetX: CGFloat = 0
    @State private var rightArmOffsetX: CGFloat = 0
    // 喜びポーズ
    @State private var showJoyPose: Bool = false
    @State private var showDefeated: Bool = false
    @State private var showHurt: Bool = false
    @State private var showAttacking: Bool = false
    @State private var joyLeftArmX: CGFloat = -65
    @State private var joyLeftArmY: CGFloat = 0
    @State private var joyLeftArmR: CGFloat = -170
    @State private var joyRightArmX: CGFloat = 63
    @State private var joyRightArmY: CGFloat = 0
    @State private var joyRightArmR: CGFloat = 170
    // 向き
    @State private var selectedFacing: KennyCharacterView.Facing = .front
    // 左向き専用オフセット
    @State private var leftEyeOX: CGFloat = 0
    @State private var leftEyeOY: CGFloat = 0
    @State private var leftEyeOSpread: CGFloat = 0
    @State private var leftEyeOScaleL: CGFloat = 1.0
    @State private var leftEyeOScaleR: CGFloat = 1.0
    @State private var leftMouthOX: CGFloat = 0
    @State private var leftMouthOY: CGFloat = 0

    // 登場アニメ
    @State private var showEntrance = false
    @State private var entranceAnimating = false
    @State private var entranceOffsetY: CGFloat = 0
    @State private var timelineValue: CGFloat = 0
    @State private var timelineScrubbing = false
    @State private var dbgLegSkew: CGFloat = 0
    @State private var dbgEntranceLegSpread: CGFloat = 0
    @State private var dbgEntranceBodyScaleX: CGFloat = 1.0
    @State private var dbgEntranceBodyScaleY: CGFloat = 1.0
    @State private var dbgEntranceArmRotation: CGFloat = 0
    @State private var dbgEntranceUseJoyArms: Bool = false
    @State private var dbgEntranceJoyArmLX: CGFloat = -65
    @State private var dbgEntranceJoyArmLY: CGFloat = 0
    @State private var dbgEntranceJoyArmLR: CGFloat = -170
    @State private var dbgEntranceJoyArmRX: CGFloat = 63
    @State private var dbgEntranceJoyArmRY: CGFloat = 0
    @State private var dbgEntranceJoyArmRR: CGFloat = 170

    // 足
    @State private var legOffsetX: CGFloat = 0
    @State private var legOffsetY: CGFloat = 0
    @State private var legScale:   CGFloat = 1.0
    @State private var legRotation: CGFloat = 0
    @State private var legSpread:  CGFloat = 0

    // 縁取り
    @State private var dbgOutlineThickness: CGFloat = 3.6
    @State private var dbgOutlinePadding: CGFloat = 0.6
    @State private var dbgOutlineColorIdx: Int = 0
    @State private var dbgBgColorIdx: Int = 0
    private let outlineColorOptions: [(String, Color)] = [
        ("黒", .black), ("白", .white), ("黄", .yellow),
        ("水", .cyan), ("緑", .green), ("赤", .red), ("紫", .purple)
    ]
    private let bgColorOptions: [(String, Color)] = [
        ("暗", Color(white: 0.15)),
        ("草原", Color(red: 0.72, green: 0.93, blue: 1.0)),
        ("洞窟", Color(red: 0.50, green: 0.48, blue: 0.45)),
        ("城", Color(red: 0.55, green: 0.55, blue: 0.80)),
        ("魔王", Color(red: 0.15, green: 0.13, blue: 0.40)),
        ("白", .white),
        ("緑", Color(red: 0.4, green: 0.7, blue: 0.3))
    ]

    // 頭
    @State private var headX: CGFloat = 0
    @State private var headY: CGFloat = 0
    @State private var headScale: CGFloat = 1.0
    @State private var headRotation: CGFloat = 0

    // 頭のシャイン（白い反射）
    @State private var shineX: CGFloat = -0.18
    @State private var shineY: CGFloat = -0.05
    @State private var shineW: CGFloat = 0.08
    @State private var shineH: CGFloat = 0.18
    @State private var shineRotation: CGFloat = -30
    @State private var shineOpacity: CGFloat = 0.9

    // プログラミック口
    @State private var useProgMouth: Bool = false
    @State private var pmouthW: CGFloat = 0.15
    @State private var pmouthH: CGFloat = 0.06
    @State private var pmouthOffsetX: CGFloat = 0
    @State private var pmouthOffsetY: CGFloat = 0
    @State private var pmouthCurve: CGFloat = 0

    // ── 調整単位 ──
    @State private var step: CGFloat = 1.0
    private let steps: [CGFloat] = [0.5, 1.0, 2.0]

    @State private var rotationStep: CGFloat = 5.0
    private let rotationSteps: [CGFloat] = [1.0, 5.0, 15.0, 45.0]

    @State private var scaleStep: CGFloat = 0.1
    private let scaleSteps: [CGFloat] = [0.05, 0.1, 0.2]

    // ── 主人公リスト ──
    private let heroEntries: [HeroEntry] = [
        HeroEntry(id: .base,      label: "base（Lv1〜4）",      appearance: CharacterAppearanceFactory.appearance(for: .base)),
        HeroEntry(id: .evolve1,   label: "evolve1（Lv5〜9）",   appearance: CharacterAppearanceFactory.appearance(for: .evolve1)),
        HeroEntry(id: .evolve2,   label: "evolve2（Lv10〜19）", appearance: CharacterAppearanceFactory.appearance(for: .evolve2)),
        HeroEntry(id: .finalForm, label: "finalForm（Lv20+）",  appearance: CharacterAppearanceFactory.appearance(for: .finalForm)),
    ]

    // ── 敵リスト ──
    private let monsterEntries: [MonsterEntry] = [
        MonsterEntry(id: "slime",      label: "スライム(島)",    appearance: .slime),
        MonsterEntry(id: "enemySlime", label: "スライム(敵)",   appearance: .enemySlime),
        MonsterEntry(id: "bossSlime",  label: "ボススライム",   appearance: .bossSlime),
        MonsterEntry(id: "goblin",     label: "ゴブリン",       appearance: .goblin),
        MonsterEntry(id: "bossGoblin", label: "ボスゴブリン",   appearance: .bossGoblin),
        MonsterEntry(id: "orc",        label: "オーク",         appearance: .orc),
        MonsterEntry(id: "bossOrc",    label: "ボスオーク",     appearance: .bossOrc),
        MonsterEntry(id: "dragon",     label: "ドラゴン",       appearance: .dragon),
        MonsterEntry(id: "bossDragon", label: "ボスドラゴン",   appearance: .bossDragon),
        MonsterEntry(id: "demon",      label: "デーモン",       appearance: .demon),
        MonsterEntry(id: "demonLord",  label: "魔王",           appearance: .demonLord),
        MonsterEntry(id: "mistakeOni", label: "まちがいおに",   appearance: .mistakeOni),
        MonsterEntry(id: "timeBoss",   label: "じかんどろぼう", appearance: .timeBoss),
    ]

    // ── 現在の見た目 ──
    private var appearance: CharacterAppearance {
        var base: CharacterAppearance
        switch category {
        case .hero:
            base = heroEntries.first { $0.id == selectedHeroStage }?.appearance
                ?? CharacterAppearanceFactory.appearance(for: .base)
        case .monster:
            base = monsterEntries.first { $0.id == selectedMonsterID }?.appearance
                ?? .slime
        }
        base.detail2 = selectedDetail2
        base.detail3 = selectedDetail3
        return base
    }

    private var currentMoodOffsets: MoodOverlayOffsets {
        MoodOverlayOffsets(
            blushX: moodBlushX, blushY: moodBlushY, blushSize: moodBlushSize, blushOpacity: moodBlushOpacity,
            smirkX: moodSmirkX, smirkY: moodSmirkY, smirkW: moodSmirkW, smirkH: moodSmirkH,
            squintW: moodSquintW, squintH: moodSquintH, squintSpread: moodSquintSpread,
            surprisedX: moodSurprisedX, surprisedY: moodSurprisedY, surprisedScale: moodSurprisedScale,
            leftEyeScale: moodLeftEyeScale, rightEyeScale: moodRightEyeScale
        )
    }

    private var currentOffsets: CharacterPartOffsets {
        var o = CharacterPartOffsets()
        // 顔
        o.eyes      = CGSize(width: eyesX,  height: eyesY)
        o.bodyScale = bodyScale
        o.eyeScale  = eyeScale
        o.eyeSpread = eyeSpreadVal
        o.mouth     = CGSize(width: mouthX, height: mouthY)
        o.nose      = CGSize(width: noseX,  height: noseY)
        // 装飾
        o.detail   = CGSize(width: detailX,  height: detailY)
        o.detailRotation = detailRotation
        o.detail2  = CGSize(width: detail2X, height: detail2Y)
        o.detail2Rotation = detail2Rotation
        o.detail3  = CGSize(width: detail3X, height: detail3Y)
        o.detail3Rotation = detail3Rotation
        o.detailSpread = detailSpread
        // 頭
        o.head        = CGSize(width: headX, height: headY)
        o.headScale   = headScale
        o.headRotation = headRotation
        // シャイン
        o.shineX = shineX; o.shineY = shineY
        o.shineW = shineW; o.shineH = shineH
        o.shineRotation = shineRotation; o.shineOpacity = shineOpacity
        // 腕
        o.armOffset = CGSize(width: armOffsetX, height: armOffsetY)
        o.armScale  = armScale
        o.armRotation = armRotation
        o.leftArmRotation = leftArmRotation
        o.rightArmRotation = rightArmRotation
        o.leftArmOffsetX = leftArmOffsetX
        o.rightArmOffsetX = rightArmOffsetX
        o.joyLeftArmX = joyLeftArmX; o.joyLeftArmY = joyLeftArmY
        o.joyLeftArmR = joyLeftArmR
        o.joyRightArmX = joyRightArmX; o.joyRightArmY = joyRightArmY
        o.joyRightArmR = joyRightArmR
        // 足
        o.legOffset = CGSize(width: legOffsetX, height: legOffsetY)
        o.legScale  = legScale
        o.legRotation = legRotation
        o.legSpread = legSpread
        // 表情
        o.mood = currentMoodOffsets
        // プログラミック口
        o.useProgrammaticMouth = useProgMouth
        o.pmouthW = pmouthW; o.pmouthH = pmouthH
        o.pmouthOffsetX = pmouthOffsetX; o.pmouthOffsetY = pmouthOffsetY
        o.pmouthCurve = pmouthCurve
        // 左向き
        o.leftEyeOffsetX = leftEyeOX
        o.leftEyeOffsetY = leftEyeOY
        o.leftEyeSpread = leftEyeOSpread
        o.leftEyeScaleL = leftEyeOScaleL
        o.leftEyeScaleR = leftEyeOScaleR
        o.leftMouthOffsetX = leftMouthOX
        o.leftMouthOffsetY = leftMouthOY
        // 登場アニメ
        if showEntrance {
            o.legSkew = dbgLegSkew
            o.entranceLegSpread = dbgEntranceLegSpread
            o.entranceBodyScaleX = dbgEntranceBodyScaleX
            o.entranceBodyScaleY = dbgEntranceBodyScaleY
            o.entranceArmRotation = dbgEntranceArmRotation
            if dbgEntranceUseJoyArms {
                o.joyLeftArmX = dbgEntranceJoyArmLX
                o.joyLeftArmY = dbgEntranceJoyArmLY
                o.joyLeftArmR = dbgEntranceJoyArmLR
                o.joyRightArmX = dbgEntranceJoyArmRX
                o.joyRightArmY = dbgEntranceJoyArmRY
                o.joyRightArmR = dbgEntranceJoyArmRR
            }
        }
        return o
    }

    // MARK: - body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // ══ 固定ヘッダー ══
                VStack(spacing: 12) {

                    // ── キャラクタープレビュー ──
                    ZStack {
                        bgColorOptions[dbgBgColorIdx].1
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        KennyCharacterView(
                            appearance: appearance,
                            size: 100,
                            isAttacking: showAttacking,
                            isHurt: showHurt,
                            isDefeated: showDefeated,
                            playEntrance: showEntrance,
                            isJoyPose: showJoyPose || (showEntrance && dbgEntranceUseJoyArms),
                            facing: selectedFacing,
                            idleMood: selectedMood,
                            outlineThickness: dbgOutlineThickness,
                            outlineColor: outlineColorOptions[dbgOutlineColorIdx].1,
                            outlinePadding: dbgOutlinePadding,
                            debugPartOffsets: currentOffsets,
                            debugMoodOffsets: currentMoodOffsets
                        )
                        .offset(y: entranceOffsetY)
                        .padding(.vertical, 16)
                    }
                    .frame(height: 200)
                    .padding(.horizontal, 20)

                    // ── body 情報 ──
                    HStack {
                        Text("body:")
                            .font(.caption.monospaced())
                            .foregroundColor(.secondary)
                        Text(appearance.body)
                            .font(.caption.monospaced().bold())
                        Spacer()
                    }
                    .padding(.horizontal, 24)

                    // ── 向き切り替え ──
                    Picker("向き", selection: $selectedFacing) {
                        Text("正面").tag(KennyCharacterView.Facing.front)
                        Text("→右向き").tag(KennyCharacterView.Facing.right)
                        Text("←左向き").tag(KennyCharacterView.Facing.left)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)

                    // ── カテゴリ切り替え（主人公 / 敵）──
                    Picker("カテゴリ", selection: $category) {
                        ForEach(DebugCharacterCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .onChange(of: category) { _, _ in loadOffsetsForCurrentBody() }
                }
                .padding(.bottom, 12)
                .background(Color(.systemBackground))

                Divider()

                // ══ スクロール領域 ══
                ScrollView {
                    VStack(spacing: 16) {

                        // ── 主人公: 進化段階リスト ──
                        if category == .hero {
                            VStack(spacing: 6) {
                                ForEach(heroEntries) { entry in
                                    Button {
                                        selectedHeroStage = entry.id
                                        loadOffsetsForCurrentBody()
                                    } label: {
                                        HStack {
                                            Text(entry.label)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(selectedHeroStage == entry.id ? .white : .primary)
                                            Spacer()
                                            Text(entry.appearance.body)
                                                .font(.caption.monospaced())
                                                .foregroundColor(selectedHeroStage == entry.id ? .white.opacity(0.8) : .secondary)
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(selectedHeroStage == entry.id ? Color.blue : Color(.systemGray6))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                        }

                        // ── 敵: モンスターリスト ──
                        if category == .monster {
                            VStack(spacing: 6) {
                                ForEach(monsterEntries) { entry in
                                    Button {
                                        selectedMonsterID = entry.id
                                        loadOffsetsForCurrentBody()
                                    } label: {
                                        HStack {
                                            Text(entry.label)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(selectedMonsterID == entry.id ? .white : .primary)
                                            Spacer()
                                            Text(entry.appearance.body)
                                                .font(.caption.monospaced())
                                                .foregroundColor(selectedMonsterID == entry.id ? .white.opacity(0.8) : .secondary)
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(selectedMonsterID == entry.id ? Color.indigo : Color(.systemGray6))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                        }

                        // ── 調整単位 ──
                        HStack(spacing: 8) {
                            Text("単位:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            ForEach(steps, id: \.self) { s in
                                Button { step = s } label: {
                                    Text("\(s, specifier: "%.1f")pt")
                                        .font(.caption.bold())
                                        .foregroundColor(step == s ? .white : .orange)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(step == s ? Color.orange : Color.orange.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                            }
                            Spacer()
                            Button("リセット") { resetOffsets() }
                                .font(.caption.bold())
                                .foregroundColor(.red)
                        }
                        .padding(.horizontal, 24)

                        Divider().padding(.horizontal, 20)

                        // ── パーツ調整 ──
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                Text("body").font(.caption2.bold()).foregroundColor(.indigo).frame(width: 40, alignment: .leading)
                                Text("大きさ").font(.caption2).foregroundColor(.secondary)
                                Button { bodyScale -= 0.05 } label: { Image(systemName: "minus.circle.fill").font(.title3).foregroundColor(.indigo.opacity(0.7)) }
                                Text("\(bodyScale, specifier: "%.2f")").font(.system(size: 13, design: .monospaced)).frame(width: 44)
                                Button { bodyScale += 0.05 } label: { Image(systemName: "plus.circle.fill").font(.title3).foregroundColor(.indigo.opacity(0.7)) }
                                Button { bodyScale = 1.0 } label: { Text("1×").font(.caption2.bold()).foregroundColor(.indigo) }
                            }
                            offsetRow(label: "eyes",  x: $eyesX,  y: $eyesY,  color: .blue)
                            // 目のサイズ・距離
                            HStack(spacing: 12) {
                                Text("目").font(.caption2).foregroundColor(.blue).frame(width: 24)
                                Text("大きさ").font(.caption2).foregroundColor(.secondary)
                                Button { eyeScale -= scaleStep } label: { Image(systemName: "minus.circle.fill").font(.title3).foregroundColor(Color.blue.opacity(0.7)) }
                                Text("\(eyeScale, specifier: "%.2f")").font(.system(size: 13, design: .monospaced)).frame(width: 44)
                                Button { eyeScale += scaleStep } label: { Image(systemName: "plus.circle.fill").font(.title3).foregroundColor(Color.blue.opacity(0.7)) }
                                Text("距離").font(.caption2).foregroundColor(.secondary)
                                Button { eyeSpreadVal -= step } label: { Image(systemName: "minus.circle.fill").font(.title3).foregroundColor(Color.blue.opacity(0.7)) }
                                Text("\(eyeSpreadVal, specifier: "%+.1f")").font(.system(size: 13, design: .monospaced)).frame(width: 44)
                                Button { eyeSpreadVal += step } label: { Image(systemName: "plus.circle.fill").font(.title3).foregroundColor(Color.blue.opacity(0.7)) }
                            }
                            HStack(spacing: 8) {
                                Text("左目").font(.caption2).foregroundColor(.blue)
                                Button { moodLeftEyeScale -= 0.05 } label: { Image(systemName: "minus.circle.fill").font(.title3).foregroundColor(.blue.opacity(0.7)) }
                                Text("\(moodLeftEyeScale, specifier: "%.2f")").font(.system(size: 12, design: .monospaced)).frame(width: 40)
                                Button { moodLeftEyeScale += 0.05 } label: { Image(systemName: "plus.circle.fill").font(.title3).foregroundColor(.blue.opacity(0.7)) }
                                Spacer()
                                Text("右目").font(.caption2).foregroundColor(.blue)
                                Button { moodRightEyeScale -= 0.05 } label: { Image(systemName: "minus.circle.fill").font(.title3).foregroundColor(.blue.opacity(0.7)) }
                                Text("\(moodRightEyeScale, specifier: "%.2f")").font(.system(size: 12, design: .monospaced)).frame(width: 40)
                                Button { moodRightEyeScale += 0.05 } label: { Image(systemName: "plus.circle.fill").font(.title3).foregroundColor(.blue.opacity(0.7)) }
                            }
                            Group {
                                detailOffsetRow()
                                detail2Row()
                                detail3Row()
                                detailSpreadRow()
                                offsetRow(label: "mouth", x: $mouthX, y: $mouthY, color: .green)
                                offsetRow(label: "nose",  x: $noseX,  y: $noseY,  color: .orange)
                            }
                            Group {
                                headOffsetRow()
                                shineRow()
                                programMouthRow()
                            }
                            // ── 左向き専用オフセット ──
                            Group {
                                Divider()
                                Text("← 左向き専用").font(.caption.bold()).foregroundColor(.purple)
                                offsetRow(label: "eyes", x: $leftEyeOX, y: $leftEyeOY, color: .purple)
                                HStack(spacing: 8) {
                                    Text("距離").font(.caption2).foregroundColor(.purple)
                                    Button { leftEyeOSpread -= step } label: { Image(systemName: "minus.circle.fill").font(.title3).foregroundColor(.purple.opacity(0.7)) }
                                    Text("\(leftEyeOSpread, specifier: "%+.1f")").font(.system(size: 13, design: .monospaced)).frame(width: 44)
                                    Button { leftEyeOSpread += step } label: { Image(systemName: "plus.circle.fill").font(.title3).foregroundColor(.purple.opacity(0.7)) }
                                }
                                HStack(spacing: 8) {
                                    Text("左目").font(.caption2).foregroundColor(.purple)
                                    Button { leftEyeOScaleL -= 0.05 } label: { Image(systemName: "minus.circle.fill").font(.title3).foregroundColor(.purple.opacity(0.7)) }
                                    Text("\(leftEyeOScaleL, specifier: "%.2f")").font(.system(size: 12, design: .monospaced)).frame(width: 40)
                                    Button { leftEyeOScaleL += 0.05 } label: { Image(systemName: "plus.circle.fill").font(.title3).foregroundColor(.purple.opacity(0.7)) }
                                    Spacer()
                                    Text("右目").font(.caption2).foregroundColor(.purple)
                                    Button { leftEyeOScaleR -= 0.05 } label: { Image(systemName: "minus.circle.fill").font(.title3).foregroundColor(.purple.opacity(0.7)) }
                                    Text("\(leftEyeOScaleR, specifier: "%.2f")").font(.system(size: 12, design: .monospaced)).frame(width: 40)
                                    Button { leftEyeOScaleR += 0.05 } label: { Image(systemName: "plus.circle.fill").font(.title3).foregroundColor(.purple.opacity(0.7)) }
                                }
                                offsetRow(label: "mouth", x: $leftMouthOX, y: $leftMouthOY, color: .purple)
                            }
                            Group {
                                armOffsetRow()
                                legOffsetRow()
                            }

                            // ── 縁取り ──
                            Divider().padding(.vertical, 4)
                            VStack(alignment: .leading, spacing: 6) {
                                Text("縁取り").font(.caption.bold()).foregroundColor(.mint)
                                HStack {
                                    Text("太さ").font(.caption2).foregroundColor(.mint).frame(width: 40, alignment: .leading)
                                    Slider(value: $dbgOutlineThickness, in: 0...8).tint(.mint)
                                    Text("\(dbgOutlineThickness, specifier: "%.1f")").font(.system(size: 11, design: .monospaced)).frame(width: 30)
                                }
                                HStack {
                                    Text("領域").font(.caption2).foregroundColor(.mint).frame(width: 40, alignment: .leading)
                                    Slider(value: $dbgOutlinePadding, in: 0...1.5).tint(.mint.opacity(0.6))
                                    Text("\(dbgOutlinePadding, specifier: "%.2f")").font(.system(size: 11, design: .monospaced)).frame(width: 40)
                                }
                                HStack {
                                    Text("色").font(.caption2).foregroundColor(.mint).frame(width: 30, alignment: .leading)
                                    ForEach(0..<outlineColorOptions.count, id: \.self) { i in
                                        Button {
                                            dbgOutlineColorIdx = i
                                        } label: {
                                            Text(outlineColorOptions[i].0)
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(dbgOutlineColorIdx == i ? .white : .primary)
                                                .padding(.horizontal, 8).padding(.vertical, 4)
                                                .background(
                                                    Capsule().fill(dbgOutlineColorIdx == i ? outlineColorOptions[i].1 : Color.gray.opacity(0.2))
                                                )
                                        }
                                    }
                                }
                                HStack {
                                    Text("背景").font(.caption2).foregroundColor(.gray).frame(width: 30, alignment: .leading)
                                    ForEach(0..<bgColorOptions.count, id: \.self) { i in
                                        Button {
                                            dbgBgColorIdx = i
                                        } label: {
                                            Circle()
                                                .fill(bgColorOptions[i].1)
                                                .frame(width: 24, height: 24)
                                                .overlay(
                                                    Circle().stroke(dbgBgColorIdx == i ? Color.white : Color.clear, lineWidth: 2)
                                                )
                                        }
                                    }
                                }
                            }

                            // ── バトル状態 ──
                            Divider().padding(.vertical, 4)
                            VStack(alignment: .leading, spacing: 6) {
                                Text("バトル状態").font(.caption.bold()).foregroundColor(.red)
                                HStack(spacing: 16) {
                                    Toggle("攻撃", isOn: $showAttacking).font(.caption2).tint(.orange)
                                    Toggle("被弾", isOn: $showHurt).font(.caption2).tint(.red)
                                    Toggle("敗北", isOn: $showDefeated).font(.caption2).tint(.gray)
                                }
                                .toggleStyle(.button)
                            }

                            // ── 喜びポーズ ──
                            Divider().padding(.vertical, 4)
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("喜びポーズ").font(.caption.bold()).foregroundColor(.purple)
                                    Spacer()
                                    Toggle("", isOn: $showJoyPose)
                                        .labelsHidden()
                                        .tint(.purple)
                                }
                                if showJoyPose {
                                    let step: CGFloat = 5
                                    let rStep: CGFloat = 5
                                    Group {
                                        Text("左腕(裏)").font(.caption2).foregroundColor(.purple)
                                        HStack {
                                            Text("X").font(.caption2)
                                            Button { joyLeftArmX -= step } label: { Image(systemName: "minus.circle.fill").foregroundColor(.purple.opacity(0.7)) }
                                            Text("\(joyLeftArmX, specifier: "%.0f")").font(.system(size: 13, design: .monospaced)).frame(width: 44)
                                            Button { joyLeftArmX += step } label: { Image(systemName: "plus.circle.fill").foregroundColor(.purple.opacity(0.7)) }
                                            Spacer()
                                            Text("R").font(.caption2)
                                            Button { joyLeftArmR -= rStep } label: { Image(systemName: "minus.circle.fill").foregroundColor(.purple.opacity(0.7)) }
                                            Text("\(joyLeftArmR, specifier: "%.0f")°").font(.system(size: 13, design: .monospaced)).frame(width: 50)
                                            Button { joyLeftArmR += rStep } label: { Image(systemName: "plus.circle.fill").foregroundColor(.purple.opacity(0.7)) }
                                        }
                                        HStack {
                                            Text("Y").font(.caption2)
                                            Button { joyLeftArmY -= step } label: { Image(systemName: "minus.circle.fill").foregroundColor(.purple.opacity(0.7)) }
                                            Text("\(joyLeftArmY, specifier: "%.0f")").font(.system(size: 13, design: .monospaced)).frame(width: 44)
                                            Button { joyLeftArmY += step } label: { Image(systemName: "plus.circle.fill").foregroundColor(.purple.opacity(0.7)) }
                                        }
                                        Text("右腕(裏)").font(.caption2).foregroundColor(.purple)
                                        HStack {
                                            Text("X").font(.caption2)
                                            Button { joyRightArmX -= step } label: { Image(systemName: "minus.circle.fill").foregroundColor(.purple.opacity(0.7)) }
                                            Text("\(joyRightArmX, specifier: "%.0f")").font(.system(size: 13, design: .monospaced)).frame(width: 44)
                                            Button { joyRightArmX += step } label: { Image(systemName: "plus.circle.fill").foregroundColor(.purple.opacity(0.7)) }
                                            Spacer()
                                            Text("R").font(.caption2)
                                            Button { joyRightArmR -= rStep } label: { Image(systemName: "minus.circle.fill").foregroundColor(.purple.opacity(0.7)) }
                                            Text("\(joyRightArmR, specifier: "%.0f")°").font(.system(size: 13, design: .monospaced)).frame(width: 50)
                                            Button { joyRightArmR += rStep } label: { Image(systemName: "plus.circle.fill").foregroundColor(.purple.opacity(0.7)) }
                                        }
                                        HStack {
                                            Text("Y").font(.caption2)
                                            Button { joyRightArmY -= step } label: { Image(systemName: "minus.circle.fill").foregroundColor(.purple.opacity(0.7)) }
                                            Text("\(joyRightArmY, specifier: "%.0f")").font(.system(size: 13, design: .monospaced)).frame(width: 44)
                                            Button { joyRightArmY += step } label: { Image(systemName: "plus.circle.fill").foregroundColor(.purple.opacity(0.7)) }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        Divider().padding(.horizontal, 20)

                        // ── 登場アニメ調整 ──
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("登場ポーズ").font(.caption.bold()).foregroundColor(.red)
                                Spacer()
                                Toggle("", isOn: $showEntrance).labelsHidden()
                            }
                            if showEntrance {
                                VStack(spacing: 6) {
                                    HStack {
                                        Text("足シアー").font(.caption2).foregroundColor(.red).frame(width: 60, alignment: .leading)
                                        Slider(value: $dbgLegSkew, in: -1.0...1.0).tint(.red)
                                        Text("\(dbgLegSkew, specifier: "%.2f")").font(.system(size: 11, design: .monospaced)).frame(width: 40)
                                    }
                                    HStack {
                                        Text("足開き").font(.caption2).foregroundColor(.red).frame(width: 60, alignment: .leading)
                                        Slider(value: $dbgEntranceLegSpread, in: -20...40).tint(.red)
                                        Text("\(dbgEntranceLegSpread, specifier: "%.1f")").font(.system(size: 11, design: .monospaced)).frame(width: 40)
                                    }
                                    HStack {
                                        Text("体X").font(.caption2).foregroundColor(.orange).frame(width: 60, alignment: .leading)
                                        Slider(value: $dbgEntranceBodyScaleX, in: 0.7...1.5).tint(.orange)
                                        Text("\(dbgEntranceBodyScaleX, specifier: "%.2f")").font(.system(size: 11, design: .monospaced)).frame(width: 40)
                                    }
                                    HStack {
                                        Text("体Y").font(.caption2).foregroundColor(.orange).frame(width: 60, alignment: .leading)
                                        Slider(value: $dbgEntranceBodyScaleY, in: 0.7...1.5).tint(.orange)
                                        Text("\(dbgEntranceBodyScaleY, specifier: "%.2f")").font(.system(size: 11, design: .monospaced)).frame(width: 40)
                                    }
                                    HStack {
                                        Text("腕回転").font(.caption2).foregroundColor(.cyan).frame(width: 60, alignment: .leading)
                                        Slider(value: $dbgEntranceArmRotation, in: -180...180).tint(.cyan)
                                        Text("\(dbgEntranceArmRotation, specifier: "%.0f")°").font(.system(size: 11, design: .monospaced)).frame(width: 40)
                                    }
                                    Divider()
                                    HStack {
                                        Text("喜び腕に切替").font(.caption2).foregroundColor(.purple)
                                        Spacer()
                                        Toggle("", isOn: $dbgEntranceUseJoyArms).labelsHidden()
                                    }
                                    if dbgEntranceUseJoyArms {
                                        let aStep: CGFloat = 5
                                        let rStep: CGFloat = 5
                                        Text("左腕").font(.caption2.bold()).foregroundColor(.purple)
                                        HStack(spacing: 4) {
                                            Text("X").font(.caption2).frame(width: 14)
                                            Button { dbgEntranceJoyArmLX -= aStep } label: { Image(systemName: "minus.circle.fill").foregroundColor(.purple.opacity(0.7)) }
                                            Text("\(dbgEntranceJoyArmLX, specifier: "%.0f")").font(.system(size: 12, design: .monospaced)).frame(width: 40)
                                            Button { dbgEntranceJoyArmLX += aStep } label: { Image(systemName: "plus.circle.fill").foregroundColor(.purple.opacity(0.7)) }
                                            Text("Y").font(.caption2).frame(width: 14)
                                            Button { dbgEntranceJoyArmLY -= aStep } label: { Image(systemName: "minus.circle.fill").foregroundColor(.purple.opacity(0.7)) }
                                            Text("\(dbgEntranceJoyArmLY, specifier: "%.0f")").font(.system(size: 12, design: .monospaced)).frame(width: 40)
                                            Button { dbgEntranceJoyArmLY += aStep } label: { Image(systemName: "plus.circle.fill").foregroundColor(.purple.opacity(0.7)) }
                                            Text("R").font(.caption2).frame(width: 14)
                                            Button { dbgEntranceJoyArmLR -= rStep } label: { Image(systemName: "minus.circle.fill").foregroundColor(.purple.opacity(0.7)) }
                                            Text("\(dbgEntranceJoyArmLR, specifier: "%.0f")°").font(.system(size: 12, design: .monospaced)).frame(width: 44)
                                            Button { dbgEntranceJoyArmLR += rStep } label: { Image(systemName: "plus.circle.fill").foregroundColor(.purple.opacity(0.7)) }
                                        }
                                        Text("右腕").font(.caption2.bold()).foregroundColor(.purple)
                                        HStack(spacing: 4) {
                                            Text("X").font(.caption2).frame(width: 14)
                                            Button { dbgEntranceJoyArmRX -= aStep } label: { Image(systemName: "minus.circle.fill").foregroundColor(.purple.opacity(0.7)) }
                                            Text("\(dbgEntranceJoyArmRX, specifier: "%.0f")").font(.system(size: 12, design: .monospaced)).frame(width: 40)
                                            Button { dbgEntranceJoyArmRX += aStep } label: { Image(systemName: "plus.circle.fill").foregroundColor(.purple.opacity(0.7)) }
                                            Text("Y").font(.caption2).frame(width: 14)
                                            Button { dbgEntranceJoyArmRY -= aStep } label: { Image(systemName: "minus.circle.fill").foregroundColor(.purple.opacity(0.7)) }
                                            Text("\(dbgEntranceJoyArmRY, specifier: "%.0f")").font(.system(size: 12, design: .monospaced)).frame(width: 40)
                                            Button { dbgEntranceJoyArmRY += aStep } label: { Image(systemName: "plus.circle.fill").foregroundColor(.purple.opacity(0.7)) }
                                            Text("R").font(.caption2).frame(width: 14)
                                            Button { dbgEntranceJoyArmRR -= rStep } label: { Image(systemName: "minus.circle.fill").foregroundColor(.purple.opacity(0.7)) }
                                            Text("\(dbgEntranceJoyArmRR, specifier: "%.0f")°").font(.system(size: 12, design: .monospaced)).frame(width: 44)
                                            Button { dbgEntranceJoyArmRR += rStep } label: { Image(systemName: "plus.circle.fill").foregroundColor(.purple.opacity(0.7)) }
                                        }
                                    }
                                    Divider()
                                    HStack {
                                        Button("コピー") {
                                            var s = "entrance: skew=\(String(format:"%.2f",dbgLegSkew)) legSpread=\(String(format:"%.1f",dbgEntranceLegSpread)) bodyX=\(String(format:"%.2f",dbgEntranceBodyScaleX)) bodyY=\(String(format:"%.2f",dbgEntranceBodyScaleY)) armR=\(String(format:"%.0f",dbgEntranceArmRotation))"
                                            if dbgEntranceUseJoyArms {
                                                s += " joyL(X:\(Int(dbgEntranceJoyArmLX)),Y:\(Int(dbgEntranceJoyArmLY)),R:\(Int(dbgEntranceJoyArmLR))) joyR(X:\(Int(dbgEntranceJoyArmRX)),Y:\(Int(dbgEntranceJoyArmRY)),R:\(Int(dbgEntranceJoyArmRR)))"
                                            }
                                            print(s)
                                        }.font(.caption).foregroundColor(.yellow)
                                        Spacer()
                                        Button {
                                            playEntranceAnimation()
                                        } label: {
                                            HStack(spacing: 4) {
                                                Image(systemName: "play.fill")
                                                Text("再生")
                                            }
                                            .font(.caption.bold())
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12).padding(.vertical, 6)
                                            .background(Capsule().fill(Color.green))
                                        }
                                        .disabled(entranceAnimating)
                                    }
                                    // タイムラインスクラブバー
                                    VStack(spacing: 2) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "timeline.selection").font(.caption2).foregroundColor(.gray)
                                            Text("タイムライン").font(.caption2).foregroundColor(.gray)
                                            Spacer()
                                            Text("\(Int(timelineValue * 100))%").font(.system(size: 11, design: .monospaced)).foregroundColor(.gray)
                                        }
                                        Slider(value: $timelineValue, in: 0...1)
                                            .tint(.green)
                                            .onChange(of: timelineValue) { _, val in
                                                if !entranceAnimating {
                                                    timelineScrubbing = true
                                                    applyTimeline(val)
                                                }
                                            }
                                        HStack(spacing: 0) {
                                            Text("落下").font(.system(size: 8)).foregroundColor(.orange).frame(maxWidth: .infinity)
                                            Text("着地").font(.system(size: 8)).foregroundColor(.red).frame(maxWidth: .infinity)
                                            Text("伸び").font(.system(size: 8)).foregroundColor(.cyan).frame(maxWidth: .infinity)
                                            Text("構え").font(.system(size: 8)).foregroundColor(.blue).frame(maxWidth: .infinity)
                                            Text("決め").font(.system(size: 8)).foregroundColor(.purple).frame(maxWidth: .infinity)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        Divider().padding(.horizontal, 20)

                        // ── 表情オーバーレイ調整 ──
                        VStack(alignment: .leading, spacing: 8) {
                            Text("表情オーバーレイ")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)

                            Picker("表情", selection: $selectedMood) {
                                Text("ふつう").tag(KennyCharacterView.IdleMood.normal)
                                Text("てれ").tag(KennyCharacterView.IdleMood.blush)
                                Text("ニヤッ").tag(KennyCharacterView.IdleMood.smirk)
                                Text("ジト目").tag(KennyCharacterView.IdleMood.squint)
                                Text("びっくり").tag(KennyCharacterView.IdleMood.surprised)
                            }
                            .pickerStyle(.segmented)

                            // 片目サイズ調整
                            moodSliderRow("left eye", value: $moodLeftEyeScale, range: 0.5...1.5, color: .blue)
                            moodSliderRow("right eye", value: $moodRightEyeScale, range: 0.5...1.5, color: .blue)

                            // 選択中の表情パラメータ
                            if selectedMood == .blush || selectedMood == .smirk {
                                moodSliderRow("blush X", value: $moodBlushX, range: 0...0.4, color: .pink)
                                moodSliderRow("blush Y", value: $moodBlushY, range: -0.6...0.3, color: .pink)
                                moodSliderRow("size", value: $moodBlushSize, range: 0.05...0.3, color: .pink)
                                moodSliderRow("opacity", value: $moodBlushOpacity, range: 0...1, color: .pink)
                            }
                            if selectedMood == .smirk {
                                moodSliderRow("smirk X", value: $moodSmirkX, range: -0.2...0.2, color: .purple)
                                moodSliderRow("smirk Y", value: $moodSmirkY, range: -0.2...0.2, color: .purple)
                                moodSliderRow("smirk W", value: $moodSmirkW, range: 0.05...0.3, color: .purple)
                                moodSliderRow("smirk H", value: $moodSmirkH, range: 0.02...0.15, color: .purple)
                            }
                            if selectedMood == .squint {
                                moodSliderRow("squint W", value: $moodSquintW, range: 0.3...1.2, color: .gray)
                                moodSliderRow("squint H", value: $moodSquintH, range: 0.01...0.08, color: .gray)
                                moodSliderRow("spread", value: $moodSquintSpread, range: 0.3...5.0, color: .gray)
                            }
                            if selectedMood == .surprised {
                                moodSliderRow("! X", value: $moodSurprisedX, range: -0.4...0.4, color: .yellow)
                                moodSliderRow("! Y", value: $moodSurprisedY, range: -0.3...0.1, color: .yellow)
                                moodSliderRow("! scale", value: $moodSurprisedScale, range: 0.05...0.25, color: .yellow)
                            }

                            // 値コピー表示
                            if selectedMood != .normal {
                                Text(moodCodeSnippet)
                                    .font(.system(size: 10, design: .monospaced))
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(white: 0.95))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                        .padding(.horizontal, 20)

                        Divider().padding(.horizontal, 20)

                        // ── コピー用コード表示 ──
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("CharacterPartOffsets.registry に貼り付け:")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button {
                                    UIPasteboard.general.string = fullCopyText
                                    HapticsManager.tap()
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "doc.on.doc")
                                        Text("コピー")
                                    }
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .background(Color.blue)
                                    .clipShape(Capsule())
                                }
                            }

                            Text(fullCopyText)
                                .font(.system(size: 11, design: .monospaced))
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(white: 0.95))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .textSelection(.enabled)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                } // ScrollView
            } // VStack
            .navigationTitle("パーツ位置調整")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("とじる") { dismiss() }
                }
            }
        }
        .onAppear {
            loadOffsetsForCurrentBody()
        }
    }

    // MARK: - detail 専用調整行（X / Y + 回転）

    @ViewBuilder
    private func detailOffsetRow() -> some View {
        let color = Color.purple
        VStack(spacing: 6) {
            HStack {
                Text("detail")
                    .font(.caption.bold())
                    .foregroundColor(color)
                    .frame(width: 50, alignment: .leading)
                Spacer()
                Text("X:\(detailX, specifier: "%+.1f")  Y:\(detailY, specifier: "%+.1f")  ∠\(detailRotation, specifier: "%+.1f")°")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            HStack(spacing: 12) {
                Text("X").font(.caption2).foregroundColor(.secondary).frame(width: 14)
                Button { detailX -= step } label: { Image(systemName: "minus.circle.fill").font(.title3).foregroundColor(color.opacity(0.7)) }
                Text("\(detailX, specifier: "%.1f")").font(.system(size: 13, design: .monospaced)).frame(width: 44)
                Button { detailX += step } label: { Image(systemName: "plus.circle.fill").font(.title3).foregroundColor(color.opacity(0.7)) }
                Spacer().frame(width: 16)
                Text("Y").font(.caption2).foregroundColor(.secondary).frame(width: 14)
                Button { detailY -= step } label: { Image(systemName: "minus.circle.fill").font(.title3).foregroundColor(color.opacity(0.7)) }
                Text("\(detailY, specifier: "%.1f")").font(.system(size: 13, design: .monospaced)).frame(width: 44)
                Button { detailY += step } label: { Image(systemName: "plus.circle.fill").font(.title3).foregroundColor(color.opacity(0.7)) }
            }
            rotationSubRow(value: $detailRotation, color: color)
        }
        .padding(10)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - detail2 選択+調整

    private let detailOptions = ["detail_none",
        "detail_blue_horn_large", "detail_blue_horn_small", "detail_blue_antenna_large",
        "detail_blue_ear", "detail_blue_ear_round",
        "detail_dark_horn_large", "detail_dark_horn_small",
        "detail_green_horn_large", "detail_red_horn_large",
        "detail_yellow_horn_large", "detail_white_horn_large"]

    @ViewBuilder
    private func detail2Row() -> some View {
        let color = Color.indigo
        VStack(spacing: 6) {
            Picker("detail2", selection: $selectedDetail2) {
                ForEach(detailOptions, id: \.self) { name in
                    Text(name.replacingOccurrences(of: "detail_", with: "")).tag(name)
                }
            }
            .pickerStyle(.menu)
            .tint(color)

            HStack(spacing: 12) {
                Text("X").font(.caption2).foregroundColor(.secondary).frame(width: 14)
                Button { detail2X -= step } label: { Image(systemName: "minus.circle.fill").font(.title3).foregroundColor(color.opacity(0.7)) }
                Text("\(detail2X, specifier: "%.1f")").font(.system(size: 13, design: .monospaced)).frame(width: 44)
                Button { detail2X += step } label: { Image(systemName: "plus.circle.fill").font(.title3).foregroundColor(color.opacity(0.7)) }
                Spacer().frame(width: 16)
                Text("Y").font(.caption2).foregroundColor(.secondary).frame(width: 14)
                Button { detail2Y -= step } label: { Image(systemName: "minus.circle.fill").font(.title3).foregroundColor(color.opacity(0.7)) }
                Text("\(detail2Y, specifier: "%.1f")").font(.system(size: 13, design: .monospaced)).frame(width: 44)
                Button { detail2Y += step } label: { Image(systemName: "plus.circle.fill").font(.title3).foregroundColor(color.opacity(0.7)) }
            }
            rotationSubRow(value: $detail2Rotation, color: color)
        }
        .padding(10)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func detail3Row() -> some View {
        let color = Color.teal
        VStack(spacing: 6) {
            Picker("detail3", selection: $selectedDetail3) {
                ForEach(detailOptions, id: \.self) { name in
                    Text(name.replacingOccurrences(of: "detail_", with: "")).tag(name)
                }
            }
            .pickerStyle(.menu)
            .tint(color)

            HStack(spacing: 12) {
                Text("X").font(.caption2).foregroundColor(.secondary).frame(width: 14)
                Button { detail3X -= step } label: { Image(systemName: "minus.circle.fill").font(.title3).foregroundColor(color.opacity(0.7)) }
                Text("\(detail3X, specifier: "%.1f")").font(.system(size: 13, design: .monospaced)).frame(width: 44)
                Button { detail3X += step } label: { Image(systemName: "plus.circle.fill").font(.title3).foregroundColor(color.opacity(0.7)) }
                Spacer().frame(width: 16)
                Text("Y").font(.caption2).foregroundColor(.secondary).frame(width: 14)
                Button { detail3Y -= step } label: { Image(systemName: "minus.circle.fill").font(.title3).foregroundColor(color.opacity(0.7)) }
                Text("\(detail3Y, specifier: "%.1f")").font(.system(size: 13, design: .monospaced)).frame(width: 44)
                Button { detail3Y += step } label: { Image(systemName: "plus.circle.fill").font(.title3).foregroundColor(color.opacity(0.7)) }
            }
            rotationSubRow(value: $detail3Rotation, color: color)
        }
        .padding(10)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func detailSpreadRow() -> some View {
        let color = Color.cyan
        VStack(spacing: 6) {
            HStack {
                Text("spread")
                    .font(.caption.bold())
                    .foregroundColor(color)
                Spacer()
                Text("\(detailSpread, specifier: "%+.1f")pt")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            HStack(spacing: 12) {
                Button { detailSpread -= step } label: { Image(systemName: "minus.circle.fill").font(.title3).foregroundColor(color.opacity(0.7)) }
                Text("\(detailSpread, specifier: "%.1f")").font(.system(size: 13, design: .monospaced)).frame(width: 44)
                Button { detailSpread += step } label: { Image(systemName: "plus.circle.fill").font(.title3).foregroundColor(color.opacity(0.7)) }
            }
        }
        .padding(10)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 腕 専用調整行（X / Y / scale / 回転）

    @ViewBuilder
    private func armOffsetRow() -> some View {
        let color = Color.pink
        VStack(spacing: 6) {
            HStack {
                Text("arm")
                    .font(.caption.bold())
                    .foregroundColor(color)
                    .frame(width: 50, alignment: .leading)
                Spacer()
                Text("X:\(armOffsetX, specifier: "%+.1f")  Y:\(armOffsetY, specifier: "%+.1f")  ×\(armScale, specifier: "%.2f")  ∠\(armRotation, specifier: "%+.1f")°")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            // X / Y
            HStack(spacing: 12) {
                Text("X").font(.caption2).foregroundColor(.secondary).frame(width: 14)
                Button { armOffsetX -= step } label: { Image(systemName: "minus.circle.fill").font(.title3).foregroundColor(color.opacity(0.7)) }
                Text("\(armOffsetX, specifier: "%.1f")").font(.system(size: 13, design: .monospaced)).frame(width: 44)
                Button { armOffsetX += step } label: { Image(systemName: "plus.circle.fill").font(.title3).foregroundColor(color.opacity(0.7)) }
                Spacer().frame(width: 16)
                Text("Y").font(.caption2).foregroundColor(.secondary).frame(width: 14)
                Button { armOffsetY -= step } label: { Image(systemName: "minus.circle.fill").font(.title3).foregroundColor(color.opacity(0.7)) }
                Text("\(armOffsetY, specifier: "%.1f")").font(.system(size: 13, design: .monospaced)).frame(width: 44)
                Button { armOffsetY += step } label: { Image(systemName: "plus.circle.fill").font(.title3).foregroundColor(color.opacity(0.7)) }
            }
            // 左右別X
            HStack(spacing: 12) {
                Text("左X").font(.caption.bold()).foregroundColor(.pink).frame(width: 30)
                Button { leftArmOffsetX -= step } label: { Image(systemName: "minus.circle.fill").font(.title3).foregroundColor(Color.pink.opacity(0.7)) }
                Text("\(leftArmOffsetX, specifier: "%+.1f")").font(.system(size: 13, design: .monospaced)).frame(width: 44)
                Button { leftArmOffsetX += step } label: { Image(systemName: "plus.circle.fill").font(.title3).foregroundColor(Color.pink.opacity(0.7)) }
                Spacer().frame(width: 16)
                Text("右X").font(.caption.bold()).foregroundColor(.blue).frame(width: 30)
                Button { rightArmOffsetX -= step } label: { Image(systemName: "minus.circle.fill").font(.title3).foregroundColor(Color.blue.opacity(0.7)) }
                Text("\(rightArmOffsetX, specifier: "%+.1f")").font(.system(size: 13, design: .monospaced)).frame(width: 44)
                Button { rightArmOffsetX += step } label: { Image(systemName: "plus.circle.fill").font(.title3).foregroundColor(Color.blue.opacity(0.7)) }
            }
            // Scale
            scaleSubRow(label: "サイズ", value: $armScale, color: color)
            // Rotation（左右共通）
            HStack {
                Text("共通").font(.caption2).foregroundColor(.secondary)
                Spacer()
            }
            rotationSubRow(value: $armRotation, color: color)
            // 左腕専用
            HStack {
                Text("左腕").font(.caption2.bold()).foregroundColor(.pink)
                Text("∠\(leftArmRotation, specifier: "%+.1f")°").font(.system(size: 11, design: .monospaced)).foregroundColor(.secondary)
                Spacer()
            }
            rotationSubRow(value: $leftArmRotation, color: .pink)
            // 右腕専用
            HStack {
                Text("右腕").font(.caption2.bold()).foregroundColor(.blue)
                Text("∠\(rightArmRotation, specifier: "%+.1f")°").font(.system(size: 11, design: .monospaced)).foregroundColor(.secondary)
                Spacer()
            }
            rotationSubRow(value: $rightArmRotation, color: .blue)
        }
        .padding(10)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 足 専用調整行（X / Y / scale / 回転）

    @ViewBuilder
    private func headOffsetRow() -> some View {
        let color = Color.mint
        VStack(spacing: 6) {
            HStack {
                Text("head")
                    .font(.caption.bold())
                    .foregroundColor(color)
                    .frame(width: 50, alignment: .leading)
                Spacer()
                Text("X:\(headX, specifier: "%+.1f")  Y:\(headY, specifier: "%+.1f")  ×\(headScale, specifier: "%.2f")  ∠\(headRotation, specifier: "%+.1f")°")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            HStack(spacing: 12) {
                Text("X").font(.caption2).foregroundColor(.secondary).frame(width: 14)
                Button { headX -= step } label: { Image(systemName: "minus.circle.fill").font(.title3).foregroundColor(color.opacity(0.7)) }
                Text("\(headX, specifier: "%.1f")").font(.system(size: 13, design: .monospaced)).frame(width: 44)
                Button { headX += step } label: { Image(systemName: "plus.circle.fill").font(.title3).foregroundColor(color.opacity(0.7)) }
                Spacer().frame(width: 16)
                Text("Y").font(.caption2).foregroundColor(.secondary).frame(width: 14)
                Button { headY -= step } label: { Image(systemName: "minus.circle.fill").font(.title3).foregroundColor(color.opacity(0.7)) }
                Text("\(headY, specifier: "%.1f")").font(.system(size: 13, design: .monospaced)).frame(width: 44)
                Button { headY += step } label: { Image(systemName: "plus.circle.fill").font(.title3).foregroundColor(color.opacity(0.7)) }
            }
            scaleSubRow(label: "サイズ", value: $headScale, color: color)
            rotationSubRow(value: $headRotation, color: color)
        }
        .padding(10)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func programMouthRow() -> some View {
        let color = Color.green
        VStack(spacing: 6) {
            HStack {
                Text("p-mouth").font(.caption.bold()).foregroundColor(color).frame(width: 60, alignment: .leading)
                Toggle("有効", isOn: $useProgMouth).labelsHidden().tint(color)
                Spacer()
                Text("W:\(pmouthW, specifier: "%.2f")  H:\(pmouthH, specifier: "%.2f")  X:\(pmouthOffsetX, specifier: "%+.0f")  Y:\(pmouthOffsetY, specifier: "%+.0f")")
                    .font(.system(size: 9, design: .monospaced)).foregroundColor(.secondary)
            }
            HStack(spacing: 8) {
                Text("W").font(.caption2).foregroundColor(.secondary)
                Button { pmouthW = max(0.01, pmouthW - 0.01) } label: { Image(systemName: "minus.circle.fill").font(.title3).foregroundColor(color.opacity(0.7)) }
                Text("\(pmouthW, specifier: "%.2f")").font(.system(size: 11, design: .monospaced)).frame(width: 44)
                Button { pmouthW += 0.01 } label: { Image(systemName: "plus.circle.fill").font(.title3).foregroundColor(color.opacity(0.7)) }
                Text("H").font(.caption2).foregroundColor(.secondary)
                Button { pmouthH = max(0.01, pmouthH - 0.01) } label: { Image(systemName: "minus.circle.fill").font(.title3).foregroundColor(color.opacity(0.7)) }
                Text("\(pmouthH, specifier: "%.2f")").font(.system(size: 11, design: .monospaced)).frame(width: 44)
                Button { pmouthH += 0.01 } label: { Image(systemName: "plus.circle.fill").font(.title3).foregroundColor(color.opacity(0.7)) }
            }
            HStack(spacing: 8) {
                Text("X").font(.caption2).foregroundColor(.secondary)
                Button { pmouthOffsetX -= step } label: { Image(systemName: "minus.circle.fill").font(.title3).foregroundColor(color.opacity(0.7)) }
                Text("\(pmouthOffsetX, specifier: "%+.0f")").font(.system(size: 11, design: .monospaced)).frame(width: 44)
                Button { pmouthOffsetX += step } label: { Image(systemName: "plus.circle.fill").font(.title3).foregroundColor(color.opacity(0.7)) }
                Text("Y").font(.caption2).foregroundColor(.secondary)
                Button { pmouthOffsetY -= step } label: { Image(systemName: "minus.circle.fill").font(.title3).foregroundColor(color.opacity(0.7)) }
                Text("\(pmouthOffsetY, specifier: "%+.0f")").font(.system(size: 11, design: .monospaced)).frame(width: 44)
                Button { pmouthOffsetY += step } label: { Image(systemName: "plus.circle.fill").font(.title3).foregroundColor(color.opacity(0.7)) }
            }
            HStack(spacing: 8) {
                Text("カーブ").font(.caption2).foregroundColor(.secondary)
                Button { pmouthCurve -= 0.1 } label: { Image(systemName: "minus.circle.fill").font(.title3).foregroundColor(color.opacity(0.7)) }
                Text("\(pmouthCurve, specifier: "%+.2f")").font(.system(size: 11, design: .monospaced)).frame(width: 50)
                Button { pmouthCurve += 0.1 } label: { Image(systemName: "plus.circle.fill").font(.title3).foregroundColor(color.opacity(0.7)) }
                Spacer()
                Button("0") { pmouthCurve = 0 }.font(.caption.bold()).foregroundColor(color)
            }
        }
        .padding(10)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func shineRow() -> some View {
        let color = Color.white
        let stepRatio: CGFloat = 0.01
        VStack(spacing: 6) {
            HStack {
                Text("shine")
                    .font(.caption.bold())
                    .foregroundColor(color)
                    .frame(width: 50, alignment: .leading)
                Spacer()
                Text("X:\(shineX, specifier: "%+.2f")  Y:\(shineY, specifier: "%+.2f")  W:\(shineW, specifier: "%.2f")  H:\(shineH, specifier: "%.2f")  ∠\(shineRotation, specifier: "%+.0f")°  α\(shineOpacity, specifier: "%.2f")")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            HStack(spacing: 8) {
                Text("X").font(.caption2).foregroundColor(.secondary)
                Button { shineX -= stepRatio } label: { Image(systemName: "minus.circle.fill").font(.title3).foregroundColor(.gray) }
                Text("\(shineX, specifier: "%+.2f")").font(.system(size: 11, design: .monospaced)).frame(width: 44)
                Button { shineX += stepRatio } label: { Image(systemName: "plus.circle.fill").font(.title3).foregroundColor(.gray) }
                Text("Y").font(.caption2).foregroundColor(.secondary)
                Button { shineY -= stepRatio } label: { Image(systemName: "minus.circle.fill").font(.title3).foregroundColor(.gray) }
                Text("\(shineY, specifier: "%+.2f")").font(.system(size: 11, design: .monospaced)).frame(width: 44)
                Button { shineY += stepRatio } label: { Image(systemName: "plus.circle.fill").font(.title3).foregroundColor(.gray) }
            }
            HStack(spacing: 8) {
                Text("W").font(.caption2).foregroundColor(.secondary)
                Button { shineW = max(0.01, shineW - stepRatio) } label: { Image(systemName: "minus.circle.fill").font(.title3).foregroundColor(.gray) }
                Text("\(shineW, specifier: "%.2f")").font(.system(size: 11, design: .monospaced)).frame(width: 44)
                Button { shineW += stepRatio } label: { Image(systemName: "plus.circle.fill").font(.title3).foregroundColor(.gray) }
                Text("H").font(.caption2).foregroundColor(.secondary)
                Button { shineH = max(0.01, shineH - stepRatio) } label: { Image(systemName: "minus.circle.fill").font(.title3).foregroundColor(.gray) }
                Text("\(shineH, specifier: "%.2f")").font(.system(size: 11, design: .monospaced)).frame(width: 44)
                Button { shineH += stepRatio } label: { Image(systemName: "plus.circle.fill").font(.title3).foregroundColor(.gray) }
            }
            HStack(spacing: 8) {
                Text("∠").font(.caption2).foregroundColor(.secondary)
                Button { shineRotation -= 5 } label: { Image(systemName: "minus.circle.fill").font(.title3).foregroundColor(.gray) }
                Text("\(shineRotation, specifier: "%+.0f")°").font(.system(size: 11, design: .monospaced)).frame(width: 44)
                Button { shineRotation += 5 } label: { Image(systemName: "plus.circle.fill").font(.title3).foregroundColor(.gray) }
                Text("α").font(.caption2).foregroundColor(.secondary)
                Button { shineOpacity = max(0, shineOpacity - 0.05) } label: { Image(systemName: "minus.circle.fill").font(.title3).foregroundColor(.gray) }
                Text("\(shineOpacity, specifier: "%.2f")").font(.system(size: 11, design: .monospaced)).frame(width: 44)
                Button { shineOpacity = min(1, shineOpacity + 0.05) } label: { Image(systemName: "plus.circle.fill").font(.title3).foregroundColor(.gray) }
            }
        }
        .padding(10)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func legOffsetRow() -> some View {
        let color = Color.teal
        VStack(spacing: 6) {
            HStack {
                Text("leg")
                    .font(.caption.bold())
                    .foregroundColor(color)
                    .frame(width: 50, alignment: .leading)
                Spacer()
                Text("X:\(legOffsetX, specifier: "%+.1f")  Y:\(legOffsetY, specifier: "%+.1f")  ×\(legScale, specifier: "%.2f")  ∠\(legRotation, specifier: "%+.1f")°")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            // X / Y
            HStack(spacing: 12) {
                Text("X").font(.caption2).foregroundColor(.secondary).frame(width: 14)
                Button { legOffsetX -= step } label: { Image(systemName: "minus.circle.fill").font(.title3).foregroundColor(color.opacity(0.7)) }
                Text("\(legOffsetX, specifier: "%.1f")").font(.system(size: 13, design: .monospaced)).frame(width: 44)
                Button { legOffsetX += step } label: { Image(systemName: "plus.circle.fill").font(.title3).foregroundColor(color.opacity(0.7)) }
                Spacer().frame(width: 16)
                Text("Y").font(.caption2).foregroundColor(.secondary).frame(width: 14)
                Button { legOffsetY -= step } label: { Image(systemName: "minus.circle.fill").font(.title3).foregroundColor(color.opacity(0.7)) }
                Text("\(legOffsetY, specifier: "%.1f")").font(.system(size: 13, design: .monospaced)).frame(width: 44)
                Button { legOffsetY += step } label: { Image(systemName: "plus.circle.fill").font(.title3).foregroundColor(color.opacity(0.7)) }
            }
            // Scale
            scaleSubRow(label: "サイズ", value: $legScale, color: color)
            // Spread
            HStack(spacing: 12) {
                Text("幅").font(.caption2).foregroundColor(.secondary).frame(width: 14)
                Button { legSpread -= step } label: { Image(systemName: "minus.circle.fill").font(.title3).foregroundColor(color.opacity(0.7)) }
                Text("\(legSpread, specifier: "%+.1f")").font(.system(size: 13, design: .monospaced)).frame(width: 44)
                Button { legSpread += step } label: { Image(systemName: "plus.circle.fill").font(.title3).foregroundColor(color.opacity(0.7)) }
                Spacer()
                Button("0") { legSpread = 0 }.font(.caption.bold()).foregroundColor(color)
            }
            // Rotation
            rotationSubRow(value: $legRotation, color: color)
        }
        .padding(10)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 回転サブ行（共通）

    @ViewBuilder
    private func rotationSubRow(value: Binding<CGFloat>, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                Text("回転単位:").font(.caption2).foregroundColor(.secondary)
                ForEach(rotationSteps, id: \.self) { rs in
                    Button { rotationStep = rs } label: {
                        Text("\(rs, specifier: "%.0f")°")
                            .font(.caption2.bold())
                            .foregroundColor(rotationStep == rs ? .white : color)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(rotationStep == rs ? color : color.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                Spacer()
            }
            HStack(spacing: 12) {
                Image(systemName: "arrow.counterclockwise").font(.caption2).foregroundColor(.secondary).frame(width: 14)
                Button { value.wrappedValue -= rotationStep } label: { Image(systemName: "minus.circle.fill").font(.title3).foregroundColor(color.opacity(0.7)) }
                Text("\(value.wrappedValue, specifier: "%.1f")°").font(.system(size: 13, design: .monospaced)).frame(width: 52)
                Button { value.wrappedValue += rotationStep } label: { Image(systemName: "plus.circle.fill").font(.title3).foregroundColor(color.opacity(0.7)) }
                Spacer()
                Button("0°") { value.wrappedValue = 0 }.font(.caption.bold()).foregroundColor(color)
            }
        }
        .padding(.top, 4)
    }

    // MARK: - スケールサブ行（共通）

    @ViewBuilder
    private func scaleSubRow(label: String, value: Binding<CGFloat>, color: Color) -> some View {
        HStack(spacing: 8) {
            Text("サイズ単位:").font(.caption2).foregroundColor(.secondary)
            ForEach(scaleSteps, id: \.self) { ss in
                Button { scaleStep = ss } label: {
                    Text("±\(ss, specifier: "%.2f")")
                        .font(.caption2.bold())
                        .foregroundColor(scaleStep == ss ? .white : color)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(scaleStep == ss ? color : color.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            Spacer()
            Button { value.wrappedValue = max(0.1, value.wrappedValue - scaleStep) } label: {
                Image(systemName: "minus.circle.fill").font(.title3).foregroundColor(color.opacity(0.7))
            }
            Text("×\(value.wrappedValue, specifier: "%.2f")").font(.system(size: 13, design: .monospaced)).frame(width: 52)
            Button { value.wrappedValue += scaleStep } label: {
                Image(systemName: "plus.circle.fill").font(.title3).foregroundColor(color.opacity(0.7))
            }
            Button("1×") { value.wrappedValue = 1.0 }.font(.caption.bold()).foregroundColor(color)
        }
    }

    // MARK: - 汎用調整行

    private func offsetRow(
        label: String,
        x: Binding<CGFloat>,
        y: Binding<CGFloat>,
        color: Color
    ) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text(label).font(.caption.bold()).foregroundColor(color).frame(width: 50, alignment: .leading)
                Spacer()
                Text("X:\(x.wrappedValue, specifier: "%+.1f")  Y:\(y.wrappedValue, specifier: "%+.1f")")
                    .font(.system(size: 12, design: .monospaced)).foregroundColor(.secondary)
            }
            HStack(spacing: 12) {
                Text("X").font(.caption2).foregroundColor(.secondary).frame(width: 14)
                Button { x.wrappedValue -= step } label: { Image(systemName: "minus.circle.fill").font(.title3).foregroundColor(color.opacity(0.7)) }
                Text("\(x.wrappedValue, specifier: "%.1f")").font(.system(size: 13, design: .monospaced)).frame(width: 44)
                Button { x.wrappedValue += step } label: { Image(systemName: "plus.circle.fill").font(.title3).foregroundColor(color.opacity(0.7)) }
                Spacer().frame(width: 16)
                Text("Y").font(.caption2).foregroundColor(.secondary).frame(width: 14)
                Button { y.wrappedValue -= step } label: { Image(systemName: "minus.circle.fill").font(.title3).foregroundColor(color.opacity(0.7)) }
                Text("\(y.wrappedValue, specifier: "%.1f")").font(.system(size: 13, design: .monospaced)).frame(width: 44)
                Button { y.wrappedValue += step } label: { Image(systemName: "plus.circle.fill").font(.title3).foregroundColor(color.opacity(0.7)) }
            }
        }
        .padding(10)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - オフセット読み込み / リセット

    private func lerpKeyframes(_ t: CGFloat, _ keyframes: [(CGFloat, CGFloat)]) -> CGFloat {
        guard !keyframes.isEmpty else { return 0 }
        if t <= keyframes.first!.0 { return keyframes.first!.1 }
        if t >= keyframes.last!.0 { return keyframes.last!.1 }
        for i in 0..<keyframes.count - 1 {
            let (t0, v0) = keyframes[i]
            let (t1, v1) = keyframes[i + 1]
            if t >= t0 && t <= t1 {
                let p = (t - t0) / (t1 - t0)
                return v0 + (v1 - v0) * p
            }
        }
        return keyframes.last!.1
    }

    private func applyTimeline(_ t: CGFloat) {
        let s = CharacterPartOffsets.forBody(appearance.body)
        let defaultEyeY = s.eyes.height

        entranceOffsetY = lerpKeyframes(t, [(0, -120), (0.12, 0), (1, 0)])

        dbgEntranceBodyScaleX = lerpKeyframes(t, [(0, 1.0), (0.12, 1.15), (0.30, 0.95), (0.45, 1.0), (1, 1.0)])
        dbgEntranceBodyScaleY = lerpKeyframes(t, [(0, 1.0), (0.12, 0.85), (0.30, 1.1), (0.45, 1.0), (1, 1.0)])

        dbgEntranceArmRotation = lerpKeyframes(t, [(0, 0), (0.12, 77), (0.30, -14), (0.38, 34), (0.45, 4), (0.55, 6), (0.70, 51), (1, 51)])

        dbgLegSkew = lerpKeyframes(t, [(0, 0), (0.12, 0.12), (0.55, 0.19), (0.70, 0.39), (1, 0.39)])
        dbgEntranceLegSpread = lerpKeyframes(t, [(0, 0), (0.12, -8), (0.55, -11.9), (0.70, -8.7), (1, -8.7)])

        eyesY = lerpKeyframes(t, [(0, defaultEyeY), (0.18, 11), (0.28, -5.3), (0.38, 16), (0.51, defaultEyeY), (1, defaultEyeY)])

        let joySwitch: CGFloat = 0.75
        if t >= joySwitch && !dbgEntranceUseJoyArms {
            dbgEntranceJoyArmLX = -60; dbgEntranceJoyArmLY = 5; dbgEntranceJoyArmLR = -255
            dbgEntranceJoyArmRX = 63; dbgEntranceJoyArmRY = 5; dbgEntranceJoyArmRR = 210
            dbgEntranceUseJoyArms = true
        } else if t < joySwitch && dbgEntranceUseJoyArms {
            dbgEntranceUseJoyArms = false
        }
    }

    private func playEntranceAnimation() {
        guard !entranceAnimating else { return }
        entranceAnimating = true

        // Phase 0: リセット（画面上）
        dbgLegSkew = 0; dbgEntranceLegSpread = 0
        dbgEntranceBodyScaleX = 1.0; dbgEntranceBodyScaleY = 1.0
        dbgEntranceArmRotation = 0; dbgEntranceUseJoyArms = false
        entranceOffsetY = -120

        // Phase 1: 落下 → 着地（潰れ + 腕77°）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeIn(duration: 0.2)) {
                entranceOffsetY = 0
                dbgEntranceBodyScaleX = 1.15
                dbgEntranceBodyScaleY = 0.85
                dbgLegSkew = 0.12
                dbgEntranceLegSpread = -8
                dbgEntranceArmRotation = 77
            }
        }

        // Phase 2a: 伸び上がり（腕 77° → -14°）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.25)) {
                dbgEntranceBodyScaleX = 0.95
                dbgEntranceBodyScaleY = 1.1
                dbgEntranceArmRotation = -14
            }
        }

        // Phase 2b: 腕バウンス（-14° → 34°）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.easeInOut(duration: 0.15)) {
                dbgEntranceArmRotation = 34
            }
        }

        // Phase 2c: 腕落ち着き（34° → 4°）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.easeOut(duration: 0.2)) {
                dbgEntranceArmRotation = 4
                dbgEntranceBodyScaleX = 1.0
                dbgEntranceBodyScaleY = 1.0
            }
        }

        // Phase 3: 構え（足シアー 0.19、足開き -11.9、腕 6°）
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) {
            withAnimation(.easeInOut(duration: 0.25)) {
                dbgLegSkew = 0.19
                dbgEntranceLegSpread = -11.9
                dbgEntranceArmRotation = 6
            }
        }

        // Phase 4a: 足開き（skew 0.39、spread -8.7）+ 腕上げ（6° → 51°）
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.25)) {
                dbgLegSkew = 0.39
                dbgEntranceLegSpread = -8.7
                dbgEntranceArmRotation = 51
            }
        }

        // Phase 4b: 喜び腕に切替 + 決めポーズ
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            dbgEntranceJoyArmLX = -60; dbgEntranceJoyArmLY = 5; dbgEntranceJoyArmLR = -255
            dbgEntranceJoyArmRX = 63; dbgEntranceJoyArmRY = 5; dbgEntranceJoyArmRR = 210
            dbgEntranceUseJoyArms = true
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                dbgEntranceBodyScaleX = 1.0
                dbgEntranceBodyScaleY = 1.0
            }
        }

        // タイムライン連動
        let totalDuration = 2.5
        let steps = 50
        for i in 0...steps {
            let delay = totalDuration * Double(i) / Double(steps)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                guard entranceAnimating else { return }
                timelineValue = CGFloat(i) / CGFloat(steps)
            }
        }

        // Phase 5: 完了
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration + 0.1) {
            entranceAnimating = false
        }
    }

    private func loadOffsetsForCurrentBody() {
        let s = CharacterPartOffsets.forBody(appearance.body)
        eyesX       = s.eyes.width;    eyesY       = s.eyes.height
        eyeScale    = s.eyeScale;        eyeSpreadVal = s.eyeSpread
        mouthX      = s.mouth.width;   mouthY      = s.mouth.height
        detailX     = s.detail.width;  detailY     = s.detail.height
        detailRotation = s.detailRotation
        noseX       = s.nose.width;    noseY       = s.nose.height
        armOffsetX  = s.armOffset.width;  armOffsetY  = s.armOffset.height
        armScale    = s.armScale;         armRotation = s.armRotation
        legOffsetX  = s.legOffset.width;  legOffsetY  = s.legOffset.height
        legScale    = s.legScale;         legRotation = s.legRotation
        legSpread   = s.legSpread
        headX       = s.head.width;      headY       = s.head.height
        headScale   = s.headScale;       headRotation = s.headRotation
        shineX = s.shineX; shineY = s.shineY
        shineW = s.shineW; shineH = s.shineH
        shineRotation = s.shineRotation; shineOpacity = s.shineOpacity
        bodyScale = s.bodyScale
        joyLeftArmX = s.joyLeftArmX; joyLeftArmY = s.joyLeftArmY; joyLeftArmR = s.joyLeftArmR
        joyRightArmX = s.joyRightArmX; joyRightArmY = s.joyRightArmY; joyRightArmR = s.joyRightArmR
        useProgMouth = s.useProgrammaticMouth
        pmouthW = s.pmouthW; pmouthH = s.pmouthH
        pmouthOffsetX = s.pmouthOffsetX; pmouthOffsetY = s.pmouthOffsetY
        pmouthCurve = s.pmouthCurve
        moodBlushX = s.mood.blushX; moodBlushY = s.mood.blushY
        moodBlushSize = s.mood.blushSize; moodBlushOpacity = s.mood.blushOpacity
        moodSmirkX = s.mood.smirkX; moodSmirkY = s.mood.smirkY
        moodSmirkW = s.mood.smirkW; moodSmirkH = s.mood.smirkH
        moodSquintW = s.mood.squintW; moodSquintH = s.mood.squintH
        moodSquintSpread = s.mood.squintSpread
        moodLeftEyeScale = s.mood.leftEyeScale
        moodRightEyeScale = s.mood.rightEyeScale
        // 左向き
        leftEyeOX = s.leftEyeOffsetX ?? 0
        leftEyeOY = s.leftEyeOffsetY ?? 0
        leftEyeOSpread = s.leftEyeSpread ?? 0
        leftEyeOScaleL = s.leftEyeScaleL ?? 1.0
        leftEyeOScaleR = s.leftEyeScaleR ?? 1.0
        leftMouthOX = s.leftMouthOffsetX ?? 0
        leftMouthOY = s.leftMouthOffsetY ?? 0
    }

    private func resetOffsets() {
        eyesX = 0; eyesY = 0; eyeScale = 1.0; eyeSpreadVal = 0
        mouthX = 0; mouthY = 0
        detailX = 0; detailY = 0; detailRotation = 0
        noseX = 0; noseY = 0
        armOffsetX = 0; armOffsetY = 0; armScale = 1.0; armRotation = 0
        leftArmRotation = 0; rightArmRotation = 0
        leftArmOffsetX = 0; rightArmOffsetX = 0
        legOffsetX = 0; legOffsetY = 0; legScale = 1.0; legRotation = 0; legSpread = 0
        headX = 0; headY = 0; headScale = 1.0; headRotation = 0
        shineX = -0.18; shineY = -0.05; shineW = 0.08; shineH = 0.18
        shineRotation = -30; shineOpacity = 0.9
        useProgMouth = false
        pmouthW = 0.15; pmouthH = 0.06; pmouthOffsetX = 0; pmouthOffsetY = 0; pmouthCurve = 0
    }

    // MARK: - コピー用コードスニペット

    private var fullCopyText: String {
        var lines: [String] = []
        lines.append("// body: \(appearance.body)")
        lines.append("// detail: \(appearance.detail)")
        if selectedDetail2 != "detail_none" {
            lines.append("// detail2: \(selectedDetail2)")
        }
        if selectedDetail3 != "detail_none" {
            lines.append("// detail3: \(selectedDetail3)")
        }
        let color = appearance.body.replacingOccurrences(of: "body_", with: "").replacingOccurrences(of: "A", with: "").replacingOccurrences(of: "B", with: "").replacingOccurrences(of: "C", with: "").replacingOccurrences(of: "D", with: "").replacingOccurrences(of: "E", with: "")
        lines.append("// horn sprites: detail_\(color)_horn_large (x1), detail_\(color)_horn_small+large (x2), detail_\(color)_horn_small+large+large (x3)")
        lines.append("// antenna sprites: detail_\(color)_antenna_large (x1-x3)")
        lines.append("// ear sprites: detail_\(color)_ear, detail_\(color)_ear_round")
        lines.append("")
        lines.append(codeSnippet)
        return lines.joined(separator: "\n")
    }

    private var codeSnippet: String {
        let body = appearance.body
        return """
        "\(body)": CharacterPartOffsets(
            bodyScale:      \(fmt(bodyScale)),
            eyes:           CGSize(width: \(fmt(eyesX)), height: \(fmt(eyesY))),
            eyeScale:       \(fmt(eyeScale)),
            eyeSpread:      \(fmt(eyeSpreadVal)),
            mouth:          CGSize(width: \(fmt(mouthX)), height: \(fmt(mouthY))),
            detail:         CGSize(width: \(fmt(detailX)), height: \(fmt(detailY))),
            detailRotation: \(fmt(detailRotation)),
            nose:           CGSize(width: \(fmt(noseX)), height: \(fmt(noseY))),
            head:           CGSize(width: \(fmt(headX)), height: \(fmt(headY))),
            headScale:      \(fmt(headScale)),
            headRotation:   \(fmt(headRotation)),
            shineX:         \(fmt(shineX)),
            shineY:         \(fmt(shineY)),
            shineW:         \(fmt(shineW)),
            shineH:         \(fmt(shineH)),
            shineRotation:  \(fmt(shineRotation)),
            shineOpacity:   \(fmt(shineOpacity)),
            useProgrammaticMouth: \(useProgMouth),
            pmouthW:        \(fmt(pmouthW)),
            pmouthH:        \(fmt(pmouthH)),
            pmouthOffsetX:  \(fmt(pmouthOffsetX)),
            pmouthOffsetY:  \(fmt(pmouthOffsetY)),
            pmouthCurve:    \(fmt(pmouthCurve)),
            armOffset:      CGSize(width: \(fmt(armOffsetX)), height: \(fmt(armOffsetY))),
            armScale:       \(fmt(armScale)),
            armRotation:      \(fmt(armRotation)),
            leftArmRotation:  \(fmt(leftArmRotation)),
            rightArmRotation: \(fmt(rightArmRotation)),
            leftArmOffsetX:   \(fmt(leftArmOffsetX)),
            rightArmOffsetX:  \(fmt(rightArmOffsetX)),
            legOffset:      CGSize(width: \(fmt(legOffsetX)), height: \(fmt(legOffsetY))),
            legScale:       \(fmt(legScale)),
            legRotation:    \(fmt(legRotation)),
            legSpread:      \(fmt(legSpread)),
            detail2:        CGSize(width: \(fmt(detail2X)), height: \(fmt(detail2Y))),
            detail2Rotation: \(fmt(detail2Rotation)),
            detail3:        CGSize(width: \(fmt(detail3X)), height: \(fmt(detail3Y))),
            detail3Rotation: \(fmt(detail3Rotation))
        ),
        """
    }

    private func fmt(_ v: CGFloat) -> String {
        if v == 0 { return "0" }
        if v == v.rounded() { return String(format: "%.0f", v) }
        return String(format: "%.2f", v)
    }

    // MARK: - 表情スライダー行

    @ViewBuilder
    private func moodSliderRow(_ label: String, value: Binding<CGFloat>, range: ClosedRange<CGFloat>, color: Color) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(color)
                .frame(width: 60, alignment: .leading)
            Slider(value: value, in: range)
                .tint(color)
            Text(String(format: "%.3f", value.wrappedValue))
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .trailing)
        }
    }

    // MARK: - 表情コードスニペット

    private var moodCodeSnippet: String {
        """
        MoodOverlayOffsets(
            blushX: \(fmt(moodBlushX)), blushY: \(fmt(moodBlushY)),
            blushSize: \(fmt(moodBlushSize)), blushOpacity: \(fmt(moodBlushOpacity)),
            smirkX: \(fmt(moodSmirkX)), smirkY: \(fmt(moodSmirkY)),
            smirkW: \(fmt(moodSmirkW)), smirkH: \(fmt(moodSmirkH)),
            squintW: \(fmt(moodSquintW)), squintH: \(fmt(moodSquintH)), squintSpread: \(fmt(moodSquintSpread)),
            surprisedX: \(fmt(moodSurprisedX)), surprisedY: \(fmt(moodSurprisedY)),
            surprisedScale: \(fmt(moodSurprisedScale)),
            leftEyeScale: \(fmt(moodLeftEyeScale)), rightEyeScale: \(fmt(moodRightEyeScale))
        )
        """
    }
}

#Preview {
    CharacterLayoutDebugView()
}
#endif

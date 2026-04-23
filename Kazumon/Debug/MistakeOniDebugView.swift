#if DEBUG
import SwiftUI

/// まちがいおに外見エディタ
/// パーツを選んでプレビュー → コードスニペットをコピーして CharacterAppearance.mistakeOni に貼り付ける
struct MistakeOniDebugView: View {
    @Environment(\.dismiss) private var dismiss

    // MARK: - パーツ選択 State

    @State private var selectedBody: String
    @State private var selectedEyes: String
    @State private var selectedMouth: String
    @State private var selectedLeftArm: String
    @State private var selectedRightArm: String
    @State private var selectedLegs: String
    @State private var selectedDetail: String
    @State private var selectedNose: String
    @State private var eyeOffsetY: CGFloat
    @State private var mouthOffsetY: CGFloat
    @State private var eyeStyle: Int       // 0=friendly,1=angry,2=neutral,3=cute
    @State private var browMood: Int       // 0=normal,1=angry,2=sad,3=surprised,4=determined
    @State private var eyeAnimated: Bool
    @State private var characterSize: CGFloat = 140

    // MARK: - 選択肢

    private let bodies  = spriteFrames.keys.filter { $0.hasPrefix("body_") }.sorted()
    private let eyes    = spriteFrames.keys.filter { $0.hasPrefix("eye_") }.sorted()
    private let mouths  = spriteFrames.keys.filter { $0.hasPrefix("mouth") }.sorted()
    private let arms    = ["(なし)"] + spriteFrames.keys.filter { $0.hasPrefix("arm_") }.sorted()
    private let legs    = ["(なし)"] + spriteFrames.keys.filter { $0.hasPrefix("leg_") }.sorted()
    private let details = ["(なし)"] + spriteFrames.keys.filter { $0.hasPrefix("detail_") }.sorted()
    private let noses   = ["(なし)"] + spriteFrames.keys.filter { $0.hasPrefix("nose_") || $0.hasPrefix("snot_") }.sorted()

    private let eyeStyles: [(label: String, value: EyeStyle)] = [
        ("friendly", .friendly),
        ("angry", .angry),
        ("neutral", .neutral),
        ("cute", .cute),
        ("psycho", .psycho),
        ("dead", .dead),
        ("closed", .closed),
        ("red", .red),
    ]
    private let browMoods: [(label: String, value: BrowMood)] = [
        ("normal", .normal),
        ("angry", .angry),
        ("sad", .sad),
        ("surprised", .surprised),
        ("determined", .determined),
    ]

    // MARK: - Init（現在の mistakeOni を初期値に）

    init() {
        let a = CharacterAppearance.mistakeOni
        _selectedBody     = State(initialValue: a.body)
        _selectedEyes     = State(initialValue: a.eyes)
        _selectedMouth    = State(initialValue: a.mouth)
        _selectedLeftArm  = State(initialValue: a.leftArm ?? "(なし)")
        _selectedRightArm = State(initialValue: a.rightArm ?? "(なし)")
        _selectedLegs     = State(initialValue: a.legs ?? "(なし)")
        _selectedDetail   = State(initialValue: a.detail ?? "(なし)")
        _selectedNose     = State(initialValue: a.nose ?? "(なし)")
        _eyeOffsetY       = State(initialValue: a.eyeOffsetY)
        _mouthOffsetY     = State(initialValue: a.mouthOffsetY)
        _eyeAnimated      = State(initialValue: a.eyeAnimated)

        // EyeStyle → index
        let eyeIdx: Int
        switch a.eyeStyle {
        case .friendly: eyeIdx = 0
        case .angry:    eyeIdx = 1
        case .neutral:  eyeIdx = 2
        case .cute:     eyeIdx = 3
        case .psycho:   eyeIdx = 4
        case .dead:     eyeIdx = 5
        case .closed:   eyeIdx = 6
        case .red:      eyeIdx = 7
        default:        eyeIdx = 2
        }
        _eyeStyle = State(initialValue: eyeIdx)

        // BrowMood → index
        let browIdx: Int
        switch a.browMood {
        case .normal:     browIdx = 0
        case .angry:      browIdx = 1
        case .sad:        browIdx = 2
        case .surprised:  browIdx = 3
        case .determined: browIdx = 4
        }
        _browMood = State(initialValue: browIdx)
    }

    // MARK: - 現在の外見を組み立て

    private var currentAppearance: CharacterAppearance {
        CharacterAppearance(
            body: selectedBody,
            eyes: selectedEyes,
            mouth: selectedMouth,
            leftArm: opt(selectedLeftArm),
            rightArm: opt(selectedRightArm),
            legs: opt(selectedLegs),
            detail: selectedDetail.isEmpty ? "detail_none" : selectedDetail,
            nose: opt(selectedNose),
            eyeOffsetY: eyeOffsetY,
            mouthOffsetY: mouthOffsetY,
            eyeStyle: eyeStyles[eyeStyle].value,
            browMood: browMoods[browMood].value,
            eyeAnimated: eyeAnimated
        )
    }

    private func opt(_ s: String) -> String? {
        s == "(なし)" ? nil : s
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // プレビュー
                ZStack {
                    // バトル背景と同じ暗い色
                    LinearGradient(
                        colors: [Color(red: 0.15, green: 0, blue: 0.1), Color(red: 0.3, green: 0, blue: 0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    KennyCharacterView(
                        appearance: currentAppearance,
                        size: characterSize
                    )
                }
                .frame(height: 240)
                .padding(.horizontal, 20)
                .padding(.top, 8)

                // サイズ調整
                HStack {
                    Text("プレビューサイズ: \(Int(characterSize))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Slider(value: $characterSize, in: 80...200, step: 10)
                }
                .padding(.horizontal, 24)
                .padding(.top, 4)

                Divider().padding(.top, 8)

                // パーツ選択リスト
                List {
                    Section("ボディ") {
                        partPicker("body", selection: $selectedBody, options: bodies)
                    }

                    Section("目") {
                        partPicker("eyes (sprite)", selection: $selectedEyes, options: eyes)
                        Picker("eyeStyle", selection: $eyeStyle) {
                            ForEach(0..<eyeStyles.count, id: \.self) { i in
                                Text(eyeStyles[i].label).tag(i)
                            }
                        }
                        Picker("browMood", selection: $browMood) {
                            ForEach(0..<browMoods.count, id: \.self) { i in
                                Text(browMoods[i].label).tag(i)
                            }
                        }
                        Toggle("eyeAnimated", isOn: $eyeAnimated)
                        sliderRow("eyeOffsetY", value: $eyeOffsetY, range: 0.1...0.7)
                    }

                    Section("口") {
                        partPicker("mouth", selection: $selectedMouth, options: mouths)
                        sliderRow("mouthOffsetY", value: $mouthOffsetY, range: 0.3...0.8)
                    }

                    Section("腕") {
                        partPicker("leftArm", selection: $selectedLeftArm, options: arms)
                        partPicker("rightArm", selection: $selectedRightArm, options: arms)
                    }

                    Section("足") {
                        partPicker("legs", selection: $selectedLegs, options: legs)
                    }

                    Section("角・装飾") {
                        partPicker("detail", selection: $selectedDetail, options: details)
                    }

                    Section("鼻") {
                        partPicker("nose", selection: $selectedNose, options: noses)
                    }

                    // コード出力
                    Section("コピー用コード") {
                        Text(codeSnippet)
                            .font(.system(size: 11, design: .monospaced))
                            .textSelection(.enabled)

                        Button("クリップボードにコピー") {
                            UIPasteboard.general.string = codeSnippet
                        }
                        .font(.caption.bold())
                    }

                    // パーツ位置調整へ
                    Section("パーツ位置調整") {
                        NavigationLink("パーツ位置を微調整") {
                            CharacterLayoutDebugView()
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("まちがいおに外見")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("とじる") { dismiss() }
                }
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func partPicker(_ label: String, selection: Binding<String>, options: [String]) -> some View {
        Picker(label, selection: selection) {
            ForEach(options, id: \.self) { name in
                Text(name).tag(name)
            }
        }
        .font(.system(size: 14, design: .monospaced))
    }

    @ViewBuilder
    private func sliderRow(_ label: String, value: Binding<CGFloat>, range: ClosedRange<CGFloat>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: "%.2f", value.wrappedValue))
                    .font(.system(size: 12, design: .monospaced))
            }
            Slider(value: value, in: range, step: 0.01)
        }
    }

    // MARK: - コードスニペット

    private var codeSnippet: String {
        let la = opt(selectedLeftArm).map { "\"\($0)\"" } ?? "nil"
        let ra = opt(selectedRightArm).map { "\"\($0)\"" } ?? "nil"
        let lg = opt(selectedLegs).map { "\"\($0)\"" } ?? "nil"
        let dt = opt(selectedDetail).map { "\"\($0)\"" } ?? "nil"
        let ns = opt(selectedNose).map { "\"\($0)\"" } ?? "nil"

        return """
        static let mistakeOni = CharacterAppearance(
            body: "\(selectedBody)", eyes: "\(selectedEyes)", mouth: "\(selectedMouth)",
            leftArm: \(la), rightArm: \(ra), legs: \(lg),
            detail: \(dt), nose: \(ns),
            eyeOffsetY: \(String(format: "%.2f", eyeOffsetY)), mouthOffsetY: \(String(format: "%.2f", mouthOffsetY)),
            eyeStyle: .\(eyeStyles[eyeStyle].label), browMood: .\(browMoods[browMood].label), eyeAnimated: \(eyeAnimated)
        )
        """
    }
}

#Preview {
    MistakeOniDebugView()
}
#endif

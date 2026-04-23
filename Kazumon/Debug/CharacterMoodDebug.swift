#if DEBUG
import SwiftUI

/// タイトルキャラ表情テスト用のDEBUG状態 + 調整パラメータ
@Observable
final class CharacterMoodDebug {
    static let shared = CharacterMoodDebug()

    // 基本設定
    var isEnabled = false
    var autoChange = false
    var tapReaction = false
    var currentMood: Mood = .normal
    var showDebugFrame = false

    enum Mood: String, CaseIterable {
        case normal    = "ふつう"
        case smirk     = "ニヤッ"
        case blush     = "てれ"
        case squint    = "ジト目"
        case surprised = "びっくり"
    }

    // MARK: - blush パラメータ
    var blushOffsetX: CGFloat { get { ud("blush_ox", default: 0.18) } set { setUd("blush_ox", newValue) } }
    var blushOffsetY: CGFloat { get { ud("blush_oy", default: 0.08) } set { setUd("blush_oy", newValue) } }
    var blushSize: CGFloat    { get { ud("blush_sz", default: 0.14) } set { setUd("blush_sz", newValue) } }
    var blushOpacity: CGFloat { get { ud("blush_op", default: 0.35) } set { setUd("blush_op", newValue) } }

    // MARK: - smirk パラメータ
    var smirkOffsetX: CGFloat   { get { ud("smirk_ox", default: 0.0) } set { setUd("smirk_ox", newValue) } }
    var smirkOffsetY: CGFloat   { get { ud("smirk_oy", default: 0.20) } set { setUd("smirk_oy", newValue) } }
    var smirkWidth: CGFloat     { get { ud("smirk_w", default: 0.18) } set { setUd("smirk_w", newValue) } }
    var smirkHeight: CGFloat    { get { ud("smirk_h", default: 0.08) } set { setUd("smirk_h", newValue) } }
    var smirkOpacity: CGFloat   { get { ud("smirk_op", default: 0.7) } set { setUd("smirk_op", newValue) } }
    var smirkRotation: CGFloat  { get { ud("smirk_rot", default: 0.0) } set { setUd("smirk_rot", newValue) } }

    // MARK: - squint パラメータ
    var squintOffsetX: CGFloat  { get { ud("squint_ox", default: 0.0) } set { setUd("squint_ox", newValue) } }
    var squintOffsetY: CGFloat  { get { ud("squint_oy", default: -0.05) } set { setUd("squint_oy", newValue) } }
    var squintWidth: CGFloat    { get { ud("squint_w", default: 0.13) } set { setUd("squint_w", newValue) } }
    var squintHeight: CGFloat   { get { ud("squint_h", default: 0.04) } set { setUd("squint_h", newValue) } }
    var squintOpacity: CGFloat  { get { ud("squint_op", default: 0.3) } set { setUd("squint_op", newValue) } }
    var squintSpacing: CGFloat  { get { ud("squint_sp", default: 0.12) } set { setUd("squint_sp", newValue) } }

    // MARK: - surprised パラメータ
    var surprisedOffsetX: CGFloat { get { ud("surp_ox", default: 0.22) } set { setUd("surp_ox", newValue) } }
    var surprisedOffsetY: CGFloat { get { ud("surp_oy", default: -0.35) } set { setUd("surp_oy", newValue) } }
    var surprisedScale: CGFloat   { get { ud("surp_sc", default: 0.15) } set { setUd("surp_sc", newValue) } }
    var surprisedOpacity: CGFloat { get { ud("surp_op", default: 1.0) } set { setUd("surp_op", newValue) } }

    // MARK: - UserDefaults

    private let prefix = "dbg_mood_"
    private let defaults = UserDefaults.standard

    private func ud(_ key: String, default val: CGFloat) -> CGFloat {
        let k = prefix + key
        return defaults.object(forKey: k) != nil ? CGFloat(defaults.double(forKey: k)) : val
    }
    private func setUd(_ key: String, _ val: CGFloat) {
        defaults.set(Double(val), forKey: prefix + key)
    }

    // MARK: - リセット

    func resetBlush() {
        for k in ["blush_ox","blush_oy","blush_sz","blush_op"] { defaults.removeObject(forKey: prefix + k) }
    }
    func resetSmirk() {
        for k in ["smirk_ox","smirk_oy","smirk_w","smirk_h","smirk_op","smirk_rot"] { defaults.removeObject(forKey: prefix + k) }
    }
    func resetSquint() {
        for k in ["squint_ox","squint_oy","squint_w","squint_h","squint_op","squint_sp"] { defaults.removeObject(forKey: prefix + k) }
    }
    func resetSurprised() {
        for k in ["surp_ox","surp_oy","surp_sc","surp_op"] { defaults.removeObject(forKey: prefix + k) }
    }
    func resetAll() {
        let keys = defaults.dictionaryRepresentation().keys.filter { $0.hasPrefix(prefix) }
        for k in keys { defaults.removeObject(forKey: k) }
    }

    private init() {}

    func randomMood() -> Mood {
        Mood.allCases.filter { $0 != .normal }.randomElement() ?? .smirk
    }
}
#endif

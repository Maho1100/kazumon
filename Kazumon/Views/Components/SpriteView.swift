import SwiftUI

// MARK: - スプライトシートから1パーツを切り出すView
// ★ Image を直接描画（overlay パターン廃止）。
//   overlay 内の Image は親の repeatForever アニメに追従しない問題があった。
//   Image を常に描画し、フレームが見つからない場合は opacity 0 で隠す。
//   ビューIDは常に同一 → 親アニメーションとの関連が維持される。
struct SpriteView: View {
    let frameName: String
    let displayWidth: CGFloat
    var flipped: Bool = false
    var tintColor: Color? = nil   // nil以外なら colorMultiply で色付け

    private var sf: SpriteFrame? { spriteFrames[frameName] }

    private var displayHeight: CGFloat {
        guard let f = sf else { return displayWidth }
        return f.height * displayWidth / f.width
    }

    var body: some View {
        // ★ 常に Image を描画。フレーム未発見時は opacity 0。
        //   if let / overlay を使わず、Image のビューIDを固定する。
        Image("spritesheet_default")
            .resizable()
            .frame(width: SPRITESHEET_SIZE, height: SPRITESHEET_SIZE)
            .offset(x: -(sf?.x ?? 0), y: -(sf?.y ?? 0))
            .frame(
                width: sf?.width ?? displayWidth,
                height: sf?.height ?? displayWidth,
                alignment: .topLeading
            )
            .clipped()
            .scaleEffect(
                x: flipped ? -(displayWidth / (sf?.width ?? displayWidth)) : (displayWidth / (sf?.width ?? displayWidth)),
                y: displayWidth / (sf?.width ?? displayWidth),
                anchor: .center
            )
            .frame(width: displayWidth, height: displayHeight)
            .colorMultiply(tintColor ?? .white)
            .opacity(sf != nil ? 1 : 0)

        // Assets.xcassetsの個別画像フォールバック（スプライトシートに無い場合）
        if sf == nil, let uiImg = UIImage(named: frameName) {
            Image(uiImage: uiImg)
                .resizable()
                .scaledToFit()
                .frame(width: displayWidth)
                .scaleEffect(x: flipped ? -1 : 1, y: 1)
                .colorMultiply(tintColor ?? .white)
        }
    }
}

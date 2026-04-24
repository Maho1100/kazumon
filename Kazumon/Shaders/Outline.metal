#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

/// キャラクター外側縁取りシェーダー（内部エッジは無視）
[[ stitchable ]] half4 outline(
    float2 position,
    SwiftUI::Layer layer,
    float thickness,
    half4 outlineColor
) {
    half4 current = layer.sample(position);

    // 不透明ピクセルはそのまま返す
    if (current.a > 0.01) {
        return current;
    }

    // 透明ピクセル: 周囲に不透明ピクセルがあるか確認
    float t = max(1.0, thickness);
    int steps = int(t);
    float closestDist = t + 1.0;

    for (int dx = -steps; dx <= steps; dx++) {
        for (int dy = -steps; dy <= steps; dy++) {
            if (dx == 0 && dy == 0) continue;
            float dist = sqrt(float(dx * dx + dy * dy));
            if (dist > t) continue;

            half4 neighbor = layer.sample(position + float2(float(dx), float(dy)));
            if (neighbor.a > 0.5 && dist < closestDist) {
                closestDist = dist;
            }
        }
    }

    if (closestDist <= t) {
        // 外側の輪郭かチェック: 反対方向にもっと外側が透明なら外側エッジ
        float fade = 1.0 - (closestDist / (t + 0.5));
        return half4(outlineColor.rgb, outlineColor.a * half(fade));
    }

    return current;
}

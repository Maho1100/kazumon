# Leonardo AI プロンプト集 — かずもん キャラデザイン

> ART_DIRECTION.md 準拠。生成後は 5.10 デザインチェックリストで検証すること。

---

## Prompt 1: 主人公 設定画（3アングル）

```
Character design sheet of a cute mascot creature for a kids' math RPG game.

The character is a small, round, teardrop-shaped creature with a chibi 2-head-tall proportion. Light cyan / aqua-green color body. Thick, uniform black outline. Flat cel-shaded coloring with minimal shading — no watercolor, no painterly texture.

Key features:
- Teardrop-shaped body (wider at bottom, slightly narrower at top)
- Large round eyes with white sclera and big dark pupils, placed low on the face
- Tiny simple smile mouth
- Short stubby legs with round feet for stable grounding
- Short mitten-shaped arms (no fingers)
- A small star symbol on the chest (identification mark)
- Slightly blushing cheeks (simple circles, not painted)
- No neck — head merges into body smoothly

Show THREE views on a white background:
1. Front view (centered)
2. Side view (left side)
3. Three-quarter view (3/4 angle)

Style: flat vector illustration, game character design sheet, clean lines, simple shapes, minimal detail, suitable for 2D sprite animation and 3D low-poly conversion. Similar style to Cut the Rope, Toca Boca, or Kirby. White background, no effects, no environment.
```
人が出てしまうので、こっちに修正

Character design sheet of a cute non-human mascot creature for a kids' math RPG game.

This is NOT a human child, NOT a kid in a hoodie, NOT a person wearing clothes. It is a small fantasy creature with a teardrop-shaped body and weak 2-head-tall chibi proportions. The head and body are merged into one smooth droplet form. No neck.

Light cyan to aqua-green body color. Thick uniform black outline. Flat cel-shaded coloring with minimal shading. No watercolor. No painterly texture. No clothing. No jacket. No hoodie. No shoes.

Key features:
- Teardrop-shaped body, wider at the bottom and narrower at the top
- Non-human mascot creature
- Large round eyes with white sclera and dark pupils, placed low on the face
- Tiny simple smile mouth
- Short mitten-shaped arms, no fingers
- Short stubby legs with round feet
- A small plus sign emblem on the chest
- Simple blush circles on cheeks
- Smooth, simple silhouette
- Minimal detail

Show THREE views on a white background:
1. Front view
2. Side view
3. Three-quarter view

Style: flat vector illustration, clean lines, simple shapes, minimal detail, character turnaround sheet, suitable for 2D sprite animation and future 3D low-poly modeling, white background, no effects, no environment
**Leonardo AI 設定のおすすめ:**
- Model: Leonardo Phoenix または Leonardo Diffusion XL
- Style: Illustration / Anime
- Guidance Scale: 7〜9（高めで指示通りに）
- 解像度: 1024x768 以上（横長で3アングル並べる）

---

## Prompt 2: 主人公 表情シート（4表情）

```
Expression sheet of a cute teardrop-shaped mascot creature. Light cyan / aqua-green body, thick black outline, flat cel-shaded style, 2-head-tall chibi proportion. Small star symbol on chest. Mitten hands, stubby legs.

Show FOUR expressions in a row on white background:
1. Normal — neutral happy, small smile, relaxed eyes
2. Happy — wide open mouth smile, eyes squeezed shut (^_^), arms raised
3. Sad — downturned mouth, droopy eyes, slightly hunched
4. Surprised — wide open round mouth (O shape), wide eyes, arms out

Same character in all four. Consistent proportions. Front-facing view only. Flat illustration style, clean vector look, thick uniform outlines. White background, no effects.
```

---

## Prompt 3: 主人公 ポーズシート（アニメーション用）

```
Pose sheet of a cute teardrop-shaped mascot creature. Light cyan / aqua-green body, thick black outline, flat cel-shaded style, 2-head-tall chibi proportion. Star on chest. Mitten hands, stubby legs.

Show FIVE poses on white background:
1. Idle — standing relaxed, slight tilt, arms at sides
2. Walking — one leg forward, arms swinging, slight lean
3. Jumping — arms up, legs tucked, happy face
4. Hit/Damage — leaning back, eyes shut, small impact stars
5. Victory — jumping with both arms raised, huge smile, eyes shut

Same character, consistent design. Front-facing view. Flat vector style, clean outlines. White background, no effects, no environment.
```

---

## Prompt 4: 基本敵（スライム相当）設定画

> 主人公が確定してから使うこと。主人公と同じ線・形・簡略度で作る。

```
Character design sheet of a cute round enemy monster for a kids' math RPG game.

The monster is a small, round, ball-shaped creature — slightly larger than the hero character. It looks confused and mischievous, NOT scary. Same art style as the hero: thick uniform black outline, flat cel-shaded coloring, minimal detail.

Key features:
- Perfectly round body shape (distinguishable from hero's teardrop shape in silhouette)
- Soft green color (lime / yellow-green)
- Large round eyes with spiral or dizzy expression (confused look)
- Small fang poking out from a wobbly grin
- Tiny stubby feet (no legs visible — sits directly on ground)
- No arms, or very tiny bump arms
- Small swirl mark on forehead (confusion symbol)
- Blushing cheeks

Show THREE views: front, side, three-quarter. White background.

Style: flat vector, game character sheet, clean lines, same visual language as a teardrop-shaped cyan hero mascot. Cute, not threatening. Suitable for 2D animation and 3D low-poly.
```

---

## Prompt 5: ボス候補 設定画

> 基本敵と並べて統一感を確認してから使う。

```
Character design sheet of a cute but imposing boss monster for a kids' math RPG game.

The boss is wider and taller than regular enemies but still cute and non-threatening. Same flat art style: thick uniform black outline, cel-shaded, minimal detail.

Key features:
- Squat, wide body — ずんぐり (stocky) build, about 1.5x wider than regular enemies
- Dark purple / indigo color body
- Large eyes with thick eyebrows showing determination (not anger)
- Wide grin with two small fangs
- Two small rounded horns on top (NOT sharp — rounded tips)
- Thick mitten-like arms crossed or on hips (confident pose)
- Sturdy short legs with big round feet
- A cracked crown or jagged marking on chest (boss symbol)

Show THREE views: front, side, three-quarter. White background.

Style: flat vector, game character design sheet. Same visual language as the teardrop-shaped cyan hero and round green regular enemy. Cute boss — a kid should want to fight it, not be scared of it. Suitable for 2D sprite and 3D low-poly.
```

---

## 生成時の注意

### やるべきこと
- 生成後、**黒ベタシルエットテスト**: 画像を真っ黒に塗りつぶして、3体の区別がつくか確認
- 主人公 → 基本敵 → ボス の順で1体ずつ確定させる
- 3体を横に並べて、**線の太さ・簡略度・頭身** が揃っているか確認

### やってはいけないこと
- 水彩風・ペイント風のスタイルで生成しない
- 背景や環境を入れない（キャラのみ白背景）
- 細かい模様やテクスチャを追加しない
- 正面だけで判断しない（横向きでも確認）

### 記号バリエーション（主人公の胸マーク候補）
星以外を試したい場合：
- `star symbol` → 星
- `plus sign symbol` → たす記号（算数RPGに最も合う）
- `droplet symbol` → しずく
- `diamond symbol` → ダイヤ
- `lightning bolt symbol` → 稲妻

おすすめは **plus sign（+）** — 算数の「たす」を象徴し、ゲームテーマと直結する。

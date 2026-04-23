# カズモン

たし算バトルで モンスターを たおす、こどもむけ算数ゲーム。

## あそびかた

ブラウザで開くだけ。インストール不要。

1. 「スタート」をタップ
2. たし算の答えを 4択から選ぶ
3. 正解するとモンスターにダメージ！
4. できるだけ高いフロアを目指そう

## 技術スタック

- HTML / CSS / JavaScript（フレームワークなし）
- Supabase（PostgreSQL — データ同期・デイリー判定）
- GitHub Pages（ホスティング）

## ローカルで動かす

```bash
git clone https://github.com/Maho1100/kazumon.git
cd kazumon
# 任意の静的サーバーで開く（例:）
npx serve .
# または index.html をブラウザで直接開く
```

Supabase 連携なしでも localStorage のみで動作します。

## DB セットアップ（Supabase）

`db/` 配下の SQL を番号順に Supabase SQL Editor で実行してください。

```
db/001_schema.sql      — テーブル定義
db/002_functions.sql   — RPC 関数
db/003_rls.sql         — Row Level Security
```

## ライセンス

[LICENSE](./LICENSE) を参照。非商用利用のみ許可。

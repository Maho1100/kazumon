# db/ — Supabase SQL 管理ルール

このフォルダは、カズモンの Supabase（PostgreSQL）構成を **SQL ファイルで再現できるようにする** ためのものです。
PC を初期化しても、新しい Supabase プロジェクトを作っても、ここの SQL を順番に流せば同じ環境が立ち上がります。

> **!! 注意 !!**
> 事業戦略・課金設計・ロードマップ・KPI などは **絶対にここに書かない**。
> それらは `private/` に置くこと（`private/` は `.gitignore` で除外済み）。

---

## ファイル一覧と適用順

SQL は **番号順に上から実行** してください。順番を守らないと外部キーや関数参照でエラーになります。

| ファイル | 内容 |
|---|---|
| `001_schema.sql` | テーブル定義（profiles など） |
| `002_functions.sql` | RPC 関数（claim_daily など） |
| `003_rls.sql` | Row Level Security ポリシー |

今後ファイルが増える場合は、この順番の後ろに追加していきます。

---

## ファイル命名規則

```
{3桁連番}_{対象}_{種類}.sql
```

例:
- `004_rankings.sql` — rankings テーブル定義
- `005_rankings_rls.sql` — rankings の RLS ポリシー
- `006_add_avatar_column.sql` — 既存テーブルへのカラム追加
- `007_leaderboard_func.sql` — 新しい RPC 関数

連番は飛ばさない。途中に挿入したくなったらリネームではなく末尾に追加する。

---

## 冪等 SQL のルール

**何度実行しても壊れない SQL** を書くこと。
Supabase SQL Editor で間違えて 2 回流しても安全なように、以下のパターンを守る。

### テーブル作成

```sql
CREATE TABLE IF NOT EXISTS profiles (
  user_id text PRIMARY KEY,
  created_at timestamptz NOT NULL DEFAULT now()
);
```

### カラム追加

```sql
-- DO ブロックで「カラムが無い場合だけ追加」
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'profiles' AND column_name = 'new_column'
  ) THEN
    ALTER TABLE profiles ADD COLUMN new_column int NOT NULL DEFAULT 0;
  END IF;
END
$$;
```

### インデックス作成

```sql
CREATE INDEX IF NOT EXISTS idx_profiles_level ON profiles (level);
```

### 関数（RPC）更新

関数は冪等な `IF NOT EXISTS` がないので、**必ず DROP → CREATE** で書く。

```sql
DROP FUNCTION IF EXISTS my_function(text);
CREATE FUNCTION my_function(p_user_id text)
RETURNS ... AS $$ ... $$ LANGUAGE plpgsql;
```

### トリガー

```sql
DROP TRIGGER IF EXISTS trg_name ON table_name;
CREATE TRIGGER trg_name ...;
```

### RLS ポリシー

```sql
DROP POLICY IF EXISTS "policy_name" ON table_name;
CREATE POLICY "policy_name" ON table_name ...;
```

---

## RLS について

現在はテスト運用のため `003_rls.sql` で **全許可ポリシー** を設定しています。

本番リリース前に必ず以下に移行すること:

1. Supabase Auth を導入する
2. ポリシーを `auth.uid()::text = user_id` に変更する
3. `SECURITY DEFINER` 関数を見直し、必要最小限に絞る
4. anon ロールの直接 INSERT/UPDATE を禁止し、RPC 経由のみにする

---

## Supabase SQL Editor での適用手順

1. Supabase ダッシュボード → **SQL Editor** を開く
2. `db/001_schema.sql` の内容をコピーして貼り付ける
3. **RUN** をクリック
4. `Success. No rows returned` が出れば OK
5. 同じ手順で `002` → `003` → … と順番に実行する

エラーが出た場合:
- `already exists` → 冪等設計なら無視して OK（ただし冪等でない SQL は修正する）
- `does not exist` → 前の番号の SQL を先に実行していない可能性あり

---

## 変更後のルール

### SQL を適用したら必ず Git に残す

1. SQL Editor で変更を適用する
2. その SQL を `db/` に新しいファイルとして追加する（または既存ファイルを更新する）
3. `git add db/ && git commit && git push` する

**「SQL Editor だけ触って Git に残さない」は禁止。**
復元できなくなるため。

### UI（ダッシュボード）で触ったら SQL に逆輸入する

Supabase の Table Editor や Auth 設定で変更した場合も、
対応する SQL を `db/` に書き起こして Git に残すこと。

---

## 動作確認チェック項目

SQL を全て適用した後、以下を確認する。

### profiles テーブル

SQL Editor で実行:

```sql
SELECT column_name, data_type, is_nullable
  FROM information_schema.columns
 WHERE table_name = 'profiles'
 ORDER BY ordinal_position;
```

期待されるカラム: `user_id`, `created_at`, `updated_at`, `level`, `xp`, `encyclopedia`, `streak_count`, `last_claim_date`, `best_score`

### claim_daily 関数

SQL Editor で実行:

```sql
SELECT * FROM claim_daily('test-user-001');
```

期待結果: `streak_count=1`, `last_claim_date=今日`, `claimed_today=false`（初回）

もう一度実行:

```sql
SELECT * FROM claim_daily('test-user-001');
```

期待結果: `claimed_today=true`（2回目は受取済み）

### RLS

SQL Editor で実行:

```sql
SELECT tablename, policyname
  FROM pg_policies
 WHERE tablename = 'profiles';
```

3つのポリシー（select, insert, update）が表示されれば OK。

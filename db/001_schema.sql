-- ========================================
-- カズモン — profiles テーブル定義
-- ========================================
-- 実行先: Supabase SQL Editor
-- 冪等: 何度実行しても安全（IF NOT EXISTS / ADD IF NOT EXISTS）

-- 1. テーブル作成
CREATE TABLE IF NOT EXISTS profiles (
  user_id         text PRIMARY KEY,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);

-- 2. カラム追加（不足分を後から追加できるよう ALTER で管理）
DO $$
BEGIN
  -- level
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'profiles' AND column_name = 'level'
  ) THEN
    ALTER TABLE profiles ADD COLUMN level int NOT NULL DEFAULT 1;
  END IF;

  -- xp
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'profiles' AND column_name = 'xp'
  ) THEN
    ALTER TABLE profiles ADD COLUMN xp int NOT NULL DEFAULT 0;
  END IF;

  -- encyclopedia (jsonb: localStorage全データのバックアップ)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'profiles' AND column_name = 'encyclopedia'
  ) THEN
    ALTER TABLE profiles ADD COLUMN encyclopedia jsonb DEFAULT '{}'::jsonb;
  END IF;

  -- streak_count
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'profiles' AND column_name = 'streak_count'
  ) THEN
    ALTER TABLE profiles ADD COLUMN streak_count int NOT NULL DEFAULT 0;
  END IF;

  -- last_claim_date
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'profiles' AND column_name = 'last_claim_date'
  ) THEN
    ALTER TABLE profiles ADD COLUMN last_claim_date date;
  END IF;

  -- best_score
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'profiles' AND column_name = 'best_score'
  ) THEN
    ALTER TABLE profiles ADD COLUMN best_score int NOT NULL DEFAULT 0;
  END IF;
END
$$;

-- 3. updated_at 自動更新トリガー
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_profiles_updated_at ON profiles;
CREATE TRIGGER trg_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

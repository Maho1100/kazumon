-- ========================================
-- カズモン — Row Level Security (RLS)
-- ========================================
-- 実行先: Supabase SQL Editor
--
-- !! 注意 !!
-- 現時点はテスト運用のため、anon ロールに全操作を許可している。
-- 本番リリース前に必ず以下へ移行すること:
--   1) Supabase Auth を導入し、user_id = auth.uid() で制限
--   2) SECURITY DEFINER 関数を SECURITY INVOKER に切り替え
--   3) anon の直接 INSERT/UPDATE を禁止し、RPC 経由のみにする

-- 1. RLS を有効化
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- 2. テスト用ポリシー（全許可）
--    TODO: 本番では auth.uid() = user_id に変更する

-- SELECT
DROP POLICY IF EXISTS "profiles_select_all" ON profiles;
CREATE POLICY "profiles_select_all" ON profiles
  FOR SELECT
  USING (true);

-- INSERT
DROP POLICY IF EXISTS "profiles_insert_all" ON profiles;
CREATE POLICY "profiles_insert_all" ON profiles
  FOR INSERT
  WITH CHECK (true);

-- UPDATE
DROP POLICY IF EXISTS "profiles_update_all" ON profiles;
CREATE POLICY "profiles_update_all" ON profiles
  FOR UPDATE
  USING (true)
  WITH CHECK (true);

-- ----------------------------------------
-- 本番用ポリシー（参考・コメントアウト）
-- ----------------------------------------
-- CREATE POLICY "profiles_select_own" ON profiles
--   FOR SELECT USING (auth.uid()::text = user_id);
--
-- CREATE POLICY "profiles_insert_own" ON profiles
--   FOR INSERT WITH CHECK (auth.uid()::text = user_id);
--
-- CREATE POLICY "profiles_update_own" ON profiles
--   FOR UPDATE
--   USING (auth.uid()::text = user_id)
--   WITH CHECK (auth.uid()::text = user_id);

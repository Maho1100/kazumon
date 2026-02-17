-- ========================================
-- カズモン — RPC 関数定義
-- ========================================
-- 実行先: Supabase SQL Editor
-- 冪等: DROP → CREATE で常に最新に上書き

-- ----------------------------------------
-- claim_daily(p_user_id text)
-- ----------------------------------------
-- デイリーボーナス受取り判定（サーバー時刻基準）
-- - Asia/Tokyo の日付で today を算出
-- - 今日すでに受取済み → claimed_today = true
-- - 未受取 → streak 更新して claimed_today = false
--
-- ※ SECURITY DEFINER: anon key からでも profiles を更新できるようにする
--   本番では Auth + RLS に移行し、SECURITY INVOKER に切り替えること
-- ※ profiles は必ず別名 p で参照（出力列名との衝突回避）

DROP FUNCTION IF EXISTS claim_daily(text);

CREATE FUNCTION claim_daily(p_user_id text)
RETURNS TABLE(streak_count int, last_claim_date date, claimed_today boolean)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_today  date;
  v_last   date;
  v_streak int;
BEGIN
  v_today := (now() AT TIME ZONE 'Asia/Tokyo')::date;

  -- 対象行をロック
  SELECT p.streak_count, p.last_claim_date
    INTO v_streak, v_last
    FROM profiles p
   WHERE p.user_id = p_user_id
     FOR UPDATE;

  -- 新規ユーザー
  IF NOT FOUND THEN
    INSERT INTO profiles (user_id, streak_count, last_claim_date)
    VALUES (p_user_id, 1, v_today);
    RETURN QUERY SELECT 1, v_today, false;
    RETURN;
  END IF;

  -- 今日すでに受取済み
  IF v_last = v_today THEN
    RETURN QUERY SELECT COALESCE(v_streak, 1), v_last, true;
    RETURN;
  END IF;

  -- ストリーク計算
  IF v_last IS NOT NULL AND v_last = v_today - 1 THEN
    v_streak := COALESCE(v_streak, 0) + 1;
  ELSE
    v_streak := 1;
  END IF;

  -- 更新
  UPDATE profiles
     SET streak_count    = v_streak,
         last_claim_date = v_today
   WHERE profiles.user_id = p_user_id;

  RETURN QUERY SELECT v_streak, v_today, false;
END;
$$;

// ========================================
// カズモン — localStorage データ管理
// ========================================

var KEYS = {
  USER:           'kazumon_user',
  ITEMS:          'kazumon_items',
  SESSIONS:       'kazumon_sessions',
  MISTAKES:       'kazumon_mistakes',
  DAILY_BONUS:    'kazumon_daily_bonus_date',
  STREAK_REWARDS: 'kazumon_streak_rewards',
  DAILY_MISSION:  'kazumon_daily_mission'
};

var MAX_SESSIONS = 100;

// レベルテーブル: [必要累計XP, レベル]
var LEVEL_TABLE = [
  [0,      1],
  [100,    2],
  [300,    3],
  [500,    4],
  [800,    5],
  [1200,   6],
  [1600,   7],
  [2000,   8],
  [2200,   9],
  [2500,  10],
  [3200,  11],
  [4000,  12],
  [4800,  13],
  [5600,  14],
  [6400,  15],
  [7200,  16],
  [8000,  20],
  [15000, 30],
  [30000, 40],
  [50000, 50],
  [80000, 60],
  [120000, 70],
  [160000, 80],
  [180000, 90],
  [200000, 100]
];

// --- ヘルパー ---

function getToday() {
  return new Date().toISOString().slice(0, 10);
}

function safeGetItem(key) {
  try {
    var raw = localStorage.getItem(key);
    return raw ? JSON.parse(raw) : null;
  } catch (e) {
    console.warn('localStorage よみこみエラー:', key, e);
    return null;
  }
}

function safeSetItem(key, value) {
  try {
    localStorage.setItem(key, JSON.stringify(value));
  } catch (e) {
    console.warn('localStorage かきこみエラー:', key, e);
  }
}

// ========================================
// 1. ユーザーデータ
// ========================================

function getDefaultUserData() {
  return {
    playerName: 'カズ',
    level: 1,
    totalXP: 0,
    bestFloor: 0,
    bestScore: 0,
    streakDays: 0,
    lastPlayDate: null,
    totalPlayCount: 0,
    totalCorrect: 0,
    totalAnswered: 0,
    soundEnabled: true
  };
}

function loadUserData() {
  var data = safeGetItem(KEYS.USER);
  if (!data) return getDefaultUserData();
  var defaults = getDefaultUserData();
  // デフォルト値でマージ（欠損フィールド補完）
  for (var key in defaults) {
    if (data[key] === undefined) {
      data[key] = defaults[key];
    }
  }
  return data;
}

function saveUserData(data) {
  safeSetItem(KEYS.USER, data);
  scheduleSyncToServer();
}

// ========================================
// 2. アイテムデータ
// ========================================

function loadItems() {
  return safeGetItem(KEYS.ITEMS) || [];
}

function saveItems(items) {
  safeSetItem(KEYS.ITEMS, items);
  scheduleSyncToServer();
}

// ========================================
// 3. セッション履歴
// ========================================

function loadSessionHistory() {
  return safeGetItem(KEYS.SESSIONS) || [];
}

function saveSessionHistory(session) {
  var sessions = loadSessionHistory();
  sessions.push(session);
  // 最大100件
  if (sessions.length > MAX_SESSIONS) {
    sessions = sessions.slice(sessions.length - MAX_SESSIONS);
  }
  safeSetItem(KEYS.SESSIONS, sessions);
  scheduleSyncToServer();
}

// ========================================
// 4. 間違いログ
// ========================================

function loadMistakeLog() {
  return safeGetItem(KEYS.MISTAKES) || [];
}

function saveMistakeLog(log) {
  safeSetItem(KEYS.MISTAKES, log);
  scheduleSyncToServer();
}

// ========================================
// 5. ストリーク更新
// ========================================

function updateStreak() {
  var user = loadUserData();
  var today = getToday();

  if (user.lastPlayDate === today) {
    // 今日すでにプレイ済み
    return user;
  }

  if (user.lastPlayDate) {
    // 昨日との差を計算
    var last = new Date(user.lastPlayDate + 'T00:00:00');
    var now  = new Date(today + 'T00:00:00');
    var diffDays = Math.round((now - last) / (1000 * 60 * 60 * 24));

    if (diffDays === 1) {
      user.streakDays++;
    } else {
      user.streakDays = 1;
    }
  } else {
    user.streakDays = 1;
  }

  user.lastPlayDate = today;
  saveUserData(user);
  return user;
}

// ========================================
// 6. 間違い追加
// ========================================

function addMistake(a, b, wrongAnswer) {
  var log = loadMistakeLog();
  var now = new Date().toISOString();
  var found = false;

  for (var i = 0; i < log.length; i++) {
    if (log[i].a === a && log[i].b === b) {
      log[i].count++;
      log[i].wrongAnswer = wrongAnswer;
      log[i].lastMistake = now;
      log[i].nextReview = calcNextReview(log[i].count);
      found = true;
      break;
    }
  }

  if (!found) {
    log.push({
      a: a,
      b: b,
      wrongAnswer: wrongAnswer,
      count: 1,
      lastMistake: now,
      nextReview: calcNextReview(1)
    });
  }

  saveMistakeLog(log);
}

function removeMistake(a, b) {
  var log = loadMistakeLog();
  var filtered = [];
  for (var i = 0; i < log.length; i++) {
    if (!(log[i].a === a && log[i].b === b)) {
      filtered.push(log[i]);
    }
  }
  saveMistakeLog(filtered);
}

function calcNextReview(count) {
  var now = Date.now();
  if (count <= 1) {
    // 2分後
    return new Date(now + 2 * 60 * 1000).toISOString();
  } else if (count === 2) {
    // 翌日
    return new Date(now + 24 * 60 * 60 * 1000).toISOString();
  } else {
    // 3日後
    return new Date(now + 3 * 24 * 60 * 60 * 1000).toISOString();
  }
}

// ========================================
// 7. 復習問題取得
// ========================================

function getReviewProblems() {
  var log = loadMistakeLog();
  var now = new Date().toISOString();
  var review = [];

  for (var i = 0; i < log.length; i++) {
    if (log[i].nextReview && log[i].nextReview <= now) {
      review.push(log[i]);
    }
  }

  return review;
}

// ========================================
// 8. XP追加・レベルアップ判定
// ========================================

function calcLevel(totalXP) {
  var level = 1;
  for (var i = 0; i < LEVEL_TABLE.length; i++) {
    if (totalXP >= LEVEL_TABLE[i][0]) {
      level = LEVEL_TABLE[i][1];
    } else {
      break;
    }
  }
  return level;
}

function addXP(amount) {
  var user = loadUserData();
  var oldLevel = user.level;

  user.totalXP += amount;
  user.level = calcLevel(user.totalXP);
  saveUserData(user);

  var leveledUp = user.level > oldLevel;
  if (leveledUp) {
    // debugLog is in game.js; keep silent here
  }

  return { newLevel: user.level, leveledUp: leveledUp };
}

// ========================================
// 9. デイリーボーナス管理
// ========================================

function getDailyBonusDate() {
  return safeGetItem(KEYS.DAILY_BONUS);
}

function setDailyBonusDate(dateStr) {
  safeSetItem(KEYS.DAILY_BONUS, dateStr);
  scheduleSyncToServer();
}

// ========================================
// 10. ストリーク報酬管理
// ========================================

var STREAK_MILESTONES = [7, 30];

function loadStreakRewards() {
  return safeGetItem(KEYS.STREAK_REWARDS) || [];
}

function markStreakRewardClaimed(milestone) {
  var claimed = loadStreakRewards();
  if (claimed.indexOf(milestone) === -1) {
    claimed.push(milestone);
    safeSetItem(KEYS.STREAK_REWARDS, claimed);
    scheduleSyncToServer();
  }
}

// ========================================
// 11. デイリーミッション管理
// ========================================

function loadDailyMission() {
  var data = safeGetItem(KEYS.DAILY_MISSION);
  var today = getToday();
  if (!data || data.date !== today) {
    return { date: today, claimed: false, attempts: 0 };
  }
  return data;
}

function saveDailyMission(data) {
  safeSetItem(KEYS.DAILY_MISSION, data);
  scheduleSyncToServer();
}

function getUnclaimedStreakReward(streakDays) {
  var claimed = loadStreakRewards();
  for (var i = 0; i < STREAK_MILESTONES.length; i++) {
    var m = STREAK_MILESTONES[i];
    if (streakDays >= m && claimed.indexOf(m) === -1) {
      return m;
    }
  }
  return null;
}

// ========================================
// 12. Supabase 同期層
// ========================================

var _syncTimer = null;
var _initialSyncDone = false;
var SYNC_DEBOUNCE_MS = 2000;

function getOrCreateUserId() {
  var id = localStorage.getItem('kazumon_user_id');
  if (!id) {
    id = crypto.randomUUID();
    localStorage.setItem('kazumon_user_id', id);
  }
  return id;
}

function _getSupabaseClient() {
  try {
    if (window._kazumonSupabase && typeof window._kazumonSupabase.from === 'function') {
      return window._kazumonSupabase;
    }
  } catch (e) {}
  return null;
}

// --- サーバーから復元 ---
async function syncFromServer() {
  var sb = _getSupabaseClient();
  if (!sb) {
    console.log('syncFromServer skip: supabase not available');
    return;
  }
  try {
    var userId = getOrCreateUserId();
    var result = await sb
      .from('profiles')
      .select('encyclopedia')
      .eq('user_id', userId)
      .maybeSingle();

    if (result.error) {
      console.warn('syncFromServer error', result.error);
      return;
    }

    if (!result.data) {
      console.log('syncFromServer ok (no server data)');
      return;
    }

    var enc = result.data.encyclopedia;
    if (enc && typeof enc === 'object' && enc.save) {
      // サーバーデータが存在 → localStorageを上書き復元
      safeSetItem(KEYS.USER, enc.save);
      if (enc.items != null)          safeSetItem(KEYS.ITEMS, enc.items);
      if (enc.sessions != null)       safeSetItem(KEYS.SESSIONS, enc.sessions);
      if (enc.mistakes != null)       safeSetItem(KEYS.MISTAKES, enc.mistakes);
      if (enc.dailyBonus != null)     safeSetItem(KEYS.DAILY_BONUS, enc.dailyBonus);
      if (enc.streakRewards != null)  safeSetItem(KEYS.STREAK_REWARDS, enc.streakRewards);
      if (enc.dailyMission != null)   safeSetItem(KEYS.DAILY_MISSION, enc.dailyMission);
      console.log('syncFromServer ok (restored)');
    } else {
      console.log('syncFromServer ok (no save data in encyclopedia)');
    }
  } catch (e) {
    console.warn('syncFromServer error', e);
  }
}

// --- サーバーへ保存 ---
async function syncToServer() {
  var sb = _getSupabaseClient();
  if (!sb) return;
  try {
    var userId = getOrCreateUserId();
    var user = loadUserData();

    var encyclopedia = {
      save:           safeGetItem(KEYS.USER),
      items:          safeGetItem(KEYS.ITEMS),
      sessions:       safeGetItem(KEYS.SESSIONS),
      mistakes:       safeGetItem(KEYS.MISTAKES),
      dailyBonus:     safeGetItem(KEYS.DAILY_BONUS),
      streakRewards:  safeGetItem(KEYS.STREAK_REWARDS),
      dailyMission:   safeGetItem(KEYS.DAILY_MISSION)
    };

    var result = await sb.from('profiles').upsert({
      user_id:         userId,
      level:           user.level,
      xp:              user.totalXP,
      encyclopedia:    encyclopedia,
      streak_count:    user.streakDays,
      last_claim_date: user.lastPlayDate,
      best_score:      user.bestScore
    });

    if (result.error) {
      console.warn('syncToServer error', result.error);
    } else {
      console.log('syncToServer ok');
    }
  } catch (e) {
    console.warn('syncToServer error', e);
  }
}

// --- デバウンス付き同期スケジューラ ---
function scheduleSyncToServer() {
  if (!_initialSyncDone) return;
  if (_syncTimer) clearTimeout(_syncTimer);
  _syncTimer = setTimeout(function () {
    _syncTimer = null;
    syncToServer();
  }, SYNC_DEBOUNCE_MS);
}

// --- 起動時の同期 ---
document.addEventListener('DOMContentLoaded', function () {
  syncFromServer().then(function () {
    _initialSyncDone = true;
    // 復元データでタイトル画面を再描画
    if (typeof applyUserDataToTitle === 'function') {
      applyUserDataToTitle();
    }
    // ローカルの最新データをサーバーへバックアップ
    scheduleSyncToServer();
  }, function (e) {
    // 失敗してもゲームは止めない
    _initialSyncDone = true;
    console.warn('syncFromServer init error', e);
  });
});

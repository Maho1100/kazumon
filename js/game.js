// ========================================
// カズモン — ゲームロジック
// ========================================

var DEBUG = false;
function debugLog() {
  if (DEBUG && console && console.log) {
    console.log.apply(console, arguments);
  }
}

// --- ユーティリティ ---

function randInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function shuffleArray(arr) {
  for (var i = arr.length - 1; i > 0; i--) {
    var j = Math.floor(Math.random() * (i + 1));
    var tmp = arr[i];
    arr[i] = arr[j];
    arr[j] = tmp;
  }
  return arr;
}

// --- 難易度設定 ---

function getDifficultyConfig(floor) {
  if (floor <= 5)  return [1, 5,  1, 4,  2];
  if (floor <= 10) return [1, 9,  1, 9,  3];
  if (floor <= 15) return [5, 9,  6, 9,  4];
  if (floor <= 20) return [10, 50, 1, 9,  5];
  if (floor <= 30) return [10, 50, 10, 50, 8];
  return [1, 99, 1, 99, 10];
}

// --- 選択肢生成 ---

function generateChoices(answer, errorRange) {
  var choices = [answer];

  while (choices.length < 4) {
    var offset = randInt(1, errorRange);
    if (Math.random() < 0.5) offset = -offset;
    var wrong = answer + offset;
    if (wrong < 1) continue;
    if (choices.indexOf(wrong) !== -1) continue;
    choices.push(wrong);
  }

  return shuffleArray(choices);
}

// --- 問題生成 ---

function generateProblem(floor, mistakeLog) {
  // 20%の確率で localStorage の復習問題を優先
  if (Math.random() < 0.2) {
    var review = getReviewProblems();
    if (review.length > 0) {
      var entry = review[randInt(0, review.length - 1)];
      var config = getDifficultyConfig(floor);
      debugLog('ふくしゅうもんだい:', entry.a, '+', entry.b);
      return {
        a: entry.a,
        b: entry.b,
        answer: entry.a + entry.b,
        choices: generateChoices(entry.a + entry.b, config[4]),
        isReview: true
      };
    }
  }

  // セッション内の間違いログからも復習
  if (mistakeLog && mistakeLog.length > 0 && Math.random() < 0.2) {
    var entry2 = mistakeLog[randInt(0, mistakeLog.length - 1)];
    var config2 = getDifficultyConfig(floor);
    return {
      a: entry2.a,
      b: entry2.b,
      answer: entry2.a + entry2.b,
      choices: generateChoices(entry2.a + entry2.b, config2[4]),
      isReview: true
    };
  }

  var cfg = getDifficultyConfig(floor);
  var a = randInt(cfg[0], cfg[1]);
  var b = randInt(cfg[2], cfg[3]);
  var answer = a + b;

  return {
    a: a,
    b: b,
    answer: answer,
    choices: generateChoices(answer, cfg[4]),
    isReview: false
  };
}

// --- フロア設定 ---

var MONSTER_NAMES = [
  { maxFloor: 5,  names: ['スライム', 'マメッチ', 'プルリン'] },
  { maxFloor: 10, names: ['ゴブリン', 'コウモリン', 'キノッピ'] },
  { maxFloor: 15, names: ['ゴーレム', 'ドラッチ', 'オニャンコ'] },
  { maxFloor: 20, names: ['ガーゴイル', 'シャドウン', 'ヨロイダケ'] },
  { maxFloor: 30, names: ['ドラゴニー', 'デスポット', 'マジョリカ'] },
  { maxFloor: Infinity, names: ['ダークキング', 'カオスドラゴ', 'まおうスラ'] }
];

var BOSS_NAMES = [
  { maxFloor: 5,  name: 'キングスライム' },
  { maxFloor: 10, name: 'ゴブリンキング' },
  { maxFloor: 15, name: 'ゴーレムマスター' },
  { maxFloor: 20, name: 'ガーゴイルロード' },
  { maxFloor: 30, name: 'ドラゴンキング' },
  { maxFloor: Infinity, name: 'まおう' }
];

function getMonsterName(floor, isBoss) {
  if (isBoss) {
    for (var i = 0; i < BOSS_NAMES.length; i++) {
      if (floor <= BOSS_NAMES[i].maxFloor) return BOSS_NAMES[i].name;
    }
  }
  for (var j = 0; j < MONSTER_NAMES.length; j++) {
    if (floor <= MONSTER_NAMES[j].maxFloor) {
      var names = MONSTER_NAMES[j].names;
      return names[randInt(0, names.length - 1)];
    }
  }
  return 'モンスター';
}

function getFloorConfig(floor) {
  var isBoss = floor % 5 === 0;

  var baseHP;
  if (floor <= 10) {
    baseHP = 1;
  } else if (floor <= 30) {
    baseHP = 2;
  } else {
    baseHP = 2 + Math.floor((floor - 30) / 5);
  }

  var monsterHP = isBoss ? baseHP * 3 : baseHP;

  var timeLimit = null;
  if (floor >= 16 && floor <= 20) {
    timeLimit = 15;
  } else if (floor >= 21 && floor <= 30) {
    timeLimit = 12;
  } else if (floor >= 31) {
    timeLimit = Math.max(5, 12 - Math.floor((floor - 30) / 5));
  }

  return {
    monsterHP: monsterHP,
    problemsNeeded: monsterHP,
    timeLimit: timeLimit,
    isBoss: isBoss,
    monsterName: getMonsterName(floor, isBoss)
  };
}

// ========================================
// ゲーム状態管理
// ========================================

var PLAYER_MAX_HP = 3;

var gameState = {
  floor: 1,
  playerHP: PLAYER_MAX_HP,
  monsterHP: 0,
  monsterMaxHP: 0,
  score: 0,
  combo: 0,
  maxCombo: 0,
  totalCorrect: 0,
  totalAnswered: 0,
  currentProblem: null,
  floorConfig: null,
  mistakeLog: [],
  droppedItems: [],
  isAnswering: false,
  isAnimating: false,
  startTime: 0
};

// --- XP/スコア計算 ---

function getComboMultiplier(combo) {
  if (combo >= 20) return 5;
  if (combo >= 15) return 4;
  if (combo >= 10) return 3;
  if (combo >= 5)  return 2;
  return 1;
}

// --- DOM要素キャッシュ ---

var dom = {};

function cacheDom() {
  dom.titleScreen   = document.getElementById('title-screen');
  dom.battleScreen  = document.getElementById('battle-screen');
  dom.resultScreen  = document.getElementById('result-screen');
  dom.floorNumber   = document.getElementById('floor-number');
  dom.score         = document.getElementById('score');
  dom.playerHPBar   = document.getElementById('player-hp-bar');
  dom.playerHPText  = document.getElementById('player-hp-text');
  dom.monsterHPBar  = document.getElementById('monster-hp-bar');
  dom.monsterHPText = document.getElementById('monster-hp-text');
  dom.monsterName   = document.getElementById('monster-name');
  dom.comboDisplay  = document.getElementById('combo-display');
  dom.comboCount    = document.getElementById('combo-count');
  dom.questionA     = document.getElementById('question-a');
  dom.questionB     = document.getElementById('question-b');
  dom.choiceBtns    = document.querySelectorAll('.choice-btn');
  dom.resultFloor     = document.getElementById('result-floor');
  dom.resultScore     = document.getElementById('result-score');
  dom.resultMaxCombo  = document.getElementById('result-max-combo');
  dom.resultAccuracy  = document.getElementById('result-accuracy');
  dom.resultTime      = document.getElementById('result-time');
  dom.resultNewRecord = document.getElementById('result-new-record');
  dom.resultRecordDiff = document.getElementById('result-record-diff');
  dom.resultItems     = document.getElementById('result-items');
  dom.resultItemsList = document.getElementById('result-items-list');
  dom.bestFloor       = document.getElementById('best-floor');
  dom.timerWrap       = document.getElementById('timer-wrap');
  dom.timerBar        = document.getElementById('timer-bar');
  dom.titleLevel      = document.getElementById('title-level');
}

// --- 画面切り替え ---

function showScreen(screenId) {
  dom.titleScreen.style.display  = 'none';
  dom.battleScreen.style.display = 'none';
  dom.resultScreen.style.display = 'none';

  var target = document.getElementById(screenId);
  target.style.display = 'flex';
  debugLog('画面きりかえ →', screenId);

  // タイトルに戻るたびデイリーボーナス判定（日またぎ対応）
  if (screenId === 'title-screen') {
    maybeShowDailyBonus();
  }
}

// --- DOM更新 ---

function updateFloorDisplay() {
  dom.floorNumber.textContent = gameState.floor;
}

function updateScoreDisplay() {
  dom.score.textContent = gameState.score.toLocaleString();
}

function updatePlayerHP() {
  var hp = Math.max(0, gameState.playerHP);
  var ratio = hp / PLAYER_MAX_HP * 100;
  dom.playerHPBar.style.width = ratio + '%';
  dom.playerHPText.textContent = hp + '/' + PLAYER_MAX_HP;
}

function updateMonsterHP() {
  var hp = Math.max(0, gameState.monsterHP);
  var ratio = hp / gameState.monsterMaxHP * 100;
  dom.monsterHPBar.style.width = ratio + '%';
  dom.monsterHPText.textContent = hp + '/' + gameState.monsterMaxHP;
}

function updateMonsterName() {
  dom.monsterName.textContent = gameState.floorConfig.monsterName;
}

// --- ボス色 ---

function getBossColor(floor) {
  if (floor <= 5)  return '#48BB78'; // みどり
  if (floor <= 10) return '#4299E1'; // あお
  if (floor <= 15) return '#9F7AEA'; // むらさき
  if (floor <= 20) return '#E53E3E'; // あか
  if (floor <= 25) return '#1A202C'; // くろ
  return '#D69E2E';                  // きん
}

function updateMonsterAppearance() {
  var monsterBody = document.querySelector('.monster-body');
  if (!monsterBody) return;

  if (gameState.floorConfig && gameState.floorConfig.isBoss) {
    var color = getBossColor(gameState.floor);
    monsterBody.style.background = color;
    monsterBody.style.boxShadow = '0 8px 24px ' + color + '80';
    monsterBody.classList.add('boss-body');
  } else {
    monsterBody.style.background = '#F56565';
    monsterBody.style.boxShadow = '0 6px 16px rgba(245, 101, 101, 0.4)';
    monsterBody.classList.remove('boss-body');
  }
}

// --- タイマー ---

var timerState = {
  endTime: 0,
  duration: 0,
  animFrame: 0,
  active: false
};

function startTimer(seconds) {
  if (!seconds) return;
  timerState.duration = seconds;
  timerState.endTime = Date.now() + seconds * 1000;
  timerState.active = true;
  dom.timerWrap.style.display = 'block';
  dom.timerBar.style.width = '100%';
  dom.timerBar.className = 'timer-bar timer-safe';
  updateTimer();
}

function stopTimer() {
  timerState.active = false;
  if (timerState.animFrame) {
    cancelAnimationFrame(timerState.animFrame);
    timerState.animFrame = 0;
  }
  dom.timerWrap.style.display = 'none';
}

function updateTimer() {
  if (!timerState.active) return;

  var remaining = (timerState.endTime - Date.now()) / 1000;

  if (remaining <= 0) {
    timerState.active = false;
    dom.timerBar.style.width = '0%';
    dom.timerWrap.style.display = 'none';
    handleTimeout();
    return;
  }

  var ratio = remaining / timerState.duration * 100;
  dom.timerBar.style.width = ratio + '%';

  // 色変更
  if (remaining <= 3) {
    dom.timerBar.className = 'timer-bar timer-danger';
  } else if (remaining <= timerState.duration * 0.5) {
    dom.timerBar.className = 'timer-bar timer-warning';
  } else {
    dom.timerBar.className = 'timer-bar timer-safe';
  }

  timerState.animFrame = requestAnimationFrame(updateTimer);
}

function handleTimeout() {
  if (!gameState.isAnswering || gameState.isAnimating) return;
  gameState.isAnswering = false;
  gameState.isAnimating = true;

  gameState.totalAnswered++;
  gameState.combo = 0;
  gameState.playerHP--;

  var p = gameState.currentProblem;

  // セッション内の間違いログ
  var found = false;
  for (var i = 0; i < gameState.mistakeLog.length; i++) {
    if (gameState.mistakeLog[i].a === p.a && gameState.mistakeLog[i].b === p.b) {
      gameState.mistakeLog[i].count++;
      found = true;
      break;
    }
  }
  if (!found) {
    gameState.mistakeLog.push({ a: p.a, b: p.b, wrongAnswer: -1, count: 1 });
  }

  // localStorage にも保存
  addMistake(p.a, p.b, -1);

  // 正解ボタンを特定してハイライト
  var correct = p.answer;
  var correctBtn = null;
  for (var j = 0; j < dom.choiceBtns.length; j++) {
    if (parseInt(dom.choiceBtns[j].textContent) === correct) {
      correctBtn = dom.choiceBtns[j];
      break;
    }
  }

  updatePlayerHP();
  animateComboDisplay(0);

  playWrongSound();
  showFloatText('じかんぎれ！', 'float-oshii', 800);

  disableChoices();
  if (correctBtn) {
    correctBtn.classList.add('correct');
    correctBtn.classList.add('blink-correct');
  }

  setTimeout(function () {
    if (correctBtn) {
      correctBtn.classList.remove('blink-correct');
    }
    if (gameState.playerHP <= 0) {
      onGameOver();
    } else {
      nextProblem();
    }
  }, 1200);
}

// --- 問題をDOMに反映 ---

function showProblem() {
  var p = gameState.currentProblem;
  dom.questionA.textContent = p.a;
  dom.questionB.textContent = p.b;

  for (var i = 0; i < dom.choiceBtns.length; i++) {
    dom.choiceBtns[i].textContent = p.choices[i];
    dom.choiceBtns[i].disabled = false;
    dom.choiceBtns[i].className = 'choice-btn';
  }

  gameState.isAnswering = true;
  gameState.isAnimating = false;

  // タイマー開始（16F以降）
  if (gameState.floorConfig && gameState.floorConfig.timeLimit) {
    startTimer(gameState.floorConfig.timeLimit);
  }

  debugLog('もんだい:', p.a, '+', p.b, '=', p.answer, '(せんたくし:', p.choices.join(', ') + ')');
}

// --- 回答処理 ---

function handleAnswer(selectedValue) {
  if (!gameState.isAnswering || gameState.isAnimating) return;
  gameState.isAnswering = false;
  gameState.isAnimating = true;
  stopTimer();

  var correct = gameState.currentProblem.answer;
  var isCorrect = selectedValue === correct;

  gameState.totalAnswered++;

  // 押されたボタンと正解ボタンを特定
  var clickedBtn = null;
  var correctBtn = null;
  for (var i = 0; i < dom.choiceBtns.length; i++) {
    var btnValue = parseInt(dom.choiceBtns[i].textContent);
    if (btnValue === selectedValue) clickedBtn = dom.choiceBtns[i];
    if (btnValue === correct) correctBtn = dom.choiceBtns[i];
  }

  if (isCorrect) {
    playCorrectSound();
    onCorrectAnswer(clickedBtn);
  } else {
    playWrongSound();
    onWrongAnswer(selectedValue, clickedBtn, correctBtn);
  }
}

function onCorrectAnswer(clickedBtn) {
  gameState.totalCorrect++;
  gameState.combo++;
  if (gameState.combo > gameState.maxCombo) {
    gameState.maxCombo = gameState.combo;
  }

  // コンボ演出音（5の倍数で特別な音）
  if (gameState.combo >= 5 && gameState.combo % 5 === 0) {
    playComboSound(gameState.combo);
  }

  // スコア加算
  var points = 10 * getComboMultiplier(gameState.combo);
  gameState.score += points;
  debugLog('せいかい！ +' + points + 'てん (コンボ x' + gameState.combo + ')');

  // モンスターHP減少
  gameState.monsterHP--;
  updateScoreDisplay();
  updateMonsterHP();
  animateComboDisplay(gameState.combo);

  // 画面フラッシュ
  dom.battleScreen.classList.add('correct-flash');
  setTimeout(function () {
    dom.battleScreen.classList.remove('correct-flash');
  }, 150);

  // アニメーション → 次のステップへ
  playCorrectAnimation(clickedBtn, function () {
    if (gameState.monsterHP <= 0) {
      onMonsterDefeated();
    } else {
      nextProblem();
    }
  });
}

function onWrongAnswer(selectedValue, clickedBtn, correctBtn) {
  gameState.combo = 0;
  gameState.playerHP--;
  debugLog('おしい！ こたえは', gameState.currentProblem.answer, '(えらんだ:', selectedValue + ')');

  // 間違いログに記録（セッション内）
  var p = gameState.currentProblem;
  var found = false;
  for (var i = 0; i < gameState.mistakeLog.length; i++) {
    if (gameState.mistakeLog[i].a === p.a && gameState.mistakeLog[i].b === p.b) {
      gameState.mistakeLog[i].count++;
      found = true;
      break;
    }
  }
  if (!found) {
    gameState.mistakeLog.push({ a: p.a, b: p.b, wrongAnswer: selectedValue, count: 1 });
  }

  // localStorage にも保存
  addMistake(p.a, p.b, selectedValue);

  updatePlayerHP();
  animateComboDisplay(gameState.combo);

  // アニメーション → 次のステップへ
  playWrongAnimation(clickedBtn, correctBtn, function () {
    if (gameState.playerHP <= 0) {
      onGameOver();
    } else {
      nextProblem();
    }
  });
}

// --- 次の問題 ---

function nextProblem() {
  gameState.currentProblem = generateProblem(gameState.floor, gameState.mistakeLog);
  showProblem();
}

// --- モンスター撃破 ---

function onMonsterDefeated() {
  playDefeatSound();

  var isBoss = gameState.floorConfig.isBoss;

  // ボス撃破ボーナス（XP 3ばい）
  if (isBoss) {
    gameState.score += 300;
    debugLog('ボスげきは！ +300ボーナス（3ばい）');
  }
  debugLog('げきは！ → つぎのフロアへ');

  updateScoreDisplay();

  // --- ボス撃破時アイテムドロップ（30%） ---
  var droppedItem = null;
  var lootLine = document.getElementById('loot-line');
  var lootText = document.getElementById('loot-text');

  if (isBoss && Math.random() < 0.3) {
    droppedItem = generateItem();
    gameState.droppedItems.push(droppedItem);
    // localStorage に即保存
    var allItems = loadItems();
    allItems.push(droppedItem);
    saveItems(allItems);
    debugLog('アイテムドロップ:', formatItemDisplay(droppedItem));
  }

  // 撃破オーバーレイにアイテム表示をセット
  if (droppedItem) {
    lootText.textContent = formatItemDisplay(droppedItem);
    lootLine.style.display = 'flex';
  } else {
    lootLine.style.display = 'none';
  }

  // 撃破演出 → 次のフロア（通常: 自動、ボス: タップ）
  playDefeatAnimation(isBoss, function () {
    // アイテム表示をリセット
    lootLine.style.display = 'none';

    gameState.floor++;

    // ボス登場チェック
    if (gameState.floor % 5 === 0) {
      playBossAppearSound();
      playBossAppearAnimation(function () {
        startBattle();
      });
    } else {
      startBattle();
    }
  });
}

// --- ゲームオーバー ---

function onGameOver() {
  stopTimer();
  debugLog('ゲームオーバー — ' + gameState.floor + 'F, スコア:', gameState.score);

  // プレイ時間算出
  var elapsed = Math.floor((Date.now() - gameState.startTime) / 1000);
  var minutes = Math.floor(elapsed / 60);
  var seconds = elapsed % 60;

  var accuracy = gameState.totalAnswered > 0
    ? Math.round(gameState.totalCorrect / gameState.totalAnswered * 100)
    : 0;

  // --- localStorage にセーブ ---
  var user = loadUserData();
  var prevBestFloor = user.bestFloor;
  var isNewRecord = false;
  if (gameState.floor > user.bestFloor) {
    user.bestFloor = gameState.floor;
    isNewRecord = true;
  }
  if (gameState.score > user.bestScore) {
    user.bestScore = gameState.score;
  }
  user.totalPlayCount++;
  user.totalCorrect += gameState.totalCorrect;
  user.totalAnswered += gameState.totalAnswered;
  saveUserData(user);

  // XP付与
  var xpGained = gameState.score;
  var xpResult = addXP(xpGained);
  if (xpResult.leveledUp) {
    playLevelUpSound();
  }

  // セッション履歴を保存
  saveSessionHistory({
    maxFloor: gameState.floor,
    score: gameState.score,
    maxCombo: gameState.maxCombo,
    correctRate: accuracy / 100,
    playedAt: new Date().toISOString(),
    duration: elapsed
  });

  // --- セッション中にドロップしたアイテム（onMonsterDefeated で蓄積済み） ---
  var droppedItems = gameState.droppedItems;

  // --- リザルト画面を更新 ---
  dom.resultFloor.textContent = gameState.floor;
  dom.resultScore.textContent = gameState.score.toLocaleString();
  dom.resultMaxCombo.textContent = gameState.maxCombo;
  dom.resultAccuracy.textContent = accuracy;
  dom.resultTime.textContent = minutes + 'ふん' + seconds + 'びょう';

  // ベスト更新
  if (isNewRecord) {
    dom.bestFloor.textContent = user.bestFloor;
    dom.resultNewRecord.style.display = 'block';
    var diff = gameState.floor - prevBestFloor;
    dom.resultRecordDiff.textContent = '+' + diff + 'F!';
    debugLog('しんきろく！ ▲', gameState.floor, 'F (+' + diff + ')');
  } else {
    dom.resultNewRecord.style.display = 'none';
  }

  // 獲得アイテム表示
  if (droppedItems.length > 0) {
    dom.resultItems.style.display = 'block';
    dom.resultItemsList.innerHTML = '';
    for (var di = 0; di < droppedItems.length; di++) {
      var item = droppedItems[di];
      var row = document.createElement('div');
      row.className = 'result-item-row';
      row.innerHTML =
        '<span class="result-item-stars rarity-' + item.rarity + '">' + (RARITY_STARS[item.rarity] || '★') + '</span>' +
        '<span class="result-item-name">' + item.name + '</span>';
      dom.resultItemsList.appendChild(row);
    }
  } else {
    dom.resultItems.style.display = 'none';
  }

  // ゲームオーバー演出 → レベルアップ演出 → リザルト画面
  playGameOverAnimation(function () {
    if (xpResult.leveledUp) {
      playLevelUpAnimation(xpResult.newLevel, function () {
        showScreen('result-screen');
      });
    } else {
      showScreen('result-screen');
    }
  });
}

// --- アイテム表示 ---

var RARITY_STARS = {
  common:    '★',
  rare:      '★★',
  epic:      '★★★',
  legendary: '★★★★'
};

function formatItemDisplay(item) {
  var stars = RARITY_STARS[item.rarity] || '★';
  return stars + ' ' + item.name;
}

// --- ずかん（アイテムコレクション） ---

var RARITY_ORDER = ['legendary', 'epic', 'rare', 'common'];
var RARITY_SECTION_LABELS = {
  legendary: '★★★★ でんせつ',
  epic:      '★★★ すごくレア',
  rare:      '★★ レア',
  common:    '★ ふつう'
};

function renderCollection() {
  var body = document.getElementById('collection-body');
  var items = loadItems();

  body.innerHTML = '';

  if (items.length === 0) {
    body.innerHTML = '<div class="collection-empty">まだ ないよ<br>あそぶと ふえるよ！</div>';
    return;
  }

  // 同名アイテムを集計: { "rare:ほしのつえ": { name, rarity, count } }
  var grouped = {};
  for (var i = 0; i < items.length; i++) {
    var key = items[i].rarity + ':' + items[i].name;
    if (grouped[key]) {
      grouped[key].count++;
    } else {
      grouped[key] = { name: items[i].name, rarity: items[i].rarity, count: 1 };
    }
  }

  // レア度ごとにセクション生成
  for (var r = 0; r < RARITY_ORDER.length; r++) {
    var rarity = RARITY_ORDER[r];
    var entries = [];
    for (var k in grouped) {
      if (grouped[k].rarity === rarity) entries.push(grouped[k]);
    }
    if (entries.length === 0) continue;

    // 名前順にソート
    entries.sort(function (a, b) { return a.name < b.name ? -1 : 1; });

    var section = document.createElement('div');
    section.className = 'collection-section';

    var label = document.createElement('div');
    label.className = 'collection-section-label rarity-' + rarity;
    label.textContent = RARITY_SECTION_LABELS[rarity];
    section.appendChild(label);

    for (var j = 0; j < entries.length; j++) {
      var row = document.createElement('div');
      row.className = 'collection-item';

      var nameSpan = document.createElement('span');
      nameSpan.className = 'collection-item-name';
      nameSpan.textContent = (RARITY_STARS[rarity] || '★') + ' ' + entries[j].name;
      row.appendChild(nameSpan);

      if (entries[j].count > 1) {
        var countSpan = document.createElement('span');
        countSpan.className = 'collection-item-count';
        countSpan.textContent = '×' + entries[j].count;
        row.appendChild(countSpan);
      }

      section.appendChild(row);
    }

    body.appendChild(section);
  }
}

function openCollection() {
  renderCollection();
  document.getElementById('collection-overlay').style.display = 'flex';
}

function closeCollection() {
  document.getElementById('collection-overlay').style.display = 'none';
}

// --- アイテム生成 ---

var ITEM_POOL = [
  // common (10)
  { name: 'ほのおのけん', rarity: 'common' },
  { name: 'みずのたて', rarity: 'common' },
  { name: 'かぜのマント', rarity: 'common' },
  { name: 'ひかりのゆびわ', rarity: 'common' },
  { name: 'もりのおまもり', rarity: 'common' },
  { name: 'てつのヘルム', rarity: 'common' },
  { name: 'いしのオノ', rarity: 'common' },
  { name: 'かわのブーツ', rarity: 'common' },
  { name: 'きのこのかさ', rarity: 'common' },
  { name: 'ホネのゆみ', rarity: 'common' },
  // rare (5)
  { name: 'ほしのつえ', rarity: 'rare' },
  { name: 'りゅうのウロコ', rarity: 'rare' },
  { name: 'こおりのやいば', rarity: 'rare' },
  { name: 'つきのペンダント', rarity: 'rare' },
  { name: 'はがねのよろい', rarity: 'rare' },
  // epic (3)
  { name: 'まほうのオーブ', rarity: 'epic' },
  { name: 'しんぴのローブ', rarity: 'epic' },
  { name: 'ひりゅうのつばさ', rarity: 'epic' },
  // legendary (2)
  { name: 'でんせつのかんむり', rarity: 'legendary' },
  { name: 'せかいじゅのしずく', rarity: 'legendary' }
];

function generateItem() {
  var roll = Math.random() * 100;
  var rarity;
  if (roll < 60)      rarity = 'common';
  else if (roll < 85)  rarity = 'rare';
  else if (roll < 95)  rarity = 'epic';
  else                 rarity = 'legendary';

  // レア度に合うアイテムをランダムに
  var candidates = [];
  for (var i = 0; i < ITEM_POOL.length; i++) {
    if (ITEM_POOL[i].rarity === rarity) candidates.push(ITEM_POOL[i]);
  }
  var picked = candidates[randInt(0, candidates.length - 1)];

  return {
    id: 'item_' + Date.now() + '_' + randInt(0, 999),
    name: picked.name,
    rarity: picked.rarity,
    obtainedAt: new Date().toISOString()
  };
}

// --- バトル開始（フロアごと） ---

function startBattle() {
  gameState.floorConfig = getFloorConfig(gameState.floor);
  gameState.monsterHP = gameState.floorConfig.monsterHP;
  gameState.monsterMaxHP = gameState.floorConfig.monsterHP;

  debugLog('--- ' + gameState.floor + 'F ---', gameState.floorConfig);

  updateFloorDisplay();
  updateMonsterHP();
  updateMonsterName();
  updateMonsterAppearance();

  gameState.currentProblem = generateProblem(gameState.floor, gameState.mistakeLog);
  showProblem();
}

// --- ゲーム開始 ---

function startGame() {
  gameState.floor = 1;
  gameState.playerHP = PLAYER_MAX_HP;
  gameState.score = 0;
  gameState.combo = 0;
  gameState.maxCombo = 0;
  gameState.totalCorrect = 0;
  gameState.totalAnswered = 0;
  gameState.mistakeLog = [];
  gameState.droppedItems = [];
  gameState.isAnswering = false;
  gameState.isAnimating = false;
  gameState.startTime = Date.now();

  stopTimer();
  updatePlayerHP();
  updateScoreDisplay();
  animateComboDisplay(0);

  debugLog('========== ゲームかいし ==========');
  showScreen('battle-screen');
  startBattle();
}

// ========================================
// ストリーク報酬
// ========================================

function generateStreakRewardItem(milestone) {
  var candidates = [];
  for (var i = 0; i < ITEM_POOL.length; i++) {
    if (milestone >= 30) {
      if (ITEM_POOL[i].rarity === 'legendary') candidates.push(ITEM_POOL[i]);
    } else if (milestone >= 7) {
      if (ITEM_POOL[i].rarity === 'epic' || ITEM_POOL[i].rarity === 'legendary') candidates.push(ITEM_POOL[i]);
    }
  }
  var picked = candidates[randInt(0, candidates.length - 1)];
  return {
    id: 'streak_' + milestone + '_' + Date.now(),
    name: picked.name,
    rarity: picked.rarity,
    obtainedAt: new Date().toISOString()
  };
}

function maybeShowStreakReward() {
  var user = loadUserData();
  var milestone = getUnclaimedStreakReward(user.streakDays);
  if (!milestone) return;

  // アイテム生成・保存
  var item = generateStreakRewardItem(milestone);
  var allItems = loadItems();
  allItems.push(item);
  saveItems(allItems);
  markStreakRewardClaimed(milestone);
  debugLog('ストリーク報酬:', milestone + 'にち →', formatItemDisplay(item));

  // DOM反映
  document.getElementById('streak-reward-title').textContent = milestone + 'にち れんぞくたっせい！';
  document.getElementById('streak-reward-days').textContent = '🔥 ' + milestone + 'にち';

  var itemEl = document.getElementById('streak-reward-item');
  itemEl.textContent = formatItemDisplay(item);
  itemEl.className = 'streak-reward-item rarity-' + item.rarity;

  document.getElementById('streak-reward-overlay').style.display = 'flex';
}

function closeStreakReward() {
  document.getElementById('streak-reward-overlay').style.display = 'none';
}

// ========================================
// なまえ入力（初回起動のみ）
// ========================================

function isValidName(name) {
  if (name.length < 3 || name.length > 8) return false;
  // ひらがな・カタカナ・長音符のみ許可
  return /^[\u3040-\u309F\u30A0-\u30FF\u30FC]+$/.test(name);
}

function maybeShowNameInput() {
  var user = loadUserData();
  // 初回起動判定: totalPlayCount === 0 かつ名前がデフォルト
  if (user.totalPlayCount > 0 || user.playerName !== 'カズ') return;

  var overlay = document.getElementById('name-overlay');
  var input = document.getElementById('name-input');
  var hint = document.getElementById('name-hint');
  var okBtn = document.getElementById('name-ok');
  var skipBtn = document.getElementById('name-skip');

  overlay.style.display = 'flex';
  input.value = '';
  okBtn.disabled = true;

  input.addEventListener('input', function () {
    var val = input.value;
    if (val.length === 0) {
      okBtn.disabled = true;
      hint.textContent = '3〜8もじ（ひらがな・カタカナ）';
      hint.classList.remove('name-hint-error');
    } else if (isValidName(val)) {
      okBtn.disabled = false;
      hint.textContent = '3〜8もじ（ひらがな・カタカナ）';
      hint.classList.remove('name-hint-error');
    } else {
      okBtn.disabled = true;
      if (val.length < 3) {
        hint.textContent = 'あと' + (3 - val.length) + 'もじ いれてね';
      } else {
        hint.textContent = 'ひらがな・カタカナで いれてね';
      }
      hint.classList.add('name-hint-error');
    }
  });

  function confirmName() {
    var val = input.value;
    if (isValidName(val)) {
      var u = loadUserData();
      u.playerName = val;
      saveUserData(u);
      document.getElementById('title-player-name').textContent = val;
    }
    overlay.style.display = 'none';
  }

  okBtn.addEventListener('click', function () {
    playTapSound();
    confirmName();
  });

  skipBtn.addEventListener('click', function () {
    playTapSound();
    overlay.style.display = 'none';
  });
}

// ========================================
// デイリーボーナス
// ========================================

function maybeShowDailyBonus() {
  var today = getToday();
  if (getDailyBonusDate() === today) return;

  // 付与（1回だけ）
  setDailyBonusDate(today);
  addXP(20);
  debugLog('デイリーボーナス +20 XP');

  // Lv 表示を即反映
  var user = loadUserData();
  dom.titleLevel.textContent = 'Lv.' + user.level;

  // オーバーレイ表示
  document.getElementById('daily-bonus-overlay').style.display = 'flex';
}

function closeDailyBonus() {
  document.getElementById('daily-bonus-overlay').style.display = 'none';
}

// ========================================
// イベントリスナー
// ========================================

// --- タイトル画面にセーブデータを反映 ---

function applyUserDataToTitle() {
  var user = loadUserData();

  // さいこうきろく
  dom.bestFloor.textContent = user.bestFloor;

  // なまえ表示
  var nameEl = document.getElementById('title-player-name');
  if (nameEl) nameEl.textContent = user.playerName;

  // レベル表示
  dom.titleLevel.textContent = 'Lv.' + user.level;

  // ストリーク更新・反映
  user = updateStreak();
  document.getElementById('streak-count').textContent = user.streakDays;

  // ストリーク報酬判定
  maybeShowStreakReward();

  // 音声設定の復元
  soundEnabled = user.soundEnabled;
  document.getElementById('sound-toggle').textContent = soundEnabled ? '🔊' : '🔇';
}

document.addEventListener('DOMContentLoaded', function () {
  cacheDom();
  applyUserDataToTitle();
  maybeShowNameInput();
  maybeShowDailyBonus();

  // デイリーボーナス — OKボタン
  document.getElementById('daily-bonus-ok').addEventListener('click', function () {
    playTapSound();
    closeDailyBonus();
  });

  // デイリーボーナス — 背景タップで閉じる
  document.getElementById('daily-bonus-overlay').addEventListener('click', function (e) {
    if (e.target === this) {
      closeDailyBonus();
    }
  });

  // ストリーク報酬 — OKボタン
  document.getElementById('streak-reward-ok').addEventListener('click', function () {
    playTapSound();
    closeStreakReward();
  });

  // ストリーク報酬 — 背景タップで閉じる
  document.getElementById('streak-reward-overlay').addEventListener('click', function (e) {
    if (e.target === this) {
      closeStreakReward();
    }
  });

  // スタートボタン
  document.getElementById('start-btn').addEventListener('click', function () {
    initAudio();
    playTapSound();
    startGame();
  });

  // 選択肢ボタン（4つ）
  for (var i = 0; i < dom.choiceBtns.length; i++) {
    (function (btn) {
      btn.addEventListener('click', function () {
        handleAnswer(parseInt(btn.textContent));
      });
    })(dom.choiceBtns[i]);
  }

  // リザルト — もういちど
  document.getElementById('retry-btn').addEventListener('click', function () {
    playTapSound();
    startGame();
  });

  // リザルト — おわる
  document.getElementById('quit-btn').addEventListener('click', function () {
    playTapSound();
    applyUserDataToTitle();
    showScreen('title-screen');
  });

  // ずかん — 開く
  document.getElementById('collection-btn').addEventListener('click', function () {
    playTapSound();
    openCollection();
  });

  // ずかん — ×ボタンで閉じる
  document.getElementById('collection-close').addEventListener('click', function () {
    playTapSound();
    closeCollection();
  });

  // ずかん — 背景（カード外）タップで閉じる
  document.getElementById('collection-overlay').addEventListener('click', function (e) {
    if (e.target === this) {
      closeCollection();
    }
  });

  // 音声トグル
  document.getElementById('sound-toggle').addEventListener('click', function () {
    initAudio();
    var enabled = toggleSound();
    this.textContent = enabled ? '🔊' : '🔇';
    // localStorage に保存
    var user = loadUserData();
    user.soundEnabled = enabled;
    saveUserData(user);
  });
});

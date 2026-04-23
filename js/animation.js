// ========================================
// カズモン — アニメーション制御
// ========================================

// --- ヘルパー ---

function addClass(el, cls) { el.classList.add(cls); }
function removeClass(el, cls) { el.classList.remove(cls); }

function disableChoices() {
  var btns = document.querySelectorAll('.choice-btn');
  for (var i = 0; i < btns.length; i++) {
    btns[i].disabled = true;
    btns[i].classList.add('disabled');
  }
}

function enableChoices() {
  var btns = document.querySelectorAll('.choice-btn');
  for (var i = 0; i < btns.length; i++) {
    btns[i].disabled = false;
    btns[i].classList.remove('disabled');
  }
}

// --- フローティングテキスト表示 ---

function showFloatText(text, className, duration) {
  var el = document.getElementById('float-text');
  el.textContent = text;
  el.className = 'float-text ' + (className || '');
  el.style.display = 'block';
  setTimeout(function () {
    el.style.display = 'none';
  }, duration || 600);
}

// --- ダメージ数字をモンスター上に表示 ---

function showDamageNumber() {
  var sprite = document.querySelector('.monster-sprite');
  var dmg = document.createElement('div');
  dmg.className = 'damage-number';
  dmg.textContent = '-1';
  sprite.appendChild(dmg);
  setTimeout(function () {
    if (dmg.parentNode) dmg.parentNode.removeChild(dmg);
  }, 700);
}

// ========================================
// 1. playCorrectAnimation
// ========================================

function playCorrectAnimation(buttonEl, callback) {
  var player = document.querySelector('.player-sprite');
  var monster = document.querySelector('.monster-sprite');

  disableChoices();

  // 正解ボタン: 緑 + 拡大 + ✓マーク
  addClass(buttonEl, 'correct');
  addClass(buttonEl, 'btn-pop');
  buttonEl.textContent = '✓ ' + buttonEl.textContent;

  // プレイヤー: ジャンプ攻撃
  setTimeout(function () {
    addClass(player, 'anim-jump-attack');
  }, 150);

  // モンスター: shake + ダメージ数字
  setTimeout(function () {
    addClass(monster, 'anim-shake');
    showDamageNumber();
  }, 350);

  // クリーンアップ → callback
  setTimeout(function () {
    removeClass(buttonEl, 'btn-pop');
    removeClass(player, 'anim-jump-attack');
    removeClass(monster, 'anim-shake');
    if (callback) callback();
  }, 800);
}

// ========================================
// 2. playWrongAnimation
// ========================================

function playWrongAnimation(wrongButtonEl, correctButtonEl, callback) {
  var monster = document.querySelector('.monster-sprite');

  disableChoices();

  // 選んだボタン: 赤 + ✗マーク
  addClass(wrongButtonEl, 'wrong');
  addClass(wrongButtonEl, 'btn-pop');
  wrongButtonEl.textContent = '✗ ' + wrongButtonEl.textContent;

  // 正解ボタン: 緑で点滅 + ✓マーク
  setTimeout(function () {
    addClass(correctButtonEl, 'correct');
    addClass(correctButtonEl, 'blink-correct');
    correctButtonEl.textContent = '✓ ' + correctButtonEl.textContent;
  }, 300);

  // モンスター: 攻撃モーション
  setTimeout(function () {
    addClass(monster, 'anim-monster-attack');
  }, 200);

  // 「おしい！」表示
  setTimeout(function () {
    showFloatText('おしい！', 'float-oshii', 600);
  }, 300);

  // クリーンアップ → callback
  setTimeout(function () {
    removeClass(wrongButtonEl, 'btn-pop');
    removeClass(correctButtonEl, 'blink-correct');
    removeClass(monster, 'anim-monster-attack');
    if (callback) callback();
  }, 1200);
}

// ========================================
// 3. animateComboDisplay
// ========================================

function animateComboDisplay(combo) {
  var display = document.getElementById('combo-display');
  if (!display) return;

  var countEl = document.getElementById('combo-count');
  var labelEl = document.getElementById('combo-label');
  if (!countEl || !labelEl) return;

  // 非表示
  if (combo < 2) {
    display.style.display = 'none';
    display.className = 'combo-display';
    return;
  }

  // 数値・ラベル更新
  countEl.textContent = combo;

  display.className = 'combo-display';
  var label = 'COMBO!';
  if (combo >= 20) {
    label = 'LEGENDARY!';
    addClass(display, 'combo-legendary');
  } else if (combo >= 15) {
    label = 'AMAZING!';
    addClass(display, 'combo-amazing');
  } else if (combo >= 10) {
    label = 'SUPER!';
    addClass(display, 'combo-super');
  } else if (combo >= 5) {
    label = 'NICE!';
    addClass(display, 'combo-nice');
  }
  labelEl.textContent = label;

  // 表示
  display.style.display = 'block';

  // バウンスアニメ（5の倍数のとき）
  if (combo >= 5 && combo % 5 === 0) {
    addClass(display, 'combo-bounce');
    setTimeout(function () {
      removeClass(display, 'combo-bounce');
    }, 500);
  }
}

// ========================================
// 4. playDefeatAnimation
// ========================================

function playDefeatAnimation(isBoss, callback) {
  var monster = document.querySelector('.monster-sprite');
  var overlay = document.getElementById('defeat-overlay');
  var text = document.getElementById('defeat-text');
  var nextBtn = document.getElementById('next-floor-btn');
  var particles = document.getElementById('defeat-particles');
  var advanced = false;

  disableChoices();

  // モンスター消滅
  addClass(monster, 'anim-defeat-vanish');

  // パーティクル生成
  particles.innerHTML = '';
  for (var i = 0; i < 8; i++) {
    var p = document.createElement('div');
    p.className = 'particle particle-' + i;
    particles.appendChild(p);
  }

  // クリーンアップ＆次へ進む（1回だけ発火）
  function advance() {
    if (advanced) return;
    advanced = true;
    nextBtn.removeEventListener('click', advance);
    overlay.removeEventListener('click', advance);
    nextBtn.style.display = 'none';
    overlay.style.display = 'none';
    removeClass(text, 'anim-zoom-in');
    removeClass(monster, 'anim-defeat-vanish');
    particles.innerHTML = '';
    if (callback) callback();
  }

  // オーバーレイ表示（400ms後）
  setTimeout(function () {
    overlay.style.display = 'flex';
    addClass(text, 'anim-zoom-in');
  }, 400);

  if (isBoss) {
    // ボス撃破: 1300ms後にボタン表示＋オーバーレイどこでもタップで進む
    setTimeout(function () {
      if (advanced) return;
      nextBtn.style.display = 'block';
      overlay.addEventListener('click', advance);
    }, 1700);
  } else {
    // 通常撃破: オーバーレイ表示から約800ms後に自動進行
    setTimeout(function () {
      advance();
    }, 1200);
  }
}

// ========================================
// 5. playBossAppearAnimation
// ========================================

function playBossAppearAnimation(callback) {
  var overlay = document.getElementById('boss-overlay');
  var text = document.getElementById('boss-appear-text');
  var battleScreen = document.getElementById('battle-screen');

  // 赤フラッシュ + シェイク
  overlay.style.display = 'flex';
  addClass(overlay, 'boss-flash');
  addClass(battleScreen, 'anim-screen-shake');
  addClass(text, 'anim-zoom-in');

  setTimeout(function () {
    removeClass(battleScreen, 'anim-screen-shake');
    removeClass(overlay, 'boss-flash');
  }, 800);

  // 1.5秒後に閉じて callback
  setTimeout(function () {
    overlay.style.display = 'none';
    removeClass(text, 'anim-zoom-in');
    if (callback) callback();
  }, 1500);
}

// ========================================
// 6. playGameOverAnimation
// ========================================

function playGameOverAnimation(callback) {
  var overlay = document.getElementById('gameover-overlay');
  var text = document.getElementById('gameover-text');
  var player = document.querySelector('.player-sprite');

  disableChoices();

  // 暗転
  overlay.style.display = 'flex';
  addClass(overlay, 'gameover-fade-in');

  // テキストフェードイン
  setTimeout(function () {
    addClass(text, 'anim-fade-in');
  }, 400);

  // プレイヤー揺れ（手を振る感じ）
  addClass(player, 'anim-wave');

  // 2秒後に callback
  setTimeout(function () {
    overlay.style.display = 'none';
    removeClass(overlay, 'gameover-fade-in');
    removeClass(text, 'anim-fade-in');
    removeClass(player, 'anim-wave');
    if (callback) callback();
  }, 2000);
}

// ========================================
// 7. playLevelUpAnimation
// ========================================

function playLevelUpAnimation(level, callback) {
  var overlay = document.getElementById('levelup-overlay');
  var text = document.getElementById('levelup-text');

  text.textContent = 'レベルアップ！ Lv.' + level;
  overlay.style.display = 'flex';
  addClass(text, 'anim-levelup');

  // 1.5秒後に閉じて callback
  setTimeout(function () {
    overlay.style.display = 'none';
    removeClass(text, 'anim-levelup');
    if (callback) callback();
  }, 1500);
}

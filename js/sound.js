// ========================================
// カズモン — Web Audio API 音声生成
// ========================================

var audioCtx = null;
var soundEnabled = true;

function initAudio() {
  if (!audioCtx) {
    try {
      audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    } catch (e) {
      audioCtx = null;
    }
  }
  if (audioCtx && audioCtx.state === 'suspended') {
    audioCtx.resume();
  }
}

function isSoundEnabled() {
  return soundEnabled;
}

function toggleSound() {
  soundEnabled = !soundEnabled;
  return soundEnabled;
}

// --- ヘルパー: 音を鳴らす共通処理 ---

function playTone(freq, duration, type, volume, rampEnd) {
  if (!audioCtx || !soundEnabled) return;

  var osc = audioCtx.createOscillator();
  var gain = audioCtx.createGain();

  osc.type = type || 'sine';
  osc.frequency.setValueAtTime(freq, audioCtx.currentTime);
  if (rampEnd) {
    osc.frequency.linearRampToValueAtTime(rampEnd, audioCtx.currentTime + duration);
  }

  gain.gain.setValueAtTime(volume || 0.3, audioCtx.currentTime);
  gain.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + duration);

  osc.connect(gain);
  gain.connect(audioCtx.destination);

  osc.start(audioCtx.currentTime);
  osc.stop(audioCtx.currentTime + duration);
}

// --- 正解音: ピコン！（880Hz→1760Hz、0.1秒） ---

function playCorrectSound() {
  if (!audioCtx || !soundEnabled) return;

  // 音1: 高めのスイープ
  playTone(880, 0.1, 'sine', 0.25, 1760);
  // 音2: 少し遅れてきらり
  setTimeout(function () {
    playTone(1320, 0.08, 'sine', 0.15);
  }, 80);
}

// --- 不正解音: ブッ（200Hz、0.15秒） ---

function playWrongSound() {
  if (!audioCtx || !soundEnabled) return;

  playTone(200, 0.15, 'square', 0.2);
  setTimeout(function () {
    playTone(150, 0.12, 'square', 0.15);
  }, 60);
}

// --- コンボ音: コンボ数で音が高くなる ---

function playComboSound(comboCount) {
  if (!audioCtx || !soundEnabled) return;

  var baseFreq = 600;
  if (comboCount >= 20) baseFreq = 1200;
  else if (comboCount >= 15) baseFreq = 1050;
  else if (comboCount >= 10) baseFreq = 900;
  else if (comboCount >= 5)  baseFreq = 750;

  // 3連音でファンファーレ感
  playTone(baseFreq, 0.08, 'sine', 0.2);
  setTimeout(function () {
    playTone(baseFreq * 1.25, 0.08, 'sine', 0.2);
  }, 80);
  setTimeout(function () {
    playTone(baseFreq * 1.5, 0.12, 'sine', 0.25);
  }, 160);
}

// --- 撃破音: ドンッ→キラキラ ---

function playDefeatSound() {
  if (!audioCtx || !soundEnabled) return;

  // ドンッ（低音インパクト）
  playTone(120, 0.2, 'sine', 0.35);
  playTone(80, 0.25, 'triangle', 0.2);

  // キラキラ上昇音
  setTimeout(function () { playTone(880,  0.1, 'sine', 0.2); }, 200);
  setTimeout(function () { playTone(1100, 0.1, 'sine', 0.2); }, 300);
  setTimeout(function () { playTone(1320, 0.1, 'sine', 0.2); }, 400);
  setTimeout(function () { playTone(1760, 0.15, 'sine', 0.25); }, 500);
}

// --- ボス登場音: ドドドド… ---

function playBossAppearSound() {
  if (!audioCtx || !soundEnabled) return;

  // 地鳴り的な低音
  playTone(60, 0.3, 'sawtooth', 0.2);
  setTimeout(function () { playTone(55, 0.3, 'sawtooth', 0.25); }, 200);
  setTimeout(function () { playTone(50, 0.3, 'sawtooth', 0.3);  }, 400);
  // 衝撃音
  setTimeout(function () {
    playTone(80, 0.4, 'square', 0.3);
    playTone(40, 0.5, 'sine', 0.2);
  }, 600);
}

// --- レベルアップ音: ファンファーレ ---

function playLevelUpSound() {
  if (!audioCtx || !soundEnabled) return;

  var notes = [523, 659, 784, 1047]; // ド ミ ソ ド（高）
  for (var i = 0; i < notes.length; i++) {
    (function (freq, delay) {
      setTimeout(function () {
        playTone(freq, 0.15, 'sine', 0.2);
      }, delay);
    })(notes[i], i * 120);
  }
  // 最後にキラッ
  setTimeout(function () {
    playTone(1568, 0.25, 'sine', 0.15);
  }, 500);
}

// --- タップ音: 軽いクリック感 ---

function playTapSound() {
  if (!audioCtx || !soundEnabled) return;

  playTone(660, 0.04, 'sine', 0.1);
}

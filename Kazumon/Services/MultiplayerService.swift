import Foundation
import FirebaseAuth
import FirebaseDatabase

/// オンライン対戦のルーム管理・状態同期を担うService
@Observable
final class MultiplayerService {
    static let shared = MultiplayerService()

    // MARK: - State

    var roomCode: String = ""
    var isHost: Bool = false
    var status: RoomStatus = .idle
    var hostName: String = ""
    var guestName: String = ""
    var hostReady: Bool = false
    var guestReady: Bool = false
    var opponentScore: Int = 0
    var opponentCorrect: Int = 0
    var opponentCombo: Int = 0
    var opponentFinished: Bool = false
    var opponentDisconnected: Bool = false
    var opponentAttackCount: Int = 0  // 相手の攻撃回数（正解数で増加）
    var winner: String = ""  // "host", "guest", "draw"
    var errorMessage: String?

    enum RoomStatus: String {
        case idle, waiting, ready, playing, finished
    }

    // MARK: - Private

    private let db = Database.database(url: "https://kazumon-new-default-rtdb.asia-southeast1.firebasedatabase.app").reference()
    private var roomRef: DatabaseReference?
    private var handles: [DatabaseHandle] = []

    private var uid: String {
        Auth.auth().currentUser?.uid ?? ""
    }

    private init() {}

    // MARK: - ルーム作成

    func createRoom(playerName: String) {
        let code = generateCode()
        roomCode = code
        isHost = true
        status = .waiting
        hostName = playerName
        guestName = ""
        hostReady = false
        guestReady = false
        errorMessage = nil
        opponentDisconnected = false

        let roomData: [String: Any] = [
            "createdAt": ServerValue.timestamp(),
            "status": RoomStatus.waiting.rawValue,
            "hostId": uid,
            "hostName": playerName,
            "guestId": "",
            "guestName": "",
            "players": [
                "host": ["isReady": false, "score": 0, "correctCount": 0, "combo": 0, "finished": false],
                "guest": ["isReady": false, "score": 0, "correctCount": 0, "combo": 0, "finished": false]
            ],
            "winner": ""
        ]

        roomRef = db.child("rooms").child(code)
        roomRef?.setValue(roomData) { [weak self] error, _ in
            if let error {
                self?.errorMessage = error.localizedDescription
                self?.status = .idle
            }
        }

        observeRoom()
    }

    // MARK: - ルーム参加

    func joinRoom(code: String, playerName: String) {
        let ref = db.child("rooms").child(code)
        ref.observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let self else { return }
            guard snapshot.exists(),
                  let data = snapshot.value as? [String: Any],
                  let roomStatus = data["status"] as? String,
                  roomStatus == RoomStatus.waiting.rawValue else {
                self.errorMessage = NSLocalizedString("online_error_no_room", comment: "")
                return
            }

            let guestId = data["guestId"] as? String ?? ""
            if !guestId.isEmpty {
                self.errorMessage = NSLocalizedString("online_error_full", comment: "")
                return
            }

            self.roomCode = code
            self.isHost = false
            self.status = .waiting
            self.guestName = playerName
            self.hostName = data["hostName"] as? String ?? ""
            self.hostReady = false
            self.guestReady = false
            self.errorMessage = nil
            self.opponentDisconnected = false
            self.roomRef = ref

            let updates: [String: Any] = [
                "guestId": self.uid,
                "guestName": playerName
            ]
            ref.updateChildValues(updates)

            self.observeRoom()
        }
    }

    // MARK: - Ready

    func setReady() {
        let key = isHost ? "host" : "guest"
        roomRef?.child("players/\(key)/isReady").setValue(true)
    }

    // MARK: - バトル開始（ホストのみ）

    func startBattle() {
        guard isHost, hostReady, guestReady else { return }
        roomRef?.child("status").setValue(RoomStatus.playing.rawValue)
    }

    // MARK: - スコア更新

    func updateScore(score: Int, correctCount: Int, combo: Int, attackCount: Int = 0) {
        let key = isHost ? "host" : "guest"
        let updates: [String: Any] = [
            "score": score,
            "correctCount": correctCount,
            "combo": combo,
            "attackCount": attackCount
        ]
        roomRef?.child("players/\(key)").updateChildValues(updates)
    }

    // MARK: - 終了報告

    func reportFinished(score: Int, correctCount: Int, combo: Int) {
        let key = isHost ? "host" : "guest"
        let updates: [String: Any] = [
            "score": score,
            "correctCount": correctCount,
            "combo": combo,
            "finished": true
        ]
        roomRef?.child("players/\(key)").updateChildValues(updates)
    }

    // MARK: - 勝敗決定（ホストが書き込む）

    func determineWinner(hostScore: Int, hostCorrect: Int, hostCombo: Int,
                         guestScore: Int, guestCorrect: Int, guestCombo: Int) {
        let w: String
        if hostScore != guestScore {
            w = hostScore > guestScore ? "host" : "guest"
        } else if hostCorrect != guestCorrect {
            w = hostCorrect > guestCorrect ? "host" : "guest"
        } else if hostCombo != guestCombo {
            w = hostCombo > guestCombo ? "host" : "guest"
        } else {
            w = "draw"
        }
        roomRef?.updateChildValues(["winner": w, "status": RoomStatus.finished.rawValue])
    }

    // MARK: - 退出

    func leaveRoom() {
        removeObservers()
        if isHost {
            roomRef?.removeValue()
        } else {
            roomRef?.child("guestId").setValue("")
            roomRef?.child("guestName").setValue("")
        }
        reset()
    }

    // MARK: - リセット

    func reset() {
        removeObservers()
        roomCode = ""
        isHost = false
        status = .idle
        hostName = ""
        guestName = ""
        hostReady = false
        guestReady = false
        opponentScore = 0
        opponentCorrect = 0
        opponentCombo = 0
        opponentFinished = false
        opponentDisconnected = false
        opponentAttackCount = 0
        winner = ""
        errorMessage = nil
        roomRef = nil
    }

    // MARK: - ルーム監視

    private func observeRoom() {
        guard let ref = roomRef else { return }
        removeObservers()

        // ステータス監視
        let h1 = ref.child("status").observe(.value) { [weak self] snap in
            guard let self, let val = snap.value as? String else { return }
            self.status = RoomStatus(rawValue: val) ?? .idle
        }
        handles.append(h1)

        // ゲスト入室監視
        let h2 = ref.child("guestName").observe(.value) { [weak self] snap in
            guard let self else { return }
            let name = snap.value as? String ?? ""
            self.guestName = name
            if !self.isHost && name.isEmpty && self.status != .idle {
                // ホストが部屋を消した
                self.opponentDisconnected = true
            }
        }
        handles.append(h2)

        // ホスト名監視（ゲスト用）
        let h3 = ref.child("hostName").observe(.value) { [weak self] snap in
            guard let self else { return }
            self.hostName = snap.value as? String ?? ""
        }
        handles.append(h3)

        // Ready監視
        let h4 = ref.child("players/host/isReady").observe(.value) { [weak self] snap in
            self?.hostReady = snap.value as? Bool ?? false
        }
        handles.append(h4)

        let h5 = ref.child("players/guest/isReady").observe(.value) { [weak self] snap in
            self?.guestReady = snap.value as? Bool ?? false
        }
        handles.append(h5)

        // 相手スコア監視
        let opponentKey = isHost ? "guest" : "host"
        let h6 = ref.child("players/\(opponentKey)").observe(.value) { [weak self] snap in
            guard let self, let data = snap.value as? [String: Any] else { return }
            self.opponentScore = data["score"] as? Int ?? 0
            self.opponentCorrect = data["correctCount"] as? Int ?? 0
            self.opponentCombo = data["combo"] as? Int ?? 0
            self.opponentFinished = data["finished"] as? Bool ?? false
            self.opponentAttackCount = data["attackCount"] as? Int ?? 0
        }
        handles.append(h6)

        // Winner監視
        let h7 = ref.child("winner").observe(.value) { [weak self] snap in
            guard let self else { return }
            self.winner = snap.value as? String ?? ""
        }
        handles.append(h7)

        // 部屋削除検知
        let h8 = ref.observe(.value) { [weak self] snap in
            guard let self else { return }
            if !snap.exists() && self.status != .idle {
                self.opponentDisconnected = true
                self.status = .idle
            }
        }
        handles.append(h8)
    }

    private func removeObservers() {
        guard let ref = roomRef else { return }
        for h in handles { ref.removeObserver(withHandle: h) }
        handles.removeAll()
    }

    // MARK: - コード生成

    private func generateCode() -> String {
        String(format: "%04d", Int.random(in: 1000...9999))
    }
}

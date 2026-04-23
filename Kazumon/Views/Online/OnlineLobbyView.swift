import SwiftUI

/// オンライン対戦ロビー（部屋作成・参加・Ready・待機）
struct OnlineLobbyView: View {
    var isFamily: Bool = false
    let onStart: () -> Void
    let onCancel: () -> Void

    @State private var mp = MultiplayerService.shared
    @State private var inputCode = ""
    @State private var phase: LobbyPhase = .menu
    @State private var showError = false

    enum LobbyPhase {
        case menu       // 作成 or 参加 選択
        case creating   // 部屋作成中（コード表示＋相手待ち）
        case joining    // コード入力画面
        case inRoom     // 部屋に入った（Ready待ち）
    }

    private var playerName: String {
        DataStore.loadPlayerName()
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.2, green: 0.5, blue: 0.9), Color(red: 0.3, green: 0.7, blue: 1.0)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            VStack(spacing: 20) {
                // 上部バー
                HStack {
                    Button {
                        HapticsManager.tap()
                        mp.leaveRoom()
                        onCancel()
                    } label: {
                        Text("battle_quit_button")
                            .font(.zenMaru(14, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                }
                .padding(.horizontal, 24).padding(.top, 16)

                Text(NSLocalizedString(isFamily ? "online_lobby_family" : "online_lobby_title", comment: ""))
                    .font(.zenMaru(24, weight: .black))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)

                Spacer()

                switch phase {
                case .menu:
                    menuView
                case .creating:
                    creatingView
                case .joining:
                    joiningView
                case .inRoom:
                    inRoomView
                }

                Spacer()
            }
        }
        .onChange(of: mp.guestName) { _, name in
            if phase == .creating && !name.isEmpty {
                withAnimation { phase = .inRoom }
            }
        }
        .onChange(of: mp.status) { _, newStatus in
            if newStatus == .playing {
                onStart()
            }
        }
        .onChange(of: mp.opponentDisconnected) { _, disconnected in
            if disconnected {
                mp.errorMessage = NSLocalizedString("online_opponent_left", comment: "")
                showError = true
            }
        }
        .onChange(of: mp.errorMessage) { _, msg in
            if msg != nil { showError = true }
        }
        .alert("online_error_title", isPresented: $showError) {
            Button("common_ok") {
                if mp.opponentDisconnected {
                    mp.leaveRoom()
                    phase = .menu
                }
                mp.errorMessage = nil
            }
        } message: {
            Text(mp.errorMessage ?? "")
        }
    }

    // MARK: - メニュー画面

    private var menuView: some View {
        VStack(spacing: 16) {
            lobbyButton(text: NSLocalizedString("online_create_room", comment: ""), color: .green) {
                HapticsManager.tap()
                mp.createRoom(playerName: playerName)
                withAnimation { phase = .creating }
            }
            lobbyButton(text: NSLocalizedString("online_join_room", comment: ""), color: .orange) {
                HapticsManager.tap()
                withAnimation { phase = .joining }
            }
        }
        .padding(.horizontal, 32)
    }

    // MARK: - 部屋作成中

    private var creatingView: some View {
        VStack(spacing: 20) {
            Text("online_room_code")
                .font(.zenMaru(16, weight: .bold))
                .foregroundStyle(.white.opacity(0.8))

            Text(mp.roomCode)
                .font(.system(size: 56, weight: .black, design: .monospaced))
                .foregroundStyle(.white)
                .tracking(8)
                .shadow(color: .black.opacity(0.3), radius: 8, y: 2)

            Text("online_waiting_opponent")
                .font(.zenMaru(16, weight: .bold))
                .foregroundStyle(.white.opacity(0.6))

            ProgressView()
                .tint(.white)
                .scaleEffect(1.2)
        }
    }

    // MARK: - コード入力

    private var joiningView: some View {
        VStack(spacing: 20) {
            Text("online_enter_code")
                .font(.zenMaru(18, weight: .bold))
                .foregroundStyle(.white)

            TextField("", text: $inputCode)
                .font(.system(size: 36, weight: .black, design: .monospaced))
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .frame(width: 200, height: 60)
                .background(Color.white.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .foregroundColor(.black)
                .onChange(of: inputCode) { _, val in
                    if val.count > 4 { inputCode = String(val.prefix(4)) }
                }

            lobbyButton(text: NSLocalizedString("online_join_button", comment: ""),
                        color: inputCode.count == 4 ? .green : .gray) {
                guard inputCode.count == 4 else { return }
                HapticsManager.tap()
                mp.joinRoom(code: inputCode, playerName: playerName)
                withAnimation { phase = .inRoom }
            }
            .disabled(inputCode.count != 4)

            Button {
                HapticsManager.tap()
                withAnimation { phase = .menu }
            } label: {
                Text("older_back_button")
                    .font(.zenMaru(14, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 32)
    }

    // MARK: - ルーム内

    private var inRoomView: some View {
        VStack(spacing: 16) {
            // ルームコード
            Text(mp.roomCode)
                .font(.system(size: 32, weight: .black, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))

            // プレイヤー表示
            HStack(spacing: 24) {
                playerCard(name: NSLocalizedString("online_self", comment: ""), isReady: mp.isHost ? mp.hostReady : mp.guestReady, isSelf: true)
                Text("VS")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.yellow)
                let opponentJoined = mp.isHost ? !mp.guestName.isEmpty : !mp.hostName.isEmpty
                if opponentJoined {
                    playerCard(name: NSLocalizedString("versus_opponent_name", comment: ""), isReady: mp.isHost ? mp.guestReady : mp.hostReady, isSelf: false)
                } else {
                    playerCard(name: "...", isReady: false, isSelf: false)
                }
            }

            Spacer().frame(height: 20)

            // Ready / 開始ボタン
            let myReady = mp.isHost ? mp.hostReady : mp.guestReady
            let bothReady = mp.hostReady && mp.guestReady

            if !myReady {
                lobbyButton(text: NSLocalizedString("online_ready", comment: ""), color: .blue) {
                    HapticsManager.tap()
                    mp.setReady()
                }
            } else if mp.isHost && bothReady {
                lobbyButton(text: NSLocalizedString("online_start_battle", comment: ""), color: .green) {
                    HapticsManager.tap()
                    mp.startBattle()
                }
            } else {
                Text("online_waiting_ready")
                    .font(.zenMaru(16, weight: .bold))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 32)
    }

    // MARK: - 部品

    @ViewBuilder
    private func playerCard(name: String, isReady: Bool, isSelf: Bool) -> some View {
        VStack(spacing: 6) {
            Circle()
                .fill(isSelf ? Color.green : Color.white.opacity(0.3))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(String(name.prefix(1)))
                        .font(.zenMaru(20, weight: .black))
                        .foregroundColor(isSelf ? .white : .black)
                )
            Text(name)
                .font(.zenMaru(14, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
            if isReady {
                Text("OK")
                    .font(.zenMaru(12, weight: .black))
                    .foregroundStyle(.yellow)
            }
        }
        .frame(width: 80)
    }

    @ViewBuilder
    private func lobbyButton(text: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.zenMaru(22, weight: .black))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity).frame(height: 60)
                .background(RoundedRectangle(cornerRadius: 16).fill(color))
                .shadow(color: color.opacity(0.4), radius: 6, y: 4)
        }
    }
}

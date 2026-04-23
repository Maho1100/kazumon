import Foundation
import UIKit

/// Supabase answer_logs テーブルへの書き込みサービス
/// REST API 直接呼び出し（SDK不要）
final class SupabaseService {
    static let shared = SupabaseService()

    private let baseURL = "https://cworoufonygmvmljvluu.supabase.co"
    private let anonKey: String

    private var userId: String {
        UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
    }

    private var profileEnsured = false

    private init() {
        // Info.plist から anon key を読み込み
        anonKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String ?? ""
        if anonKey.isEmpty {
            print("⚠️ [SupabaseService] SUPABASE_ANON_KEY not found in Info.plist")
        }
    }

    // MARK: - answer_logs に書き込み

    struct AnswerLogPayload: Encodable {
        let user_id: String
        let content_type: String
        let question: String
        let correct_answer: Int
        let user_answer: Int
        let is_correct: Bool
        let response_time_ms: Int
        let attempt_count: Int
    }

    /// 回答ログを送信（バックグラウンド、失敗してもゲームに影響しない）
    func logAnswer(
        operatorSymbol: String,
        a: Int,
        b: Int,
        correctAnswer: Int,
        userAnswer: Int,
        isCorrect: Bool,
        responseTimeMs: Int,
        attemptCount: Int
    ) {
        guard !anonKey.isEmpty else { return }

        let contentType: String
        switch operatorSymbol {
        case "＋": contentType = "addition"
        case "－": contentType = "subtraction"
        case "×": contentType = "multiplication"
        case "÷": contentType = "division"
        default:   contentType = "addition"
        }

        let payload = AnswerLogPayload(
            user_id: userId,
            content_type: contentType,
            question: "\(a) \(operatorSymbol) \(b)",
            correct_answer: correctAnswer,
            user_answer: userAnswer,
            is_correct: isCorrect,
            response_time_ms: responseTimeMs,
            attempt_count: attemptCount
        )

        Task.detached(priority: .utility) {
            do {
                try await self.postAnswerLog(payload)
            } catch {
                print("⚠️ [SupabaseService] logAnswer failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - REST API 呼び出し

    // MARK: - profiles に user_id を登録（初回のみ）

    private func ensureProfile() async {
        guard !profileEnsured else { return }
        guard let url = URL(string: "\(baseURL)/rest/v1/profiles") else { return }

        struct ProfilePayload: Encodable {
            let user_id: String
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        // 既に存在する場合は何もしない（409を無視）
        request.setValue("resolution=ignore-duplicates", forHTTPHeaderField: "Prefer")
        request.httpBody = try? JSONEncoder().encode(ProfilePayload(user_id: userId))
        request.timeoutInterval = 10

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse {
                if (200...299).contains(http.statusCode) || http.statusCode == 409 {
                    profileEnsured = true
                } else {
                    print("⚠️ [SupabaseService] ensureProfile HTTP \(http.statusCode)")
                }
            }
        } catch {
            print("⚠️ [SupabaseService] ensureProfile failed: \(error.localizedDescription)")
        }
    }

    // MARK: - play_sessions

    struct SessionCreatePayload: Encodable {
        let user_id: String
        let content_type: String
    }

    struct SessionUpdatePayload: Encodable {
        let ended_at: String
        let total_questions: Int
        let correct_count: Int
    }

    /// セッション作成 → UUID を返す
    func createSession(contentType: String) async -> String? {
        guard !anonKey.isEmpty else { return nil }
        await ensureProfile()

        guard let url = URL(string: "\(baseURL)/rest/v1/play_sessions") else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        request.httpBody = try? JSONEncoder().encode(
            SessionCreatePayload(user_id: userId, content_type: contentType)
        )
        request.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                print("⚠️ [SupabaseService] createSession HTTP \(http.statusCode)")
                return nil
            }
            // レスポンスから id を取得
            if let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
               let first = arr.first,
               let id = first["id"] as? String {
                return id
            }
        } catch {
            print("⚠️ [SupabaseService] createSession failed: \(error.localizedDescription)")
        }
        return nil
    }

    /// セッション終了時に更新
    func updateSession(id: String, totalQuestions: Int, correctCount: Int) {
        guard !anonKey.isEmpty else { return }

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let payload = SessionUpdatePayload(
            ended_at: iso.string(from: Date()),
            total_questions: totalQuestions,
            correct_count: correctCount
        )

        Task.detached(priority: .utility) { [self] in
            do {
                guard let url = URL(string: "\(baseURL)/rest/v1/play_sessions?id=eq.\(id)") else { return }
                var request = URLRequest(url: url)
                request.httpMethod = "PATCH"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue(anonKey, forHTTPHeaderField: "apikey")
                request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
                request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
                request.httpBody = try JSONEncoder().encode(payload)
                request.timeoutInterval = 10

                let (_, response) = try await URLSession.shared.data(for: request)
                if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                    print("⚠️ [SupabaseService] updateSession HTTP \(http.statusCode)")
                }
            } catch {
                print("⚠️ [SupabaseService] updateSession failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - versus_results

    struct VersusResultPayload: Encodable {
        let user_id: String
        let player_score: Int
        let opponent_score: Int
        let is_win: Bool
        let bp_delta: Int
        let bp_after: Int
        let is_family: Bool
        let is_online: Bool
    }

    func logVersusResult(
        playerScore: Int,
        opponentScore: Int,
        isWin: Bool,
        bpDelta: Int,
        bpAfter: Int,
        isFamily: Bool,
        isOnline: Bool = false
    ) {
        guard !anonKey.isEmpty else { return }

        let payload = VersusResultPayload(
            user_id: userId,
            player_score: playerScore,
            opponent_score: opponentScore,
            is_win: isWin,
            bp_delta: bpDelta,
            bp_after: bpAfter,
            is_family: isFamily,
            is_online: isOnline
        )

        Task.detached(priority: .utility) { [self] in
            await ensureProfile()
            do {
                guard let url = URL(string: "\(baseURL)/rest/v1/versus_results") else { return }
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue(anonKey, forHTTPHeaderField: "apikey")
                request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
                request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
                request.httpBody = try JSONEncoder().encode(payload)
                request.timeoutInterval = 10

                let (_, response) = try await URLSession.shared.data(for: request)
                if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                    print("⚠️ [SupabaseService] logVersusResult HTTP \(http.statusCode)")
                }
            } catch {
                print("⚠️ [SupabaseService] logVersusResult failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - answer_logs に POST

    private func postAnswerLog(_ payload: AnswerLogPayload) async throws {
        // まず profiles に登録されていることを保証
        await ensureProfile()

        guard let url = URL(string: "\(baseURL)/rest/v1/answer_logs") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        request.httpBody = try JSONEncoder().encode(payload)
        request.timeoutInterval = 10

        let (_, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            print("⚠️ [SupabaseService] HTTP \(http.statusCode)")
        }
    }
}

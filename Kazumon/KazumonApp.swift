import SwiftUI
import Firebase
import FirebaseAuth

@main
struct KazumonApp: App {
    init() {
        DataStore.migrateIfNeeded()
        DataStore.runDataMigrationIfNeeded()
        FirebaseApp.configure()
        applyDefaultFont()
        NotificationManager.shared.cancelAll()

        AnalyticsManager.logAppOpen()

        // User ID + User Property を Analytics に連携
        if let user = Auth.auth().currentUser {
            AnalyticsManager.setUserID(user.uid)
            AnalyticsManager.setLoginType(user.isAnonymous ? "anonymous" : "email")
        }
        AnalyticsManager.setUserTier(PurchaseManager.shared.isPro ? "pro" : "free")
        if DataStore.hasCompletedSetup() {
            AnalyticsManager.setAgeGroup(DataStore.loadAgeGroup().rawValue)
        }

        // 匿名ログイン（オンライン対戦用）— 起動をブロックしない
        if Auth.auth().currentUser == nil {
            Task.detached(priority: .utility) {
                do {
                    let result = try await Auth.auth().signInAnonymously()
                    await MainActor.run {
                        print("[Auth] Anonymous sign-in success")
                        AnalyticsManager.setUserID(result.user.uid)
                        AnalyticsManager.setLoginType("anonymous")
                    }
                } catch {
                    print("[Auth] Anonymous sign-in failed: \(error.localizedDescription)")
                }
            }
        }

        #if DEBUG
        // フォント登録確認用（コンソールに出力）
        let zenFamilies = UIFont.familyNames.sorted().filter { $0.contains("Zen") }
        if zenFamilies.isEmpty {
            print("⚠️ Zen Maru Gothic が登録されていません")
            print("📋 登録済みフォント一覧:")
            for family in UIFont.familyNames.sorted() {
                print("  \(family): \(UIFont.fontNames(forFamilyName: family))")
            }
        } else {
            for family in zenFamilies {
                print("✅ \(family): \(UIFont.fontNames(forFamilyName: family))")
            }
        }
        #endif
    }

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                AnalyticsManager.trackAppBackground()
            }
        }
    }

    private func applyDefaultFont() {
        // UIKitレベルでデフォルトフォントを Zen Maru Gothic に設定
        let appearance = UINavigationBar.appearance()
        appearance.largeTitleTextAttributes = [
            .font: UIFont(name: "ZenMaruGothic-Black", size: 34) ?? .systemFont(ofSize: 34)
        ]
        appearance.titleTextAttributes = [
            .font: UIFont(name: "ZenMaruGothic-Bold", size: 17) ?? .systemFont(ofSize: 17)
        ]
    }
}

// MARK: - Zen Maru Gothic フォント拡張
extension Font {
    static func zenMaru(_ size: CGFloat, weight: ZenMaruWeight = .regular) -> Font {
        .custom(weight.fontName, size: size, relativeTo: textStyle(for: size))
    }

    private static func textStyle(for size: CGFloat) -> Font.TextStyle {
        switch size {
        case ..<12:  return .caption2
        case ..<14:  return .caption
        case ..<16:  return .footnote
        case ..<18:  return .body
        case ..<22:  return .title3
        case ..<28:  return .title2
        default:     return .title
        }
    }

    enum ZenMaruWeight {
        case regular, bold, black

        var fontName: String {
            switch self {
            case .regular: "ZenMaruGothic-Regular"
            case .bold:    "ZenMaruGothic-Bold"
            case .black:   "ZenMaruGothic-Black"
            }
        }
    }
}

// MARK: - アプリ全体にZen Maru Gothicを適用するModifier
struct ZenMaruFontModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .environment(\.font, .custom("ZenMaruGothic-Regular", size: 16, relativeTo: .body))
    }
}

extension View {
    func zenMaruFont() -> some View {
        modifier(ZenMaruFontModifier())
    }
}

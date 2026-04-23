import Foundation
import StoreKit
import Observation

/// Pro版購入状態を管理（v1.1: StoreKit2）
@Observable
final class PurchaseManager {
    static let shared = PurchaseManager()

    /// 無料版の1日あたりプレイ上限
    static let maxFreePlayCount = 3

    /// 無料版の最大フロア
    static let maxFreeFloor = 30

    private static let proKey = "kazumon_is_pro"
    private static let productID = "info.ohlo.Kazumon.pro"

    /// Pro版購入済みかどうか
    var isPro: Bool {
        didSet {
            UserDefaults.standard.set(isPro, forKey: Self.proKey)
        }
    }

    private var transactionUpdateTask: Task<Void, Never>?

    private init() {
        isPro = UserDefaults.standard.bool(forKey: Self.proKey)
        transactionUpdateTask = listenForTransactions()
    }

    deinit {
        transactionUpdateTask?.cancel()
    }

    /// 今日プレイできるかどうか
    var canPlay: Bool {
        isPro || DataStore.todayPlayCount() < Self.maxFreePlayCount
    }

    /// 残りプレイ回数（Pro版は無制限 → Int.max）
    var remainingPlays: Int {
        isPro ? .max : max(0, Self.maxFreePlayCount - DataStore.todayPlayCount())
    }

    /// Pro版の表示価格（StoreKitから取得）
    var proDisplayPrice: String = ""

    func fetchPrice() async {
        guard let product = try? await Product.products(for: [Self.productID]).first else { return }
        await MainActor.run { proDisplayPrice = product.displayPrice }
    }

    /// Pro版を購入（StoreKit2）
    func purchase() async throws {
        let products = try await Product.products(for: [Self.productID])
        guard let product = products.first else { return }
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await MainActor.run {
                self.isPro = true
                AnalyticsManager.logProPurchased()
            }
            await transaction.finish()
        case .userCancelled:
            AnalyticsManager.logResultPurchase(state: "cancel", productId: Self.productID)
        case .pending:
            AnalyticsManager.logResultPurchase(state: "pending", productId: Self.productID)
        @unknown default:
            break
        }
    }

    /// 購入を復元（StoreKit2）
    func restore() async throws {
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result),
               transaction.productID == Self.productID {
                await MainActor.run { self.isPro = true }
                await transaction.finish()
            }
        }
    }

    private func listenForTransactions() -> Task<Void, Never> {
        let pid = Self.productID
        return Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { break }
                if let transaction = try? Self.verifyResult(result),
                   transaction.productID == pid {
                    await MainActor.run { self.isPro = true }
                    await transaction.finish()
                }
            }
        }
    }

    private nonisolated static func verifyResult<T>(
        _ result: VerificationResult<T>
    ) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let value):
            return value
        }
    }

    private func checkVerified<T>(
        _ result: VerificationResult<T>
    ) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let value):
            return value
        }
    }

    enum StoreError: Error {
        case failedVerification
    }
}

import Foundation
import StoreKit
import WidgetKit

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    // MARK: - Product IDs
    let subscriptionProductIDs: [String] = [
        "com.CardsOfTheSevenSistersApp.subscription.weekly",
        "com.CardsOfTheSevenSistersApp.subscription.monthly",
        "com.CardsOfTheSevenSistersApp.subscription.6months",
        "com.CardsOfTheSevenSistersApp.subscription.annual"
    ]

    // MARK: - Published State
    @Published var products: [Product] = []
    @Published var isSubscribed: Bool = false
    @Published var activeProductID: String? = nil
    @Published var isPurchasing: Bool = false
    @Published var errorMessage: String? = nil
    @Published var hasBillingIssue: Bool = false
    @Published var purchaseSucceeded: Bool = false

    private var transactionListenerTask: Task<Void, Never>?

    #if DEBUG
    static let debugOverrideKey = "subscriptionDebugOverride"
    #endif

    private init() {
        // Restore persisted state immediately so Settings shows correct badge on cold launch
        let storedActive = UserDefaults.standard.bool(forKey: "subscriptionIsActive")
        #if DEBUG
        let overrideOn = UserDefaults.standard.bool(forKey: Self.debugOverrideKey)
        isSubscribed = overrideOn || storedActive
        #else
        isSubscribed = storedActive
        #endif
        activeProductID = UserDefaults.standard.string(forKey: "subscriptionActiveProductID")

        // Keep the App Group mirror aligned with what we just restored so the widget
        // renders correctly before any StoreKit transaction callbacks arrive.
        WidgetBridge.writeIsSubscribed(isSubscribed)

        transactionListenerTask = listenForTransactions()

        Task {
            await fetchProducts()
            await checkCurrentEntitlements()
            await processUnfinishedTransactions()
        }
    }

    deinit {
        transactionListenerTask?.cancel()
    }

    // MARK: - Fetch Products
    func fetchProducts() async {
        do {
            let fetched = try await Product.products(for: subscriptionProductIDs)
            let order = subscriptionProductIDs
            products = fetched.sorted {
                (order.firstIndex(of: $0.id) ?? 999) < (order.firstIndex(of: $1.id) ?? 999)
            }
            if products.isEmpty {
                errorMessage = "No subscription plans available. Check your connection and try again."
            }
        } catch {
            errorMessage = "Could not load products: \(error.localizedDescription)"
        }
    }

    // MARK: - Purchase
    func purchase(_ product: Product) async {
        isPurchasing = true
        errorMessage = nil
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updateSubscriptionStatus(from: transaction)
                await transaction.finish()
                purchaseSucceeded = true
            case .userCancelled:
                break
            case .pending:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Restore Purchases
    func restorePurchases() async {
        isPurchasing = true
        errorMessage = nil
        defer { isPurchasing = false }

        do {
            try await AppStore.sync()
            await checkCurrentEntitlements()
        } catch {
            errorMessage = "Restore failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Transaction Listener
    private func listenForTransactions() -> Task<Void, Never> {
        Task(priority: .background) {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updateSubscriptionStatus(from: transaction)
                    await transaction.finish()
                } catch {
                    // Unverified transaction — ignore
                }
            }
        }
    }

    // MARK: - Check Current Entitlements
    func checkCurrentEntitlements() async {
        var foundActive = false
        var foundProductID: String? = nil
        var foundBillingIssue = false

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if transaction.revocationDate == nil {
                    foundActive = true
                    foundProductID = transaction.productID
                }
            } catch {
                // Ignore unverified
            }
        }

        // Ensure products are loaded before checking subscription status
        if products.isEmpty { await fetchProducts() }

        // Check for billing retry or grace period across all subscription products
        for product in products {
            guard let statuses = try? await product.subscription?.status else { continue }
            for status in statuses {
                switch status.state {
                case .inBillingRetryPeriod, .inGracePeriod:
                    foundBillingIssue = true
                default:
                    break
                }
            }
        }

        let wasSubscribed = isSubscribed
        #if DEBUG
        let overrideOn = UserDefaults.standard.bool(forKey: Self.debugOverrideKey)
        let effectiveActive = foundActive || overrideOn
        #else
        let effectiveActive = foundActive
        #endif
        isSubscribed = effectiveActive
        activeProductID = foundProductID
        hasBillingIssue = foundBillingIssue
        UserDefaults.standard.set(foundActive, forKey: "subscriptionIsActive")
        UserDefaults.standard.set(foundProductID, forKey: "subscriptionActiveProductID")
        WidgetBridge.writeIsSubscribed(effectiveActive)
        WidgetCenter.shared.reloadAllTimelines()
        if wasSubscribed && !effectiveActive {
            Task { await CalendarSyncService.shared.removeFutureEvents() }
        }
    }

    #if DEBUG
    /// Debug-only override that forces subscriber state on regardless of StoreKit.
    /// Persisted across launches; toggle from the Settings menu.
    var debugSubscriptionOverride: Bool {
        get { UserDefaults.standard.bool(forKey: Self.debugOverrideKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.debugOverrideKey)
            if newValue {
                isSubscribed = true
                WidgetBridge.writeIsSubscribed(true)
                WidgetCenter.shared.reloadAllTimelines()
            } else {
                // Re-evaluate from real StoreKit state
                Task { await checkCurrentEntitlements() }
            }
            objectWillChange.send()
        }
    }
    #endif

    // MARK: - Process Unfinished Transactions
    func processUnfinishedTransactions() async {
        for await result in Transaction.unfinished {
            do {
                let transaction = try checkVerified(result)
                await updateSubscriptionStatus(from: transaction)
                await transaction.finish()
            } catch {
                // Ignore unverified
            }
        }
    }

    // MARK: - Helpers
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let value):
            return value
        }
    }

    private func updateSubscriptionStatus(from transaction: Transaction) async {
        let notRevoked = transaction.revocationDate == nil
        let notExpired = transaction.expirationDate.map { $0 > Date() } ?? true
        let storeActive = notRevoked && notExpired
        let wasSubscribed = isSubscribed
        #if DEBUG
        let overrideOn = UserDefaults.standard.bool(forKey: Self.debugOverrideKey)
        let effectiveActive = storeActive || overrideOn
        #else
        let effectiveActive = storeActive
        #endif
        isSubscribed = effectiveActive
        activeProductID = storeActive ? transaction.productID : nil
        UserDefaults.standard.set(storeActive, forKey: "subscriptionIsActive")
        UserDefaults.standard.set(activeProductID, forKey: "subscriptionActiveProductID")
        WidgetBridge.writeIsSubscribed(effectiveActive)
        WidgetCenter.shared.reloadAllTimelines()
        if wasSubscribed && !effectiveActive {
            Task { await CalendarSyncService.shared.removeFutureEvents() }
        }
    }
}

enum StoreError: Error {
    case failedVerification
}

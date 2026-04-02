import Foundation
import StoreKit

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    // MARK: - Product IDs
    let subscriptionProductIDs: [String] = [
        "com.CardsOfTheSevenSistersApp.subscription.weekly",
        "com.CardsOfTheSevenSistersApp.subscription.monthly",
        "com.CardsOfTheSevenSistersApp.subscription.annual"
    ]
    let lifetimeProductID = "com.CardsOfTheSevenSistersApp.purchase.lifetime"

    var allProductIDs: [String] {
        subscriptionProductIDs + [lifetimeProductID]
    }

    // MARK: - Published State
    @Published var products: [Product] = []
    @Published var isSubscribed: Bool = false
    @Published var activeProductID: String? = nil
    @Published var isPurchasing: Bool = false
    @Published var errorMessage: String? = nil

    private var transactionListenerTask: Task<Void, Never>?

    private init() {
        // Restore persisted state immediately so Settings shows correct badge on cold launch
        isSubscribed = UserDefaults.standard.bool(forKey: "subscriptionIsActive")
        activeProductID = UserDefaults.standard.string(forKey: "subscriptionActiveProductID")

        transactionListenerTask = listenForTransactions()

        Task {
            await fetchProducts()
            await checkCurrentEntitlements()
        }
    }

    deinit {
        transactionListenerTask?.cancel()
    }

    // MARK: - Fetch Products
    func fetchProducts() async {
        do {
            let fetched = try await Product.products(for: allProductIDs)
            // Sort: weekly, monthly, annual, lifetime
            let order = allProductIDs
            products = fetched.sorted {
                (order.firstIndex(of: $0.id) ?? 999) < (order.firstIndex(of: $1.id) ?? 999)
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

        isSubscribed = foundActive
        activeProductID = foundProductID
        UserDefaults.standard.set(foundActive, forKey: "subscriptionIsActive")
        UserDefaults.standard.set(foundProductID, forKey: "subscriptionActiveProductID")
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
        isSubscribed = transaction.revocationDate == nil
        activeProductID = isSubscribed ? transaction.productID : nil
        UserDefaults.standard.set(isSubscribed, forKey: "subscriptionIsActive")
        UserDefaults.standard.set(activeProductID, forKey: "subscriptionActiveProductID")
    }
}

enum StoreError: Error {
    case failedVerification
}

import XCTest
import StoreKit
import StoreKitTest
@testable import CardsofTheSevenSisters

@MainActor
final class SubscriptionManagerTests: XCTestCase {

    var session: SKTestSession!
    let manager = SubscriptionManager.shared

    private let annualID  = "com.CardsOfTheSevenSistersApp.subscription.annual"
    private let monthlyID = "com.CardsOfTheSevenSistersApp.subscription.monthly"
    private let weeklyID  = "com.CardsOfTheSevenSistersApp.subscription.weekly"
    private let sixMonthID = "com.CardsOfTheSevenSistersApp.subscription.6months"

    override func setUpWithError() throws {
        session = try SKTestSession(configurationFileNamed: "StoreKit_Config")
        session.disableDialogs = true
        session.resetToDefaultState()
        session.clearTransactions()
    }

    override func tearDownWithError() throws {
        session.clearTransactions()
        session.resetToDefaultState()
    }

    // MARK: - Helpers

    private func fetchedProducts() async throws -> [Product] {
        let ids = manager.subscriptionProductIDs
        return try await Product.products(for: ids)
    }

    // MARK: - Purchase succeeds → isSubscribed becomes true

    func testPurchaseSucceeds() async throws {
        try await session.buyProduct(productIdentifier: annualID)
        await manager.checkCurrentEntitlements()

        XCTAssertTrue(manager.isSubscribed)
        XCTAssertEqual(manager.activeProductID, annualID)
    }

    // MARK: - expireSubscription → isSubscribed becomes false

    func testExpireSubscriptionClearsActive() async throws {
        try await session.buyProduct(productIdentifier: monthlyID)
        await manager.checkCurrentEntitlements()
        XCTAssertTrue(manager.isSubscribed)

        try session.expireSubscription(productIdentifier: monthlyID)
        await manager.checkCurrentEntitlements()

        XCTAssertFalse(manager.isSubscribed)
        XCTAssertNil(manager.activeProductID)
    }

    // MARK: - forceRenewal → stays subscribed across renewal

    func testForceRenewalMaintainsSubscription() async throws {
        try await session.buyProduct(productIdentifier: annualID)
        await manager.checkCurrentEntitlements()
        XCTAssertTrue(manager.isSubscribed)

        try session.forceRenewalOfSubscription(productIdentifier: annualID)
        await manager.checkCurrentEntitlements()

        XCTAssertTrue(manager.isSubscribed)
        XCTAssertEqual(manager.activeProductID, annualID)
    }

    // MARK: - Billing retry → hasBillingIssue becomes true

    func testBillingRetrySetsBillingIssue() async throws {
        try await session.buyProduct(productIdentifier: monthlyID)
        await manager.fetchProducts()
        await manager.checkCurrentEntitlements()
        XCTAssertFalse(manager.hasBillingIssue)

        session.shouldEnterBillingRetryOnRenewal = true
        try session.forceRenewalOfSubscription(productIdentifier: monthlyID)
        await manager.checkCurrentEntitlements()

        XCTAssertTrue(manager.hasBillingIssue)
    }

    // MARK: - Resolve billing retry → hasBillingIssue clears

    func testResolveBillingRetryClearsBillingIssue() async throws {
        try await session.buyProduct(productIdentifier: monthlyID)
        await manager.fetchProducts()
        session.shouldEnterBillingRetryOnRenewal = true
        try session.forceRenewalOfSubscription(productIdentifier: monthlyID)
        await manager.checkCurrentEntitlements()
        XCTAssertTrue(manager.hasBillingIssue)

        let transactions = try session.allTransactions()
        if let retryTx = transactions.first(where: { $0.productIdentifier == monthlyID }) {
            try session.resolveIssueForTransaction(identifier: retryTx.identifier)
        }
        await manager.checkCurrentEntitlements()

        XCTAssertFalse(manager.hasBillingIssue)
    }

    // MARK: - failTransactionsEnabled → errorMessage surfaces

    func testFailedTransactionSurfacesError() async throws {
        session.failTransactionsEnabled = true
        session.failureError = .unknown

        let products = try await fetchedProducts()
        guard let annual = products.first(where: { $0.id == annualID }) else {
            XCTFail("Annual product not found")
            return
        }

        await manager.purchase(annual)

        XCTAssertNotNil(manager.errorMessage)
        XCTAssertFalse(manager.isSubscribed)
    }

    // MARK: - Interrupted purchase resolves on processUnfinishedTransactions

    func testInterruptedPurchaseProcessedOnNextLaunch() async throws {
        // Simulate a purchase that completed server-side but was never finished by the app
        try await session.buyProduct(productIdentifier: weeklyID)

        // Reset state to simulate cold launch before transaction was processed
        await manager.checkCurrentEntitlements()
        XCTAssertTrue(manager.isSubscribed)

        // processUnfinishedTransactions is what runs on launch — verify it handles cleanly
        await manager.processUnfinishedTransactions()

        // Subscription should still be active after processing
        XCTAssertTrue(manager.isSubscribed)
    }
}

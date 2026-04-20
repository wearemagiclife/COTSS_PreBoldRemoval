import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedProductID: String = "com.CardsOfTheSevenSistersApp.subscription.annual"
    @State private var showThankYou: Bool = false

    private let cardBackground = AppConstants.Colors.capsuleButton

    var body: some View {
        ZStack {
            Color.appLaunchBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppConstants.Spacing.cardPadding) {

                    // MARK: - Header
                    headerSection

                    // MARK: - Plan Cards
                    if subscriptionManager.products.isEmpty {
                        loadingPlaceholder
                    } else {
                        planCardsSection
                    }

                    // MARK: - CTA
                    ctaSection

                    // MARK: - Footer
                    footerSection
                }
                .padding(.horizontal, AppConstants.Spacing.cardPadding)
                .padding(.top, AppConstants.Spacing.tight)
                .padding(.bottom, AppConstants.Spacing.section)
            }

            if subscriptionManager.isPurchasing {
                purchasingOverlay
            }

            if showThankYou {
                thankYouOverlay
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20))
                        .foregroundColor(AppTheme.primaryText)
                        .frame(width: AppConstants.ButtonSizes.closeButton, height: AppConstants.ButtonSizes.closeButton)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close subscription")
            }
        }
        .toolbarBackground(Color.appLaunchBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .alert("Error", isPresented: Binding(
            get: { subscriptionManager.errorMessage != nil },
            set: { if !$0 { subscriptionManager.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { subscriptionManager.errorMessage = nil }
        } message: {
            Text(subscriptionManager.errorMessage ?? "")
        }
        .task {
            if subscriptionManager.products.isEmpty {
                await subscriptionManager.fetchProducts()
            }
        }
        .onChange(of: subscriptionManager.purchaseSucceeded) { _, succeeded in
            guard succeeded else { return }
            subscriptionManager.purchaseSucceeded = false
            showThankYou = true
            Task {
                try? await Task.sleep(for: .seconds(2))
                dismiss()
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 44))
                .foregroundColor(AppTheme.goldAccent)
                .padding(.top, 8)

            Text("Support Seven Sisters")
                .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.title))
                .foregroundColor(AppTheme.primaryText)
                .multilineTextAlignment(.center)

            Text("All features are free. Your support\nkeeps the cards turning.")
                .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                .foregroundColor(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            if subscriptionManager.isSubscribed {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(AppTheme.goldAccent)
                    Text("Thank you for your support!")
                        .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.callout))
                        .foregroundColor(AppTheme.goldAccent)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(AppTheme.goldAccent.opacity(0.12))
                .cornerRadius(AppTheme.cornerRadius)
            }
        }
        .padding(.bottom, 4)
    }

    // MARK: - Plan Cards
    private var planCardsSection: some View {
        VStack(spacing: AppConstants.Spacing.tight) {
            ForEach(subscriptionManager.products) { product in
                SubscriptionPlanCard(
                    product: product,
                    isSelected: selectedProductID == product.id,
                    isRecommended: product.id == "com.CardsOfTheSevenSistersApp.subscription.annual"
                ) {
                    selectedProductID = product.id
                }
            }
        }
    }

    private var loadingPlaceholder: some View {
        VStack(spacing: AppConstants.Spacing.tight) {
            ForEach(0..<4, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(cardBackground.opacity(0.5))
                    .frame(height: 72)
                    .overlay(ProgressView())
            }

            Button {
                Task { await subscriptionManager.fetchProducts() }
            } label: {
                Text("Retry")
                    .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.callout))
                    .foregroundColor(AppTheme.secondaryText)
                    .underline()
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
    }

    // MARK: - CTA Section
    private var ctaSection: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    guard let product = subscriptionManager.products.first(where: { $0.id == selectedProductID }) else { return }
                    await subscriptionManager.purchase(product)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "applelogo")
                        .font(.system(size: 16, weight: .semibold))
                    Text(ctaTitle)
                        .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(GoldButtonStyle())
            .disabled(subscriptionManager.isPurchasing || subscriptionManager.products.isEmpty)

            Button {
                Task { await subscriptionManager.restorePurchases() }
            } label: {
                Text("Restore Purchases")
                    .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.callout))
                    .foregroundColor(AppTheme.secondaryText)
                    .underline()
            }
            .buttonStyle(.plain)
            .disabled(subscriptionManager.isPurchasing)
        }
        .padding(.top, 4)
    }

    // MARK: - Footer
    private var footerSection: some View {
        VStack(spacing: 6) {
            Text("Subscriptions auto-renew until cancelled. Cancel any time in Settings > Apple ID.")
                .font(.custom("Iowan Old Style", size: 11))
                .foregroundColor(AppTheme.secondaryText)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Link("Privacy Policy", destination: URL(string: "https://wearemagic.life/privacy")!)
                Link("Terms of Use", destination: URL(string: "https://wearemagic.life/terms")!)
            }
            .font(.custom("Iowan Old Style", size: 11))
            .foregroundColor(AppTheme.secondaryText.opacity(0.8))
        }
        .padding(.top, 4)
    }

    // MARK: - Purchasing Overlay
    private var purchasingOverlay: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.goldAccent))
                    .scaleEffect(1.4)
                Text("Processing...")
                    .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.body))
                    .foregroundColor(AppTheme.primaryText)
            }
            .padding(32)
            .background(AppTheme.cardBackground)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 6)
        }
    }

    // MARK: - Thank You Overlay
    private var thankYouOverlay: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 48))
                    .foregroundColor(AppTheme.goldAccent)
                Text("Thank you!")
                    .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.title))
                    .foregroundColor(AppTheme.primaryText)
                Text("Your support means everything.")
                    .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                    .foregroundColor(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(36)
            .background(AppTheme.cardBackground)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.3), radius: 16, x: 0, y: 8)
        }
        .transition(.opacity)
    }

    // MARK: - Helpers
    private var ctaTitle: String {
        subscriptionManager.products.contains { $0.id == selectedProductID }
            ? "Pay with Apple" : "Support the App"
    }
}

// MARK: - Plan Card Component
private struct SubscriptionPlanCard: View {
    let product: Product
    let isSelected: Bool
    let isRecommended: Bool
    let onTap: () -> Void

    private var planLabel: String {
        switch product.id {
        case _ where product.id.contains("weekly"):  return "Weekly"
        case _ where product.id.contains("6month"):  return "6 Months"
        case _ where product.id.contains("monthly"): return "Monthly"
        case _ where product.id.contains("annual"):  return "Annual"
        default: return product.displayName
        }
    }

    private var planDescription: String {
        switch product.id {
        case _ where product.id.contains("weekly"):  return "Billed every week"
        case _ where product.id.contains("6month"):  return "Billed every 6 months"
        case _ where product.id.contains("monthly"): return "Billed every month"
        case _ where product.id.contains("annual"):  return "Billed once per year"
        default: return ""
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Selection indicator
                ZStack {
                    Circle()
                        .strokeBorder(
                            isSelected ? AppTheme.goldAccent : AppTheme.primaryText.opacity(0.3),
                            lineWidth: isSelected ? 2 : 1
                        )
                        .frame(width: 22, height: 22)

                    if isSelected {
                        Circle()
                            .fill(AppTheme.goldAccent)
                            .frame(width: 12, height: 12)
                    }
                }

                // Labels
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(planLabel)
                            .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                            .foregroundColor(AppTheme.primaryText)

                        if isRecommended {
                            Text("Best Value")
                                .font(.custom("Iowan Old Style", size: 10))
                                .foregroundColor(AppTheme.goldAccent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(AppTheme.goldAccent.opacity(0.15))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(AppTheme.goldAccent.opacity(0.4), lineWidth: 1)
                                )
                        }
                    }

                    Text(planDescription)
                        .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.callout))
                        .foregroundColor(AppTheme.secondaryText)
                }

                Spacer()

                // Price
                VStack(alignment: .trailing, spacing: 2) {
                    if let intro = product.subscription?.introductoryOffer {
                        Text(intro.displayPrice)
                            .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                            .foregroundColor(isSelected ? AppTheme.goldAccent : AppTheme.primaryText)
                        Text("then \(product.displayPrice)")
                            .font(.custom("Iowan Old Style", size: 11))
                            .foregroundColor(AppTheme.secondaryText)
                    } else {
                        Text(product.displayPrice)
                            .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                            .foregroundColor(isSelected ? AppTheme.goldAccent : AppTheme.primaryText)
                    }
                }
            }
            .padding(AppConstants.Spacing.tight)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppConstants.Colors.capsuleButton.opacity(0.96))
                    .shadow(color: .black.opacity(0.10), radius: 6, x: 0, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        isSelected ? AppTheme.goldAccent : AppTheme.primaryText.opacity(0.10),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(planLabel), \(product.subscription?.introductoryOffer?.displayPrice ?? product.displayPrice), \(planDescription)")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

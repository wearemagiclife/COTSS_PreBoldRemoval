import SwiftUI
import StoreKit

struct SettingsMenuView: View {
    @Binding var isPresented: Bool

    @ObservedObject private var authManager = AuthenticationManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared

    @State private var showingProfile = false
    @State private var showingAppStorePrompt = false
    @State private var showingVisitListingPrompt = false

    @Environment(\.requestReview) private var requestReview
    @AppStorage("hasRatedApp") private var hasRated = false

    private var safeAreaTop: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.top ?? 59
    }

    private var safeAreaBottom: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.bottom ?? 59
    }

    // Adaptive card background for light/dark mode
    private let cardBackground = AppConstants.Colors.capsuleButton

    var body: some View {
        ZStack {
            // Dimmed backdrop — tap to dismiss
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }
                .animation(.spring(response: AppConstants.Animation.springResponse, dampingFraction: AppConstants.Animation.springDamping), value: isPresented)

            // Settings panel
            VStack {
                NavigationStack {
                ZStack {
                    AppTheme.backgroundColor.ignoresSafeArea()

                    ScrollView {
                        VStack(spacing: AppConstants.Spacing.tight) {

                            // ── Extra top breathing room so "Your Profile" is never clipped
                            //    by the navigation bar / close button area
                            Spacer().frame(height: AppConstants.Spacing.tight)

                            VStack(spacing: AppConstants.Spacing.tight) {

                            // MARK: – Account ──────────────────────────

                            Button { showingProfile = true } label: {
                                SettingsRow(
                                    systemImage: "person.crop.circle",
                                    title: "Your Profile",
                                    subtitle: "Edit, Sign Out, or Delete",
                                    cardBackground: cardBackground
                                )
                            }
                            .buttonStyle(.plain)
                            .sheet(isPresented: $showingProfile) {
                                ProfileSheet(onDismissAll: { isPresented = false })
                            }

                            // MARK: – Learn

                            NavigationLink {
                                LearnView()
                            } label: {
                                SettingsRow(
                                    systemImage: "book.fill",
                                    title: "Learn",
                                    subtitle: "Tips & Tutorials",
                                    cardBackground: cardBackground
                                )
                            }

                            // MARK: – Subscription

                            NavigationLink {
                                SubscriptionView()
                                    .environmentObject(subscriptionManager)
                            } label: {
                                SettingsRow(
                                    systemImage: "star.fill",
                                    title: subscriptionManager.isSubscribed ? "Your Subscription" : "Subscribe Today",
                                    subtitle: subscriptionManager.isSubscribed
                                        ? "⭐️ Thank you ⭐️"
                                        : "Unlock All ⭐️ Features",
                                    cardBackground: cardBackground,
                                    subtitleColor: subscriptionManager.isSubscribed ? AppTheme.goldAccent : nil
                                )
                            }

                            // MARK: – Premium Features ──────────────────

                            // Section label for premium items
                            SettingsSectionHeader(title: "Premium")
                                .padding(.top, 4)

                            VStack(spacing: AppConstants.Spacing.tight) {
                                NavigationLink {
                                    AppearanceSettingsView()
                                } label: {
                                    SettingsRow(
                                        systemImage: "moon.fill",
                                        title: "Appearance",
                                        subtitle: "New Dark Mode",
                                        cardBackground: cardBackground,
                                        isPremium: true
                                    )
                                }

                                NavigationLink {
                                    CalendarSyncView()
                                } label: {
                                    SettingsRow(
                                        systemImage: "calendar.badge.plus",
                                        title: "Sync to Calendar",
                                        subtitle: "See beyond tomorrow",
                                        cardBackground: cardBackground,
                                        isPremium: true
                                    )
                                }

                                NavigationLink {
                                    WidgetInfoView()
                                } label: {
                                    SettingsRow(
                                        systemImage: "rectangle.stack",
                                        title: "Get the Widget",
                                        subtitle: "Your Current Cards in view",
                                        cardBackground: cardBackground,
                                        isPremium: true
                                    )
                                }
                            }

                            // MARK: – General ──────────────────────────

                            SettingsSectionHeader(title: "General")
                                .padding(.top, 4)

                            NavigationLink {
                                NotificationSettingsView()
                            } label: {
                                SettingsRow(
                                    systemImage: "bell.badge",
                                    title: "Notifications",
                                    subtitle: "Never miss a Daily Card",
                                    cardBackground: cardBackground
                                )
                            }

                            // MARK: Rate the App
                            Button {
                                rateApp()
                            } label: {
                                SettingsRow(
                                    systemImage: "star.bubble",
                                    title: "Rate the App",
                                    subtitle: hasRated ? "Thanks for your rating! ♥" : "Share your experience",
                                    cardBackground: cardBackground
                                )
                            }

                            // MARK: Legal & Support
                            NavigationLink {
                                SupportView()
                            } label: {
                                SettingsRow(
                                    systemImage: "bubble.left.and.bubble.right",
                                    title: "Get Support",
                                    subtitle: "Policies & Contact",
                                    cardBackground: cardBackground
                                )
                            }

                            #if DEBUG
                            // MARK: Debug — force subscription on (Debug builds only)
                            Toggle(isOn: Binding(
                                get: { subscriptionManager.debugSubscriptionOverride },
                                set: { subscriptionManager.debugSubscriptionOverride = $0 }
                            )) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("DEBUG: Force Subscribed")
                                        .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                                        .foregroundColor(AppTheme.primaryText)
                                    Text("Override StoreKit; widget unlocks")
                                        .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.callout))
                                        .foregroundColor(AppTheme.secondaryText)
                                }
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, AppConstants.Spacing.ornament)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(cardBackground.opacity(0.96))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(AppTheme.primaryText.opacity(0.10), lineWidth: 1)
                            )
                            #endif

                        }  // inner VStack (settings rows)
                            .padding(.horizontal, AppConstants.Spacing.pageInset - 3)
                            .padding(.bottom, AppConstants.Spacing.tight)
                        }  // outer VStack
                    }  // ScrollView
                }  // ZStack (background + ScrollView)
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { isPresented = false }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 20))
                                .foregroundColor(AppTheme.primaryText)
                                .frame(width: AppConstants.ButtonSizes.closeButton, height: AppConstants.ButtonSizes.closeButton)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Close settings")
                        .accessibilityHint("Returns to home screen")
                    }
                }
                .toolbarBackground(AppTheme.backgroundColor, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .onAppear {
                    // Hide hairline and make nav bar fully transparent to avoid a defined edge
                    let appearance = UINavigationBarAppearance()
                    appearance.configureWithTransparentBackground()
                    appearance.backgroundEffect = nil
                    appearance.backgroundColor = .clear
                    appearance.shadowColor = .clear
                    UINavigationBar.appearance().standardAppearance = appearance
                    UINavigationBar.appearance().scrollEdgeAppearance = appearance

                    let toolAppearance = UIToolbarAppearance()
                    toolAppearance.configureWithTransparentBackground()
                    toolAppearance.backgroundEffect = nil
                    toolAppearance.backgroundColor = .clear
                    toolAppearance.shadowColor = .clear
                    UIToolbar.appearance().standardAppearance = toolAppearance
                    UIToolbar.appearance().compactAppearance = toolAppearance
                    UIToolbar.appearance().scrollEdgeAppearance = toolAppearance
                }
                .task {
                    await subscriptionManager.checkCurrentEntitlements()
                }
                .alert("Visit Our App Store Listing?", isPresented: $showingVisitListingPrompt) {
                    Button("Visit Listing") {
                        if let url = URL(string: "itms-apps://apps.apple.com/ca/app/cards-of-the-seven-sisters/id6753740480") {
                            UIApplication.shared.open(url)
                        }
                    }
                    Button("Maybe Later", role: .cancel) { }
                } message: {
                    Text("See your review, explore screenshots, or share the app with someone.")
                }
                .alert("Thank you for rating!", isPresented: $showingAppStorePrompt) {
                    Button("Write a Review") {
                        hasRated = true
                        if let url = URL(string: "itms-apps://apps.apple.com/ca/app/cards-of-the-seven-sisters/id6753740480?action=write-review") {
                            UIApplication.shared.open(url)
                        }
                    }
                    Button("No Thanks", role: .cancel) {
                        hasRated = true
                    }
                } message: {
                    Text("Would you like to write a review on the App Store? It only takes a moment.")
                }
            }  // NavigationStack
            .padding(.top, AppConstants.Spacing.pageInset - 15)
            .padding(.horizontal, AppConstants.Spacing.pageInset - 10)
            .background(AppTheme.backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.modal))
            .shadow(color: Color(red: 1.0, green: 0.95, blue: 0.88).opacity(0.12), radius: 120, x: 0, y: 0)
            }  // VStack
            .padding(.horizontal, 18)
            .padding(.top, safeAreaTop + AppConstants.Spacing.pageInset)
            .padding(.bottom, safeAreaBottom + AppConstants.Spacing.pageInset - 5)
        }  // ZStack (backdrop + panel)
    }

    private func rateApp() {
        if hasRated {
            showingVisitListingPrompt = true
        } else {
            requestReview()
            Task {
                try? await Task.sleep(for: .seconds(1))
                showingAppStorePrompt = true
            }
        }
    }

    private func openWebsite() {
        if let url = URL(string: "https://wearemagic.life") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Section Header

/// Lightweight label to visually group settings rows (e.g. "Premium", "General").
private struct SettingsSectionHeader: View {
    let title: String

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.custom("Iowan Old Style", size: 12))
                .fontWeight(.bold)
                .tracking(1.2)
                .foregroundColor(AppTheme.secondaryText.opacity(0.7))
            Spacer()
        }
        .padding(.horizontal, 6)
        .padding(.bottom, -2)
    }
}

// MARK: - Settings Row

private struct SettingsRow: View {
    let systemImage: String
    let title: String
    let subtitle: String?
    let cardBackground: Color
    var subtitleColor: Color? = nil
    /// Optional SF Symbol name shown after the subtitle text.
    var subtitleTrailingIcon: String? = nil
    /// When true, shows a small star badge on the icon circle.
    var isPremium: Bool = false

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private var iconColor: Color { colorScheme == .dark ? AppTheme.accentText : AppTheme.primaryText }

    var body: some View {
        HStack(spacing: AppConstants.Spacing.tight) {
            // Icon with optional premium badge
            ZStack(alignment: .topTrailing) {
                ZStack {
                    Circle()
                        .strokeBorder(iconColor.opacity(0.45), lineWidth: 1)
                        .frame(width: 40, height: 40)

                    Image(systemName: systemImage)
                        .font(.system(size: AppConstants.FontSizes.subheadline, weight: .semibold))
                        .foregroundColor(iconColor)
                        .accessibilityHidden(true)
                }

                // Small star badge for premium rows (replaces emoji in title)
                if isPremium {
                    Image(systemName: "star.fill")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(AppTheme.goldAccent)
                        .frame(width: 14, height: 14)
                        .background(
                            Circle()
                                .fill(cardBackground)
                                .shadow(color: .black.opacity(0.08), radius: 1, x: 0, y: 1)
                        )
                        .offset(x: 3, y: -3)
                        .accessibilityHidden(true)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                    .foregroundColor(AppTheme.primaryText)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)

                if let subtitle = subtitle {
                    HStack(spacing: 4) {
                        Text(subtitle)
                        if let iconName = subtitleTrailingIcon {
                            Image(systemName: iconName)
                                .font(.system(size: AppConstants.FontSizes.callout - 2, weight: .semibold))
                        }
                    }
                    .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.callout))
                    .foregroundColor(subtitleColor ?? AppTheme.secondaryText)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                }
            }

            Spacer(minLength: 0)
        }
        // Increased vertical padding for better tap targets (≥ 44pt)
        .padding(.vertical, 14)
        .padding(.horizontal, AppConstants.Spacing.ornament)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(cardBackground.opacity(0.96))
                .shadow(color: .black.opacity(0.10), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.primaryText.opacity(0.10), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

// MARK: - SupportView

struct SupportView: View {
    @Environment(\.dismiss) private var dismiss
    private let cardBackground = AppConstants.Colors.capsuleButton

    var body: some View {
        ZStack {
            AppTheme.backgroundColor.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: AppConstants.Spacing.ornament) {

                    // ── Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("We're here to help.")
                            .font(.custom("Iowan Old Style", size: 28))
                            .foregroundColor(AppTheme.primaryText)

                        Text("Reach out anytime, or review our policies below. We designed this app to respect your privacy and keep things simple.")
                            .font(.custom("Iowan Old Style", size: 16))
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    .padding(.bottom, AppConstants.Spacing.tight)

                    // ── Get Support
                    Button(action: {
                        if let url = URL(string: "https://wearemagic.life/support") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        SupportSectionCard(
                            title: "Get Support",
                            subtitle: "Reach us at wearemagic.life/support",
                            cardBackground: cardBackground
                        )
                    }
                    .buttonStyle(.plain)

                    // ── Our Policies
                    NavigationLink {
                        LegalLinksView()
                    } label: {
                        SupportSectionCard(
                            title: "Our Policies",
                            subtitle: "Privacy Policy, Terms of Service & more",
                            cardBackground: cardBackground
                        )
                    }
                    .buttonStyle(.plain)

                    Spacer(minLength: AppConstants.Spacing.cardPadding)
                }
                .padding(.horizontal, AppConstants.Spacing.cardPadding)
                .padding(.top, AppConstants.Spacing.pageInset)
                .padding(.bottom, AppConstants.Spacing.section)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20))
                        .foregroundColor(AppTheme.primaryText)
                        .frame(width: AppConstants.ButtonSizes.closeButton, height: AppConstants.ButtonSizes.closeButton)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")
                .accessibilityHint("Returns to settings")
            }
        }
        .toolbarBackground(AppTheme.backgroundColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

private struct SupportSectionCard: View {
    let title: String
    let subtitle: String
    let cardBackground: Color

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.custom("Iowan Old Style", size: 18))
                .foregroundColor(AppTheme.primaryText)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
            Text(subtitle)
                .font(.custom("Iowan Old Style", size: 14))
                .foregroundColor(AppTheme.secondaryText)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
        }
        .padding(AppConstants.Spacing.tight)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(cardBackground.opacity(0.96))
                .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.primaryText.opacity(0.10), lineWidth: 1)
        )
    }
}

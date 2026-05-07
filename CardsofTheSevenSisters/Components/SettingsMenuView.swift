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
    private var hasRated: Bool {
        UserDefaults.standard.bool(forKey: "hasRatedApp")
    }

    private var safeAreaTop: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.top ?? 59
    }

    private var safeAreaBottom: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.bottom ?? 0
    }

    // Adaptive card background for light/dark mode
    private let cardBackground = AppConstants.Colors.capsuleButton

    var body: some View {
        ZStack {
            // Dimmed backdrop — tap to dismiss
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            // Settings panel
            VStack {
                NavigationStack {
                ZStack {
                    AppTheme.backgroundColor.ignoresSafeArea()

                    ScrollView {
                        VStack(spacing: AppConstants.Spacing.ornament) {
                            VStack(spacing: AppConstants.Spacing.tight) {
                            // MARK: Manage Profile
                            Button { showingProfile = true } label: {
                                SettingsRow(
                                    systemImage: "person.crop.circle",
                                    title: "Your Profile",
                                    subtitle: "Update, Sign Out, or Delete",
                                    cardBackground: cardBackground
                                )
                            }
                            .buttonStyle(.plain)
                            .sheet(isPresented: $showingProfile) {
                                ProfileSheet(onDismissAll: { isPresented = false })
                            }

                            // MARK: Learn
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

                            // MARK: Subscription
                            NavigationLink {
                                SubscriptionView()
                                    .environmentObject(subscriptionManager)
                            } label: {
                                SettingsRow(
                                    systemImage: "star.fill",
                                    title: "Subcribe Today",
                                    subtitle: "Unlock All ⭐️ Features",
                                    cardBackground: cardBackground,
                                    subtitleColor: subscriptionManager.isSubscribed ? AppTheme.goldAccent : nil
                                )
                            }

                            // MARK: Gold Benefits
                            VStack(spacing: AppConstants.Spacing.tight) {
                                NavigationLink {
                                    AppearanceSettingsView()
                                } label: {
                                    SettingsRow(
                                        systemImage: "moon.fill",
                                        title: "⭐ Appearance",
                                        subtitle: "New Black & Gold Theme!",
                                        cardBackground: cardBackground
                                    )
                                }

                                NavigationLink {
                                    CalendarSyncView()
                                } label: {
                                    SettingsRow(
                                        systemImage: "calendar.badge.plus",
                                        title: "⭐ Sync to Calendar",
                                        subtitle: "See beyond tomorrow",
                                        cardBackground: cardBackground
                                    )
                                }

                                NavigationLink {
                                    WidgetInfoView()
                                } label: {
                                    SettingsRow(
                                        systemImage: "rectangle.stack",
                                        title: "⭐ Get the Widget",
                                        subtitle: "Your Current Cards in view",
                                        cardBackground: cardBackground
                                    )
                                }
                            }

                            // MARK: Notifications
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
                            .padding(AppConstants.Spacing.tight)
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
                        .padding(.horizontal, AppConstants.Spacing.pageInset)
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
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppTheme.primaryText)
                                .frame(width: 32, height: 32)
                                .background(AppConstants.Colors.capsuleButton)
                                .clipShape(Circle())
                                .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Close settings")
                        .accessibilityHint("Returns to home screen")
                    }
                }
                .toolbarBackground(AppTheme.backgroundColor, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(.none, for: .navigationBar)
                .onAppear {
                    // Remove the hairline separator below the navigation bar
                    let appearance = UINavigationBarAppearance()
                    appearance.configureWithOpaqueBackground()
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
                .alert("Thank you for rating! ⭐️", isPresented: $showingAppStorePrompt) {
                    Button("Write a Review") {
                        if let url = URL(string: "itms-apps://apps.apple.com/ca/app/cards-of-the-seven-sisters/id6753740480?action=write-review") {
                            UIApplication.shared.open(url)
                        }
                    }
                    Button("No Thanks", role: .cancel) { }
                } message: {
                    Text("Would you like to write a review on the App Store? It only takes a moment.")
                }
            }  // NavigationStack
            .background(AppTheme.backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.modal))
            .shadow(color: Color(red: 1.0, green: 0.95, blue: 0.88).opacity(0.12), radius: 120, x: 0, y: 0)
            }  // VStack
            .padding(.horizontal, 28)
            .padding(.top, safeAreaTop + 8)
            .padding(.bottom, 8)
        }  // ZStack (backdrop + panel)
        .animation(.spring(response: AppConstants.Animation.springResponse, dampingFraction: AppConstants.Animation.springDamping), value: isPresented)
    }

    private func rateApp() {
        if hasRated {
            showingVisitListingPrompt = true
        } else {
            UserDefaults.standard.set(true, forKey: "hasRatedApp")
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

private struct SettingsRow: View {
    let systemImage: String
    let title: String
    let subtitle: String?
    let cardBackground: Color
    var subtitleColor: Color? = nil

    var body: some View {
        HStack(spacing: AppConstants.Spacing.ornament) {
            ZStack {
                Circle()
                    .strokeBorder(AppTheme.primaryText.opacity(0.25), lineWidth: 1)
                    .frame(width: 40, height: 40)

                Image(systemName: systemImage)
                    .font(.system(size: AppConstants.FontSizes.subheadline, weight: .semibold))
                    .foregroundColor(AppTheme.primaryText)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                    .foregroundColor(AppTheme.primaryText)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.callout))
                        .foregroundColor(subtitleColor ?? AppTheme.secondaryText)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer()
        }
        .padding(.vertical, AppConstants.Spacing.small)
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
                    Text("We're here to help.")
                        .font(.custom("Iowan Old Style", size: 28))
                        .foregroundColor(AppTheme.primaryText)
                        .padding(.bottom, AppConstants.Spacing.tight)

                    Text("Reach out anytime, or review our policies below. We designed this app to respect your privacy and keep things simple.")
                        .font(.custom("Iowan Old Style", size: 16))
                        .foregroundColor(AppTheme.secondaryText)
                        .padding(.bottom, AppConstants.Spacing.tight)

                    // Get Support
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

                    // Our Policies
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
                        .frame(width: AppConstants.ButtonSizes.backButton, height: AppConstants.ButtonSizes.backButton)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.custom("Iowan Old Style", size: 18))
                .foregroundColor(AppTheme.primaryText)
            Text(subtitle)
                .font(.custom("Iowan Old Style", size: 14))
                .foregroundColor(AppTheme.secondaryText)
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


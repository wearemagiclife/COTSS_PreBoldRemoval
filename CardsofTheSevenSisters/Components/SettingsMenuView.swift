import SwiftUI
import StoreKit

struct SettingsMenuView: View {
    @Binding var isPresented: Bool

    @ObservedObject private var authManager = AuthenticationManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared

    @State private var showingDeleteAccountAlert = false
    @State private var showingProfile = false
    @State private var showingSignedOutBanner = false
    @State private var showingDeletedBanner = false
    @State private var showingAppStorePrompt = false
    @State private var showingVisitListingPrompt = false

    @Environment(\.requestReview) private var requestReview
    private var hasRated: Bool {
        UserDefaults.standard.bool(forKey: "hasRatedApp")
    }

    private var safeAreaTop: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.top ?? 0
    }

    // Adaptive card background for light/dark mode
    private let cardBackground = AppConstants.Colors.capsuleButton

    var body: some View {
        ZStack {
            // Dimmed backdrop — tap to dismiss
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            // Settings panel — inset on all 4 sides, same as CardDetailModalView
            NavigationStack {
                ZStack {
                    AppTheme.backgroundColor.ignoresSafeArea()

                    ScrollView {
                        VStack(spacing: AppConstants.Spacing.cardPadding) {
                            VStack(spacing: AppConstants.Spacing.tight) {
                            Button { showingProfile = true } label: {
                                SettingsRow(
                                    systemImage: "person.crop.circle",
                                    title: "Profile",
                                    subtitle: "Make Changes",
                                    cardBackground: cardBackground
                                )
                            }
                            .buttonStyle(.plain)
                            .sheet(isPresented: $showingProfile) {
                                ProfileSheet()
                            }

                            NavigationLink {
                                SubscriptionView()
                                    .environmentObject(subscriptionManager)
                            } label: {
                                SettingsRow(
                                    systemImage: "star.fill",
                                    title: "Subscription",
                                    subtitle: subscriptionManager.isSubscribed ? "Active — thank you!" : "Support the Seven Sisters",
                                    cardBackground: cardBackground,
                                    subtitleColor: subscriptionManager.isSubscribed ? AppTheme.goldAccent : nil
                                )
                            }

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

                            NavigationLink {
                                AppearanceSettingsView()
                            } label: {
                                SettingsRow(
                                    systemImage: "moon.fill",
                                    title: "Appearance",
                                    subtitle: "Light, Dark, or System",
                                    cardBackground: cardBackground
                                )
                            }

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

                            NavigationLink {
                                LegalLinksView()
                            } label: {
                                SettingsRow(
                                    systemImage: "doc.text.magnifyingglass",
                                    title: "Legal",
                                    subtitle: "Our Policies & Terms",
                                    cardBackground: cardBackground
                                )
                            }

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

                            Button {
                                openWebsite()
                            } label: {
                                SettingsRow(
                                    systemImage: "globe",
                                    title: "Need Support?",
                                    subtitle: "wearemagic.life/support",
                                    cardBackground: cardBackground
                                )
                            }

                            // SIGN OUT BUTTON
                            Button {
                                showingSignedOutBanner = true
                                Task {
                                    try? await Task.sleep(for: .seconds(1.5))
                                    authManager.signOut()
                                    DataManager.shared.clearProfile()
                                    isPresented = false
                                }
                            } label: {
                                SettingsRow(
                                    systemImage: "rectangle.portrait.and.arrow.right",
                                    title: DataManager.shared.isGuestMode ? "Exit Guest Mode" : "Sign Out",
                                    subtitle: DataManager.shared.isGuestMode ? "Return to sign in screen" : "Sign out of your account",
                                    cardBackground: cardBackground
                                )
                            }

                            // DELETE ACCOUNT BUTTON - only show for non-guests
                            if !DataManager.shared.isGuestMode {
                                Button {
                                    showingDeleteAccountAlert = true
                                } label: {
                                    SettingsRow(
                                        systemImage: "trash",
                                        title: "Delete Account",
                                        subtitle: "Permanently delete all data",
                                        cardBackground: cardBackground
                                    )
                                }
                            }

                        }  // inner VStack (settings rows)
                        .padding(.horizontal, AppConstants.Spacing.cardPadding)
                        .padding(.bottom, AppConstants.Spacing.section)
                        }  // outer VStack
                    }  // ScrollView
                }  // ZStack (background + ScrollView)
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { isPresented = false }) {
                            if UIScreen.main.bounds.height < 700 {
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppTheme.primaryText)
                                    .frame(width: 28, height: 28)
                                    .background(AppConstants.Colors.capsuleButton)
                                    .clipShape(Circle())
                                    .contentShape(Circle())
                            } else {
                                Image(systemName: "xmark")
                                    .font(.system(size: 20))
                                    .foregroundColor(AppTheme.primaryText)
                                    .frame(width: AppConstants.ButtonSizes.closeButton, height: AppConstants.ButtonSizes.closeButton)
                                    .contentShape(Rectangle())
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Close settings")
                        .accessibilityHint("Returns to home screen")
                    }
                }
                .toolbarBackground(AppTheme.backgroundColor, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
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
                .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Delete Account", role: .destructive) {
                        showingDeletedBanner = true
                        Task {
                            try? await Task.sleep(for: .seconds(1.5))
                            authManager.deleteAccount()
                            isPresented = false
                        }
                    }
                } message: {
                    Text("This will permanently delete your account and all associated data — including your profile, preferences, and card history. This action cannot be undone.")
                }
            }  // NavigationStack
            .background(AppTheme.backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.modal))
            .shadow(color: Color(red: 1.0, green: 0.95, blue: 0.88).opacity(0.12), radius: 120, x: 0, y: 0)
            .padding(.horizontal, AppConstants.Spacing.pageInset)
            .padding(.bottom, AppConstants.Spacing.pageInset)
            .padding(.top, safeAreaTop + AppConstants.Spacing.pageInset)
        if showingSignedOutBanner {
            VStack {
                Spacer()
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppTheme.goldAccent)
                    Text(DataManager.shared.isGuestMode ? "Exited guest mode" : "Signed out successfully")
                        .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                        .foregroundColor(AppTheme.primaryText)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(AppTheme.cardBackground)
                .cornerRadius(14)
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                .padding(.bottom, 48)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            .zIndex(30)
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: showingSignedOutBanner)
        }
        if showingDeletedBanner {
            VStack {
                Spacer()
                HStack(spacing: 10) {
                    Image(systemName: "trash.circle.fill")
                        .foregroundColor(.red.opacity(0.8))
                    Text("Account permanently deleted")
                        .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                        .foregroundColor(AppTheme.primaryText)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(AppTheme.cardBackground)
                .cornerRadius(14)
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                .padding(.bottom, 48)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            .zIndex(30)
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: showingDeletedBanner)
        }
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

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                    .foregroundColor(AppTheme.primaryText)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.callout))
                        .foregroundColor(subtitleColor ?? AppTheme.secondaryText)
                }
            }

            Spacer()
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
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

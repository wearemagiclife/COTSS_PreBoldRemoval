import SwiftUI

struct SettingsMenuView: View {
    @Binding var isPresented: Bool

    @ObservedObject private var authManager = AuthenticationManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared

    @State private var showingDeleteAccountAlert = false
    @State private var showingRateApp = false

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
                            Text("Settings")
                                .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.dynamicBody))
                                .foregroundColor(AppTheme.primaryText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, AppConstants.Spacing.tight)

                        VStack(spacing: AppConstants.Spacing.tight) {
                            NavigationLink {
                                ProfileSheet()
                            } label: {
                                SettingsRow(
                                    systemImage: "person.crop.circle",
                                    title: "Profile",
                                    subtitle: "Make Changes",
                                    cardBackground: cardBackground
                                )
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
                                showingRateApp = true
                            } label: {
                                SettingsRow(
                                    systemImage: "star.bubble",
                                    title: "Rate the App",
                                    subtitle: "Share your experience",
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
                                if DataManager.shared.isGuestMode {
                                    DataManager.shared.clearProfile()
                                } else {
                                    authManager.signOut()
                                }
                                isPresented = false
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
                .sheet(isPresented: $showingRateApp) {
                    NavigationStack {
                        RateAppView()
                    }
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                }
                .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Delete", role: .destructive) {
                        authManager.deleteAccount()
                        isPresented = false
                    }
                } message: {
                    Text("This will permanently delete all your data including your profile, preferences, and card history. This action cannot be undone.")
                }
            }  // NavigationStack
            .background(AppTheme.backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.modal))
            .shadow(color: Color(red: 1.0, green: 0.95, blue: 0.88).opacity(0.12), radius: 120, x: 0, y: 0)
            .padding(AppConstants.Spacing.pageInset)
        }  // ZStack (backdrop + panel)
        .animation(.spring(response: AppConstants.Animation.springResponse, dampingFraction: AppConstants.Animation.springDamping), value: isPresented)
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

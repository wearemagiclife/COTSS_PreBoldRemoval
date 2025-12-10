import SwiftUI

struct SettingsMenuView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject private var authManager = AuthenticationManager.shared

    @State private var showingDeleteAccountAlert = false

    // Adaptive card background for light/dark mode
    private let cardBackground = AppConstants.Colors.capsuleButton

    var body: some View {
        NavigationStack {
            ZStack {
                // Full-screen app background
                Color.appLaunchBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppConstants.Spacing.cardPadding) {
                        Text("Settings")
                            .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.title))
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
                                    subtitle: "Need to change your details?",
                                    cardBackground: cardBackground
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
                                    subtitle: "Never miss your Daily Card",
                                    cardBackground: cardBackground
                                )
                            }

                            NavigationLink {
                                LegalLinksView()
                            } label: {
                                SettingsRow(
                                    systemImage: "doc.text.magnifyingglass",
                                    title: "Legal",
                                    subtitle: "Privacy, Terms, & Data Deletion",
                                    cardBackground: cardBackground
                                )
                            }

                            Button {
                                openWebsite()
                            } label: {
                                SettingsRow(
                                    systemImage: "globe",
                                    title: "Need Support?",
                                    subtitle: "www.wearemagic.life/support",
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
                                dismiss()
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

                        }
                    }
                    .padding(.horizontal, AppConstants.Spacing.cardPadding)
                    .padding(.bottom, AppConstants.Spacing.section)
                }
            }
            .navigationTitle("") // we'll style our own header
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
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
            // Match nav bar to background so it doesn't show as a gray bar
            .toolbarBackground(Color.appLaunchBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    authManager.deleteAccount()
                    dismiss()
                }
            } message: {
                Text("This will permanently delete all your data including your profile, preferences, and card history. This action cannot be undone.")
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
                        .foregroundColor(AppTheme.secondaryText)
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

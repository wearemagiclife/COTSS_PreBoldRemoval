import SwiftUI

struct SettingsMenuView: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var authManager = AuthenticationManager.shared

    // Reuse the same parchment tone you use elsewhere
    private let cardBackground = Color(red: 0.95, green: 0.91, blue: 0.82)

    var body: some View {
        NavigationStack {
            ZStack {
                // Full-screen app background
                Color.appLaunchBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        Text("Settings")
                            .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.title))
                            .foregroundColor(AppTheme.primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 8)

                        VStack(spacing: 14) {
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
                                authManager.signOut()
                                dismiss()
                            } label: {
                                SettingsRow(
                                    systemImage: "rectangle.portrait.and.arrow.right",
                                    title: "Sign Out",
                                    subtitle: "Sign out of your account",
                                    cardBackground: cardBackground
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("") // we'll style our own header
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(cardBackground.opacity(0.9))
                            )
                            .foregroundColor(AppTheme.primaryText)
                    }
                }
            }
            // Match nav bar to background so it doesn't show as a gray bar
            .toolbarBackground(Color.appLaunchBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .strokeBorder(AppTheme.primaryText.opacity(0.25), lineWidth: 1)
                    .frame(width: 40, height: 40)

                Image(systemName: systemImage)
                    .font(.system(size: AppConstants.FontSizes.subheadline, weight: .semibold))
                    .foregroundColor(AppTheme.primaryText)
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
        .padding(14)
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

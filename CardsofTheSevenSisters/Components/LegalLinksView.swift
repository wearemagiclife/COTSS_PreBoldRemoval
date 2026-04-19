import SwiftUI

struct LegalLinksView: View {
    @Environment(\.dismiss) private var dismiss
    private let cardBackground = AppConstants.Colors.capsuleButton

    var body: some View {
        ZStack {
            Color.appLaunchBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: AppConstants.Spacing.ornament) {
                    Text("We believe in your right to Data Autonomy.")
                        .font(.custom("Iowan Old Style", size: 28))
                        .foregroundColor(AppTheme.primaryText)
                        .padding(.bottom, AppConstants.Spacing.tight)

                    Text("Out of respect, we designed this app to never receive any of your personally identifying information or profit from your data. We may receive anonymous logs regarding this app only for diagnostics (only if you have agree to this). We tried to make all of our agreements and policies as human friendly as possible. Feel free to contact us at support@wearemagic.life.")
                        .font(.custom("Iowan Old Style", size: 16))
                        .foregroundColor(AppTheme.secondaryText)
                        .padding(.bottom, AppConstants.Spacing.tight)

                    LegalLinkCard(
                        title: "Privacy Policy",
                        subtitle: "We take your Right to Privacy seriously.",
                        url: "https://www.wearemagic.life/privacy-policy",
                        cardBackground: cardBackground
                    )

                    LegalLinkCard(
                        title: "Terms of Service",
                        subtitle: "Clear terms for a better future",
                        url: "https://www.wearemagic.life/terms-of-service",
                        cardBackground: cardBackground
                    )

                    LegalLinkCard(
                        title: "Copyright & Licensing",
                        subtitle: "Setting healthy boundaries for our art",
                        url: "https://www.wearemagic.life/copyright-licensing",
                        cardBackground: cardBackground
                    )

                    LegalLinkCard(
                        title: "Data Deletion Policy",
                        subtitle: "Just say the word",
                        url: "https://www.wearemagic.life/data-deletion-policy",
                        cardBackground: cardBackground
                    )

                    LegalLinkCard(
                        title: "EULA",
                        subtitle: "Apple's End User Licensing Agreement",
                        url: "https://www.wearemagic.life/eula",
                        cardBackground: cardBackground
                    )

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
        .toolbarBackground(Color.appLaunchBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

private struct LegalSectionCard: View {
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

private struct LegalLinkCard: View {
    let title: String
    let subtitle: String
    let url: String
    let cardBackground: Color

    var body: some View {
        Button(action: openURL) {
            LegalSectionCard(
                title: title,
                subtitle: subtitle,
                cardBackground: cardBackground
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("View \(title)")
        .accessibilityHint("Opens document in browser")
    }

    private func openURL() {
        guard let link = URL(string: url) else { return }
        UIApplication.shared.open(link)
    }
}

import SwiftUI

struct LegalLinksView: View {
    private let cardBackground = Color(red: 0.95, green: 0.91, blue: 0.82)

    var body: some View {
        ZStack {
            Color.appLaunchBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("We believe in your right to Data Autonomy.")
                        .font(.custom("Iowan Old Style", size: 28))
                        .foregroundColor(AppTheme.primaryText)
                        .padding(.bottom, 8)

                    Text("Out of respect, we designed this app to never receive any of your personally identifying information, or to profit from it. We receive anonymous logs for diagnostics. We tried to make these as human friendly as possible, and are available to answer any questions you may have at support@wearemagic.life.")
                        .font(.custom("Iowan Old Style", size: 16))
                        .foregroundColor(AppTheme.secondaryText)
                        .padding(.bottom, 12)

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

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Legal")
        .navigationBarTitleDisplayMode(.inline)
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
    }

    private func openURL() {
        guard let link = URL(string: url) else { return }
        UIApplication.shared.open(link)
    }
}

import SwiftUI

struct LearnView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showTutorial = false

    // Match SettingsMenuView button color
    private let cardBackground = AppConstants.Colors.capsuleButton

    var body: some View {
        ZStack {
            Color.appLaunchBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: AppConstants.Spacing.ornament) {
                    Text("Get to know The Cards")
                        .font(.custom("Iowan Old Style", size: 28))
                        .foregroundColor(AppTheme.primaryText)
                        .padding(.bottom, AppConstants.Spacing.tight)

                    Text("Our app starts with your Birth Card, then explore the cards that influence your Yearly Cycle, 52-Day Cycles, and your Daily Card—a clear rhythm you can actually work with.")
                        .font(.custom("Iowan Old Style", size: 16))
                        .foregroundColor(AppTheme.secondaryText)
                        .padding(.bottom, AppConstants.Spacing.tight)

                    // Restart tutorial button
                    Button(action: {
                        showTutorial = true
                    }) {
                        LearnSectionCard(
                            title: "Restart Tutorial",
                            subtitle: "Replay the Welcome Tutorial.",
                            cardBackground: cardBackground
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Restart Tutorial")
                    .accessibilityHint("Replay the welcome tutorial")
                    .sheet(isPresented: $showTutorial) {
                        OnboardingTutorialViewWrapper(
                            isPresented: $showTutorial,
                            birthCard: DataManager.shared.getCard(by: 1),
                            solarCard: DataManager.shared.getCard(by: 2),
                            fiftytwoCard: DataManager.shared.getCard(by: 3),
                            dailyCard: DataManager.shared.getCard(by: 4),
                            userName: "You",
                            onComplete: {
                                showTutorial = false
                            }
                        )
                    }

                    // Web link cards
                    LearnLinkCard(
                        title: "About Cardology",
                        subtitle: "A Celestial Calendar in the Cards",
                        url: "https://www.wearemagic.life/about-cardology",
                        cardBackground: cardBackground
                    )

                    LearnLinkCard(
                        title: "The Seven Sisters",
                        subtitle: "The Stars That Guide",
                        url: "https://www.wearemagic.life/cards-of-the-seven-sisters",
                        cardBackground: cardBackground
                    )

                    LearnLinkCard(
                        title: "Your Daily Card",
                        subtitle: "A Quick Forecast & Point of Focus",
                        url: "https://www.wearemagic.life/destiny-card-readings#daily-card",
                        cardBackground: cardBackground
                    )

                    LearnLinkCard(
                        title: "Your 52-Day Cycle",
                        subtitle: "7 Rhythms Each Year",
                        url:"https://www.wearemagic.life/destiny-card-readings#52-day-card-fiftytwocycle",
                        cardBackground: cardBackground
                    )

                    LearnLinkCard(
                        title: "Your Yearly Cycle",
                        subtitle: "Sets an Annual Focus",
                        url:"https://www.wearemagic.life/destiny-card-readings#yearly-card-solarcycle",
                        cardBackground: cardBackground
                    )

                    LearnLinkCard(
                        title: "The Planetary Influences",
                        subtitle: "Sitting with the Seven Planets",
                        url:"https://www.wearemagic.life/planetary-influences",
                        cardBackground: cardBackground
                    )

                    LearnLinkCard(
                        title: "The Card Spreads",
                        subtitle: "Meeting the Fractal Math Behind it",
                        url:"https://www.wearemagic.life/the-life-spread",
                        cardBackground: cardBackground
                    )

                    LearnLinkCard(
                        title: "The Story of Numbers",
                        subtitle: "Ancient Traditions of the Cosmos",
                        url:"https://www.wearemagic.life/numbers",
                        cardBackground: cardBackground
                    )

                    Spacer(minLength: AppConstants.Spacing.cardPadding)
                }
                .padding(.horizontal, AppConstants.Spacing.cardPadding)
                .padding(.top, AppConstants.Spacing.pageInset)
                .padding(.bottom, AppConstants.Spacing.section)
            }
        }
        .navigationTitle("Learn")
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

// MARK: - LearnSectionCard

private struct LearnSectionCard: View {
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

// MARK: - LearnLinkCard

private struct LearnLinkCard: View {
    let title: String
    let subtitle: String
    let url: String
    let cardBackground: Color

    var body: some View {
        Button(action: openURL) {
            LearnSectionCard(
                title: title,
                subtitle: subtitle,
                cardBackground: cardBackground
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Learn about \(title)")
        .accessibilityHint("Opens article in browser")
    }

    private func openURL() {
        guard let link = URL(string: url) else { return }
        UIApplication.shared.open(link)
    }
}

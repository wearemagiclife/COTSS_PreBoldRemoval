import SwiftUI

struct LifeSpreadView: View {

    // MARK: - State / Managers

    @ObservedObject private var dataManager = DataManager.shared
    @StateObject private var calculator = CardCalculationService()
    @Environment(\.presentationMode) var presentationMode

    @State private var showCardDetail = false
    @State private var detailCard: Card? = nil
    @State private var isKarmaCard = false
    @State private var karmaDescription = ""

    // MARK: - Calendar

    private var userCalendar: Calendar {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        return calendar
    }

    // MARK: - Core Cards

    private var birthCard: Card {
        let components = userCalendar.dateComponents([.month, .day],
                                                     from: dataManager.userProfile.birthDate)

        let cardId = BirthCardLookup.shared.calculateCardForDate(
            monthValue: components.month ?? 1,
            dayValue: components.day ?? 1
        )

        return dataManager.getCard(by: cardId)
    }

    private var birthCardTitle: String {
        if let def = getCardDefinition(by: birthCard.id) {
            return def.name
        }
        return birthCard.name
    }

    private var birthCardSubtitle: String {
        if let def = getCardDefinition(by: birthCard.id) {
            return def.title.lowercased()
        }
        return ""
    }

    private var birthCardDescription: String {
        let repo = DescriptionRepository.shared
        return repo.birthDescriptions[String(birthCard.id)] ?? "No description available."
    }

    private var birthDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: dataManager.userProfile.birthDate)
    }

    // MARK: - Page Title (Navigation)

    private var lifeSpreadTitle: String {
        if showCardDetail {
            if isKarmaCard, let card = detailCard {
                if karma1CardIds.contains(card.id) {
                    return "First Karma Card"
                } else if karma2CardIds.contains(card.id) {
                    return "Second Karma Card"
                } else {
                    return "Karma Cards"
                }
            } else {
                return "Your Birth Card"
            }
        }
        return "Your Life Spread"
    }

    // MARK: - Karma Connections

    private var karmaConnections: [KarmaConnection] {
        dataManager.getKarmaConnections(for: birthCard.id)
    }

    private var karma1CardIds: [Int] {
        guard let first = karmaConnections.first else { return [] }
        return first.cards
    }

    private var karma2CardIds: [Int] {
        guard karmaConnections.count > 1 else { return [] }
        return karmaConnections[1].cards
    }

    private var allKarmaCards: [Card] {
        let ids = karma1CardIds + karma2CardIds
        return ids.compactMap { dataManager.getCard(by: $0) }
    }

    private var firstKarmaCard: Card? {
        if let id = karma1CardIds.first {
            return dataManager.getCard(by: id)
        }
        return allKarmaCards.first
    }

    private var karmaCardTitle: String {
        guard let karmaCard = firstKarmaCard else { return "" }
        if let def = getCardDefinition(by: karmaCard.id) {
            return def.name
        }
        return karmaCard.name
    }

    private var karmaCardDescription: String {
        guard let karmaCard = firstKarmaCard else { return "" }

        let repo = DescriptionRepository.shared
        let idStr = String(karmaCard.id)

        if karma1CardIds.contains(karmaCard.id),
           let desc = repo.karmaCard1Descriptions[idStr] {
            return desc
        }

        if karma2CardIds.contains(karmaCard.id),
           let desc = repo.karmaCard2Descriptions[idStr] {
            return desc
        }

        return "No description available."
    }

    // These arrays are used for *both* the on-screen layout and the share sheet.

    private var karma1Cards: [Card] {
        karma1CardIds.compactMap { dataManager.getCard(by: $0) }
    }

    private var karma2Cards: [Card] {
        karma2CardIds.compactMap { dataManager.getCard(by: $0) }
    }

    // MARK: - Helpers used by share button (NEW – logic only)

    private func spreadType(for card: Card) -> String {
        if !isKarmaCard {
            return "Your Birth Card"
        }
        if karma1CardIds.contains(card.id) {
            return "First Karma Card"
        }
        if karma2CardIds.contains(card.id) {
            return "Second Karma Card"
        }
        return "Karma Card"
    }

    private func titleForCard(_ card: Card) -> String {
        if let def = getCardDefinition(by: card.id) {
            return def.name
        }
        return card.name
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color(red: 0.86, green: 0.77, blue: 0.57)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppConstants.Spacing.sectionSpacing) {
                    mainTitleSection
                    birthCardSection

                    if !allKarmaCards.isEmpty {
                        karmaConnectionsSection
                    }

                    if !allKarmaCards.isEmpty {
                        LineBreak("linedesignd", width: UIScreen.main.bounds.width * 0.65)
                            .padding(.top, AppConstants.Spacing.sectionSpacing / 2)
                            .padding(.bottom, AppConstants.Spacing.large)
                    }
                }
                .padding(.horizontal, AppConstants.Spacing.medium)
                .padding(.vertical, AppConstants.Spacing.large)
            }

            if showCardDetail, let card = detailCard {
                CardDetailModalView(
                    card: card,
                    cardType: .birth,
                    contentType: isKarmaCard ? .karma(karmaDescription) : nil,
                    isPresented: $showCardDetail
                )
                .zIndex(10)
            }
        }
        .onAppear {
            RatingService.shared.trackBirthCardView()
        }
        .standardNavigation(
            title: lifeSpreadTitle,
            hasBackButton: true,
            backAction: {
                if showCardDetail {
                    withAnimation(.spring(
                        response: AppConstants.Animation.springResponse,
                        dampingFraction: AppConstants.Animation.springDamping
                    )) {
                        showCardDetail = false
                    }
                } else {
                    presentationMode.wrappedValue.dismiss()
                }
            },
            trailingContent: {
                AnyView(
                    Group {
                        // 1. If a card detail is open, share THAT card
                        if showCardDetail, let card = detailCard {
                            BirthCardShareButton(
                                card: card,
                                cardTitle: titleForCard(card),
                                cardDescription: isKarmaCard ? karmaDescription : birthCardDescription,
                                spreadType: spreadType(for: card),
                                subtitle: birthDateString
                            )

                        // 2. Otherwise, we're on the spread
                        } else if firstKarmaCard != nil {
                            LifeSpreadShareButton(
                                birthCard: birthCard,
                                birthCardTitle: birthCardTitle,
                                birthCardSubtitle: birthCardSubtitle,
                                karma1Cards: karma1Cards,
                                karma2Cards: karma2Cards,
                                primaryKarmaTitle: karmaCardTitle,
                                primaryKarmaDescription: karmaCardDescription,
                                birthDate: dataManager.userProfile.birthDate,
                                userName: dataManager.userProfile.name
                            )

                        // 3. No karma cards – single birth card share
                        } else {
                            BirthCardShareButton(
                                card: birthCard,
                                cardTitle: birthCardTitle,
                                cardDescription: birthCardDescription,
                                spreadType: "Your Birth Card",
                                subtitle: birthDateString
                            )
                        }
                    }
                )
            }
        )
    }

    // MARK: - Main Section (Page Header)
    
    private var mainTitleSection: some View {
        VStack(spacing: AppConstants.Spacing.titleSpacing) {
            // "YOUR BIRTH CARD" as main title
            
            Text("YOUR BIRTH CARD")
                .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.headline))
                .fontWeight(.heavy)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
            
            Text("this is your main archetypal influence")
                .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        
    
        .padding(.top, AppConstants.Spacing.small)
    }

    private var birthCardSection: some View {
        HStack {
            Spacer()
            TappableCard(
                card: birthCard,
                size: CGSize(
                    width: AppConstants.CardSizes.largeWidth * 1.1,
                    height: AppConstants.CardSizes.largeWidth * 1.1 * AppConstants.CardSizes.aspect
                ),
                action: showBirthCard
            )
            Spacer()
        }
    }

    // MARK: - Karma Section

    private var karmaConnectionsSection: some View {
        let width = UIScreen.main.bounds.width
        let innerSpacing: CGFloat = 10

        let firstCards = karma1Cards
        let secondCards = karma2Cards

        let hasFirst = !firstCards.isEmpty
        let hasSecond = !secondCards.isEmpty

        return VStack(spacing: AppConstants.Spacing.sectionSpacing) {
            // Top decorative line
            LineBreak("linedesign", width: width * 0.7)

            // First Karma Section
            if hasFirst {
                VStack(spacing: innerSpacing) {
                    Text("First Karmic Connections")
                        .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.dynamicHeadline))
                        .fontWeight(.bold)
                        .foregroundColor(.black)

                    karmaCardsLayout(
                        cards: firstCards,
                        interCardSpacing: width * 0.04,
                        verticalSpacing: AppConstants.Spacing.sectionSpacing
                    )
                }
            }

            // Divider between sections (if both exist)
            if hasFirst && hasSecond {
                SimpleDivider(width: width * 0.7)
                    .padding(.vertical, AppConstants.Spacing.small)
            }

            // Second Karma Section
            if hasSecond {
                VStack(spacing: innerSpacing) {
                    Text("Second Karmic Connections")
                        .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.dynamicHeadline))
                        .fontWeight(.bold)
                        .foregroundColor(.black)

                    karmaCardsLayout(
                        cards: secondCards,
                        interCardSpacing: width * 0.04,
                        verticalSpacing: AppConstants.Spacing.sectionSpacing
                    )
                }
            }
        }
        .padding(.horizontal, width * 0.06)
    }

    @ViewBuilder
    private func karmaCardsLayout(
        cards: [Card],
        interCardSpacing: CGFloat,
        verticalSpacing: CGFloat
    ) -> some View {
        if cards.count == 1 {
            HStack {
                Spacer()
                TappableCard(
                    card: cards[0],
                    size: AppConstants.CardSizes.medium,
                    action: { showKarmaCard(cards[0]) }
                )
                Spacer()
            }
        } else {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: interCardSpacing),
                    GridItem(.flexible(), spacing: interCardSpacing)
                ],
                spacing: verticalSpacing
            ) {
                ForEach(cards, id: \.id) { card in
                    TappableCard(
                        card: card,
                        size: AppConstants.CardSizes.medium,
                        action: { showKarmaCard(card) }
                    )
                }
            }
        }
    }

    // MARK: - Card Taps

    private func showBirthCard() {
        detailCard = birthCard
        isKarmaCard = false
        karmaDescription = ""

        withAnimation(.easeInOut(duration: 0.3)) {
            showCardDetail = true
        }
    }

    private func showKarmaCard(_ card: Card) {
        let id = String(card.id)
        let repo = DescriptionRepository.shared

        let isKC1 = karma1CardIds.contains(card.id)
        let baseDescription = isKC1
            ? (repo.karmaCard1Descriptions[id] ?? "No description available.")
            : (repo.karmaCard2Descriptions[id] ?? "No description available.")

        // Add intro text for karma cards
        let description: String
        if isKC1 {
            let intro = "This card is your lifelong Karmic Lesson. When you notice its qualities, it may be a signal to make changes.\n\nIf you know someone born with this birth card, they are meant to receive help from you in this karmic relationship. You will both benefit from the offerings you give.\n\n"
            description = intro + baseDescription
        } else {
            let intro = "This card's qualities are a gift. When you use these natural talents, they are known to encourage positive outcomes.\n\nIf you know someone born with this birth card, you are meant to receive help in this karmic relationship. You will both benefit from the offerings they give.\n\n"
            description = intro + baseDescription
        }

        detailCard = card
        isKarmaCard = true
        karmaDescription = description

        withAnimation(.easeInOut(duration: 0.3)) {
            showCardDetail = true
        }
    }
}

#Preview {
    NavigationView {
        LifeSpreadView()
    }
}

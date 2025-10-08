import SwiftUI

struct LifeSpreadView: View {
    
    // MARK: - State / Managers
    @StateObject private var dataManager = DataManager.shared
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
        let components = userCalendar.dateComponents([.month, .day], from: dataManager.userProfile.birthDate)
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
        // If a detail modal is open, personalize by what kind of card it is
        if showCardDetail {
            // Karma card detail
            if isKarmaCard, let card = detailCard {
                if karma1CardIds.contains(card.id) {
                    return "First Karma Card"
                } else if karma2CardIds.contains(card.id) {
                    return "Second Karma Card"
                } else {
                    // Fallback if it somehow isn't in either set
                    return "Karma Cards"
                }
            } else {
                // Birth card detail
                return "Your Birth Card"
            }
        }
        
        // Overview spread
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
                        LineBreak("linedesignd")
                            .frame(width: UIScreen.main.bounds.width * 0.65)
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
        .standardNavigation(
            title: lifeSpreadTitle,    // 🔥 ALWAYS "Your Life Spread"
            backAction: {
                if showCardDetail {
                    withAnimation(.spring(
                        response: AppConstants.Animation.springResponse,
                        dampingFraction: AppConstants.Animation.springDamping
                    )) { showCardDetail = false }
                } else {
                    presentationMode.wrappedValue.dismiss()
                }
            },
            trailingContent: {
                AnyView(
                    Group {
                        if let karmaCard = firstKarmaCard {
                            LifeSpreadShareLink(
                                birthCard: birthCard,
                                birthCardTitle: birthCardTitle,
                                birthCardDescription: birthCardDescription,
                                karmaCard: karmaCard,
                                karmaCardTitle: karmaCardTitle,
                                karmaCardDescription: karmaCardDescription,
                                birthDate: dataManager.userProfile.birthDate,
                                userName: dataManager.userProfile.name,
                                headerTitle: "Your Life Spread"   // 🔥 CORRECTED
                            )
                        } else {
                            SingleCardShareLink(
                                card: birthCard,
                                cardTitle: birthCardTitle,
                                cardDescription: birthCardDescription,
                                readingType: "Your Birth Card",
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
            
            // 🔥 BIRTH CARD TITLE
            SectionHeader(
                birthCardTitle.uppercased(),
                fontSize: AppConstants.FontSizes.large
            )
            
            // 🔥 BIRTH CARD SUBTITLE
            Text(birthCardSubtitle)
                .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
        }
        .padding(.top, AppConstants.Spacing.small)
    }
    
    private var birthCardSection: some View {
        HStack {
            Spacer()
            TappableCard(
                card: birthCard,
                size: AppConstants.CardSizes.large,
                action: showBirthCard
            )
            Spacer()
        }
    }
    
    // MARK: - Karma Section
    
    private var karmaConnectionsSection: some View {
        let width = UIScreen.main.bounds.width
        let innerSpacing: CGFloat = 10
        
        let firstCards = karma1CardIds.compactMap { dataManager.getCard(by: $0) }
        let secondCards = karma2CardIds.compactMap { dataManager.getCard(by: $0) }
        
        let groups: [(title: String, cards: [Card])] = [
            ("First Karmic Connections", firstCards),
            ("Second Karmic Connections", secondCards)
        ].filter { !$0.cards.isEmpty }
        
        return VStack(spacing: AppConstants.Spacing.sectionSpacing) {
            ForEach(Array(groups.enumerated()), id: \.element.title) { index, group in
                VStack(spacing: innerSpacing) {

                    if index == 0 {
                        LineBreak("linedesign")
                            .frame(width: width * 0.23)
                    } else {
                        Rectangle()
                            .fill(AppTheme.primaryText.opacity(0.3))
                            .frame(width: width * 0.23, height: 1)
                    }

                    Text(group.title)
                        .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.dynamicHeadline))
                        .foregroundColor(.black)
                    
                    karmaCardsLayout(
                        cards: group.cards,
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
        let description =
            isKC1
            ? (repo.karmaCard1Descriptions[id] ?? "No description available.")
            : (repo.karmaCard2Descriptions[id] ?? "No description available.")
        
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

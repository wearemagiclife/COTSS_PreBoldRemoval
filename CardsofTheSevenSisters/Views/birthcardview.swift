import SwiftUI

struct BirthCardView: View {
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var calculator = CardCalculationService()
    @Environment(\.presentationMode) var presentationMode
    @State private var showCardDetail = false
    @State private var detailCard: Card? = nil
    @State private var isKarmaCard = false
    @State private var karmaDescription = ""
    
    private var userCalendar: Calendar {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        return calendar
    }
    
    private var birthCard: Card {
        let components = userCalendar.dateComponents([.month, .day], from: dataManager.userProfile.birthDate)
        let cardId = BirthCardLookup.shared.calculateCardForDate(monthValue: components.month ?? 1, dayValue: components.day ?? 1)
        return dataManager.getCard(by: cardId)
    }
    
    private var karmaConnections: [KarmaConnection] {
        dataManager.getKarmaConnections(for: birthCard.id)
    }

    private var birthCardTitle: String {
        if let def = getCardDefinition(by: birthCard.id) {
            return def.name
        }
        return birthCard.name
    }

    private var birthCardDescription: String {
        let repo = DescriptionRepository.shared
        return repo.birthDescriptions[String(birthCard.id)] ?? "No description available."
    }

    private var birthDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: dataManager.userProfile.birthDate)
    }

    // Karma card properties for sharing
    private var firstKarmaCard: Card? {
        guard let firstConnection = karmaConnections.first,
              let firstCardId = firstConnection.cards.first else {
            return nil
        }
        return dataManager.getCard(by: firstCardId)
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
        let cardId = String(karmaCard.id)
        // Use karma card 1 description for the first connection
        return repo.karmaCard1Descriptions[cardId] ?? "No description available."
    }

    var body: some View {
        ZStack {
            Color(red: 0.86, green: 0.77, blue: 0.57)
                .ignoresSafeArea(.all)
            
            ScrollView {
                VStack(spacing: AppConstants.Spacing.sectionSpacing) {
                    
                    mainTitleSection
                    birthCardSection
                    
                    LineBreak()
                    
                    if !karmaConnections.isEmpty {
                        karmaConnectionsSection
                    }
                    
                    LineBreak("linedesignd")
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
                .id("\(card.id)-\(isKarmaCard ? karmaDescription : "standard")")
            }
        }
        .standardNavigation(
            title: "Your Life Spread",
            backAction: {
                if showCardDetail {
                    withAnimation(.spring(response: AppConstants.Animation.springResponse, dampingFraction: AppConstants.Animation.springDamping)) {
                        showCardDetail = false
                    }
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
                                headerTitle: "Your Birth Card"
                            )
                        } else {
                            SingleCardShareLink(
                                card: birthCard,
                                cardTitle: birthCardTitle,
                                cardDescription: birthCardDescription,
                                readingType: "Birth Card",
                                subtitle: birthDateString
                            )
                        }
                    }
                )
            }
        )
    }
    
    private var mainTitleSection: some View {
        VStack(spacing: AppConstants.Spacing.titleSpacing) {
            SectionHeader(
                birthCard.name.uppercased(),
                fontSize: AppConstants.FontSizes.large
            )
            
            if let def = getCardDefinition(by: birthCard.id) {
                Text(def.title.lowercased())
                    .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, AppConstants.Spacing.small)
    }
    
    private var birthCardSection: some View {
        HStack(spacing: AppConstants.Spacing.cardSpacing) {
            Spacer()
            TappableCard(
                card: birthCard,
                size: AppConstants.CardSizes.large,
                action: showBirthCard
            )
            Spacer()
        }
    }
    
    private var karmaConnectionsSection: some View {
        VStack(spacing: AppConstants.Spacing.large) {
            SectionHeader(
                "Life Connections",
                fontSize: AppConstants.FontSizes.title
            )
            
            if let firstConnection = karmaConnections.first {
                let cards = firstConnection.cards.compactMap { dataManager.getCard(by: $0) }
                
                if cards.count == 1 {
                    // Center single karma card
                    HStack(spacing: AppConstants.Spacing.cardSpacing) {
                        Spacer()
                        TappableCard(
                            card: cards[0],
                            size: AppConstants.CardSizes.medium,
                            action: { showKarmaCard(cards[0]) }
                        )
                        Spacer()
                    }
                } else if cards.count == 2 {
                    // Two karma cards side by side (matching DailyCardView format)
                    HStack(spacing: AppConstants.Spacing.cardSpacing) {
                        TappableCard(
                            card: cards[0],
                            size: AppConstants.CardSizes.medium,
                            action: { showKarmaCard(cards[0]) }
                        )
                        
                        TappableCard(
                            card: cards[1],
                            size: AppConstants.CardSizes.medium,
                            action: { showKarmaCard(cards[1]) }
                        )
                    }
                } else {
                    // Fallback to grid for more than 2 cards
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: AppConstants.Spacing.large),
                            GridItem(.flexible(), spacing: AppConstants.Spacing.large)
                        ],
                        alignment: .center,
                        spacing: AppConstants.Spacing.large
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
        }
    }
    
    private func showBirthCard() {
        detailCard = birthCard
        isKarmaCard = false
        karmaDescription = ""
        withAnimation(.easeInOut(duration: 0.3)) {
            showCardDetail = true
        }
    }
    
    private func showKarmaCard(_ card: Card) {
        let cardId = String(card.id)
        let descRepo = DescriptionRepository.shared
        let isKarma1 = karmaConnections.first?.cards.first == card.id
        let description = isKarma1
            ? descRepo.karmaCard1Descriptions[cardId] ?? ""
            : descRepo.karmaCard2Descriptions[cardId] ?? ""

        detailCard = card
        isKarmaCard = true
        karmaDescription = description
        withAnimation(.easeInOut(duration: 0.3)) {
            showCardDetail = true
        }
    }
    
    private func dismissCardDetail() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showCardDetail = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            detailCard = nil
            isKarmaCard = false
            karmaDescription = ""
        }
    }
}

#Preview {
    NavigationView {
        BirthCardView()
    }
}

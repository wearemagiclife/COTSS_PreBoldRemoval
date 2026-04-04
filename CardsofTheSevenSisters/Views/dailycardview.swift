import SwiftUI

struct DailyCardView: View {
    @StateObject private var viewModel = DailyCardViewModel()
    @ObservedObject private var dataManager = DataManager.shared
    @Environment(\.presentationMode) var presentationMode
    @State private var showCardDetail = false
    @State private var selectedCard: Card? = nil
    @State private var selectedCardType: CardType = .daily
    @State private var selectedContentType: DetailContentType? = nil
    
    private var shareContent: ShareCardContent {
        if let selectedCard = selectedCard {
            return ShareCardContent.fromModal(
                card: selectedCard,
                cardType: selectedCardType,
                contentType: selectedContentType,
                date: viewModel.calculationDate
            )
        } else {
            return ShareCardContent.fromModal(
                card: viewModel.todayCard.card,
                cardType: CardType.daily,
                contentType: nil,
                date: viewModel.calculationDate
            )
        }
    }

    private var dailyCardTitle: String {
        if let def = getCardDefinition(by: viewModel.todayCard.card.id) {
            return def.name
        }
        return viewModel.todayCard.card.name
    }

    private var dailyCardDescription: String {
        let repo = DescriptionRepository.shared
        return repo.dailyDescriptions[String(viewModel.todayCard.card.id)] ?? "No description available."
    }

    private var planetInfo: (title: String, description: String) {
        let info = AppConstants.PlanetDescriptions.getDescription(for: viewModel.todayCard.planet)
        return (info.title, info.description)
    }
    
    private var navigationTitle: String {
        if showCardDetail, let card = selectedCard {
            if card.id == viewModel.yesterdayCard.card.id {
                return "Yesterday's Card"
            } else if card.id == viewModel.todayCard.card.id {
                return "Today's Card"
            } else if card.id == viewModel.tomorrowCard.card.id {
                return "Tomorrow's Card"
            } else if case .planetary(let planet) = selectedContentType {
                return "\(planet.capitalized) Influence"
            } else {
                if let def = getCardDefinition(by: card.id) {
                    return def.name
                }
                return card.name
            }
        }
        return AppConstants.Strings.dailyInfluence
    }
    
    private var shareDetails: (
        cardTypeName: String,
        card: Card,
        cardTitle: String,
        cardDescription: String,
        planetName: String,
        planetTitle: String,
        planetDescription: String,
        date: Date
    ) {
        var shareCardTypeName: String = "Daily Card"
        var shareCard: Card = viewModel.todayCard.card
        var shareCardTitle: String = dailyCardTitle
        var shareCardDescription: String = dailyCardDescription
        var sharePlanetName: String = viewModel.todayCard.planet
        var sharePlanetTitle: String = planetInfo.title
        var sharePlanetDescription: String = planetInfo.description
        var shareDate: Date = viewModel.calculationDate
        
        if showCardDetail, let card = selectedCard {
            if card.id == viewModel.yesterdayCard.card.id {
                shareCardTypeName = "Yesterday's Card"
                shareCard = viewModel.yesterdayCard.card
                if let def = getCardDefinition(by: shareCard.id) {
                    shareCardTitle = def.name
                } else {
                    shareCardTitle = shareCard.name
                }
                let repo = DescriptionRepository.shared
                shareCardDescription = repo.dailyDescriptions[String(shareCard.id)] ?? "No description available."
                sharePlanetName = viewModel.yesterdayCard.planet
                let planetInfo = AppConstants.PlanetDescriptions.getDescription(for: sharePlanetName)
                sharePlanetTitle = planetInfo.title
                sharePlanetDescription = planetInfo.description
                shareDate = viewModel.calculationDate.addingTimeInterval(-86400) // 1 day before
            } else if card.id == viewModel.todayCard.card.id {
                shareCardTypeName = "Today's Card"
                shareCard = viewModel.todayCard.card
                shareCardTitle = dailyCardTitle
                shareCardDescription = dailyCardDescription
                sharePlanetName = viewModel.todayCard.planet
                sharePlanetTitle = planetInfo.title
                sharePlanetDescription = planetInfo.description
                shareDate = viewModel.calculationDate
            } else if card.id == viewModel.tomorrowCard.card.id {
                shareCardTypeName = "Tomorrow's Card"
                shareCard = viewModel.tomorrowCard.card
                if let def = getCardDefinition(by: shareCard.id) {
                    shareCardTitle = def.name
                } else {
                    shareCardTitle = shareCard.name
                }
                let repo = DescriptionRepository.shared
                shareCardDescription = repo.dailyDescriptions[String(shareCard.id)] ?? "No description available."
                sharePlanetName = viewModel.tomorrowCard.planet
                let planetInfo = AppConstants.PlanetDescriptions.getDescription(for: sharePlanetName)
                sharePlanetTitle = planetInfo.title
                sharePlanetDescription = planetInfo.description
                shareDate = viewModel.calculationDate.addingTimeInterval(86400) // 1 day after
            } else {
                shareCard = card
                if let def = getCardDefinition(by: shareCard.id) {
                    shareCardTitle = def.name
                } else {
                    shareCardTitle = shareCard.name
                }
                let repo = DescriptionRepository.shared
                shareCardDescription = repo.dailyDescriptions[String(shareCard.id)] ?? "No description available."
                
                if case .planetary(let planet) = selectedContentType {
                    sharePlanetName = planet
                    let planetInfo = AppConstants.PlanetDescriptions.getDescription(for: planet)
                    sharePlanetTitle = planetInfo.title
                    sharePlanetDescription = planetInfo.description
                } else {
                    sharePlanetName = viewModel.todayCard.planet
                    sharePlanetTitle = planetInfo.title
                    sharePlanetDescription = planetInfo.description
                }
                
                shareDate = viewModel.calculationDate
                
                shareCardTypeName = navigationTitle
            }
        }
        
        return (
            cardTypeName: shareCardTypeName,
            card: shareCard,
            cardTitle: shareCardTitle,
            cardDescription: shareCardDescription,
            planetName: sharePlanetName,
            planetTitle: sharePlanetTitle,
            planetDescription: sharePlanetDescription,
            date: shareDate
        )
    }
    
    var body: some View {
        ZStack {
            AppTheme.backgroundColor
                .ignoresSafeArea(.all)
            
            ScrollView {
                VStack(spacing: AppConstants.Spacing.ornament) {

                    mainTitleSection
                    todayCardSection

                    LineBreak()

                    lastCycleCardsSection

                    LineBreak("linedesignd")
                }
                .padding(.horizontal, AppConstants.Spacing.pageInset)
                .padding(.vertical, AppConstants.Spacing.section)
            }
            
            if showCardDetail, let card = selectedCard {
                CardDetailModalView(
                    card: card,
                    cardType: selectedCardType,
                    contentType: selectedContentType,
                    isPresented: $showCardDetail
                )
                .zIndex(10)
                .id("\(card.id)-\(String(describing: selectedContentType))")
            }
        }
        .standardNavigation(
            title: navigationTitle,
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
                    HStack(spacing: AppConstants.Spacing.tight) {
                        let details = shareDetails
                        
                        DailyCardShareLink(
                            dailyCard: details.card,
                            dailyCardTitle: details.cardTitle,
                            dailyCardDescription: details.cardDescription,
                            planetName: details.planetName,
                            planetTitle: details.planetTitle,
                            planetDescription: details.planetDescription,
                            date: details.date,
                            cardTypeName: details.cardTypeName
                        )

                        if DataManager.shared.explorationDate != nil {
                            Button(AppConstants.Strings.reset) {
                                DataManager.shared.explorationDate = nil
                            }
                            .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.callout))
                            .foregroundColor(AppTheme.primaryText)
                            .accessibilityLabel("Reset to today")
                            .accessibilityHint("Returns to today's daily card")
                        }
                    }
                )
            }
        )
        .errorFallback(message: viewModel.errorMessage)
        .onAppear {
            dataManager.markDailyCardAsRevealed()
        }
        .onDisappear {
            dataManager.markDailyCardAsRevealed()
        }
    }
    
    private var mainTitleSection: some View {
        VStack(spacing: AppConstants.Spacing.tight) {
            SectionHeader(
                viewModel.formatCardName(viewModel.todayCard.card.name).uppercased(),
                fontSize: AppConstants.FontSizes.large
            )

            Text("as your \(viewModel.todayCard.planet) day")
                .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                .foregroundColor(AppTheme.primaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.top, AppConstants.Spacing.tight)
    }
    
    private var todayCardSection: some View {
        HStack(spacing: AppConstants.Spacing.cardSpacing) {
            TappableCard(
                card: viewModel.todayCard.card,
                size: AppConstants.CardSizes.largePaired,
                action: {
                    showCardDetail(
                        card: viewModel.todayCard.card,
                        cardType: .daily,
                        contentType: .standard
                    )
                }
            )

            TappablePlanetCard(
                planet: viewModel.todayCard.planet,
                size: AppConstants.CardSizes.largePaired,
                action: {
                    showCardDetail(
                        card: viewModel.todayCard.card,
                        cardType: .daily,
                        contentType: .planetary(viewModel.todayCard.planet)
                    )
                }
            )
        }
    }
    
    private var lastCycleCardsSection: some View {
        HStack(spacing: AppConstants.Spacing.page) {
            VStack(spacing: AppConstants.Spacing.tight) {
                Text("YESTERDAY")
                    .dynamicType(baseSize: AppConstants.FontSizes.body, textStyle: .headline)
                    .fontWeight(.heavy)
                    .foregroundColor(AppTheme.primaryText)
                    .multilineTextAlignment(.center)

                TappableCard(
                    card: viewModel.yesterdayCard.card,
                    size: AppConstants.CardSizes.medium,
                    action: {
                        showCardDetail(
                            card: viewModel.yesterdayCard.card,
                            cardType: .daily,
                            contentType: .standard
                        )
                    }
                )
            }

            VStack(spacing: AppConstants.Spacing.tight) {
                Text("TOMORROW")
                    .dynamicType(baseSize: AppConstants.FontSizes.body, textStyle: .headline)
                    .fontWeight(.heavy)
                    .foregroundColor(AppTheme.primaryText)
                    .multilineTextAlignment(.center)

                TappableCard(
                    card: viewModel.tomorrowCard.card,
                    size: AppConstants.CardSizes.medium,
                    action: {
                        showCardDetail(
                            card: viewModel.tomorrowCard.card,
                            cardType: .daily,
                            contentType: .standard
                        )
                    }
                )
            }
        }
    }
    
    private func showCardDetail(card: Card, cardType: CardType, contentType: DetailContentType?) {
        selectedCard = card
        selectedCardType = cardType
        selectedContentType = contentType
        withAnimation(.easeInOut(duration: 0.3)) {
            showCardDetail = true
        }
    }
    
    private func dismissCardDetail() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showCardDetail = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            selectedCard = nil
            selectedCardType = .daily
            selectedContentType = nil
        }
    }
}

#Preview {
    NavigationView {
        DailyCardView()
    }
}

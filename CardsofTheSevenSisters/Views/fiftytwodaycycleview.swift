import SwiftUI

struct FiftyTwoDayCycleView: View {
    @StateObject private var viewModel = FiftyTwoDayCycleViewModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var showCardDetail = false
    @State private var selectedCard: Card? = nil
    @State private var selectedCardType: CardType? = nil
    @State private var selectedContentType: DetailContentType? = nil

    private var cycleCardTitle: String {
        if let def = getCardDefinition(by: viewModel.currentPeriodCard.id) {
            return def.name
        }
        return viewModel.currentPeriodCard.name
    }

    private var cycleCardDescription: String {
        let repo = DescriptionRepository.shared
        return repo.fiftyTwoDescriptions[String(viewModel.currentPeriodCard.id)] ?? "No description available."
    }

    private var planetInfo: (title: String, description: String) {
        let info = AppConstants.PlanetDescriptions.getDescription(for: currentPlanetaryPhase)
        return (info.title, info.description)
    }

    private var cycleInfoText: String {
        guard let currentDates = currentCycleDates else {
            return "\(currentPlanetaryPhase) Phase"
        }
        return "\(currentPlanetaryPhase) Phase - \(DataManager.shared.formatDateRange(start: currentDates.start, end: currentDates.end))"
    }
    
    // Helper computed properties to get date ranges
    private var currentCycleDates: (start: Date, end: Date)? {
        return DataManager.shared.getCycleDates(for: DataManager.shared.userProfile.birthDate)
    }
    
    private var previousCycleDates: (start: Date, end: Date)? {
        return DataManager.shared.getPreviousCycleDates(for: DataManager.shared.userProfile.birthDate)
    }
    
    private var nextCycleDates: (start: Date, end: Date)? {
        return DataManager.shared.getNextCycleDates(for: DataManager.shared.userProfile.birthDate)
    }
    
    // Get current planetary phase name
    private var currentPlanetaryPhase: String {
        return DataManager.shared.getCurrentPlanetaryPhase(for: DataManager.shared.userProfile.birthDate)
    }

    var body: some View {
        ZStack {
            Color(red: 0.86, green: 0.77, blue: 0.57)
                .ignoresSafeArea(.all)

            ScrollView {
                VStack(spacing: AppConstants.Spacing.sectionSpacing) {
                    headerSection
                    mainCardsSection

                    LineBreak()

                    periodCardsSection

                    LineBreak("linedesignd")
                }
                .padding(.horizontal, AppConstants.Spacing.medium)
                .padding(.vertical, AppConstants.Spacing.large)
            }

            if showCardDetail, let card = selectedCard, let cardType = selectedCardType {
                CardDetailModalView(
                    card: card,
                    cardType: cardType,
                    contentType: selectedContentType,
                    isPresented: $showCardDetail
                )
                .zIndex(10)
                .id("\(card.id)-\(String(describing: selectedContentType))")
            }
        }
        .standardNavigation(
            title: AppConstants.Strings.fiftyTwoDayInfluence,
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
                    HStack(spacing: 12) {
                        AstralCycleShareLink(
                            cycleCard: viewModel.currentPeriodCard,
                            cycleCardTitle: cycleCardTitle,
                            cycleCardDescription: cycleCardDescription,
                            planetName: currentPlanetaryPhase,
                            planetTitle: planetInfo.title,
                            planetDescription: planetInfo.description,
                            cycleInfo: cycleInfoText
                        )

                        if DataManager.shared.explorationDate != nil {
                            Button(AppConstants.Strings.reset) {
                                DataManager.shared.explorationDate = nil
                            }
                            .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.callout))
                            .foregroundColor(.black)
                        }
                    }
                )
            }
        )
        .errorFallback(message: viewModel.errorMessage)
    }

    private var headerSection: some View {
        VStack(spacing: AppConstants.Spacing.titleSpacing) {
            // "YOUR CURRENT CYCLE" as main title
            Text("YOUR CURRENT CYCLE")
                .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.large))
                .fontWeight(.heavy)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
            
            // Planetary phase text
            Text("in your \(currentPlanetaryPhase) phase")
                .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.title))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
            
            // Date range as subtitle
            if let currentDates = currentCycleDates {
                Text(DataManager.shared.formatDateRange(start: currentDates.start, end: currentDates.end))
                    .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, AppConstants.Spacing.small)
    }

    private var mainCardsSection: some View {
        HStack(spacing: AppConstants.Spacing.cardSpacing) {
            TappableCard(
                card: viewModel.currentPeriodCard,
                size: AppConstants.CardSizes.large,
                action: {
                    showCardDetail(
                        card: viewModel.currentPeriodCard,
                        cardType: .fiftyTwoDay,
                        contentType: .standard
                    )
                }
            )

            TappablePlanetCard(
                planet: currentPlanetaryPhase,
                size: AppConstants.CardSizes.large,
                action: {
                    showCardDetail(
                        card: viewModel.currentPeriodCard,
                        cardType: .fiftyTwoDay,
                        contentType: .planetary(currentPlanetaryPhase)
                    )
                }
            )
        }
    }

    private var periodCardsSection: some View {
        HStack(spacing: AppConstants.Spacing.cardSpacing) {
            // Last Cycle Card with Date
            VStack(spacing: AppConstants.Spacing.small) {
                Text(AppConstants.Strings.lastCycle)
                    .dynamicType(baseSize: AppConstants.FontSizes.body, textStyle: .body)
                    .fontWeight(.heavy)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
                
                if let previousDates = previousCycleDates {
                    Text(DataManager.shared.formatDateRange(start: previousDates.start, end: previousDates.end))
                        .dynamicType(baseSize: AppConstants.FontSizes.body, textStyle: .body)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.8)
                }
                
                TappableCard(
                    card: viewModel.lastPeriodCard,
                    size: AppConstants.CardSizes.medium,
                    action: {
                        showCardDetail(
                            card: viewModel.lastPeriodCard,
                            cardType: .fiftyTwoDay,
                            contentType: .standard
                        )
                    }
                )
            }
            
            // Next Cycle Card with Date
            VStack(spacing: AppConstants.Spacing.small) {
                Text(AppConstants.Strings.nextCycle)
                    .dynamicType(baseSize: AppConstants.FontSizes.body, textStyle: .body)
                    .fontWeight(.heavy)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
                
                if let nextDates = nextCycleDates {
                    Text(DataManager.shared.formatDateRange(start: nextDates.start, end: nextDates.end))
                        .dynamicType(baseSize: AppConstants.FontSizes.body, textStyle: .body)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.8)
                }
                
                TappableCard(
                    card: viewModel.nextPeriodCard,
                    size: AppConstants.CardSizes.medium,
                    action: {
                        showCardDetail(
                            card: viewModel.nextPeriodCard,
                            cardType: .fiftyTwoDay,
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
            selectedCardType = nil
            selectedContentType = nil
        }
    }
}

#Preview {
    NavigationView {
        FiftyTwoDayCycleView()
    }
}

import SwiftUI

struct FiftyTwoDayCycleView: View {
    @StateObject private var viewModel = FiftyTwoDayCycleViewModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var showCardDetail = false
    @State private var selectedCard: Card? = nil
    @State private var selectedCardType: CardType? = nil
    @State private var selectedContentType: DetailContentType? = nil

    private var cycleCardDescription: String {
        let repo = DescriptionRepository.shared
        return repo.fiftyTwoDescriptions[String(viewModel.currentPeriodCard.id)] ?? "No description available."
    }

    private var planetInfo: (title: String, description: String) {
        let info = AppConstants.PlanetDescriptions.getDescription(for: currentPlanetaryPhase)
        return (info.title, info.description)
    }

    private var cycleCardTitle: String {
        if let def = getCardDefinition(by: viewModel.currentPeriodCard.id) {
            return def.name
        }
        return viewModel.currentPeriodCard.name
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

    private func shortDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale.current
        // Get locale-ordered components (MM/dd or dd/MM), then replace separator with "."
        formatter.setLocalizedDateFormatFromTemplate("MMdd")
        let raw = formatter.string(from: date)
        return raw.replacingOccurrences(of: "/", with: ".")
                  .replacingOccurrences(of: "-", with: ".")
    }

    private func shortDateRangeString(start: Date, end: Date) -> String {
        return "\(shortDateString(start)) - \(shortDateString(end))"
    }

    private var navigationTitle: String {
        if showCardDetail, let card = selectedCard, let contentType = selectedContentType {
            
            // If showing detail for last or next period cards, show contextual titles
            if card.id == viewModel.lastPeriodCard.id {
                return "Last 52-Day Cycle"
            }
            if card.id == viewModel.nextPeriodCard.id {
                return "Next 52-Day Card"
            }
            if card.id == viewModel.currentPeriodCard.id {
                return "Current 52-Day Card"
            }
            
            switch contentType {
            case .planetary(let planet):
                return "\(planet.capitalized) Influence"
            default:
                if let def = getCardDefinition(by: card.id) {
                    return def.name
                }
                return card.name
            }
        }

        // Default when no detail is showing
        return AppConstants.Strings.fiftyTwoDayInfluence
    }

    var body: some View {
        ZStack {
            AppTheme.backgroundColor
                .ignoresSafeArea(.all)

            ScrollView {
                VStack(spacing: AppConstants.Spacing.ornament) {
                    headerSection
                    mainCardsSection

                    LineBreak()

                    periodCardsSection

                    LineBreak("linedesignd")
                }
                .padding(.horizontal, AppConstants.Spacing.pageInset)
                .padding(.vertical, AppConstants.Spacing.section)
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
            title: navigationTitle,
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
                    HStack(spacing: AppConstants.Spacing.tight) {
                        // 1. When a card detail modal is open
                        if showCardDetail, let card = selectedCard {
                            // Planetary detail share
                            if case .planetary(let planet) = selectedContentType {
                                let planetDetails = AppConstants.PlanetDescriptions.getDescription(for: planet)
                                let planetImage = ImageManager.shared.loadPlanetImage(for: planet)

                                SingleCardShareLink(
                                    card: card,
                                    cardTitle: planetDetails.title,
                                    cardDescription: planetDetails.description,
                                    spreadType:  navigationTitle,
                                    subtitle: cycleInfoText,
                                    overrideImage: planetImage
                                )
                            } else {
                                // 52-day card detail share (last / current / next)
                                let selectedTitle: String = {
                                    if let def = getCardDefinition(by: card.id) { return def.name }
                                    return card.name
                                }()

                                let selectedDescription: String = {
                                    let repo = DescriptionRepository.shared
                                    return repo.fiftyTwoDescriptions[String(card.id)]
                                        ?? "No 52-day description available."
                                }()

                                // Determine which cycle we are sharing (last / current / next)
                                let (sharePlanetName, shareDates): (String, (start: Date, end: Date)?) = {
                                    if card.id == viewModel.lastPeriodCard.id {
                                        return (viewModel.previousPlanetaryPhase, previousCycleDates)
                                    } else if card.id == viewModel.nextPeriodCard.id {
                                        return (viewModel.nextPlanetaryPhase, nextCycleDates)
                                    } else if card.id == viewModel.currentPeriodCard.id {
                                        return (currentPlanetaryPhase, currentCycleDates)
                                    } else {
                                        return (currentPlanetaryPhase, currentCycleDates)
                                    }
                                }()

                                let sharePlanetInfo = AppConstants.PlanetDescriptions.getDescription(for: sharePlanetName)

                                let shareCycleInfoText: String = {
                                    if let dates = shareDates {
                                        return "\(sharePlanetName) Phase - " +
                                            DataManager.shared.formatDateRange(start: dates.start, end: dates.end)
                                    } else {
                                        return "\(sharePlanetName) Phase"
                                    }
                                }()

                                if card.id == viewModel.lastPeriodCard.id {
                                    fiftytwoCycleShareLink(
                                        cycleCard: card,
                                        cycleCardTitle: selectedTitle,
                                        cycleCardDescription: selectedDescription,
                                        planetName: sharePlanetName,
                                        planetTitle: sharePlanetInfo.title,
                                        planetDescription: sharePlanetInfo.description,
                                        cycleInfo: shareCycleInfoText,
                                        headerTitle: "Last 52-Day Card"
                                    )
                                } else if card.id == viewModel.nextPeriodCard.id {
                                    fiftytwoCycleShareLink(
                                        cycleCard: card,
                                        cycleCardTitle: selectedTitle,
                                        cycleCardDescription: selectedDescription,
                                        planetName: sharePlanetName,
                                        planetTitle: sharePlanetInfo.title,
                                        planetDescription: sharePlanetInfo.description,
                                        cycleInfo: shareCycleInfoText,
                                        headerTitle: "Next 52-Day Card"
                                    )
                                } else if card.id == viewModel.currentPeriodCard.id {
                                    fiftytwoCycleShareLink(
                                        cycleCard: card,
                                        cycleCardTitle: selectedTitle,
                                        cycleCardDescription: selectedDescription,
                                        planetName: sharePlanetName,
                                        planetTitle: sharePlanetInfo.title,
                                        planetDescription: sharePlanetInfo.description,
                                        cycleInfo: shareCycleInfoText,
                                        headerTitle: "Current 52-Day Card"
                                    )
                                } else {
                                    fiftytwoCycleShareLink(
                                        cycleCard: card,
                                        cycleCardTitle: selectedTitle,
                                        cycleCardDescription: selectedDescription,
                                        planetName: sharePlanetName,
                                        planetTitle: sharePlanetInfo.title,
                                        planetDescription: sharePlanetInfo.description,
                                        cycleInfo: shareCycleInfoText
                                    )
                                }
                            }
                        // 2. No modal open – share current cycle
                        } else {
                            fiftytwoCycleShareLink(
                                cycleCard: viewModel.currentPeriodCard,
                                cycleCardTitle: cycleCardTitle,
                                cycleCardDescription: cycleCardDescription,
                                planetName: currentPlanetaryPhase,
                                planetTitle: planetInfo.title,
                                planetDescription: planetInfo.description,
                                cycleInfo: cycleInfoText,
                                headerTitle: "52-Day Card"
                            )
                        }

                        // 3. Reset button (still inside the HStack!)
                        if DataManager.shared.explorationDate != nil {
                            Button(AppConstants.Strings.reset) {
                                DataManager.shared.explorationDate = nil
                            }
                            .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.callout))
                            .foregroundColor(AppTheme.primaryText)
                            .accessibilityLabel("Reset to current cycle")
                            .accessibilityHint("Returns to current 52-day cycle")
                        }
                    }
                )
            }
        )
        .errorFallback(message: viewModel.errorMessage)
    }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var headerSection: some View {
        VStack(spacing: AppConstants.Spacing.tight) {
            VStack(spacing: 2) {
                Text("CURRENT PLANETARY CYCLE")
                    .dynamicType(baseSize: AppConstants.FontSizes.large, textStyle: .headline)
                    .fontWeight(.heavy)
                    .foregroundColor(AppTheme.primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                    .minimumScaleFactor(dynamicTypeSize.isAccessibilitySize ? 1 : 0.5)

                if let currentDates = currentCycleDates {
                    Text(shortDateRangeString(start: currentDates.start, end: currentDates.end))
                        .dynamicType(baseSize: AppConstants.FontSizes.callout, textStyle: .callout)
                        .foregroundColor(AppTheme.primaryText)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(.top, AppConstants.Spacing.tight)
    }

    private var mainCardsSection: some View {
        HStack(spacing: AppConstants.Spacing.page) {
            TappableCard(
                card: viewModel.currentPeriodCard,
                size: AppConstants.CardSizes.largePaired,
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
                size: AppConstants.CardSizes.largePaired,
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
        HStack(spacing: AppConstants.Spacing.page) {
            VStack(spacing: AppConstants.Spacing.tight) {
                VStack(spacing: 2) {
                    Text("LAST CYCLE")
                        .dynamicType(baseSize: AppConstants.FontSizes.body, textStyle: .headline)
                        .fontWeight(.heavy)
                        .foregroundColor(AppTheme.primaryText)
                        .multilineTextAlignment(.center)

                    if let previousDates = previousCycleDates {
                        Text(shortDateRangeString(start: previousDates.start, end: previousDates.end))
                            .dynamicType(baseSize: AppConstants.FontSizes.callout, textStyle: .callout)
                            .foregroundColor(AppTheme.primaryText)
                            .multilineTextAlignment(.center)
                    }
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

                Text(viewModel.previousPlanetaryPhase.localizedUppercase)
                    .dynamicType(baseSize: AppConstants.FontSizes.body, textStyle: .headline)
                    .fontWeight(.heavy)
                    .foregroundColor(AppTheme.primaryText)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: AppConstants.Spacing.tight) {
                VStack(spacing: 2) {
                    Text("NEXT CYCLE")
                        .dynamicType(baseSize: AppConstants.FontSizes.body, textStyle: .headline)
                        .fontWeight(.heavy)
                        .foregroundColor(AppTheme.primaryText)
                        .multilineTextAlignment(.center)

                    if let nextDates = nextCycleDates {
                        Text(shortDateRangeString(start: nextDates.start, end: nextDates.end))
                            .dynamicType(baseSize: AppConstants.FontSizes.callout, textStyle: .callout)
                            .foregroundColor(AppTheme.primaryText)
                            .multilineTextAlignment(.center)
                    }
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

                Text(viewModel.nextPlanetaryPhase.localizedUppercase)
                    .dynamicType(baseSize: AppConstants.FontSizes.body, textStyle: .headline)
                    .fontWeight(.heavy)
                    .foregroundColor(AppTheme.primaryText)
                    .multilineTextAlignment(.center)
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


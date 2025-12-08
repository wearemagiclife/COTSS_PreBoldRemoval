import SwiftUI

struct FiftyTwoDayCycleView: View {
    @StateObject private var viewModel = FiftyTwoDayCycleViewModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var showCardDetail = false
    @State private var selectedCard: Card? = nil
    @State private var selectedCardType: CardType? = nil
    @State private var selectedContentType: DetailContentType? = nil

    @State private var lastCycleTitleWidth: CGFloat = 0
    @State private var nextCycleTitleWidth: CGFloat = 0
    @State private var lastCycleDateWidth: CGFloat = 0
    @State private var nextCycleDateWidth: CGFloat = 0

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

    // Formats a date as MM-dd (e.g., 03-07)
    private func shortDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MM.dd"
        return formatter.string(from: date)
    }

    // Formats a date range as MM-dd | MM-dd
    private func shortDateRangeString(start: Date, end: Date) -> String {
        return "\(shortDateString(start)) - \(shortDateString(end))"
    }

    // Available width for titles/dates (match the column width)
    private var titleAvailableWidth: CGFloat { AppConstants.CardSizes.large.width }
    private var dateAvailableWidth: CGFloat { AppConstants.CardSizes.large.width }

    // Unified scales so both sides match exactly and never truncate with ellipses
    private var unifiedTitleScale: CGFloat {
        let maxWidth = max(lastCycleTitleWidth, nextCycleTitleWidth)
        guard maxWidth > 0 else { return 1 }
        return min(1, titleAvailableWidth / maxWidth)
    }

    private var unifiedDateScale: CGFloat {
        let maxWidth = max(lastCycleDateWidth, nextCycleDateWidth)
        guard maxWidth > 0 else { return 1 }
        return min(1, dateAvailableWidth / maxWidth)
    }

    private struct LastCycleTitleWidthKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
    }

    private struct NextCycleTitleWidthKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
    }

    private struct LastCycleDateWidthKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
    }

    private struct NextCycleDateWidthKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
    }

    private var navigationTitle: String {
        if showCardDetail, let card = selectedCard, let contentType = selectedContentType {
            
            // If showing detail for last or next period cards, show contextual titles
            if card.id == viewModel.lastPeriodCard.id {
                return "Your Last 52-Day Card"
            }
            if card.id == viewModel.nextPeriodCard.id {
                return "Your Next 52-Day Card"
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
        return AppConstants.Strings.fiftyTwoDayInfluence
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
                    HStack(spacing: 12) {
                        Group {
                            if showCardDetail, let card = selectedCard {
                                if case .planetary(let planet) = selectedContentType {
                                    let planetDetails = AppConstants.PlanetDescriptions.getDescription(for: planet)
                                    let planetImage = ImageManager.shared.loadPlanetImage(for: planet)
                                    SingleCardShareLink(
                                        card: card,
                                        cardTitle: planetDetails.title,
                                        cardDescription: planetDetails.description,
                                        spreadType: "Current Planetary Influence",
                                        subtitle: cycleInfoText,
                                        overrideImage: planetImage
                                    )
                                } else {
                                    let selectedTitle: String = {
                                        if let def = getCardDefinition(by: card.id) { return def.name }
                                        return card.name
                                    }()
                                    let selectedDescription: String = {
                                        let repo = DescriptionRepository.shared
                                        return repo.fiftyTwoDescriptions[String(card.id)] ?? "No 52-day description available."
                                    }()
                                    fiftytwoCycleShareLink(
                                        cycleCard: card,
                                        cycleCardTitle: selectedTitle,
                                        cycleCardDescription: selectedDescription,
                                        planetName: currentPlanetaryPhase,
                                        planetTitle: planetInfo.title,
                                        planetDescription: planetInfo.description,
                                        cycleInfo: cycleInfoText
                                    )
                                }
                            } else {
                                fiftytwoCycleShareLink(
                                    cycleCard: viewModel.currentPeriodCard,
                                    cycleCardTitle: cycleCardTitle,
                                    cycleCardDescription: cycleCardDescription,
                                    planetName: currentPlanetaryPhase,
                                    planetTitle: planetInfo.title,
                                    planetDescription: planetInfo.description,
                                    cycleInfo: cycleInfoText
                                )
                            }
                        }

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
            Text("CURRENT PLANETARY CYCLE")
                .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.headline))
                .fontWeight(.heavy)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            
            if let currentDates = currentCycleDates {
                Text(shortDateRangeString(start: currentDates.start, end: currentDates.end))
                    .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
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
                Text("LAST CYCLE")
                    .dynamicType(baseSize: AppConstants.FontSizes.body, textStyle: .headline)
                    .fontWeight(.heavy)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .truncationMode(.tail)
                    .background(GeometryReader { geo in
                        Color.clear.preference(key: NextCycleTitleWidthKey.self, value: geo.size.width)
                    })
                    .scaleEffect(unifiedTitleScale, anchor: .center)
                
                if let previousDates = previousCycleDates {
                    Text(shortDateRangeString(start: previousDates.start, end: previousDates.end))
                        .dynamicType(baseSize: AppConstants.FontSizes.callout, textStyle: .callout)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .background(GeometryReader { geo in
                            Color.clear.preference(key: LastCycleDateWidthKey.self, value: geo.size.width)
                        })
                        .scaleEffect(unifiedDateScale, anchor: .center)
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
                
                
                Text("\(viewModel.previousPlanetaryPhase.localizedUppercase)")
                    .dynamicType(baseSize: AppConstants.FontSizes.body, textStyle: .headline)
                    .fontWeight(.heavy)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .background(GeometryReader { geo in
                        Color.clear.preference(key: LastCycleTitleWidthKey.self, value: geo.size.width)
                    })
                    .scaleEffect(unifiedTitleScale, anchor: .center)
            }
            
            .frame(width: AppConstants.CardSizes.large.width)
            
            // Next Cycle Card with Date
            VStack(spacing: AppConstants.Spacing.small) {
                Text("NEXT CYCLE")
                    .dynamicType(baseSize: AppConstants.FontSizes.body, textStyle: .headline)
                    .fontWeight(.heavy)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .background(GeometryReader { geo in
                        Color.clear.preference(key: NextCycleTitleWidthKey.self, value: geo.size.width)
                    })
                    .scaleEffect(unifiedTitleScale, anchor: .center)
                
                if let nextDates = nextCycleDates {
                    Text(shortDateRangeString(start: nextDates.start, end: nextDates.end))
                        .dynamicType(baseSize: AppConstants.FontSizes.callout, textStyle: .callout)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .background(GeometryReader { geo in
                            Color.clear.preference(key: NextCycleDateWidthKey.self, value: geo.size.width)
                        })
                        .scaleEffect(unifiedDateScale, anchor: .center)
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
                
                Text("\(viewModel.nextPlanetaryPhase.localizedUppercase)")
                        .dynamicType(baseSize: AppConstants.FontSizes.body, textStyle: .headline)
                        .fontWeight(.heavy)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .background(GeometryReader { geo in
                            Color.clear.preference(key: LastCycleTitleWidthKey.self, value: geo.size.width)
                        })
                        .scaleEffect(unifiedTitleScale, anchor: .center)
            }
            .frame(width: AppConstants.CardSizes.large.width)
        }
        .onPreferenceChange(LastCycleTitleWidthKey.self) { lastCycleTitleWidth = $0 }
        .onPreferenceChange(NextCycleTitleWidthKey.self) { nextCycleTitleWidth = $0 }
        .onPreferenceChange(LastCycleDateWidthKey.self) { lastCycleDateWidth = $0 }
        .onPreferenceChange(NextCycleDateWidthKey.self) { nextCycleDateWidth = $0 }
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


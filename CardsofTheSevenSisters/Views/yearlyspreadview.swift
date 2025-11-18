import SwiftUI

struct YearlySpreadView: View {
    @StateObject private var viewModel = YearlyCardViewModel()
    @ObservedObject private var dataManager = DataManager.shared
    @Environment(\.presentationMode) var presentationMode
    @State private var showCardDetail = false
    @State private var selectedCard: Card? = nil
    
    private let cardType: CardType = .yearly

    private var yearlyCardTitle: String {
        if let def = getCardDefinition(by: viewModel.currentYearCard.id) {
            return def.name
        }
        return viewModel.currentYearCard.name
    }

    private var yearlyCardDescription: String {
        let repo = DescriptionRepository.shared
        return repo.yearlyDescriptions[String(viewModel.currentYearCard.id)] ?? "No description available."
    }

    private var currentYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: viewModel.calculationDate)
    }
    
    // Date range computed properties
    private var currentCycleDateRange: String {
        if let dates = dataManager.getCycleDates(for: dataManager.userProfile.birthDate) {
            return dataManager.formatDateRange(start: dates.start, end: dates.end)
        }
        return "Aug 30 - Oct 20" // fallback
    }
    
    private var previousCycleDateRange: String {
        if let dates = dataManager.getPreviousCycleDates(for: dataManager.userProfile.birthDate) {
            return dataManager.formatDateRange(start: dates.start, end: dates.end)
        }
        return "Jul 9 - Aug 29" // fallback
    }
    
    private var nextCycleDateRange: String {
        if let dates = dataManager.getNextCycleDates(for: dataManager.userProfile.birthDate) {
            return dataManager.formatDateRange(start: dates.start, end: dates.end)
        }
        return "Oct 21 - Dec 11" // fallback
    }
    
    private var currentYearNumber: Int {
        Int(currentYear) ?? Calendar.current.component(.year, from: viewModel.calculationDate)
    }

    private var lastYearLabel: String { "Reflection | \(currentYearNumber - 1)" }
    private var nextYearLabel: String { "Envision | \(currentYearNumber + 1)" }
    
    private var navigationTitle: String {
        if showCardDetail, let card = selectedCard {
            if card.id == viewModel.currentYearCard.id {
                return "This Year's Card"
            } else if card.id == viewModel.lastYearCard.id {
                return "Last Year's Card"
            } else if card.id == viewModel.nextYearCard.id {
                return "Next Year's Card"
            } else {
                return "Yearly Card"
            }
        }
        return AppConstants.Strings.yearlyInfluence
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.86, green: 0.77, blue: 0.57)
                .ignoresSafeArea(.all)
                
            ScrollView {
                VStack(spacing: AppConstants.Spacing.sectionSpacing) {
                    headerSection
                    mainCardSection
                    
                    LineBreak()
                    
                    yearlyCardsSection
                    
                    LineBreak("linedesignd")
                }
                .padding(.horizontal, AppConstants.Spacing.medium)
                .padding(.vertical, AppConstants.Spacing.large)
            }
            
            if showCardDetail, let card = selectedCard {
                CardDetailModalView(
                    card: card,
                    cardType: cardType,
                    contentType: nil as DetailContentType?,
                    isPresented: $showCardDetail
                )
                .zIndex(10)
                .id("\(card.id)")
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
                                let spread = spreadType(for: card)
                                let subtitle = subtitleYear(for: card)
                                let (title, description) = yearlyTitleAndDescription(for: card)

                                SingleCardShareLink(
                                    card: card,
                                    cardTitle: title,
                                    cardDescription: description,
                                    spreadType: spread,
                                    subtitle: subtitle
                                )
                            } else {
                                SingleCardShareLink(
                                    card: viewModel.currentYearCard,
                                    cardTitle: yearlyCardTitle,
                                    cardDescription: yearlyCardDescription,
                                    spreadType: "My Yearly Spread",
                                    subtitle: currentYear
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
            // "THE PRESENT | THIS YEAR'S CARD" as main title
            Text("THE PRESENT YEAR")
                .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.large))
                .fontWeight(.heavy)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .lineLimit(1)
            
            // "each birthday begins with a fresh start and a new card" as subtitle
            Text("each birthday offers a fresh start & a new card")
                .dynamicType(baseSize: AppConstants.FontSizes.body, textStyle: .body)
                .fontWeight(.bold)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
        }
        .padding(.top, AppConstants.Spacing.small)
    }
    
    private var mainCardSection: some View {
        TappableCard(
            card: viewModel.currentYearCard,
            size: AppConstants.CardSizes.large,
            action: {
                showCardDetail(card: viewModel.currentYearCard)
            }
        )
    }
    
    private var yearlyCardsSection: some View {
        HStack(spacing: AppConstants.Spacing.cardSpacing) {
            // Last Cycle Card with Date
            VStack(spacing: AppConstants.Spacing.small) {
                Text("Last Year's Card")
                    .dynamicType(baseSize: AppConstants.FontSizes.body, textStyle: .body)
                    .fontWeight(.heavy)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
                
                TappableCard(
                    card: viewModel.lastYearCard,
                    size: AppConstants.CardSizes.medium,
                    action: {
                        showCardDetail(card: viewModel.lastYearCard)
                    }
                )
            }
            
            // Next Cycle Card with Date
            VStack(spacing: AppConstants.Spacing.small) {
                Text("Next Year's Card")
                    .dynamicType(baseSize: AppConstants.FontSizes.body, textStyle: .body)
                    .fontWeight(.heavy)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
                              
                TappableCard(
                    card: viewModel.nextYearCard,
                    size: AppConstants.CardSizes.medium,
                    action: {
                        showCardDetail(card: viewModel.nextYearCard)
                    }
                )
            }
        }
    }
    
    private func showCardDetail(card: Card) {
        selectedCard = card
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
        }
    }
    
    private func spreadType(for card: Card) -> String {
        if card.id == viewModel.currentYearCard.id { return "This Year's Card" }
        if card.id == viewModel.lastYearCard.id { return "Last Year's Card" }
        if card.id == viewModel.nextYearCard.id { return "Next Year's Card" }
        return "Yearly Card"
    }

    private func subtitleYear(for card: Card) -> String {
        if card.id == viewModel.currentYearCard.id { return String(currentYearNumber) }
        if card.id == viewModel.lastYearCard.id { return String(currentYearNumber - 1) }
        if card.id == viewModel.nextYearCard.id { return String(currentYearNumber + 1) }
        return currentYear
    }

    private func yearlyTitleAndDescription(for card: Card) -> (String, String) {
        let title: String
        if let def = getCardDefinition(by: card.id) {
            title = def.name
        } else {
            title = card.name
        }
        let repo = DescriptionRepository.shared
        let desc = repo.yearlyDescriptions[String(card.id)] ?? "No description available."
        return (title, desc)
    }
}

#Preview {
    NavigationView {
        YearlySpreadView()
    }
}


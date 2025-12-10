import SwiftUI

struct PlayingCardView: View {
    let card: Card
    let size: CardSize
    @Environment(\.sizeCategory) var sizeCategory
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    
    enum CardSize {
        case small, medium, large
        
        var dimensions: CGSize {
            switch self {
            case .small: return CGSize(width: 80, height: 120)
            case .medium: return CGSize(width: 120, height: 176)
            case .large: return CGSize(width: 150, height: 220)
            }
        }
    }
    
    var body: some View {
        Group {
            if let uiImage = loadCardImage() {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: scaledWidth, height: scaledHeight)
                    .scaleEffect(colorScheme == .dark ? 0.95 : 1.0)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .darkModeCardEffects()
                    .accessibilityLabel(cardAccessibilityLabel)
                    .accessibilityAddTraits(.isImage)
            } else {
                textBasedCardView
            }
        }
        .frame(minWidth: AppConstants.Accessibility.minimumTouchTarget,
               minHeight: AppConstants.Accessibility.minimumTouchTarget)
        .contentShape(Rectangle())
    }
    
    private var scaledWidth: CGFloat {
        let baseWidth = size.dimensions.width
        return sizeCategory.isAccessibilityCategory ? baseWidth * 1.3 : baseWidth
    }
    
    private var scaledHeight: CGFloat {
        let baseHeight = size.dimensions.height
        return sizeCategory.isAccessibilityCategory ? baseHeight * 1.3 : baseHeight
    }
    
    private var cardAccessibilityLabel: String {
        let suitName = card.suit.rawValue.lowercased()
        let valueName = cardValueName(card.value)
        return "\(valueName) of \(suitName)"
    }
    
    private func cardValueName(_ value: String) -> String {
        switch value.uppercased() {
        case "A": return "Ace"
        case "K": return "King"
        case "Q": return "Queen"
        case "J": return "Jack"
        default: return value
        }
    }
    
    private func loadCardImage() -> UIImage? {
        let imageName = card.imageName
        
        if let image = UIImage(named: imageName) {
            return image
        }
        
        if let image = UIImage(named: "Resources/Images/\(imageName)") {
            return image
        }
        
        if let path = Bundle.main.path(forResource: imageName, ofType: "png", inDirectory: "Resources/Images"),
           let image = UIImage(contentsOfFile: path) {
            return image
        }
        
        if let path = Bundle.main.path(forResource: imageName, ofType: "png"),
           let image = UIImage(contentsOfFile: path) {
            return image
        }
        
        return nil
    }
    
    private var textBasedCardView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.cardBackground)
                .darkModeCardEffects()

            VStack {
                HStack {
                    Text(card.value)
                        .dynamicType(baseSize: size.fontSize, textStyle: .headline)

                        .foregroundColor(AppTheme.primaryText)
                    Spacer()
                }

                Spacer()

                Text(card.suitSymbol)
                    .font(.system(size: size.suitSize))
                    .foregroundColor(AppTheme.primaryText)

                    .accessibilityHidden(true)

                Spacer()

                HStack {
                    Spacer()
                    Text(card.value)
                        .dynamicType(baseSize: size.fontSize, textStyle: .headline)

                        .foregroundColor(AppTheme.primaryText)
                        .rotationEffect(.degrees(180))
                        .accessibilityHidden(true)
                }
            }
            .padding(8)
        }
        .frame(width: scaledWidth, height: scaledHeight)
        .accessibilityLabel(cardAccessibilityLabel)
        .accessibilityAddTraits(.isImage)
    }
}

extension PlayingCardView.CardSize {
    var fontSize: CGFloat {
        switch self {
        case .small: return 12
        case .medium: return 16
        case .large: return 20
        }
    }
    
    var suitSize: CGFloat {
        switch self {
        case .small: return 32
        case .medium: return 48
        case .large: return 64
        }
    }
}

struct CardDetailView: View {
    let card: Card
    let showDescription: Bool
    @Environment(\.sizeCategory) var sizeCategory
    
    var body: some View {
        VStack(spacing: AppConstants.Spacing.ornament) {
            if let def = getCardDefinition(by: card.id) {
                Text("THE \(def.name)")
                    .dynamicType(baseSize: 36, textStyle: .largeTitle)

                    .foregroundColor(AppTheme.primaryText)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)
                    .accessibilityAddTraits(.isHeader)
            } else {
                Text(card.name)
                    .dynamicType(baseSize: 36, textStyle: .largeTitle)

                    .foregroundColor(AppTheme.primaryText)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)
                    .accessibilityAddTraits(.isHeader)
            }

            if let def = getCardDefinition(by: card.id) {
                Text(def.title)
                    .dynamicType(baseSize: 20, textStyle: .title3)

                    .italic()
                    .foregroundColor(AppTheme.primaryText)
                    .multilineTextAlignment(.center)
            }

            PlayingCardView(card: card, size: .large)
                .accessibilityLabel("\(card.value) of \(card.suit.rawValue)")

            if showDescription {
                ScrollView {
                    Text(card.description)
                        .dynamicType(baseSize: 18, textStyle: .body)
                        .lineSpacing(AppConstants.Typography.bodyLineSpacing)
                        .foregroundColor(AppTheme.primaryText)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .accessibilityElement(children: .contain)
    }
}

struct KarmaCardRow: View {
    let cards: [Card]
    let description: String
    @Environment(\.sizeCategory) var sizeCategory
    
    var body: some View {
        VStack(spacing: AppConstants.Spacing.tight) {
            LazyVGrid(columns: adaptiveColumns, spacing: AppConstants.Spacing.tight) {
                ForEach(cards) { (card: Card) in
                    VStack(spacing: 8) {
                        PlayingCardView(card: card, size: .small)
                            .accessibleCard(card)
                        
                        Text(card.name)
                            .dynamicType(baseSize: 18, textStyle: .caption1)
                            .foregroundColor(AppTheme.primaryText)

                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.8)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(card.value) of \(card.suit.rawValue), \(card.name)")
                }
            }

            Text(description)
                .dynamicType(baseSize: 18, textStyle: .body)
                .lineSpacing(AppConstants.Typography.bodyLineSpacing)
                .italic()
                .foregroundColor(AppTheme.primaryText)
                .multilineTextAlignment(.leading)
                .padding(.horizontal)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .contain)
    }
    
    private var adaptiveColumns: [GridItem] {
        let minWidth: CGFloat = sizeCategory.isAccessibilityCategory ? 120 : 90
        return Array(repeating: GridItem(.adaptive(minimum: minWidth)), count: 1)
    }
}

#Preview {
    let sampleCard = Card(
        id: 1,
        name: "Ace of Hearts",
        value: "A",
        suit: .hearts,
        title: "The Card of Love",
        description: "Love is your ruling force."
    )
    
    VStack(spacing: 20) {
        PlayingCardView(card: sampleCard, size: .large)
        
        PlayingCardView(card: sampleCard, size: .medium)
        
        PlayingCardView(card: sampleCard, size: .small)
    }
    .padding()
}

import SwiftUI

// MARK: - TappableCard

struct TappableCard: View {
    let card: Card
    let size: CGSize
    let cornerRadius: CGFloat
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    init(card: Card, size: CGSize, cornerRadius: CGFloat? = nil, action: @escaping () -> Void) {
        self.card = card
        self.size = size
        self.cornerRadius = cornerRadius ?? AppConstants.CardStyle.cornerRadius(for: size)
        self.action = action
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        let accessibilityLabel = cardAccessibilityLabel

        if let image = ImageManager.shared.loadCardImage(for: card) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size.width, height: size.height)
                .scaleEffect(colorScheme == .dark ? 0.95 : 1.0)
                .clipShape(shape)
                .contentShape(shape)
                .darkModeCardEffects(size: size)
                .onTapGesture { action() }
                .accessibilityLabel(accessibilityLabel)
                .accessibilityAddTraits([.isButton, .isImage])
        } else {
            FallbackCardView(card: card, size: size, cornerRadius: cornerRadius)
                .onTapGesture { action() }
                .accessibilityLabel(accessibilityLabel)
                .accessibilityAddTraits([.isButton, .isImage])
        }
    }

    private var cardAccessibilityLabel: String {
        if let def = getCardDefinition(by: card.id) {
            return "\(def.name), tap for details"
        }
        return "\(card.value) of \(card.suit.rawValue), tap for details"
    }
}

// MARK: - TappablePlanetCard

struct TappablePlanetCard: View {
    let planet: String
    let size: CGSize
    let cornerRadius: CGFloat
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    init(planet: String, size: CGSize, cornerRadius: CGFloat? = nil, action: @escaping () -> Void) {
        self.planet = planet
        self.size = size
        self.cornerRadius = cornerRadius ?? AppConstants.CardStyle.cornerRadius(for: size)
        self.action = action
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        let accessibilityLabel = "\(planet), tap for details"

        if let image = ImageManager.shared.loadPlanetImage(for: planet) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size.width, height: size.height)
                .scaleEffect(colorScheme == .dark ? 0.95 : 1.0)
                .clipShape(shape)
                .contentShape(shape)
                .darkModeCardEffects(size: size)
                .onTapGesture { action() }
                .accessibilityLabel(accessibilityLabel)
                .accessibilityAddTraits([.isButton, .isImage])
        } else {
            FallbackPlanetView(planet: planet, size: size, cornerRadius: cornerRadius)
                .onTapGesture { action() }
                .accessibilityLabel(accessibilityLabel)
                .accessibilityAddTraits([.isButton, .isImage])
        }
    }
}

// MARK: - Fixed Insets (hard-coded per size)

private struct FixedInsets {
    let leftRight: CGFloat
    let top: CGFloat
    let bottom: CGFloat

    var edgeInsets: EdgeInsets {
        EdgeInsets(top: top, leading: leftRight, bottom: bottom, trailing: leftRight)
    }

    static func forWidth(_ width: CGFloat) -> FixedInsets {
        let wLarge  = AppConstants.CardSizes.large.width   // 156
        let wMedium = AppConstants.CardSizes.medium.width  // 120
        let epsilon: CGFloat = 0.5

        if abs(width - wLarge) < epsilon {
            // Match HomeView look: tighter all around (bottom a bit tighter)
            return FixedInsets(leftRight: 1.6, top: 0.6, bottom: 0.3)
        } else if abs(width - wMedium) < epsilon {
            return FixedInsets(leftRight: 1.3, top: 0.5, bottom: 0.25)
        } else {
            // Conservative default for other widths
            return FixedInsets(leftRight: 1.8, top: 0.7, bottom: 0.35)
        }
    }
}

// MARK: - CardWithLabel

struct CardWithLabel: View {
    let card: Card
    let label: String
    let size: CGSize
    let action: () -> Void

    var body: some View {
        VStack(spacing: AppConstants.Spacing.tight) {
            Text(label)
                .dynamicType(baseSize: AppConstants.FontSizes.body, textStyle: .body)
                .fontWeight(.heavy)
                .foregroundColor(AppTheme.primaryText)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)

            TappableCard(card: card, size: size, action: action)
        }
    }
}

// MARK: - FallbackCardView

struct FallbackCardView: View {
    let card: Card
    let size: CGSize
    let cornerRadius: CGFloat

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        shape
            .fill(AppTheme.cardBackground)
            .overlay(
                shape.strokeBorder(AppTheme.darkAccent, lineWidth: 2)
            )
            .frame(width: size.width, height: size.height)
            .overlay(
                VStack {
                    suitIcon(for: card.suit)
                    Spacer()
                    suitIcon(for: card.suit)
                        .rotationEffect(.degrees(180))
                }
                .padding(AppConstants.Spacing.small)
            )
            .contentShape(shape)
            .darkModeCardEffects(size: size)
    }

    @ViewBuilder
    private func suitIcon(for suit: CardSuit) -> some View {
        switch suit {
        case .hearts:   Image(systemName: "heart").font(.title2).foregroundColor(AppTheme.primaryText).accessibilityHidden(true)
        case .clubs:    Image(systemName: "suit.club").font(.title2).foregroundColor(AppTheme.primaryText).accessibilityHidden(true)
        case .diamonds: Image(systemName: "diamond").font(.title2).foregroundColor(AppTheme.primaryText).accessibilityHidden(true)
        case .spades:   Image(systemName: "suit.spade").font(.title2).foregroundColor(AppTheme.primaryText).accessibilityHidden(true)
        case .joker:    Text("🃏").font(.title2).accessibilityHidden(true)
        }
    }
}

// MARK: - FallbackPlanetView

struct FallbackPlanetView: View {
    let planet: String
    let size: CGSize
    let cornerRadius: CGFloat

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        ZStack {
            shape
                .fill(AppTheme.cardBackground)
                .overlay(
                    shape.strokeBorder(AppTheme.darkAccent.opacity(0.0), lineWidth: 0)
                )
                .frame(width: size.width, height: size.height)
                .contentShape(shape)
                .darkModeCardEffects(size: size)

            VStack {
                Text(planetSymbol(for: planet))
                    .font(.system(size: 64))
                    .foregroundColor(AppTheme.primaryText)
                    .fontWeight(.heavy)

                Text(planet.uppercased())
                    .dynamicType(baseSize: AppConstants.FontSizes.body, textStyle: .body)
                    .foregroundColor(AppTheme.primaryText)
                    .fontWeight(.heavy)
            }
        }
    }

    private func planetSymbol(for planet: String) -> String {
        switch planet.lowercased() {
        case "mercury": return "☿"
        case "venus":   return "♀"
        case "mars":    return "♂"
        case "jupiter": return "♃"
        case "saturn":  return "♄"
        case "uranus":  return "♅"
        case "neptune": return "♆"
        case "pluto":   return "♇"
        default:        return "◯"
        }
    }
}

// MARK: - SectionHeader

struct SectionHeader: View {
    let title: String
    let fontSize: CGFloat

    init(_ title: String, fontSize: CGFloat = AppConstants.FontSizes.headline) {
        self.title = title
        self.fontSize = fontSize
    }

    var body: some View {
        Text(title)
            .dynamicType(baseSize: fontSize, textStyle: .headline)
            .fontWeight(.regular)
            .foregroundColor(AppTheme.primaryText)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.7)
    }
}

// MARK: - LineBreak

struct LineBreak: View {
    let imageName: String
    let width: CGFloat

    private var clampedWidth: CGFloat {
        min(max(width, 280), 300)
    }
    private var effectiveWidth: CGFloat {
        clampedWidth * 0.75
    }

    private var calculatedHeight: CGFloat {
        effectiveWidth * 0.1
    }

    init(_ imageName: String = "linedesign", width: CGFloat = 280) {
        self.imageName = imageName
        self.width = width
    }

    var body: some View {
        if let image = UIImage(named: imageName) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: effectiveWidth, height: calculatedHeight)
                .accessibilityHidden(true)
        } else {
            Rectangle()
                .frame(width: effectiveWidth, height: calculatedHeight)
                .foregroundColor(.black.opacity(0.3))
                .accessibilityHidden(true)
        }
    }
}

// MARK: - Simple Divider Line (2/3 of LineBreak width)

struct SimpleDivider: View {
    let width: CGFloat

    private var dividerWidth: CGFloat {
        let lineBreakWidth = min(max(width, 280), 300) * 0.75
        return lineBreakWidth * 0.67  // 2/3 of LineBreak width
    }

    init(width: CGFloat = 200) {
        self.width = width
    }

    var body: some View {
        Rectangle()
            .fill(AppTheme.primaryText.opacity(0.3))
            .frame(width: dividerWidth, height: 1)
            .accessibilityHidden(true)
    }
}


import SwiftUI
import UIKit

enum CardType {
    case planetary, daily, birth, yearly, fiftyTwoDay
}

enum DetailContentType {
    case standard, extended, karma(String), planetary(String)
}

struct CardDetailModalView: View {
    let card: Card
    let cardType: CardType
    let contentType: DetailContentType?
    @Binding var isPresented: Bool

    // MARK: - Title glyph sizing to visually match (or exceed) 24pt text
    private var titleUIFont: UIFont { UIFont(name: "Iowan Old Style", size: 24) ?? .systemFont(ofSize: 24) }
    // Scale up slightly so the image reads like a typographic title
    private var nameGlyphHeight: CGFloat { titleUIFont.lineHeight * 1.25 } // reduced to match smaller card

    // Helper to check if content is karma type
    private var isKarmaContent: Bool {
        if case .karma = contentType { return true }
        return false
    }

    // iPad font scaling
    private var isIPad: Bool {
        UIScreen.main.bounds.width > 500
    }

    private func scaledFont(_ baseSize: CGFloat) -> CGFloat {
        isIPad ? baseSize * 1.4 : baseSize
    }
    
    private var navTitle: String {
        switch cardType {
        case .daily:
            return "Daily Card"
        case .birth:
            return "Birth Card"
        case .yearly:
            return "Yearly Card"
        case .fiftyTwoDay:
            return "52-Day Card"
        case .planetary:
            if case .planetary(let planet) = contentType {
                return "\(planet.capitalized) Influence"
            } else {
                return "Planetary Influence"
            }
        }
    }

    private var shareText: String {
        let title: String = navTitle
        let cardName: String = {
            if let def = getCardDefinition(by: card.id) {
                return def.name
            } else {
                return "\(card.value) of \(card.suit.rawValue)"
            }
        }()
        let desc = descriptionText()
        return "\(title): \(cardName)\n\n\(desc)"
    }

    var body: some View {
        ZStack {
            Color.black.opacity(isPresented ? 0.6 : 0)
                .ignoresSafeArea(.all)
                .onTapGesture {
                    closeModal()
                }
                .allowsHitTesting(isPresented)
                .accessibilityLabel("Close card details")
                .accessibilityAddTraits(.isButton)
                .accessibilityHint("Double tap to close")

            ScrollView {
                VStack(spacing: 25) {
                    Group {
                        if case .planetary(let planet) = contentType {
                            if let planetImage = ImageManager.shared.loadPlanetImage(for: planet) {
                                Image(uiImage: planetImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: isIPad ? 320 : 240)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                                    .accessibilityLabel("\(planet) planetary influence")
                                    .accessibilityAddTraits(.isImage)
                            }
                        } else {
                            if let uiImage = ImageManager.shared.loadCardImage(for: card) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: isIPad ? 320 : 240)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                                    .accessibilityLabel("\(card.value) of \(card.suit.rawValue)")
                                    .accessibilityAddTraits(.isImage)
                            }
                        }
                    }
                    .id("cardTop")

                    VStack(spacing: 10) {
                        Group {
                            if case .planetary(let planet) = contentType {
                                let planetInfo = AppConstants.PlanetDescriptions.getDescription(for: planet)
                                Text(planetInfo.title.lowercased())
                                    .font(.custom("Iowan Old Style", size: scaledFont(20)))
                                    .foregroundColor(.black)
                                    .multilineTextAlignment(.center)
                            } else {
                                if let def = getCardDefinition(by: card.id) {
                                    // Name glyph (replaces the big bold card name text)
                                    let assetName = cardNameAsset(def.name)
                                    if let nameGlyph = UIImage(named: assetName) {
                                        Image(uiImage: nameGlyph)
                                            .resizable()
                                            .renderingMode(.original)
                                            .scaledToFit()
                                            .frame(height: isIPad ? nameGlyphHeight * 1.4 : nameGlyphHeight)
                                            .accessibilityLabel(def.name)
                                            .accessibilityAddTraits(.isHeader)
                                    } else {
    #if DEBUG
                                        // Visual debug: if asset is missing, show a subtle placeholder to catch it
                                        Text("Missing: \(assetName)")
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(.red)
    #else
                                        // In release, show nothing rather than fallback bold text
                                        EmptyView()
    #endif
                                    }

                                    // Subtitle - hide for karma cards
                                    if case .karma = contentType {
                                        // No subtitle for karma cards
                                    } else {
                                        Text(def.title.lowercased())
                                            .font(.custom("Iowan Old Style", size: scaledFont(18)))
                                            .foregroundColor(.black)
                                            .multilineTextAlignment(.center)
                                            .padding(.top, 2)
                                    }
                                }
                            }
                        }

                        LineBreak(width: isIPad ? 260 : 180)
                            .padding(.vertical, isKarmaContent ? 8 : 12)

                        Text(descriptionText())
                            .font(.custom("Iowan Old Style", size: scaledFont(17)))
                            .lineSpacing(isIPad ? 7 : 5)
                            .tracking(0.3)
                            .foregroundColor(.black)
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal, isIPad ? 20 : 10)

                        // Birth dates for karma cards - below description
                        if case .karma = contentType {
                            VStack(spacing: 6) {
                                Text("Birthdates with this Card:")
                                    .font(.custom("Iowan Old Style", size: scaledFont(14)))
                                    .foregroundColor(.black)
                                    .multilineTextAlignment(.center)

                                Text(formatBirthDates(for: card.id))
                                    .font(.custom("Iowan Old Style", size: scaledFont(14)))
                                    .foregroundColor(.black.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                            }
                            .padding(.top, 16)
                        }

                        LineBreak("linedesignd", width: isIPad ? 260 : 180)
                            .padding(.top, 12)
                            .padding(.bottom, 12)
                    }
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                .padding(.bottom, 12)
            }
            .scrollIndicators(.hidden)
            .scrollTargetLayout()
            .scrollPosition(id: .constant("cardTop"))
            .padding(.vertical, 30) // static top/bottom buffer so content never touches card edges
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: AppConstants.CornerRadius.modal)
                    .fill(AppTheme.backgroundColor)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.modal))
            .padding(25)
            .scaleEffect(isPresented ? 1 : 1)
            .opacity(isPresented ? 1 : 0)
            .allowsHitTesting(isPresented)
            .zIndex(10)
        }
        .animation(.spring(response: AppConstants.Animation.springResponse, dampingFraction: AppConstants.Animation.springDamping), value: isPresented)
    }

    private func closeModal() {
        withAnimation(.spring(response: AppConstants.Animation.springResponse, dampingFraction: AppConstants.Animation.springDamping)) {
            isPresented = false
        }
    }

    private func descriptionText() -> String {
        switch contentType {
        case .karma(let description):
            return description
        case .planetary(let planet):
            let planetInfo = AppConstants.PlanetDescriptions.getDescription(for: planet)
            return planetInfo.description
        case .extended:
            return "Extended content handled by view"
        case .standard, .none:
            let repo = DescriptionRepository.shared
            let cardID = String(card.id)
            switch cardType {
            case .daily:
                return repo.dailyDescriptions[cardID] ?? "No daily description available."
            case .birth:
                return repo.birthDescriptions[cardID] ?? "No birth description available."
            case .yearly:
                return repo.yearlyDescriptions[cardID] ?? "No yearly description available."
            case .fiftyTwoDay:
                return repo.fiftyTwoDescriptions[cardID] ?? "No 52-day description available."
            case .planetary:
                return "Error: Planetary descriptions should be passed via contentType"
            }
        }
    }

    private func formatBirthDates(for cardId: Int) -> String {
        let dates = BirthCardLookup.shared.getDatesForCard(cardId)
        guard !dates.isEmpty else { return "" }

        let monthAbbr = ["Jan.", "Feb.", "Mar.", "Apr.", "May", "Jun.",
                         "Jul.", "Aug.", "Sep.", "Oct.", "Nov.", "Dec."]

        let formatted = dates.map { date in
            let monthName = monthAbbr[date.month - 1]
            return "\(monthName) \(date.day)"
        }.joined(separator: ", ")

        return formatted
    }
}

// MARK: - Asset name resolver for the small name glyph
private func cardNameAsset(_ raw: String) -> String {
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    let lower = trimmed.lowercased()
    
    // Joker assets are titled "The Joker"
    if lower.contains("joker") { return "The Joker" }
    
    // Other assets are uppercased with spaces, e.g., "EIGHT OF CLUBS"
    // Normalize underscores/dashes just in case
    let spaced = trimmed
        .replacingOccurrences(of: "_", with: " ")
        .replacingOccurrences(of: "-", with: " ")
        .replacingOccurrences(of: "  ", with: " ")
    return spaced.uppercased()
}


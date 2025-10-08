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

    // MARK: - Title glyph sizing to visually match (or exceed) 28pt text
    private var titleUIFont: UIFont { UIFont(name: "Iowan Old Style", size: 28) ?? .systemFont(ofSize: 28) }
    // Scale up slightly so the image reads like a typographic title
    private var nameGlyphHeight: CGFloat { titleUIFont.lineHeight * 1.35 } // tweak factor as desired

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
                                    .frame(height: 300)
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
                                    .frame(height: 300)
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
                                    .font(.custom("Iowan Old Style", size: 22))
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
                                            .frame(height: nameGlyphHeight)
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

                                    // Subtitle remains
                                    Text(def.title.lowercased())
                                        .font(.custom("Iowan Old Style", size: 21))
                                        .foregroundColor(.black)
                                        .multilineTextAlignment(.center)
                                        .padding(.top, 2)
                                }
                            }
                        }

                        if let lineImage = UIImage(named: "linedesign") {
                            Image(uiImage: lineImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 120)
                                .padding(.vertical, 15)
                                .accessibilityHidden(true)
                        }

                        Text(descriptionText())
                            .font(.custom("Iowan Old Style", size: 20))
                            .lineSpacing(5)
                            .tracking(0.8)
                            .foregroundColor(.black)
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal, 25)
                    }
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
            .scrollTargetLayout()
            .scrollPosition(id: .constant("cardTop"))
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color(red: 0.86, green: 0.77, blue: 0.57).opacity(0.95))
            )
            .clipShape(RoundedRectangle(cornerRadius: 25))
            .scaleEffect(isPresented ? 1 : 0.8)
            .opacity(isPresented ? 1 : 0)
            .padding(.horizontal, 25)
            .padding(.top, 44)
            .padding(.bottom, 20)
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

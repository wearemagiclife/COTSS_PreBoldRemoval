import Foundation

struct WidgetCard: Decodable {
    let id: Int
    let name: String
    let value: String
    let suit: String
    let title: String

    var rankShort: String {
        switch value.lowercased() {
        case "a": return "A"
        case "j": return "J"
        case "q": return "Q"
        case "k": return "K"
        case "joker": return "★"
        default: return value
        }
    }

    var suitSFSymbol: String {
        switch suit.lowercased() {
        case "hearts":   return "suit.heart.fill"
        case "diamonds": return "suit.diamond.fill"
        case "clubs":    return "suit.club.fill"
        case "spades":   return "suit.spade.fill"
        default:         return "star.fill"
        }
    }

    var isRed: Bool {
        let s = suit.lowercased()
        return s == "hearts" || s == "diamonds"
    }

    /// Matches the main app's `Card.imageName` format, e.g. `9c`, `jh`, `10s`, `ad`.
    var imageName: String {
        let rank: String
        switch value.lowercased() {
        case "a": rank = "a"
        case "j": rank = "j"
        case "q": rank = "q"
        case "k": rank = "k"
        case "joker": rank = "joker"
        default: rank = value
        }
        let suitLetter: String
        switch suit.lowercased() {
        case "hearts":   suitLetter = "h"
        case "clubs":    suitLetter = "c"
        case "diamonds": suitLetter = "d"
        case "spades":   suitLetter = "s"
        default:         suitLetter = ""
        }
        return "\(rank)\(suitLetter)"
    }
}

private struct WidgetCardData: Decodable {
    let cards: [WidgetCard]
}

enum WidgetCardLookup {
    static let shared: [Int: WidgetCard] = {
        guard let url = Bundle.main.url(forResource: "cards_base", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let deck = try? JSONDecoder().decode(WidgetCardData.self, from: data) else {
            return [:]
        }
        return Dictionary(uniqueKeysWithValues: deck.cards.map { ($0.id, $0) })
    }()

    static func card(id: Int) -> WidgetCard? {
        shared[id]
    }
}

import Foundation

struct Card: Identifiable, Codable {
    let id: Int
    let name: String
    let value: String
    let suit: CardSuit
    let title: String
    let description: String
    
    var suitSymbol: String {
        switch suit {
        case .hearts: return "♥"
        case .clubs: return "♣"
        case .diamonds: return "♦"
        case .spades: return "♠"
        case .joker: return "🃏"
        }
    }
    
    var isRed: Bool {
        suit == .hearts || suit == .diamonds
    }
    
    var imageName: String {
        let valueString: String
        switch value.lowercased() {
        case "a": valueString = "a"
        case "j": valueString = "j"
        case "q": valueString = "q"
        case "k": valueString = "k"
        case "joker": valueString = "joker"
        default: valueString = value
        }
        
        let suitString: String
        switch suit {
        case .hearts: suitString = "h"
        case .clubs: suitString = "c"
        case .diamonds: suitString = "d"
        case .spades: suitString = "s"
        case .joker: suitString = ""
        }
        
        return "\(valueString)\(suitString)"
    }
}

enum CardSuit: String, CaseIterable, Codable {
    case hearts, clubs, diamonds, spades, joker
}

struct CardData: Codable {
    let cards: [Card]
}

struct KarmaData: Codable {
    let karmaConnections1: [String: KarmaConnection]
    let karmaConnections2: [String: KarmaConnection]
}

struct KarmaConnection: Codable {
    let cards: [Int]
    let description: String
}

struct DailyCardResult {
    let card: Card
    let planet: String
    let planetNum: Int
}

struct UserProfile: Codable {
    var name: String
    var birthDate: Date
    
    init(name: String = "", birthDate: Date = Date()) {
        self.name = name
        self.birthDate = birthDate
    }
}


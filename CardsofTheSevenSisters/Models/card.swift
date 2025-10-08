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

struct CardConstants {
    static let ACE_OF_HEARTS = 1
    static let TWO_OF_HEARTS = 2
    static let THREE_OF_HEARTS = 3
    static let FOUR_OF_HEARTS = 4
    static let FIVE_OF_HEARTS = 5
    static let SIX_OF_HEARTS = 6
    static let SEVEN_OF_HEARTS = 7
    static let EIGHT_OF_HEARTS = 8
    static let NINE_OF_HEARTS = 9
    static let TEN_OF_HEARTS = 10
    static let JACK_OF_HEARTS = 11
    static let QUEEN_OF_HEARTS = 12
    static let KING_OF_HEARTS = 13
    static let ACE_OF_CLUBS = 14
    static let TWO_OF_CLUBS = 15
    static let THREE_OF_CLUBS = 16
    static let FOUR_OF_CLUBS = 17
    static let FIVE_OF_CLUBS = 18
    static let SIX_OF_CLUBS = 19
    static let SEVEN_OF_CLUBS = 20
    static let EIGHT_OF_CLUBS = 21
    static let NINE_OF_CLUBS = 22
    static let TEN_OF_CLUBS = 23
    static let JACK_OF_CLUBS = 24
    static let QUEEN_OF_CLUBS = 25
    static let KING_OF_CLUBS = 26
    
    static let ACE_OF_DIAMONDS = 27
    static let TWO_OF_DIAMONDS = 28
    static let THREE_OF_DIAMONDS = 29
    static let FOUR_OF_DIAMONDS = 30
    static let FIVE_OF_DIAMONDS = 31
    static let SIX_OF_DIAMONDS = 32
    static let SEVEN_OF_DIAMONDS = 33
    static let EIGHT_OF_DIAMONDS = 34
    static let NINE_OF_DIAMONDS = 35
    static let TEN_OF_DIAMONDS = 36
    static let JACK_OF_DIAMONDS = 37
    static let QUEEN_OF_DIAMONDS = 38
    static let KING_OF_DIAMONDS = 39
    
    static let ACE_OF_SPADES = 40
    static let TWO_OF_SPADES = 41
    static let THREE_OF_SPADES = 42
    static let FOUR_OF_SPADES = 43
    static let FIVE_OF_SPADES = 44
    static let SIX_OF_SPADES = 45
    static let SEVEN_OF_SPADES = 46
    static let EIGHT_OF_SPADES = 47
    static let NINE_OF_SPADES = 48
    static let TEN_OF_SPADES = 49
    static let JACK_OF_SPADES = 50
    static let QUEEN_OF_SPADES = 51
    static let KING_OF_SPADES = 52
}

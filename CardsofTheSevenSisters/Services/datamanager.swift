import Foundation

class DataManager: ObservableObject {
    static let shared = DataManager()

    @Published var userProfile = UserProfile()
    @Published var explorationDate: Date?
    @Published var isDailyCardRevealed: Bool = false
    @Published var isInitialized: Bool = false

    private var cards: [Card] = []
    private var karmaConnections1: [String: KarmaConnection] = [:]
    private var karmaConnections2: [String: KarmaConnection] = [:]
    private var dailyCardRevealDate: String? {
        get { UserDefaults.standard.string(forKey: "dailyCardRevealDate") }
        set { UserDefaults.standard.set(newValue, forKey: "dailyCardRevealDate") }
    }

    private init() {
        // Only load critical synchronous data
        loadUserProfile()
        checkDailyCardRevealStatus()

        // Load heavy data asynchronously in background
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.loadCardData()
            self?.loadKarmaData()

            DispatchQueue.main.async {
                self?.isInitialized = true
            }
        }
    }

    private func loadCardData() {
        guard let url = Bundle.main.url(forResource: "cards_base", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let cardData = try? JSONDecoder().decode(CardData.self, from: data) else {
            createFallbackCards()
            return
        }

        cards = cardData.cards
    }

    private func createFallbackCards() {
        for i in 1...52 {
            let suit: CardSuit
            let suitOffset: Int

            switch i {
            case 1...13:
                suit = .hearts
                suitOffset = 0
            case 14...26:
                suit = .clubs
                suitOffset = 13
            case 27...39:
                suit = .diamonds
                suitOffset = 26
            case 40...52:
                suit = .spades
                suitOffset = 39
            default:
                suit = .hearts
                suitOffset = 0
            }

            let cardIndex = i - suitOffset
            let values = ["", "A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]
            let faceNames = ["", "ACE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE", "TEN", "JACK", "QUEEN", "KING"]

            let card = Card(
                id: i,
                name: "\(faceNames[cardIndex]) OF \(suit.rawValue.uppercased())",
                value: values[cardIndex],
                suit: suit,
                title: "The \(faceNames[cardIndex]) of \(suit.rawValue.capitalized)",
                description: "No description available."
            )
            cards.append(card)
        }
    }

    private func loadKarmaData() {
        guard let url = Bundle.main.url(forResource: "karma_cards", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let karmaData = try? JSONDecoder().decode(KarmaData.self, from: data) else {
            karmaConnections1 = [:]
            karmaConnections2 = [:]
            return
        }

        karmaConnections1 = karmaData.karmaConnections1
        karmaConnections2 = karmaData.karmaConnections2
    }
    
    
    private func checkDailyCardRevealStatus() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        
        let todayString = formatter.string(from: Date())
        
        if let lastRevealDate = dailyCardRevealDate {
            if lastRevealDate == todayString {
                isDailyCardRevealed = UserDefaults.standard.bool(forKey: "isDailyCardRevealed")
            } else {
                resetDailyCardReveal()
            }
        } else {
            resetDailyCardReveal()
        }
    }
    
    func markDailyCardAsRevealed() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        
        let todayString = formatter.string(from: Date())
        
        DispatchQueue.main.async {
            self.isDailyCardRevealed = true
        }
        dailyCardRevealDate = todayString
        UserDefaults.standard.set(true, forKey: "isDailyCardRevealed")
    }
    
    private func resetDailyCardReveal() {
        isDailyCardRevealed = false
        UserDefaults.standard.set(false, forKey: "isDailyCardRevealed")
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        dailyCardRevealDate = formatter.string(from: Date())
    }
    
    func getTodayCard() -> Card {
        let calendar = Calendar.current
        let now = explorationDate ?? Date()
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: now) ?? 1
        let cardId = ((dayOfYear - 1) % 52) + 1
        return getCard(by: cardId)
    }

    func getCard(by id: Int) -> Card {
        guard id >= 1 && id <= 52 else {
            return cards.first { $0.id == 1 } ?? createFallbackCard(id: 1)
        }

        return cards.first { $0.id == id } ?? createFallbackCard(id: id)
    }

    private func createFallbackCard(id: Int) -> Card {
        let suit: CardSuit
        let suitOffset: Int

        switch id {
        case 1...13:
            suit = .hearts
            suitOffset = 0
        case 14...26:
            suit = .clubs
            suitOffset = 13
        case 27...39:
            suit = .diamonds
            suitOffset = 26
        case 40...52:
            suit = .spades
            suitOffset = 39
        default:
            suit = .hearts
            suitOffset = 0
        }

        let cardIndex = id - suitOffset
        let values = ["", "A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]
        let faceNames = ["", "ACE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE", "TEN", "JACK", "QUEEN", "KING"]

        return Card(
            id: id,
            name: "\(faceNames[cardIndex]) OF \(suit.rawValue.uppercased())",
            value: values[cardIndex],
            suit: suit,
            title: "The \(faceNames[cardIndex]) of \(suit.rawValue.capitalized)",
            description: "Card description not available."
        )
    }

    func getKarmaConnections(for cardId: Int) -> [KarmaConnection] {
        guard cardId >= 1 && cardId <= 52 else {
            return []
        }

        var connections: [KarmaConnection] = []
        let cardIdString = String(cardId)

        if let connection1 = karmaConnections1[cardIdString] {
            let validCards = connection1.cards.filter { $0 >= 1 && $0 <= 52 }
            if !validCards.isEmpty {
                connections.append(KarmaConnection(cards: validCards, description: connection1.description))
            }
        }

        if let connection2 = karmaConnections2[cardIdString] {
            let validCards = connection2.cards.filter { $0 >= 1 && $0 <= 52 }
            if !validCards.isEmpty {
                connections.append(KarmaConnection(cards: validCards, description: connection2.description))
            }
        }

        return connections
    }

    func validateBirthDate(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()

        if date > now {
            return false
        }

        let ageComponents = calendar.dateComponents([.year], from: date, to: now)
        if let years = ageComponents.year, years > 150 {
            return false
        }

        return true
    }

    func updateProfile(name: String, birthDate: Date) -> Bool {
        guard validateBirthDate(birthDate) else {
            return false
        }

        userProfile.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        userProfile.birthDate = birthDate
        saveUserProfile()
        return true
    }

    func saveUserProfile() {
        if let data = try? JSONEncoder().encode(userProfile) {
            UserDefaults.standard.set(data, forKey: "userProfile")
        }
    }

    private func loadUserProfile() {
        if let data = UserDefaults.standard.data(forKey: "userProfile"),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            userProfile = profile
        }
    }

    var isProfileComplete: Bool {
        !userProfile.name.isEmpty
    }
    
    // Clear Profile Extension for Sign Out
    func clearProfile() {
        // Reset profile to default
        userProfile = UserProfile()
        isDailyCardRevealed = false
        explorationDate = nil
        
        // Clear any saved profile data
        UserDefaults.standard.removeObject(forKey: "userProfile")
        UserDefaults.standard.removeObject(forKey: "dailyCardRevealDate")
        UserDefaults.standard.removeObject(forKey: "isDailyCardRevealed")
    }
}

// MARK: - Planetary Period Data Models
struct PlanetaryPeriodData: Codable {
    let planetaryPeriods: [String: PlanetaryPeriod]
}

struct PlanetaryPeriod: Codable {
    let birthday: String
    let mercury: PeriodRange
    let venus: PeriodRange
    let mars: PeriodRange
    let jupiter: PeriodRange
    let saturn: PeriodRange
    let uranus: PeriodRange
    let neptune: PeriodRange
}

struct PeriodRange: Codable {
    let start: String
    let end: String
}

// MARK: - 52-Day Cycle Extension
extension DataManager {
    
    // Load planetary periods from JSON with proper error handling
    private func loadPlanetaryPeriods() -> [String: PlanetaryPeriod]? {
        // Try different possible paths for the JSON file
        let possiblePaths = [
            ("birth_card_planetary_periods", "json", "Resources/Data"),
            ("birth_card_planetary_periods", "json", "resources/data"),
            ("birth_card_planetary_periods", "json", nil)
        ]
        
        for (resource, ext, subdir) in possiblePaths {
            if let url = Bundle.main.url(forResource: resource, withExtension: ext, subdirectory: subdir),
               let data = try? Data(contentsOf: url) {
                
                do {
                    let periodData = try JSONDecoder().decode(PlanetaryPeriodData.self, from: data)
                    return periodData.planetaryPeriods
                } catch {
                    continue
                }
            }
        }

        return nil
    }
    
    // Get planetary period for a birth date
    func getPlanetaryPeriod(for birthDate: Date) -> PlanetaryPeriod? {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        let birthKey = formatter.string(from: birthDate)

        guard let periods = loadPlanetaryPeriods(),
              let period = periods[birthKey] else {
            return nil
        }
        
        return period
    }
    
    // Get current planetary phase name
    func getCurrentPlanetaryPhase(for birthDate: Date) -> String {
        guard let period = getPlanetaryPeriod(for: birthDate) else {
            return "Mercury" // fallback
        }
        
        let calendar = Calendar.current
        let now = explorationDate ?? Date()
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: now) ?? 1
        
        // Convert MM/dd format to day of year for comparison
        let phases: [(String, PeriodRange)] = [
            ("Mercury", period.mercury),
            ("Venus", period.venus),
            ("Mars", period.mars),
            ("Jupiter", period.jupiter),
            ("Saturn", period.saturn),
            ("Uranus", period.uranus),
            ("Neptune", period.neptune)
        ]
        
        for (phaseName, range) in phases {
            if let startDay = dayOfYearFromMMDD(range.start),
               let endDay = dayOfYearFromMMDD(range.end) {
                
                if startDay <= endDay {
                    // Normal range within same year
                    if dayOfYear >= startDay && dayOfYear <= endDay {
                        return phaseName
                    }
                } else {
                    // Range crosses year boundary (e.g., Dec 15 - Jan 10)
                    if dayOfYear >= startDay || dayOfYear <= endDay {
                        return phaseName
                    }
                }
            }
        }
        
        return "Mercury" // fallback
    }
    
    // Helper function to convert MM/dd to day of year
    private func dayOfYearFromMMDD(_ dateString: String) -> Int? {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        
        guard let date = formatter.date(from: dateString) else { return nil }
        
        // Set to current year for comparison
        var components = calendar.dateComponents([.month, .day], from: date)
        components.year = currentYear
        
        guard let fullDate = calendar.date(from: components) else { return nil }
        
        return calendar.ordinality(of: .day, in: .year, for: fullDate)
    }
    
    // Get current planetary range for date calculations
    func getCurrentPlanetaryRange(for birthDate: Date) -> PeriodRange? {
        guard let period = getPlanetaryPeriod(for: birthDate) else { return nil }
        
        let currentPhase = getCurrentPlanetaryPhase(for: birthDate)
        
        switch currentPhase {
        case "Mercury": return period.mercury
        case "Venus": return period.venus
        case "Mars": return period.mars
        case "Jupiter": return period.jupiter
        case "Saturn": return period.saturn
        case "Uranus": return period.uranus
        case "Neptune": return period.neptune
        default: return period.mercury
        }
    }
    
    // Calculate 52-day cycle dates
    func getCycleDates(for birthDate: Date) -> (start: Date, end: Date)? {
        guard let range = getCurrentPlanetaryRange(for: birthDate) else { return nil }
        
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: explorationDate ?? Date())
        
        // Parse start date
        guard let startDate = dateFromMMDD(range.start, year: currentYear),
              let endDate = dateFromMMDD(range.end, year: currentYear) else {
            return nil
        }
        
        // Handle year boundary crossing
        if endDate < startDate {
            // End date is in next year
            let nextYear = currentYear + 1
            guard let adjustedEndDate = dateFromMMDD(range.end, year: nextYear) else {
                return nil
            }
            return (start: startDate, end: adjustedEndDate)
        }
        
        return (start: startDate, end: endDate)
    }
    
    // Helper to create date from MM/dd string
    private func dateFromMMDD(_ dateString: String, year: Int) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter.date(from: "\(dateString)/\(year)")
    }
    
    // Get previous cycle dates
    func getPreviousCycleDates(for birthDate: Date) -> (start: Date, end: Date)? {
        guard let currentDates = getCycleDates(for: birthDate) else { return nil }
        
        let calendar = Calendar.current
        let duration = calendar.dateComponents([.day], from: currentDates.start, to: currentDates.end).day ?? 52
        
        let previousEnd = calendar.date(byAdding: .day, value: -1, to: currentDates.start)!
        let previousStart = calendar.date(byAdding: .day, value: -duration, to: previousEnd)!
        
        return (start: previousStart, end: previousEnd)
    }
    
    // Get next cycle dates
    func getNextCycleDates(for birthDate: Date) -> (start: Date, end: Date)? {
        guard let currentDates = getCycleDates(for: birthDate) else { return nil }
        
        let calendar = Calendar.current
        let duration = calendar.dateComponents([.day], from: currentDates.start, to: currentDates.end).day ?? 52
        
        let nextStart = calendar.date(byAdding: .day, value: 1, to: currentDates.end)!
        let nextEnd = calendar.date(byAdding: .day, value: duration, to: nextStart)!
        
        return (start: nextStart, end: nextEnd)
    }
    
    // Format date range with smart year handling
    func formatDateRange(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        let startString = formatter.string(from: start)
        let endString = formatter.string(from: end)

        return "\(startString) - \(endString)"
    }
}

// MARK: - Supporting Structures
struct CardDefinition: Codable, Identifiable {
    let id: Int
    let name: String
    let value: String
    let suit: String
    let title: String
}

private struct CardDeck: Codable {
    let cards: [CardDefinition]
}

private let cardsByID: [Int: CardDefinition] = {
    guard let url = Bundle.main.url(forResource: "cards_base", withExtension: "json"),
          let data = try? Data(contentsOf: url),
          let deck = try? JSONDecoder().decode(CardDeck.self, from: data) else {
        return [:]
    }
    return Dictionary(uniqueKeysWithValues: deck.cards.map { ($0.id, $0) })
}()

func getCardDefinition(by id: Int) -> CardDefinition? {
    cardsByID[id]
}

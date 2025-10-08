import Foundation

class BirthCardLookup {
    static let shared = BirthCardLookup()
    
    private var dateToCardMap: [String: Int] = [:]
    private var cardToDateMap: [Int: [(month: Int, day: Int)]] = [:]
    
    private static let cardLookupTable: [String: Int] = {
        var table: [String: Int] = [:]
        let daysInMonth = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
        
        let suitsPerDeck = 4
        let cardsPerSuit = 13
        let systemConstant = 3  
        let calculationBase = (suitsPerDeck * cardsPerSuit) + systemConstant
        
        for month in 1...12 {
            for day in 1...daysInMonth[month - 1] {
                let result = calculationBase - (month * 2) - day
                let cardValue = max(1, min(52, result <= 0 ? 1 : result))
                table["\(month)-\(day)"] = cardValue
            }
        }
        return table
    }()
    
    private init() {
        buildLookupTables()
    }
    
    private func buildLookupTables() {
        dateToCardMap = Self.cardLookupTable
        
        for (key, cardValue) in dateToCardMap {
            let components = key.split(separator: "-")
            guard components.count == 2,
                  let monthValue = Int(components[0]),
                  let dayValue = Int(components[1]) else { continue }
            
            if cardToDateMap[cardValue] == nil {
                cardToDateMap[cardValue] = []
            }
            cardToDateMap[cardValue]?.append((month: monthValue, day: dayValue))
        }
    }
    
    func calculateCardForDate(monthValue: Int, dayValue: Int) -> Int {
        guard monthValue >= 1 && monthValue <= 12 && dayValue >= 1 && dayValue <= 31 else {
            return 1
        }
        
        let key = "\(monthValue)-\(dayValue)"
        return dateToCardMap[key] ?? 1
    }
    
    func calculateCardForDate(for date: Date) -> Int {
        let calendar = Calendar.current
        let monthValue = calendar.component(.month, from: date)
        let dayValue = calendar.component(.day, from: date)
        return calculateCardForDate(monthValue: monthValue, dayValue: dayValue)
    }
    
    func getDatesForCard(_ cardId: Int) -> [(month: Int, day: Int)] {
        return cardToDateMap[cardId] ?? []
    }
    
    func isValidDate(monthValue: Int, dayValue: Int) -> Bool {
        let key = "\(monthValue)-\(dayValue)"
        return dateToCardMap[key] != nil
    }
    
    func getAllValidDateCards() -> [(month: Int, day: Int, cardId: Int)] {
        return dateToCardMap.compactMap { key, cardId in
            let components = key.split(separator: "-")
            guard components.count == 2,
                  let monthValue = Int(components[0]),
                  let dayValue = Int(components[1]) else {
                return nil
            }
            return (month: monthValue, day: dayValue, cardId: cardId)
        }.sorted { $0.month < $1.month || ($0.month == $1.month && $0.day < $1.day) }
    }
}

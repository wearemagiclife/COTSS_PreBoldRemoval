import Foundation

enum WidgetPlanetaryLookup {
    private struct PeriodsPayload: Decodable {
        let planetaryPeriods: [String: Period]
    }

    private struct Period: Decodable {
        let birthday: String
        let mercury: Range
        let venus: Range
        let mars: Range
        let jupiter: Range
        let saturn: Range
        let uranus: Range
        let neptune: Range
    }

    private struct Range: Decodable {
        let start: String
        let end: String
    }

    private static let mmddFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MM/dd"
        return f
    }()

    private static let periods: [String: Period] = {
        guard let url = Bundle.main.url(forResource: "birth_card_planetary_periods", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let payload = try? JSONDecoder().decode(PeriodsPayload.self, from: data) else {
            return [:]
        }
        return payload.planetaryPeriods
    }()

    static func currentPlanet(birthDate: Date, on evaluationDate: Date) -> String {
        let birthKey = mmddFormatter.string(from: birthDate)
        guard let period = periods[birthKey] else { return "Mercury" }

        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: evaluationDate) ?? 1

        let phases: [(String, Range)] = [
            ("Mercury", period.mercury),
            ("Venus", period.venus),
            ("Mars", period.mars),
            ("Jupiter", period.jupiter),
            ("Saturn", period.saturn),
            ("Uranus", period.uranus),
            ("Neptune", period.neptune)
        ]

        for (name, range) in phases {
            if let startDay = dayOfYearFromMMDD(range.start),
               let endDay = dayOfYearFromMMDD(range.end) {
                if startDay <= endDay {
                    if dayOfYear >= startDay && dayOfYear <= endDay { return name }
                } else {
                    if dayOfYear >= startDay || dayOfYear <= endDay { return name }
                }
            }
        }
        return "Mercury"
    }

    static func phaseNumber(from planet: String) -> Int {
        switch planet.lowercased() {
        case "mercury": return 1
        case "venus":   return 2
        case "mars":    return 3
        case "jupiter": return 4
        case "saturn":  return 5
        case "uranus":  return 6
        case "neptune": return 7
        default:        return 1
        }
    }

    private static func dayOfYearFromMMDD(_ dateString: String) -> Int? {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        guard let date = mmddFormatter.date(from: dateString) else { return nil }
        var components = calendar.dateComponents([.month, .day], from: date)
        components.year = currentYear
        guard let full = calendar.date(from: components) else { return nil }
        return calendar.ordinality(of: .day, in: .year, for: full)
    }
}

#if DEBUG
import Foundation

// Map planet name to period number used by CardCalculationService.extractCycleCard
private func periodNumber(from planet: String) -> Int {
    switch planet.lowercased() {
    case "mercury": return 1
    case "venus": return 2
    case "mars": return 3
    case "jupiter": return 4
    case "saturn": return 5
    case "uranus": return 6
    case "neptune": return 7
    default: return 1
    }
}

public enum Debug52DayDiagnostics {
    /// Print a side-by-side comparison of 52-day period and card from:
    /// - Algorithm (CardCalculationService.retrieveCurrentPhase)
    /// - JSON planetary phase (DataManager.getCurrentPlanetaryPhase)
    /// Also prints current/prev/next date ranges from DataManager.
    public static func run(birthDate: Date, evaluationDate: Date = Date()) {
        let dm = DataManager.shared
        let calc = CardCalculationService()

        // Birth card id
        let birthId = BirthCardLookup.shared.calculateCardForDate(for: birthDate)
        let age = calc.calculatePersonAge(birthDate: birthDate, onDate: evaluationDate)

        // Algorithm-based period number
        let algPeriod = calc.retrieveCurrentPhase(userBirthDate: birthDate, evaluationDate: evaluationDate)

        // JSON-based phase name and mapped period number
        let planet = dm.getCurrentPlanetaryPhase(for: birthDate)
        let jsonPeriod = periodNumber(from: planet)

        // Cards using each period number
        let cardAlg = calc.extractCycleCard(primaryCard: birthId, personAge: age, phaseNumber: algPeriod)
        let cardJSON = calc.extractCycleCard(primaryCard: birthId, personAge: age, phaseNumber: jsonPeriod)

        // Date ranges from DataManager (JSON-based)
        let currentRange = dm.getCycleDates(for: birthDate)
        let prevRange = dm.getPreviousCycleDates(for: birthDate)
        let nextRange = dm.getNextCycleDates(for: birthDate)

        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        func rangeText(_ r: (start: Date, end: Date)?) -> String {
            guard let r = r else { return "nil" }
            return "\(fmt.string(from: r.start)) - \(fmt.string(from: r.end))"
        }

        print("""
        ================= 52-Day Diagnostics =================
        BirthDate:      \(birthDate)
        EvaluationDate: \(evaluationDate)
        BirthCardID:    \(birthId)
        
        ALG period:     \(algPeriod)  -> card id \(cardAlg)
        JSON phase:     \(planet) (\(jsonPeriod)) -> card id \(cardJSON)
        
        Current range:  \(rangeText(currentRange))
        Previous range: \(rangeText(prevRange))
        Next range:     \(rangeText(nextRange))
        ======================================================
        """)
    }
}
#endif

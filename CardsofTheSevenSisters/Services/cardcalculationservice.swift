import Foundation

class CardCalculationService: ObservableObject {
    private var s0 = Array(0...52)
    private var s1 = Array(0...52)
    
    private var userCalendar: Calendar {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        return calendar
    }
    
    private var transformationLookup: [Int: Int] {
        return [
            1: 27, 2: 14, 3: 1, 4: 43, 5: 30, 6: 17, 7: 8, 8: 46,
            9: 33, 10: 24, 12: 49, 13: 15, 14: 2, 15: 40, 16: 31,
            17: 18, 18: 5, 19: 47, 20: 34, 22: 12, 23: 50, 24: 37,
            25: 3, 26: 41, 27: 28, 28: 19, 29: 6, 30: 44, 31: 35,
            32: 22, 33: 9, 34: 51, 35: 38, 36: 25, 37: 42, 38: 29,
            39: 16, 40: 7, 41: 45, 42: 32, 43: 23, 44: 10, 45: 48,
            46: 39, 47: 26, 48: 13, 49: 4, 50: 20, 51: 36
        ]
    }
    
    private func resetArrayStructure() {
        s0 = Array(0...52)
        s1 = Array(0...52)
    }
    
    private func performTransformation() {
        guard s0.count > 52 && s1.count > 52 else {
            return
        }
        
        for (sourceIndex, targetIndex) in transformationLookup {
            s1[targetIndex] = s0[sourceIndex]
        }
        
        for c in 1...52 {
            s0[c] = s1[c]
        }
    }
    
    func generateTimeInfluence(userBirthDate: Date, primaryCard: Int, evaluationDate: Date) -> DailyCardResult {
        guard primaryCard >= 1 && primaryCard <= 52 else {
            let fallbackCard = DataManager.shared.getCard(by: 1)
            return DailyCardResult(card: fallbackCard, planet: "Mer", planetNum: 1)
        }
        
        resetArrayStructure()
        
        let normalizedStart = userCalendar.startOfDay(for: userBirthDate)
        let normalizedTarget = userCalendar.startOfDay(for: evaluationDate)
        
        let totalDays = userCalendar.dateComponents([.day], from: normalizedStart, to: normalizedTarget).day ?? 0
        let weekCount = totalDays / 7
        let remainingDays = totalDays % 7
        
        for _ in 1...(weekCount + 1) {
            performTransformation()
        }
        
        var position = 1
        while position <= 52 && s0[position] != primaryCard {
            position += 1
        }
        
        position = position + 1
        if (position + remainingDays) > 52 {
            position = position - 52
        }
        
        let finalIndex = position + remainingDays
        guard finalIndex >= 1 && finalIndex <= 52 && s1.count > finalIndex else {
            let fallbackCard = DataManager.shared.getCard(by: primaryCard)
            return DailyCardResult(card: fallbackCard, planet: "Mer", planetNum: 1)
        }
        
        let celestialPhase = retrieveCelestialPhase(remainingDays + 1)
        let resultCardId = s1[finalIndex]
        let resultCard = DataManager.shared.getCard(by: resultCardId)
        
        return DailyCardResult(
            card: resultCard,
            planet: celestialPhase,
            planetNum: remainingDays + 1
        )
    }
    
    func deriveAnnualInfluence(primaryCard: Int, personAge: Int) -> Int {
        guard primaryCard >= 1 && primaryCard <= 52 && personAge >= 0 else {
            return 1
        }
        
        resetArrayStructure()
        
        let cycleAge = personAge / 7
        
        if cycleAge < 1 {
            performTransformation()
            var position = 1
            while position <= 52 && s1[position] != primaryCard {
                position += 1
            }
            
            if position + personAge + 1 > 52 {
                position = position - 52
            }
            
            let resultIndex = position + personAge + 1
            guard resultIndex >= 1 && resultIndex <= 52 && s1.count > resultIndex else {
                return primaryCard
            }
            
            return s1[resultIndex]
        } else {
            let cycles = cycleAge
            let cycleRemainder = personAge - (cycles * 7)
            
            for _ in 1...(cycles + 1) {
                performTransformation()
            }
            
            var position = 1
            while position <= 52 && s0[position] != primaryCard {
                position += 1
                if position > 52 { break }
            }
            
            if (position + cycleRemainder + 1) > 52 {
                position = position - 52
            }
            
            let resultIndex = position + cycleRemainder + 1
            guard resultIndex >= 1 && resultIndex <= 52 && s1.count > resultIndex else {
                return primaryCard
            }
            
            return s1[resultIndex]
        }
    }
    
    func extractCycleCard(primaryCard: Int, personAge: Int, phaseNumber: Int) -> Int {
        guard primaryCard >= 1 && primaryCard <= 52 && personAge >= 0 && phaseNumber >= 1 && phaseNumber <= 7 else {
            return 1
        }
        
        resetArrayStructure()
        
        for _ in 1...(personAge + 1) {
            performTransformation()
        }
        
        var position = 1
        while position <= 52 && s0[position] != primaryCard {
            position += 1
        }
        
        var adjustedPosition = position + phaseNumber
        if adjustedPosition > 52 {
            adjustedPosition = adjustedPosition - 52
        }
        
        guard adjustedPosition >= 1 && adjustedPosition <= 52 && s0.count > adjustedPosition else {
            return primaryCard
        }
        
        return s0[adjustedPosition]
    }
    
    func retrieveCurrentPhase(userBirthDate: Date, evaluationDate: Date) -> Int {
        let normalizedStart = userCalendar.startOfDay(for: userBirthDate)
        let normalizedTarget = userCalendar.startOfDay(for: evaluationDate)
        
        let dayCount = userCalendar.dateComponents([.day], from: normalizedStart, to: normalizedTarget).day ?? 0
        
        let yearProgress = dayCount % 365
        let phasePosition = (yearProgress / 52) + 1
        
        let boundedPhase = max(1, min(phasePosition, 7))
        
        return boundedPhase
    }
    
    func calculatePersonAge(birthDate: Date, onDate: Date = Date()) -> Int {
        let ageData = userCalendar.dateComponents([.year], from: birthDate, to: onDate)
        return ageData.year ?? 0
    }
    
    func retrieveCelestialPhase(_ dayValue: Int) -> String {
        let celestialCodes = ["", "Mer", "Ven", "Mar", "Jup", "Sat", "Ura", "Nep"]
        let code = celestialCodes.indices.contains(dayValue) ? celestialCodes[dayValue] : ""
        return expandCelestialCode(code)
    }
    
    private func expandCelestialCode(_ code: String) -> String {
        switch code {
        case "Mer": return "Mercury"
        case "Ven": return "Venus"
        case "Mar": return "Mars"
        case "Jup": return "Jupiter"
        case "Sat": return "Saturn"
        case "Ura": return "Uranus"
        case "Nep": return "Neptune"
        default: return ""
        }
    }
}

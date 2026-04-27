import Foundation

struct WidgetCalc {
    private static let transformationLookup: [Int: Int] = [
        1: 27, 2: 14, 3: 1, 4: 43, 5: 30, 6: 17, 7: 8, 8: 46,
        9: 33, 10: 24, 12: 49, 13: 15, 14: 2, 15: 40, 16: 31,
        17: 18, 18: 5, 19: 47, 20: 34, 22: 12, 23: 50, 24: 37,
        25: 3, 26: 41, 27: 28, 28: 19, 29: 6, 30: 44, 31: 35,
        32: 22, 33: 9, 34: 51, 35: 38, 36: 25, 37: 42, 38: 29,
        39: 16, 40: 7, 41: 45, 42: 32, 43: 23, 44: 10, 45: 48,
        46: 39, 47: 26, 48: 13, 49: 4, 50: 20, 51: 36
    ]

    private static var userCalendar: Calendar {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        return calendar
    }

    static func birthCardID(monthValue: Int, dayValue: Int) -> Int {
        guard monthValue >= 1, monthValue <= 12, dayValue >= 1, dayValue <= 31 else { return 1 }
        let calculationBase = (4 * 13) + 3
        let result = calculationBase - (monthValue * 2) - dayValue
        return max(1, min(52, result <= 0 ? 1 : result))
    }

    static func dailyInfluence(birthDate: Date, primaryCard: Int, on evaluationDate: Date) -> (cardID: Int, planetNum: Int) {
        guard primaryCard >= 1 && primaryCard <= 52 else {
            return (1, 1)
        }

        var s0 = Array(0...52)
        var s1 = Array(0...52)

        let start = userCalendar.startOfDay(for: birthDate)
        let target = userCalendar.startOfDay(for: evaluationDate)
        let totalDays = userCalendar.dateComponents([.day], from: start, to: target).day ?? 0
        let weekCount = totalDays / 7
        let remainingDays = totalDays % 7

        for _ in 1...(weekCount + 1) {
            transform(&s0, &s1)
        }

        var position = 1
        while position <= 52 && s0[position] != primaryCard {
            position += 1
        }

        position += 1
        if (position + remainingDays) > 52 {
            position -= 52
        }

        let finalIndex = position + remainingDays
        guard finalIndex >= 1 && finalIndex <= 52 && s1.count > finalIndex else {
            return (primaryCard, remainingDays + 1)
        }

        return (s1[finalIndex], remainingDays + 1)
    }

    static func yearlyCardID(primaryCard: Int, personAge: Int) -> Int {
        guard primaryCard >= 1 && primaryCard <= 52 && personAge >= 0 else {
            return 1
        }

        var s0 = Array(0...52)
        var s1 = Array(0...52)

        let cycleAge = personAge / 7

        if cycleAge < 1 {
            transform(&s0, &s1)
            var position = 1
            while position <= 52 && s1[position] != primaryCard {
                position += 1
            }

            if position + personAge + 1 > 52 {
                position -= 52
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
                transform(&s0, &s1)
            }

            var position = 1
            while position <= 52 && s0[position] != primaryCard {
                position += 1
                if position > 52 { break }
            }

            if (position + cycleRemainder + 1) > 52 {
                position -= 52
            }

            let resultIndex = position + cycleRemainder + 1
            guard resultIndex >= 1 && resultIndex <= 52 && s1.count > resultIndex else {
                return primaryCard
            }
            return s1[resultIndex]
        }
    }

    static func cycleCardID(primaryCard: Int, personAge: Int, phaseNumber: Int) -> Int {
        guard primaryCard >= 1 && primaryCard <= 52 && personAge >= 0 && phaseNumber >= 1 && phaseNumber <= 7 else {
            return 1
        }

        var s0 = Array(0...52)
        var s1 = Array(0...52)

        for _ in 1...(personAge + 1) {
            transform(&s0, &s1)
        }

        var position = 1
        while position <= 52 && s0[position] != primaryCard {
            position += 1
        }

        var adjusted = position + phaseNumber
        if adjusted > 52 { adjusted -= 52 }

        guard adjusted >= 1 && adjusted <= 52 && s0.count > adjusted else {
            return primaryCard
        }
        return s0[adjusted]
    }

    static func personAge(birthDate: Date, onDate: Date) -> Int {
        userCalendar.dateComponents([.year], from: birthDate, to: onDate).year ?? 0
    }

    private static func transform(_ s0: inout [Int], _ s1: inout [Int]) {
        guard s0.count > 52 && s1.count > 52 else { return }
        for (src, tgt) in transformationLookup {
            s1[tgt] = s0[src]
        }
        for c in 1...52 {
            s0[c] = s1[c]
        }
    }
}

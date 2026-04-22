import EventKit
import Foundation

class CalendarSyncService {
    static let shared = CalendarSyncService()
    private let eventStore = EKEventStore()
    private let eventIDsKey = "calendarSyncEventIDs"

    private init() {}

    // MARK: - Public API

    func requestAccess() async -> Bool {
        if #available(iOS 17.0, *) {
            do {
                return try await eventStore.requestWriteOnlyAccessToEvents()
            } catch {
                return false
            }
        } else {
            return await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .event) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func syncCalendarEvents(for productID: String, birthDate: Date) async {
        guard await requestAccess() else { return }

        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let days = durationDays(for: productID)
        let calc = CardCalculationService()
        let birthCardId = BirthCardLookup.shared.calculateCardForDate(for: birthDate)
        let birthMMDD = cal.dateComponents([.month, .day], from: birthDate)

        // Snapshot description dictionaries on main thread to avoid data races
        let dailyDescs = await MainActor.run { DescriptionRepository.shared.dailyDescriptions }
        let cycleDescs = await MainActor.run { DescriptionRepository.shared.fiftyTwoDescriptions }
        let yearlyDescs = await MainActor.run { DescriptionRepository.shared.yearlyDescriptions }

        var savedEvents: [EKEvent] = []
        var previousPlanet: String? = nil

        for offset in 0..<days {
            guard let date = cal.date(byAdding: .day, value: offset, to: today) else { continue }

            // Daily card event
            let dailyResult = calc.generateTimeInfluence(
                userBirthDate: birthDate,
                primaryCard: birthCardId,
                evaluationDate: date
            )
            let dailyShortName = "\(dailyResult.card.value)\(dailyResult.card.suitSymbol)"

            if let event = makeAllDayEvent(
                title: dailyShortName,
                notes: "Today's card is the \(dailyShortName) in \(dailyResult.planet).\n\nExplore your cards: sevensistersapp://",
                date: date
            ) {
                savedEvents.append(event)
            }

            // 52-day cycle event at each new planetary period boundary
            let planet = DataManager.shared.getPlanetaryPhase(for: birthDate, on: date)
            if let prev = previousPlanet, planet != prev {
                let age = calc.calculatePersonAge(birthDate: birthDate, onDate: date)
                let cycleCardId = calc.extractCycleCard(
                    primaryCard: birthCardId,
                    personAge: age,
                    phaseNumber: planetNumber(planet)
                )
                let cycleCard = DataManager.shared.getCard(by: cycleCardId)
                let cycleShortName = "\(cycleCard.value)\(cycleCard.suitSymbol)"

                if let event = makeAllDayEvent(
                    title: "Welcoming the \(cycleShortName) in \(planet)",
                    notes: "For the next 52 days, the \(cycleShortName) will offer insights to the areas of life highlighted by \(planet).\n\nExplore your cards: sevensistersapp://",
                    date: date
                ) {
                    savedEvents.append(event)
                }
            }
            previousPlanet = planet

            // Yearly card event on the user's birthday
            let dc = cal.dateComponents([.month, .day], from: date)
            if dc.month == birthMMDD.month && dc.day == birthMMDD.day {
                let age = calc.calculatePersonAge(birthDate: birthDate, onDate: date)
                let yearlyCardId = calc.deriveAnnualInfluence(primaryCard: birthCardId, personAge: age)
                let yearlyCard = DataManager.shared.getCard(by: yearlyCardId)
                let yearlyShortName = "\(yearlyCard.value)\(yearlyCard.suitSymbol)"

                if let event = makeAllDayEvent(
                    title: "Happy Birthday from the \(yearlyShortName)!",
                    notes: "Happy Birthday from Cards of the Seven Sisters! Wishing you a beautiful year guided by the \(yearlyShortName).\n\nExplore your cards: sevensistersapp://",
                    date: date
                ) {
                    savedEvents.append(event)
                }
            }
        }

        // Batch save and commit
        for event in savedEvents {
            try? eventStore.save(event, span: .thisEvent, commit: false)
        }
        try? eventStore.commit()

        let newIDs = savedEvents.compactMap { $0.eventIdentifier }.filter { !$0.isEmpty }
        saveEventIDs(loadEventIDs() + newIDs)
    }

    func removeFutureEvents() async {
        let ids = loadEventIDs()
        guard !ids.isEmpty else { return }

        let today = Calendar.current.startOfDay(for: Date())
        var keptIDs: [String] = []

        for id in ids {
            guard let event = eventStore.event(withIdentifier: id) else { continue }
            if event.startDate >= today {
                try? eventStore.remove(event, span: .thisEvent, commit: false)
            } else {
                keptIDs.append(id)
            }
        }
        try? eventStore.commit()
        saveEventIDs(keptIDs)
    }

    // MARK: - Helpers

    private func makeAllDayEvent(title: String, notes: String, date: Date) -> EKEvent? {
        guard let calendar = findOrCreateAppCalendar() else { return nil }
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.notes = notes
        event.isAllDay = true
        event.startDate = date
        event.endDate = date
        event.calendar = calendar
        return event
    }

    private func findOrCreateAppCalendar() -> EKCalendar? {
        let calendarTitle = "Seven Sisters"

        if let existing = eventStore.calendars(for: .event).first(where: { $0.title == calendarTitle }) {
            return existing
        }

        // Pick the best source: prefer iCloud so it syncs, fall back to local
        let source = eventStore.sources.first(where: { $0.sourceType == .calDAV && $0.title == "iCloud" })
            ?? eventStore.sources.first(where: { $0.sourceType == .local })
            ?? eventStore.defaultCalendarForNewEvents?.source

        guard let source else { return eventStore.defaultCalendarForNewEvents }

        let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
        newCalendar.title = calendarTitle
        newCalendar.source = source
        newCalendar.cgColor = CGColor(red: 0.58, green: 0.47, blue: 0.35, alpha: 1.0) // warm gold

        do {
            try eventStore.saveCalendar(newCalendar, commit: true)
            return newCalendar
        } catch {
            return eventStore.defaultCalendarForNewEvents
        }
    }

    private func planetNumber(_ planet: String) -> Int {
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

    private func durationDays(for productID: String) -> Int {
        if productID.contains("weekly")  { return 7 }
        if productID.contains("6month")  { return 180 }
        if productID.contains("monthly") { return 30 }
        if productID.contains("annual")  { return 365 }
        return 30
    }

    private func saveEventIDs(_ ids: [String]) {
        UserDefaults.standard.set(ids, forKey: eventIDsKey)
    }

    private func loadEventIDs() -> [String] {
        UserDefaults.standard.stringArray(forKey: eventIDsKey) ?? []
    }
}

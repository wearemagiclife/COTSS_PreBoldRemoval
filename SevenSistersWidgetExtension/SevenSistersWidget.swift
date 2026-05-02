import WidgetKit
import SwiftUI

struct SevenSistersEntry: TimelineEntry {
    let date: Date
    let state: State

    enum State {
        case locked
        case missingProfile
        case ready(WidgetCards)
    }
}

struct WidgetCards {
    let daily: WidgetCard
    let planet: String
    let fiftyTwoDay: WidgetCard
    let yearly: WidgetCard
}

struct SevenSistersProvider: TimelineProvider {
    func placeholder(in context: Context) -> SevenSistersEntry {
        Self.mockEntry()
    }

    func getSnapshot(in context: Context, completion: @escaping (SevenSistersEntry) -> Void) {
        completion(Self.mockEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SevenSistersEntry>) -> Void) {
        let now = Date()
        let entry = Self.mockEntry() // TODO: replace with makeEntry(at: now) before shipping
        let nextRefresh = Calendar.current.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 1),
            matchingPolicy: .nextTime
        ) ?? now.addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    static func mockEntry() -> SevenSistersEntry {
        SevenSistersEntry(date: Date(), state: .ready(WidgetCards(
            daily:       WidgetCard(id: 1,  name: "Ace of Hearts",   value: "a", suit: "hearts",   title: ""),
            planet:      "mercury",
            fiftyTwoDay: WidgetCard(id: 14, name: "Ace of Clubs",    value: "a", suit: "clubs",    title: ""),
            yearly:      WidgetCard(id: 27, name: "Ace of Diamonds", value: "a", suit: "diamonds", title: "")
        )))
    }

    static func makeEntry(at date: Date) -> SevenSistersEntry {
        guard WidgetBridge.readIsSubscribed() else {
            return SevenSistersEntry(date: date, state: .locked)
        }

        guard let birthDate = WidgetBridge.readBirthDate() else {
            return SevenSistersEntry(date: date, state: .missingProfile)
        }

        let calendar = Calendar.current
        let birthComps = calendar.dateComponents([.month, .day], from: birthDate)
        let birthCardID = WidgetCalc.birthCardID(
            monthValue: birthComps.month ?? 1,
            dayValue: birthComps.day ?? 1
        )

        let age = WidgetCalc.personAge(birthDate: birthDate, onDate: date)
        let daily = WidgetCalc.dailyInfluence(birthDate: birthDate, primaryCard: birthCardID, on: date)
        let planet = WidgetPlanetaryLookup.currentPlanet(birthDate: birthDate, on: date)
        let phaseNum = WidgetPlanetaryLookup.phaseNumber(from: planet)
        let cycleID = WidgetCalc.cycleCardID(primaryCard: birthCardID, personAge: age, phaseNumber: phaseNum)
        let yearlyID = WidgetCalc.yearlyCardID(primaryCard: birthCardID, personAge: age)

        guard let dailyCard = WidgetCardLookup.card(id: daily.cardID),
              let fiftyTwoCard = WidgetCardLookup.card(id: cycleID),
              let yearlyCard = WidgetCardLookup.card(id: yearlyID) else {
            return SevenSistersEntry(date: date, state: .missingProfile)
        }

        return SevenSistersEntry(
            date: date,
            state: .ready(WidgetCards(
                daily: dailyCard,
                planet: planet,
                fiftyTwoDay: fiftyTwoCard,
                yearly: yearlyCard
            ))
        )
    }
}

private let goldAccent = Color(red: 0.75, green: 0.60, blue: 0.35)

struct SevenSistersWidgetView: View {
    var entry: SevenSistersProvider.Entry

    @Environment(\.widgetFamily) var widgetFamily

    /// Resolves the in-app appearance preference (0=system, 1=light, 2=dark).
    /// `nil` returned for `.system` means inherit from system trait.
    private var preferredColorScheme: ColorScheme? {
        switch WidgetBridge.readAppearanceMode() {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }

    private var isDark: Bool {
        switch WidgetBridge.readAppearanceMode() {
        case 1: return false
        case 2: return true
        default: return true
        }
    }

    var body: some View {
        let scheme = preferredColorScheme
        return Group {
            if let scheme {
                content.environment(\.colorScheme, scheme)
            } else {
                content
            }
        }
        .containerBackground(for: .widget) {
            if isDark {
                ZStack {
                    Color(red: 0.05, green: 0.04, blue: 0.04)
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(goldAccent.opacity(0.30), lineWidth: 0.75)
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color(red: 1.0, green: 0.95, blue: 0.88).opacity(0.08), lineWidth: 10)
                        .blur(radius: 8)
                }
            } else {
                Color(red: 0.86, green: 0.75, blue: 0.55)
            }
        }
        .widgetURL(URL(string: "sevensistersapp://daily"))
    }

    @ViewBuilder
    private var content: some View {
        switch entry.state {
        case .locked:
            lockedView
        case .missingProfile:
            missingProfileView
        case .ready(let cards):
            readyGrid(cards)
        }
    }

    private func readyGrid(_ cards: WidgetCards) -> some View {
        switch widgetFamily {
        case .systemSmall:  AnyView(smallGrid(cards))
        default:            AnyView(mediumGrid(cards))
        }
    }

    private func smallGrid(_ cards: WidgetCards) -> some View {
        GeometryReader { geo in
            // Guard against zero-size on first pass; use 155pt as a safe fallback.
            let safeW = geo.size.width  > 0 ? geo.size.width  : 155
            let safeH = geo.size.height > 0 ? geo.size.height : 155
            let headerH: CGFloat = 24
            let vSpacing: CGFloat = 6
            let hPadding: CGFloat = 4
            let cardGap:  CGFloat = 10
            let cardW = (safeW - hPadding * 2 - cardGap) / 2
            let cardH = min(cardW / (2.5 / 3.5), safeH - headerH - vSpacing * 2)

            VStack(spacing: vSpacing) {
                Text("TODAY'S CARD")
                    .font(.custom("Iowan Old Style", size: 13))
                    .tracking(2)
                    .foregroundStyle(goldAccent)
                    .frame(height: headerH)

                HStack(spacing: cardGap) {
                    cardArt(cards.daily.imageName, width: cardW, height: cardH, isHero: true)
                    cardArt(cards.planet.lowercased(), width: cardW, height: cardH, isHero: true)
                }
            }
            .frame(width: safeW, height: safeH)
        }
    }

    private func mediumGrid(_ cards: WidgetCards) -> some View {
        GeometryReader { geo in
            let safeW = geo.size.width  > 0 ? geo.size.width  : 329
            let safeH = geo.size.height > 0 ? geo.size.height : 155
            let cardAspect: CGFloat = 2.5 / 3.5
            let headerH: CGFloat = 16
            let vSpacing: CGFloat = 6
            let groupGap: CGFloat = 26
            let cardGap:  CGFloat = 22

            let hPadding: CGFloat = 16
            let cardW = (safeW - hPadding - groupGap - cardGap * 2) / 4
            let cardH = min(cardW / cardAspect, safeH - headerH - vSpacing)
            let twoCardGroupW = cardW * 2 + cardGap

            let headingFont = Font.custom("Iowan Old Style", size: 12)

            VStack(spacing: vSpacing) {
                // Header row
                HStack(spacing: 0) {
                    Text("TODAY'S CARD")
                        .font(headingFont)
                        .tracking(2)
                        .foregroundStyle(goldAccent)
                        .frame(width: twoCardGroupW)
                    Spacer().frame(width: groupGap)
                    Text("52-DAY")
                        .font(headingFont)
                        .tracking(2)
                        .foregroundStyle(goldAccent)
                        .frame(width: cardW)
                    Spacer().frame(width: cardGap)
                    Text("YEAR")
                        .font(headingFont)
                        .tracking(2)
                        .foregroundStyle(goldAccent)
                        .frame(width: cardW)
                }
                .frame(height: headerH)

                // Card row
                HStack(spacing: 0) {
                    HStack(spacing: cardGap) {
                        cardArt(cards.daily.imageName, width: cardW, height: cardH, isHero: false)
                        cardArt(cards.planet.lowercased(), width: cardW, height: cardH, isHero: false)
                    }
                    .frame(width: twoCardGroupW)
                    Spacer().frame(width: groupGap)
                    cardArt(cards.fiftyTwoDay.imageName, width: cardW, height: cardH, isHero: false)
                    Spacer().frame(width: cardGap)
                    cardArt(cards.yearly.imageName, width: cardW, height: cardH, isHero: false)
                }
            }
            .frame(width: safeW, height: safeH)
        }
    }

    /// Card image with gold-glow shadow + drop shadow, matching the home view's `darkModeCardEffects`.
    private func cardArt(_ name: String, width: CGFloat, height: CGFloat, isHero: Bool) -> some View {
        let glowOpacity: Double = isHero ? 0.60 : 0.40
        let glowRadius: CGFloat = isHero ? 18 : 10
        return Image(name)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: width, height: height)
            // Gold aura — two layered shadows for a richer bloom
            .shadow(color: isDark ? goldAccent.opacity(glowOpacity) : .clear,
                    radius: glowRadius, x: 0, y: 0)
            .shadow(color: isDark ? goldAccent.opacity(glowOpacity * 0.4) : .clear,
                    radius: glowRadius * 2.5, x: 0, y: 0)
            // Base drop shadow for depth
            .shadow(color: .black.opacity(0.5), radius: 6, x: 0, y: 3)
    }

    private var lockedView: some View {
        Link(destination: URL(string: "sevensistersapp://subscribe")!) {
            VStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(goldAccent)
                Text("Subscribe to unlock")
                    .font(.system(.callout, design: .serif))
                    .foregroundStyle(goldAccent)
                Text("Tap to see your cards")
                    .font(.system(.caption, design: .serif))
                    .foregroundStyle(goldAccent.opacity(0.7))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var missingProfileView: some View {
        Link(destination: URL(string: "sevensistersapp://setup")!) {
            VStack(spacing: 8) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 26))
                    .foregroundStyle(goldAccent)
                Text("Open the app to set up your cards")
                    .font(.system(.caption, design: .serif))
                    .foregroundStyle(goldAccent)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        }
    }
}

struct SevenSistersWidget: Widget {
    let kind: String = "SevenSistersWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SevenSistersProvider()) { entry in
            SevenSistersWidgetView(entry: entry)
        }
        .configurationDisplayName("Seven Sisters")
        .description("Your daily, planet, 52-day, and yearly cards at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

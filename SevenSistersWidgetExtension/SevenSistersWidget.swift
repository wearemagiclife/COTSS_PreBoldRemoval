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
        SevenSistersEntry(date: Date(), state: .locked)
    }

    func getSnapshot(in context: Context, completion: @escaping (SevenSistersEntry) -> Void) {
        completion(Self.makeEntry(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SevenSistersEntry>) -> Void) {
        let now = Date()
        let entry = Self.makeEntry(at: now)
        let nextRefresh = Calendar.current.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 1),
            matchingPolicy: .nextTime
        ) ?? now.addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
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

    /// Resolves the in-app appearance preference (0=system, 1=light, 2=dark).
    /// `nil` returned for `.system` means inherit from system trait.
    private var preferredColorScheme: ColorScheme? {
        switch WidgetBridge.readAppearanceMode() {
        case 1: return .light
        case 2: return .dark
        default: return nil
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
            ZStack {
                // Deep near-black base — slightly warmer than pure black
                Color(red: 0.05, green: 0.04, blue: 0.04)

                // Soft inner gold rim — thin stroke + diffused glow, matching the modal card style
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(goldAccent.opacity(0.30), lineWidth: 0.75)

                // Inner edge shadow — simulates the modal's warm ambient rim
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color(red: 1.0, green: 0.95, blue: 0.88).opacity(0.08), lineWidth: 10)
                    .blur(radius: 8)
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
        GeometryReader { geo in
            // Card aspect ratio matches the deck art (~2.5:3.5).
            let cardAspect: CGFloat = 2.5 / 3.5
            // Reserve vertical for: header text (~18) + top card + ornament (~16) + bottom row (card + label ~12)
            let headerH: CGFloat = 18
            let ornamentH: CGFloat = 16
            let labelH: CGFloat = 12
            let vSpacing: CGFloat = 10  // generous spacing for airy feel

            // Cards sized to leave breathing room on all sides
            let usableH = geo.size.height - headerH - ornamentH - labelH - vSpacing * 4
            let heroH = usableH * 0.50          // smaller top cards
            let heroW = heroH * cardAspect
            let bottomH = heroH * 0.70          // notably smaller bottom cards
            let bottomW = bottomH * cardAspect

            VStack(spacing: vSpacing) {
                // Header
                Text("TODAY'S CARD")
                    .font(.custom("Iowan Old Style", size: 12))
                    .tracking(2)
                    .foregroundStyle(goldAccent)
                    .frame(height: headerH)

                // Top row: daily + planet — same size, same styling
                HStack(alignment: .center, spacing: 14) {
                    cardArt(cards.daily.imageName, width: heroW, height: heroH, isHero: true)
                    cardArt(cards.planet.lowercased(), width: heroW, height: heroH, isHero: true)
                }

                // Ornament divider
                if let line = UIImage(named: "linedesignd") {
                    Image(uiImage: line)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: geo.size.width * 0.7, height: ornamentH)
                } else {
                    Rectangle()
                        .fill(goldAccent.opacity(0.4))
                        .frame(width: geo.size.width * 0.5, height: 1)
                        .frame(height: ornamentH)
                }

                // Bottom row: 52-Day + Yearly with labels
                HStack(spacing: 18) {
                    labeledCard(imageName: cards.fiftyTwoDay.imageName,
                                title: "52-Day Card",
                                width: bottomW, height: bottomH, labelHeight: labelH)
                    labeledCard(imageName: cards.yearly.imageName,
                                title: "Yearly Card",
                                width: bottomW, height: bottomH, labelHeight: labelH)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    /// Card image with gold-glow shadow + drop shadow, matching the home view's `darkModeCardEffects`.
    private func cardArt(_ name: String, width: CGFloat, height: CGFloat, isHero: Bool) -> some View {
        let isDark: Bool
        switch WidgetBridge.readAppearanceMode() {
        case 1: isDark = false
        case 2: isDark = true
        default: isDark = true   // widget container is black; treat system as dark for glow purposes
        }
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

    private func labeledCard(imageName: String, title: String,
                             width: CGFloat, height: CGFloat, labelHeight: CGFloat) -> some View {
        VStack(spacing: 4) {
            cardArt(imageName, width: width, height: height, isHero: false)
            Text(title)
                .font(.custom("Iowan Old Style", size: 10))
                .foregroundStyle(goldAccent.opacity(0.9))
                .lineLimit(1)
                .frame(height: labelHeight)
        }
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
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

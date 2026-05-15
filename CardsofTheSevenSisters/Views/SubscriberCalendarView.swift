import SwiftUI

// MARK: - Subscriber Calendar View

struct SubscriberCalendarView: View {
    @ObservedObject private var dataManager = DataManager.shared
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    @State private var currentMonth: Date = {
        let cal = Calendar.current
        return cal.date(from: cal.dateComponents([.year, .month], from: Date())) ?? Date()
    }()
    @State private var sheetDate: IdentifiableDate? = nil
    @Binding var showingSettings: Bool

    // Cache cell data keyed by date's timeIntervalSinceReferenceDate to avoid recomputing every body render
    @State private var cellCache: [Double: (DailyCardResult, Bool)] = [:]  // date → (result, isCycleStart)

    private let cal = Calendar.current
    private let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundColor.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header gear
                    headerView

                    // Main content sits below the gear
                    if subscriptionManager.isSubscribed {
                        subscriberCalendar
                    } else {
                        subscriberGate
                    }
                }

                // Card detail modal overlay — must live inside ZStack to avoid split-screen
                if showCardDetailModal, let card = cardModalCard {
                    CardDetailModalView(
                        card: card,
                        cardType: .daily,
                        contentType: .standard,
                        isPresented: $showCardDetailModal,
                        dateLabel: nil
                    )
                    .zIndex(10)
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $sheetDate) { item in
                CalendarDayDetailSheet(date: item.date)
            }
            .task {
                // Pre-warm descriptions synchronously so they're ready before first tap
                DescriptionRepository.shared.ensureLoaded()
            }
            .task(id: currentMonth) {
                // Compute cell data for the visible month on a background thread
                let dates = gridDates()
                let birthDate = dataManager.userProfile.birthDate
                let birthId = BirthCardLookup.shared.calculateCardForDate(
                    monthValue: cal.component(.month, from: birthDate),
                    dayValue: cal.component(.day, from: birthDate)
                )
                let calculator = CardCalculationService()
                var built: [Double: (DailyCardResult, Bool)] = [:]

                for d in dates.compactMap({ $0 }) {
                    let key = d.timeIntervalSinceReferenceDate
                    let today = cal.startOfDay(for: d)
                    let result = calculator.generateTimeInfluence(
                        userBirthDate: birthDate,
                        primaryCard: birthId,
                        evaluationDate: today
                    )
                    var isCycleStart = false
                    if let yesterday = cal.date(byAdding: .day, value: -1, to: today) {
                        let todayCycle = DataManager.shared.current52DayCard(for: birthDate, on: today)
                        let ydayCycle = DataManager.shared.current52DayCard(for: birthDate, on: yesterday)
                        isCycleStart = todayCycle.id != ydayCycle.id
                    }
                    built[key] = (result, isCycleStart)
                }

                await MainActor.run { cellCache = built }
            }

        }
    }

    private var headerView: some View {
        HStack {
            Spacer()
            Button(action: { showingSettings = true }) {
                Image(systemName: "gearshape")
                    .font(.title2)
                    .foregroundColor(AppTheme.primaryText)
            }
            .accessibilityLabel("Settings")
            .accessibilityHint("Opens settings menu")
        }
        .padding(.horizontal, AppConstants.Spacing.pageInset)
        .padding(.vertical, AppConstants.Spacing.ornament)
    }

    // MARK: - Subscriber Calendar

    private var subscriberCalendar: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Vintage title banner
                vintageTitleBanner
                    .padding(.horizontal, AppConstants.Spacing.pageInset)
                    .padding(.bottom, AppConstants.Spacing.ornament)

                // Month navigation inside a decorative frame
                vintageMonthNavigation
                    .padding(.horizontal, AppConstants.Spacing.pageInset)

                // Ornamental rule
                VintageOrnamentalRule()
                    .padding(.horizontal, AppConstants.Spacing.pageInset)
                    .padding(.vertical, AppConstants.Spacing.tight)

                // Week header + grid share the same LazyVGrid so columns are pixel-perfect
                calendarGridWithHeader
                    .padding(.horizontal, AppConstants.Spacing.pageInset)
                    .padding(.vertical, AppConstants.Spacing.ornament)

                // Bottom ornament
                VintageBottomOrnament()
                    .padding(.horizontal, AppConstants.Spacing.pageInset)
                    .padding(.bottom, AppConstants.Spacing.section)
            }
            .padding(.bottom, AppConstants.Spacing.section)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Vintage Title Banner

    private var vintageTitleBanner: some View {
        Text("✦  CARD ALMANAC  ✦")
            .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.callout))
            .fontWeight(.bold)
            .tracking(3.5)
            .foregroundColor(AppTheme.accentText)
            .accessibilityLabel("Card Almanac")
    }

    // MARK: - Vintage Month Navigation

    private var vintageMonthNavigation: some View {
        HStack(alignment: .center, spacing: 0) {
            // Left arrow — vintage serif style
            Button {
                withAnimation(.easeInOut(duration: 0.22)) {
                    currentMonth = cal.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                }
            } label: {
                Text("‹")
                    .font(.custom("Iowan Old Style", size: 36))
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.accentText)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Previous month")

            Spacer()

            VStack(spacing: 3) {
                Text(monthYearString(for: currentMonth).uppercased())
                    .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                    .tracking(2)
                    .foregroundColor(AppTheme.primaryText.opacity(0.90))

                let thisMonth = cal.date(from: cal.dateComponents([.year, .month], from: Date())) ?? Date()
                if !cal.isDate(currentMonth, equalTo: thisMonth, toGranularity: .month) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            currentMonth = thisMonth
                        }
                    } label: {
                        Text("— Return to Present —")
                            .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.caption))
                            .tracking(1)
                            .foregroundColor(AppTheme.accentText)
                    }
                    .accessibilityLabel("Return to current month")
                }
            }

            Spacer()

            // Right arrow
            Button {
                withAnimation(.easeInOut(duration: 0.22)) {
                    currentMonth = cal.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                }
            } label: {
                Text("›")
                    .font(.custom("Iowan Old Style", size: 36))
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.accentText)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Next month")
        }
    }

    // MARK: - Calendar Grid (header + cells share one LazyVGrid for exact column alignment)

    @State private var showCardDetailModal = false
    @State private var cardModalCard: Card? = nil
    @State private var cardModalDate: Date? = nil

    private let weekdayLabels = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]

    private var calendarGridWithHeader: some View {
        let dates = gridDates()
        return VStack(spacing: 0) {
            // Weekday labels row — shares same column structure as the grid below
            LazyVGrid(columns: gridColumns, spacing: 0) {
                ForEach(weekdayLabels, id: \.self) { label in
                    Text(label)
                        .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.callout))
                        .fontWeight(.bold)
                        .tracking(1)
                        .foregroundColor(AppTheme.accentText)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 8)
                        .accessibilityHidden(true)
                }
            }

            // Single full-width ledger rule — no column gaps
            VStack(spacing: 2) {
                Rectangle()
                    .fill(AppTheme.primaryText.opacity(0.45))
                    .frame(height: 1)
                Rectangle()
                    .fill(AppTheme.primaryText.opacity(0.15))
                    .frame(height: 0.5)
            }

            // Date cells grid — top padding on each cell controls gap below rule
            LazyVGrid(columns: gridColumns, spacing: 0) {
            // Date cells — fixed height so every row is identical
            ForEach(0..<dates.count, id: \.self) { i in
                if let date = dates[i] {
                    let inMonth = cal.isDate(date, equalTo: currentMonth, toGranularity: .month)
                    let key = date.timeIntervalSinceReferenceDate
                    let cached = cellCache[key]
                    let card = cached?.0.card ?? dailyResult(for: date).card
                    let isCycleStart = cached?.1 ?? false
                    VintageCalendarDayCell(
                        date: date,
                        card: card,
                        cycleCard: isCycleStart ? DataManager.shared.current52DayCard(for: dataManager.userProfile.birthDate, on: cal.startOfDay(for: date)) : nil,
                        isToday: cal.isDateInToday(date),
                        isCurrentMonth: inMonth,
                        onDayTap: {
                            guard inMonth else { return }
                            sheetDate = IdentifiableDate(date: date)
                        },
                        onCardTap: {
                            guard inMonth else { return }
                            cardModalCard = card
                            cardModalDate = date
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showCardDetailModal = true
                            }
                        }
                    )
                } else {
                    Color.clear.frame(height: 86)
                }
            }
            } // end inner LazyVGrid
        } // end outer VStack
    }

    // MARK: - Subscriber Gate

    private var subscriberGate: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppConstants.Spacing.ornament) {
                // Vintage header
                VStack(spacing: 10) {
                    Text("✦  CARD ALMANAC  ✦")
                        .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.caption))
                        .tracking(3.5)
                        .foregroundColor(AppTheme.accentText.opacity(1))
                        .padding(.top, 20)
                        .accessibilityLabel("Card Almanac")

                    Text("Your Card Calendar")
                        .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.title))
                        .foregroundColor(AppTheme.primaryText)
                        .multilineTextAlignment(.center)

                    Text("See which cards are coming up, day by day.")
                        .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                        .foregroundColor(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.bottom, 4)

                // Blurred calendar preview with lock overlay
                ZStack {
                    // Preview calendar (blurred)
                    VStack(spacing: 0) {
                        gatePreviewGrid
                            .padding(.horizontal, 4)
                            .padding(.vertical, 10)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(AppConstants.Colors.capsuleButton.opacity(0.96))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(AppTheme.primaryText.opacity(0.15), lineWidth: 1)
                    )
                    .blur(radius: 10)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)

                    // Lock overlay card
                    VStack(spacing: 18) {
                        Text("⚿")
                            .font(.system(size: 28))
                            .foregroundColor(AppTheme.accentText)
                            .accessibilityHidden(true)

                        VStack(spacing: 8) {
                            Text("Subscribe to Unlock")
                                .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                                .foregroundColor(AppTheme.primaryText)
                                .multilineTextAlignment(.center)

                            Text("See your daily card for every\nday of the weeks ahead.")
                                .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.callout))
                                .foregroundColor(AppTheme.secondaryText)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }

                        NavigationLink {
                            SubscriptionView()
                                .environmentObject(subscriptionManager)
                        } label: {
                            HStack {
                                Text("View Subscription Plans")
                                    .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                        }
                        .buttonStyle(GoldButtonStyle())
                    }
                    .padding(.horizontal, 28)
                    .padding(.vertical, 28)
                    .background(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(AppTheme.backgroundColor.opacity(0.94))
                            .shadow(color: Color.black.opacity(0.22), radius: 18, x: 0, y: 6)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(AppTheme.accentText.opacity(0.25), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, AppConstants.Spacing.section)
            }
            .padding(.horizontal, AppConstants.Spacing.cardPadding)
            .padding(.top, AppConstants.Spacing.tight)
        }
    }

    // blurred preview grid (non-interactive, gate backdrop)
    private var gatePreviewGrid: some View {
        let dates = gridDates()
        let previewCount = min(dates.count, 35)
        return LazyVGrid(columns: gridColumns, spacing: 10) {
            ForEach(0..<previewCount, id: \.self) { i in
                if let date = dates[i] {
                    VintageCalendarDayCell(
                        date: date,
                        card: cellCache[date.timeIntervalSinceReferenceDate]?.0.card ?? dailyResult(for: date).card,
                        cycleCard: nil,
                        isToday: false,
                        isCurrentMonth: true
                    )
                } else {
                    Color.clear.frame(height: dayCellHeight)
                }
            }
        }
    }

    // MARK: - Helpers

    private var birthCardId: Int {
        let components = cal.dateComponents([.month, .day], from: dataManager.userProfile.birthDate)
        return BirthCardLookup.shared.calculateCardForDate(monthValue: components.month ?? 1, dayValue: components.day ?? 1)
    }

    private func dailyResult(for date: Date) -> DailyCardResult {
        let calculator = CardCalculationService()
        return calculator.generateTimeInfluence(
            userBirthDate: dataManager.userProfile.birthDate,
            primaryCard: birthCardId,
            evaluationDate: cal.startOfDay(for: date)
        )
    }

    /// Returns the 52-day cycle card for a date only if it's the first day of a new cycle period.
    private func cycleCardIfNew(for date: Date) -> Card? {
        let birthDate = dataManager.userProfile.birthDate
        let today = cal.startOfDay(for: date)
        guard let yesterday = cal.date(byAdding: .day, value: -1, to: today) else { return nil }

        let todayCycle = DataManager.shared.current52DayCard(for: birthDate, on: today)
        let yesterdayCycle = DataManager.shared.current52DayCard(for: birthDate, on: yesterday)

        return todayCycle.id != yesterdayCycle.id ? todayCycle : nil
    }

    private func monthYearString(for date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: date)
    }

    private var dayCellHeight: CGFloat { 72 }

    private func gridDates() -> [Date?] {
        guard let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: currentMonth)) else {
            return []
        }
        let firstWeekday = cal.component(.weekday, from: monthStart) - 1
        let daysInMonth = cal.range(of: .day, in: .month, for: currentMonth)?.count ?? 30

        var dates: [Date?] = Array(repeating: nil, count: firstWeekday)
        for day in 0..<daysInMonth {
            dates.append(cal.date(byAdding: .day, value: day, to: monthStart))
        }
        let remainder = dates.count % 7
        if remainder != 0 {
            dates += Array(repeating: nil as Date?, count: 7 - remainder)
        }
        return dates
    }
}

// MARK: - Vintage Ornamental Components

/// A double-line rule reminiscent of antique ledger books
private struct VintageLedgerRule: View {
    var body: some View {
        VStack(spacing: 2) {
            Rectangle()
                .fill(AppTheme.primaryText.opacity(0.55))
                .frame(height: 1)
            Rectangle()
                .fill(AppTheme.primaryText.opacity(0.18))
                .frame(height: 0.5)
        }
    }
}

/// A centered ornamental rule with a diamond motif
private struct VintageOrnamentalRule: View {
    var body: some View {
        HStack(spacing: 6) {
            Rectangle()
                .fill(AppTheme.accentText.opacity(0.35))
                .frame(height: 0.5)

            Text("✦")
                .font(.custom("Iowan Old Style", size: 10))
                .foregroundColor(AppTheme.accentText.opacity(0.55))

            Rectangle()
                .fill(AppTheme.accentText.opacity(0.35))
                .frame(height: 0.5)
        }
    }
}

/// A small decorative ornament for the bottom of the calendar
private struct VintageBottomOrnament: View {
    var body: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(AppTheme.primaryText.opacity(0.12))
                .frame(height: 0.5)

            Text("· · ✦ · ·")
                .font(.custom("Iowan Old Style", size: 11))
                .foregroundColor(AppTheme.accentText.opacity(0.4))

            Rectangle()
                .fill(AppTheme.primaryText.opacity(0.12))
                .frame(height: 0.5)
        }
    }
}

// MARK: - Sheet date wrapper (avoids .sheet(isPresented:) race condition)

private struct IdentifiableDate: Identifiable {
    let id = UUID()
    let date: Date
}

// MARK: - Calendar Day Detail Sheet

struct CalendarDayDetailSheet: View {
    let date: Date

    @ObservedObject private var dataManager = DataManager.shared

    private let cal = Calendar.current

    // MARK: - Computed data for the selected date

    private var birthCardId: Int {
        let comps = cal.dateComponents([.month, .day], from: dataManager.userProfile.birthDate)
        return BirthCardLookup.shared.calculateCardForDate(monthValue: comps.month ?? 1, dayValue: comps.day ?? 1)
    }

    private var dailyResult: DailyCardResult {
        CardCalculationService().generateTimeInfluence(
            userBirthDate: dataManager.userProfile.birthDate,
            primaryCard: birthCardId,
            evaluationDate: cal.startOfDay(for: date)
        )
    }

    private var cycleCard: Card {
        DataManager.shared.current52DayCard(for: dataManager.userProfile.birthDate, on: cal.startOfDay(for: date))
    }

    private var cyclePlanet: String {
        DataManager.shared.getPlanetaryPhase(for: dataManager.userProfile.birthDate, on: cal.startOfDay(for: date))
    }

    private var yearlyCard: Card {
        let calculator = CardCalculationService()
        let age = calculator.calculatePersonAge(birthDate: dataManager.userProfile.birthDate, onDate: date)
        let cardId = calculator.deriveAnnualInfluence(primaryCard: birthCardId, personAge: age)
        return DataManager.shared.getCard(by: cardId)
    }

    private var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Date heading with ornament
            VStack(spacing: 6) {
                Text("✦  \(dateString.uppercased())  ✦")
                    .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.callout))
                    .fontWeight(.bold)
                    .tracking(3.5)
                    .foregroundColor(AppTheme.accentText)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                VintageOrnamentalRule()
                    .padding(.horizontal, AppConstants.Spacing.pageInset)
            }
            .padding(.top, AppConstants.Spacing.section)
            .padding(.bottom, AppConstants.Spacing.ornament)

            digestView
                .padding(.horizontal, AppConstants.Spacing.pageInset)
                .padding(.top, AppConstants.Spacing.ornament)
                .padding(.bottom, AppConstants.Spacing.section)
        }
        .frame(maxWidth: .infinity)
        .presentationDetents([.height(340)])
        .presentationDragIndicator(.visible)
        .presentationBackground(AppTheme.backgroundColor)
    }

    // MARK: - Digest text

    private var digestView: some View {
        let daily = dailyResult.card
        let planet = dailyResult.planet
        let cycle = cycleCard
        let cycPlanet = cyclePlanet
        let yearly = yearlyCard
        let fontSize: CGFloat = 19

        return VStack(alignment: .leading, spacing: AppConstants.Spacing.ornament) {
            // "Today's card is the 5♦ in Neptune."
            (
                Text("Today's card is the ")
                    .font(.custom("Iowan Old Style", size: fontSize))
                    .foregroundColor(AppTheme.primaryText)
                + Text("\(daily.value)\(daily.suitSymbol)")
                    .font(.custom("Iowan Old Style", size: fontSize))
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.accentText)
                + Text(" in ")
                    .font(.custom("Iowan Old Style", size: fontSize))
                    .foregroundColor(AppTheme.primaryText)
                + Text("\(planet)")
                    .font(.custom("Iowan Old Style", size: fontSize))
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.accentText)
                + Text(".")
                    .font(.custom("Iowan Old Style", size: fontSize))
                    .foregroundColor(AppTheme.primaryText)
            )
            .lineSpacing(5)
            .multilineTextAlignment(.leading)

            // "The J♦ will offer insights for this 52-Day Saturn period."
            (
                Text("The ")
                    .font(.custom("Iowan Old Style", size: fontSize))
                    .foregroundColor(AppTheme.primaryText)
                + Text("\(cycle.value)\(cycle.suitSymbol)")
                    .font(.custom("Iowan Old Style", size: fontSize))
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.accentText)
                + Text(" will offer insights for this 52-Day ")
                    .font(.custom("Iowan Old Style", size: fontSize))
                    .foregroundColor(AppTheme.primaryText)
                + Text(cycPlanet)
                    .font(.custom("Iowan Old Style", size: fontSize))
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.accentText)
                + Text(" period.")
                    .font(.custom("Iowan Old Style", size: fontSize))
                    .foregroundColor(AppTheme.primaryText)
            )
            .lineSpacing(5)
            .multilineTextAlignment(.leading)

            // "These cycles will offer fresh perspectives to explore the themes of your 2♦ year."
            (
                Text("These cycles will offer fresh perspectives to explore the themes of your ")
                    .font(.custom("Iowan Old Style", size: fontSize))
                    .foregroundColor(AppTheme.primaryText)
                + Text("\(yearly.value)\(yearly.suitSymbol)")
                    .font(.custom("Iowan Old Style", size: fontSize))
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.accentText)
                + Text(" year.")
                    .font(.custom("Iowan Old Style", size: fontSize))
                    .foregroundColor(AppTheme.primaryText)
            )
            .lineSpacing(5)
            .multilineTextAlignment(.leading)
        }
    }
}

// MARK: - Vintage Calendar Day Cell

struct VintageCalendarDayCell: View {
    let date: Date
    let card: Card
    let cycleCard: Card?
    let isToday: Bool
    let isCurrentMonth: Bool
    var onDayTap: () -> Void = {}
    var onCardTap: () -> Void = {}

    /// ♦ and ♠ are geometrically narrow glyphs and read smaller than ♥/♣ at the same size.
    /// ♠ gets +4pt, ♦ gets +3pt.
    private func symbolSize(base: CGFloat) -> CGFloat {
        if card.suit == .spades { return base + 4 }
        if card.suit == .diamonds { return base + 3 }
        return base
    }

    private func cellAccessibilityLabel(dayNumber: Int, isCycleStart: Bool) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        let dateStr = formatter.string(from: date)
        let prefix = isToday ? "Today, \(dateStr)" : dateStr
        let cardStr = "\(card.value) of \(card.suit.rawValue.capitalized)"
        let cycleStr = isCycleStart ? ". New 52-day cycle begins" : ""
        return "\(prefix). \(cardStr)\(cycleStr)."
    }

    var body: some View {
        let dayNumber = Calendar.current.component(.day, from: date)
        let isCycleStart = cycleCard != nil
        let rankSize: CGFloat = AppConstants.FontSizes.subheadline
        let suitSize: CGFloat = symbolSize(base: rankSize)
        let cardColor = AppTheme.accentText

        // Outer frame IS the cell slot — padding lives inside so grid always sees the same height
        ZStack(alignment: .top) {
            Color.clear

            VStack(spacing: 5) {
                // Day number
                Text("\(dayNumber)")
                    .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                    .fontWeight(.regular)
                    .foregroundColor(
                        isCurrentMonth ? AppTheme.primaryText : AppTheme.primaryText.opacity(0.25)
                    )
                    .frame(maxWidth: .infinity, minHeight: 22, maxHeight: 22, alignment: .center)
                    .overlay(alignment: .bottom) {
                        if isToday {
                            Capsule()
                                .fill(AppTheme.primaryText.opacity(0.25))
                                .frame(width: 14, height: 1.5)
                                .offset(y: 3)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { onDayTap() }

                // Card shorthand — HStack isolates glyphs so font-size variance can't shift rows
                HStack(alignment: .center, spacing: 3) {
                    Text(card.value)
                        .font(.custom("Iowan Old Style", size: rankSize))
                        .fontWeight(.bold)
                        .foregroundColor(cardColor)
                        .fixedSize()
                    Text(card.suitSymbol)
                        .font(.custom("Iowan Old Style", size: suitSize))
                        .fontWeight(.bold)
                        .foregroundColor(cardColor)
                        .fixedSize()
                }
                .lineLimit(1)
                .frame(maxWidth: .infinity, minHeight: 22, maxHeight: 22, alignment: .center)
                .clipped()
                .opacity(isCurrentMonth ? 1.0 : 0.25)
                .onTapGesture { onCardTap() }

                // Cycle-start marker — reserved slot regardless of presence
                Color.clear.frame(height: 8).overlay(
                    Group {
                        if isCycleStart && isCurrentMonth {
                            Text("✦")
                                .font(.system(size: 6))
                                .foregroundColor(AppTheme.accentText)
                        }
                    }
                )
            }
            .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, minHeight: 86, maxHeight: 86, alignment: .top)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(cellAccessibilityLabel(dayNumber: dayNumber, isCycleStart: isCycleStart))
        .accessibilityHint(isCurrentMonth ? "Tap to view all cards for this day" : "")
        .accessibilityAddTraits(isCurrentMonth ? .isButton : [])
        .accessibilityAction(.default) { onDayTap() }
        .accessibilityHidden(!isCurrentMonth)
    }
}

// Keep old name as alias so any other references compile
typealias CalendarDayCell = VintageCalendarDayCell

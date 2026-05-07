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
    private let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 3), count: 7)

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
                    let dateLabel: String? = {
                        guard let d = cardModalDate else { return nil }
                        let f = DateFormatter()
                        f.dateFormat = "EEEE, MMMM d"
                        return f.string(from: d)
                    }()
                    CardDetailModalView(
                        card: card,
                        cardType: .daily,
                        contentType: .standard,
                        isPresented: $showCardDetailModal,
                        dateLabel: dateLabel
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
            VStack(spacing: AppConstants.Spacing.ornament) {
                // Month navigation (no decorated background)
                monthNavigationSection
                    .padding(.horizontal, AppConstants.Spacing.pageInset)
                    .padding(.top, AppConstants.Spacing.tight)

                // Week header + grid (flat, native-like)
                VStack(spacing: 0) {
                    weekdayHeaderRow
                        .padding(.horizontal, AppConstants.Spacing.pageInset)
                        .padding(.vertical, AppConstants.Spacing.tight)

                    Rectangle()
                        .fill(AppTheme.primaryText.opacity(0.08))
                        .frame(height: 0.5)
                        .padding(.horizontal, AppConstants.Spacing.pageInset)

                    calendarGrid
                        .padding(.horizontal, AppConstants.Spacing.pageInset)
                        .padding(.vertical, AppConstants.Spacing.ornament)
                }
            }
            .padding(.bottom, AppConstants.Spacing.section)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Month Navigation Section

    private var monthNavigationSection: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.22)) {
                    currentMonth = cal.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(AppTheme.accentText)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            VStack(spacing: 2) {
                Text(monthYearString(for: currentMonth))
                    .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.headline + 2))
                    .foregroundColor(AppTheme.secondaryText)

                let thisMonth = cal.date(from: cal.dateComponents([.year, .month], from: Date())) ?? Date()
                if !cal.isDate(currentMonth, equalTo: thisMonth, toGranularity: .month) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            currentMonth = thisMonth
                        }
                    } label: {
                        Text("Back to Today")
                            .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.callout))
                            .foregroundColor(AppTheme.accentText)
                    }
                }
            }

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.22)) {
                    currentMonth = cal.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.accentText)
                    .frame(width: 44, height: 44)
            }
        }
    }

    // MARK: - Weekday Header

    private var weekdayHeaderRow: some View {
        HStack(spacing: 0) {
            ForEach(["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"], id: \.self) { label in
                Text(label)
                    .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.callout))
                    .foregroundColor(AppTheme.secondaryText)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Calendar Grid

    @State private var showCardDetailModal = false
    @State private var cardModalCard: Card? = nil
    @State private var cardModalDate: Date? = nil

    private var calendarGrid: some View {
        let dates = gridDates()
        return LazyVGrid(columns: gridColumns, spacing: 14) {
            ForEach(0..<dates.count, id: \.self) { i in
                if let date = dates[i] {
                    let inMonth = cal.isDate(date, equalTo: currentMonth, toGranularity: .month)
                    let key = date.timeIntervalSinceReferenceDate
                    let cached = cellCache[key]
                    let card = cached?.0.card ?? dailyResult(for: date).card
                    let isCycleStart = cached?.1 ?? false
                    CalendarDayCell(
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
                    Color.clear.frame(height: dayCellHeight)
                }
            }
        }
    }

    // MARK: - Subscriber Gate

    private var subscriberGate: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppConstants.Spacing.ornament) {
                // Header — matches subscriber view for visual consistency
                VStack(spacing: 10) {
                    Image(systemName: "calendar")
                        .font(.system(size: 36))
                        .foregroundColor(AppTheme.accentText)
                        .padding(.top, 20)

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
                        weekdayHeaderRow
                            .padding(.horizontal, 6)
                            .padding(.vertical, 12)

                        Rectangle()
                            .fill(AppTheme.primaryText.opacity(0.12))
                            .frame(height: 1)
                            .padding(.horizontal, 8)

                        gatePreviewGrid
                            .padding(.horizontal, 4)
                            .padding(.vertical, 10)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(AppConstants.Colors.capsuleButton.opacity(0.96))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(AppTheme.primaryText.opacity(0.10), lineWidth: 1)
                    )
                    .blur(radius: 10)
                    .allowsHitTesting(false)

                    // Lock overlay card
                    VStack(spacing: 18) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 30))
                            .foregroundColor(AppTheme.accentText)

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
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(AppTheme.backgroundColor.opacity(0.94))
                            .shadow(color: Color.black.opacity(0.22), radius: 18, x: 0, y: 6)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
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
        return LazyVGrid(columns: gridColumns, spacing: 18) {
            ForEach(0..<previewCount, id: \.self) { i in
                if let date = dates[i] {
                    CalendarDayCell(
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
            Text(dateString)
                .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                .foregroundColor(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, AppConstants.Spacing.section)
                .padding(.bottom, AppConstants.Spacing.ornament)

            digestView
                .padding(.horizontal, AppConstants.Spacing.pageInset)
                .padding(.top, AppConstants.Spacing.ornament)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.backgroundColor)
        .presentationDetents([.fraction(0.30)])
        .presentationDragIndicator(.visible)
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
                + Text(" in \(planet).")
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

// MARK: - Calendar Day Cell

struct CalendarDayCell: View {
    let date: Date
    let card: Card
    let cycleCard: Card?
    let isToday: Bool
    let isCurrentMonth: Bool
    var onDayTap: () -> Void = {}
    var onCardTap: () -> Void = {}

    var body: some View {
        let dayNumber = Calendar.current.component(.day, from: date)
        let isCycleStart = cycleCard != nil

        VStack(spacing: 4) {
            // Day number — fixed 28×28 frame so all cells stay the same height
            // Tap → daily digest sheet
            ZStack {
                if isToday {
                    Circle()
                        .fill(AppTheme.primaryText.opacity(0.12))
                        .frame(width: 28, height: 28)
                }
                Text("\(dayNumber)")
                    .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                    .foregroundColor(
                        isToday ? AppTheme.accentText :
                        (isCurrentMonth ? AppTheme.primaryText : AppTheme.secondaryText.opacity(0.4))
                    )
            }
            .frame(width: 28, height: 28)
            .contentShape(Circle())
            .onTapGesture { onDayTap() }

            // Card shorthand — warm card-background fill, no grey
            let baseSize: CGFloat = AppConstants.FontSizes.callout
            let symbolSize: CGFloat = baseSize + 4
            (
                Text(card.value)
                    .font(.custom("Iowan Old Style", size: baseSize))
                    .fontWeight(.semibold)
                    .foregroundColor(isToday ? AppTheme.accentText : AppTheme.primaryText)
                + Text(" \(card.suitSymbol)")
                    .font(.custom("Iowan Old Style", size: symbolSize))
                    .foregroundColor(isToday ? AppTheme.accentText : AppTheme.secondaryText)
            )
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isToday ? AppTheme.accentText.opacity(0.12) : AppTheme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(AppTheme.primaryText.opacity(0.10), lineWidth: 0.5)
            )
            .opacity(isCurrentMonth ? 1.0 : 0.35)
            .onTapGesture { onCardTap() }

            // Subtle accent dot on 52-day cycle-start days
            if isCycleStart && isCurrentMonth {
                Circle()
                    .fill(AppTheme.accentText.opacity(0.6))
                    .frame(width: 5, height: 5)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .frame(maxWidth: .infinity)
    }
}


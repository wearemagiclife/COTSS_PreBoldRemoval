import SwiftUI

struct OnboardingTutorialView: View {
    @Binding var isPresented: Bool
    @State private var currentStep: Int = 0
    @State private var showContent: Bool = false
    @State private var showOverlay: Bool = false
    @State private var backgroundOpacity: Double = 0
    @State private var isTransitioning: Bool = false
    
    // Available dimensions (measured from safe area via GeometryReader in body)
    @State private var availableScreenHeight: CGFloat = UIScreen.main.bounds.height
    @State private var availableScreenWidth: CGFloat = UIScreen.main.bounds.width

    // Animation states for the floating card
    @State private var cardPosition: CGPoint = .zero
    @State private var cardScale: CGFloat = 1.0
    @State private var cardOpacity: Double = 0
    @State private var showFloatingCard: Bool = false
    @State private var cardShadowRadius: CGFloat = 5
    @State private var cardShadowOpacity: Double = 0.2
    @State private var highlightedCardStep: Int? = nil  // Which card to highlight before pickup

    // Store background card positions
    @State private var birthCardFrame: CGRect = .zero
    @State private var solarCardFrame: CGRect = .zero
    @State private var fiftytwoCardFrame: CGRect = .zero
    @State private var dailyCardFrame: CGRect = .zero
    
    // modalCardPosition is now computed — no stored state needed

    // Welcome screen animation states
    @State private var showWelcomeTitle: Bool = false
    @State private var showWelcomeLineDesign: Bool = false
    @State private var showWelcomeText: Bool = false
    @State private var showWelcomeBody: Bool = false

    // Final screen animation state
    @State private var showSettingsText: Bool = false

    // Button visibility state (fades in after card settles)
    @State private var showButtons: Bool = false

    // Prevents multiple timer starts
    @State private var hasStarted: Bool = false

    // Opening animation states
    @State private var homeBackgroundOpacity: Double = 0
    @State private var starSplashOpacity: Double = 0

    @Environment(\.colorScheme) private var colorScheme

    let birthCard: Card
    let solarCard: Card
    let fiftytwoCard: Card
    let dailyCard: Card
    let userName: String
    let onComplete: () -> Void

    private let tutorialSteps = [
        TutorialStep(
            cardTypeHeader: "WELCOME",
            description: "" // This will be handled separately for the welcome screen
        ),
        TutorialStep(
            cardTypeHeader: "YOUR BIRTH CARD",
            description: "This archetype gives insight into lifelong motifs. It's calculated using your birthday and is the main card in your Life Spread."
        ),
        TutorialStep(
            cardTypeHeader: "YOUR YEARLY CARD",
            description: "Each birthday, you get a new Yearly Card as an annual theme for growth. It's the main card in your Yearly Spread."
        ),
        TutorialStep(
            cardTypeHeader: "YOUR 52-DAY CARD",
            description: "You spend 52 Days of each year with a card offered by each of the 7 Planets. This creates time for reflection across the areas of life they govern."
        ),
        TutorialStep(
            cardTypeHeader: "YOUR DAILY CARD",
            description: "Big change comes from small steps."
        ),
    ]

    var body: some View {
        GeometryReader { screenGeo in
            ZStack {
                // Always-visible background color so the screen is never transparent
                AppTheme.backgroundColor
                    .ignoresSafeArea()

                // Static background image of home view (fades in after star splash)
                staticHomeViewBackground
                    .opacity(homeBackgroundOpacity)

                // Star splash — sevensisters image fades in then out at startup
                if let starImage = UIImage(named: "sevensisters") {
                    Image(uiImage: starImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 280)
                        .opacity(starSplashOpacity)
                }

                // Dark overlay that fades in/out
                Color.black.opacity(backgroundOpacity)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.4), value: backgroundOpacity)

                // Tutorial modal
                if showOverlay {
                    tutorialModalContent
                }

                // Floating animating card
                if showFloatingCard {
                    floatingCard
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .coordinateSpace(name: "tutorialRoot")
            .onAppear {
                availableScreenHeight = screenGeo.size.height
                availableScreenWidth = screenGeo.size.width
                startTutorial()
            }
            .onChange(of: screenGeo.size) { _, s in
                availableScreenHeight = s.height
                availableScreenWidth = s.width
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Static Background
    private var staticHomeViewBackground: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    Image(systemName: "gearshape")
                        .font(.title2)
                        .foregroundColor(AppTheme.primaryText)
                }
                .padding(.horizontal, AppConstants.Spacing.pageInset)
                .padding(.vertical, AppConstants.Spacing.ornament)

                // Welcome text
                Text("Welcome, \(userName.isEmpty ? "Guest" : userName)")
                    .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.extraLarge))
                    .foregroundColor(AppTheme.primaryText)
                    .padding(.bottom, AppConstants.Spacing.tight)
                    .opacity(showOverlay ? 0 : 1)
                    .animation(.easeOut(duration: 0.3), value: showOverlay)

                if let lineImage = UIImage(named: "linedesign") {
                    Image(uiImage: lineImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 260)
                        .padding(.top, AppConstants.Spacing.tight)
                }

                // Cards section
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        Text("YOUR DAILY CARD")
                            .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.title))
                            .foregroundColor(AppTheme.primaryText)
                        Spacer()
                    }
                    .padding(.bottom, AppConstants.Spacing.tight)
                    .opacity(showOverlay ? 0 : 1)
                    .animation(.easeOut(duration: 0.3), value: showOverlay)

                    VStack(spacing: 0) {
                        Spacer(minLength: AppConstants.Spacing.small)

                        // Daily card back placeholder
                        if let cardBackImage = UIImage(named: "cardback") {
                            Image(uiImage: cardBackImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: AppConstants.CardSizes.extraLarge.width, height: AppConstants.CardSizes.extraLarge.height)
                                .clipShape(RoundedRectangle(cornerRadius: AppConstants.CardStyle.cornerRadius(for: AppConstants.CardSizes.extraLarge)))
                                .modifier(DarkModeGoldGlow(size: AppConstants.CardSizes.extraLarge))
                                .cardShadow(size: AppConstants.CardSizes.extraLarge)
                                .scaleEffect(highlightedCardStep == 4 ? 1.15 : 1.0)
                                .animation(.spring(response: 0.5, dampingFraction: 0.65), value: highlightedCardStep)
                                .opacity((currentStep == 4 && showFloatingCard) ? 0 : 1)
                                .animation(.none, value: showFloatingCard)
                                .background(
                                    GeometryReader { geo in
                                        Color.clear.preference(key: DailyCardFramePreferenceKey.self, value: geo.frame(in: .named("tutorialRoot")))
                                    }
                                )
                                .onPreferenceChange(DailyCardFramePreferenceKey.self) { frame in
                                    dailyCardFrame = frame
                                }
                        }

                        Spacer(minLength: AppConstants.Spacing.small)

                        Text("Tap Card to Reveal")
                            .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.headline + 2))
                            .foregroundColor(AppTheme.primaryText)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, AppConstants.Spacing.titleSpacing)
                            .opacity((showFloatingCard && currentStep >= 1 && currentStep <= 3) ? 0 : 1)
                            .animation(.easeOut(duration: 0.2), value: showFloatingCard)
                    }

                    if let lineImageD = UIImage(named: "linedesignd") {
                        Image(uiImage: lineImageD)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 260)
                            .padding(.bottom, AppConstants.Spacing.section)
                    }

                    // Three small cards row
                    HStack(alignment: .top, spacing: AppConstants.Spacing.tight) {
                        // Birth card
                        VStack(spacing: AppConstants.Spacing.small) {
                            if let cardImage = ImageManager.shared.loadCardImage(for: birthCard) {
                                Image(uiImage: cardImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: AppConstants.CardSizes.small.width, height: AppConstants.CardSizes.small.height)
                                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.CardStyle.cornerRadius(for: AppConstants.CardSizes.extraLarge)))
                                    .modifier(DarkModeGoldGlow(size: AppConstants.CardSizes.extraLarge))
                                    .cardShadow(size: AppConstants.CardSizes.extraLarge)
                                    .scaleEffect(highlightedCardStep == 1 ? 1.15 : 1.0)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.65), value: highlightedCardStep)
                                    .opacity((currentStep == 1 && showFloatingCard) ? 0 : 1)
                                    .animation(.none, value: showFloatingCard)
                                    .background(
                                        GeometryReader { geo in
                                            Color.clear.preference(key: BirthCardFramePreferenceKey.self, value: geo.frame(in: .named("tutorialRoot")))
                                        }
                                    )
                                    .onPreferenceChange(BirthCardFramePreferenceKey.self) { frame in
                                        birthCardFrame = frame
                                    }
                            }
                            Text("Birth Card")
                                .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.body))
                                .foregroundColor(AppTheme.primaryText)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity)

                        // Solar card
                        VStack(spacing: AppConstants.Spacing.small) {
                            if let cardImage = ImageManager.shared.loadCardImage(for: solarCard) {
                                Image(uiImage: cardImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: AppConstants.CardSizes.small.width, height: AppConstants.CardSizes.small.height)
                                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.CardStyle.cornerRadius(for: AppConstants.CardSizes.extraLarge)))
                                    .modifier(DarkModeGoldGlow(size: AppConstants.CardSizes.extraLarge))
                                    .cardShadow(size: AppConstants.CardSizes.extraLarge)
                                    .scaleEffect(highlightedCardStep == 2 ? 1.15 : 1.0)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.65), value: highlightedCardStep)
                                    .opacity((currentStep == 2 && showFloatingCard) ? 0 : 1)
                                    .animation(.none, value: showFloatingCard)
                                    .background(
                                        GeometryReader { geo in
                                            Color.clear.preference(key: SolarCardFramePreferenceKey.self, value: geo.frame(in: .named("tutorialRoot")))
                                        }
                                    )
                                    .onPreferenceChange(SolarCardFramePreferenceKey.self) { frame in
                                        solarCardFrame = frame
                                    }
                            }
                            Text("Yearly Spread")
                                .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.body))
                                .foregroundColor(AppTheme.primaryText)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity)

                        // fiftytwo card
                        VStack(spacing: AppConstants.Spacing.small) {
                            if let cardImage = ImageManager.shared.loadCardImage(for: fiftytwoCard) {
                                Image(uiImage: cardImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: AppConstants.CardSizes.small.width, height: AppConstants.CardSizes.small.height)
                                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.CardStyle.cornerRadius(for: AppConstants.CardSizes.extraLarge)))
                                    .modifier(DarkModeGoldGlow(size: AppConstants.CardSizes.extraLarge))
                                    .cardShadow(size: AppConstants.CardSizes.extraLarge)
                                    .scaleEffect(highlightedCardStep == 3 ? 1.15 : 1.0)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.65), value: highlightedCardStep)
                                    .opacity((currentStep == 3 && showFloatingCard) ? 0 : 1)
                                    .animation(.none, value: showFloatingCard)
                                    .background(
                                        GeometryReader { geo in
                                            Color.clear.preference(key: fiftytwoCardFramePreferenceKey.self, value: geo.frame(in: .named("tutorialRoot")))
                                        }
                                    )
                                    .onPreferenceChange(fiftytwoCardFramePreferenceKey.self) { frame in
                                        fiftytwoCardFrame = frame
                                    }
                            }
                            Text("52-Day Cycle")
                                .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.body))
                                .foregroundColor(AppTheme.primaryText)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, AppConstants.Spacing.pageInset)
                    .opacity(showOverlay ? 0.65 : 1.0)
                    .blur(radius: showOverlay ? 2 : 0)
                    .animation(.easeInOut(duration: 0.3), value: showOverlay)
                }

            }
            .padding(.bottom, 62)
        }
        .background(AppTheme.backgroundColor)
        .ignoresSafeArea(edges: .bottom)
    }

    // Target height for the floating card at rest.
    // Uses availableScreenHeight (safe-area-adjusted) so it stays consistent with the
    // modal's own layout, which is also sized from availableScreenHeight.
    private var floatingCardHeight: CGFloat {
        availableScreenHeight * 0.25
    }

    // Computed deterministically — no GeometryReader, no race condition.
    // Zone 1 starts at: modal top padding + content vertical padding + close button clearance
    // Zone 1 center  = zone top + floatingCardHeight / 2
    private var modalCardPosition: CGPoint {
        let modalTopPadding = AppConstants.Spacing.page      // .padding(.top, page) on the modal
        let contentVertPadding = AppConstants.Spacing.ornament  // .padding(.vertical, ornament) on content
        let zoneTop = modalTopPadding + contentVertPadding + closeButtonClearance
        return CGPoint(x: availableScreenWidth / 2, y: zoneTop + floatingCardHeight / 2)
    }

    // MARK: - Floating Card
    private var floatingCard: some View {
        Group {
            if currentStep == 4 {
                if let cardBackImage = UIImage(named: "cardback") {
                    Image(uiImage: cardBackImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: floatingCardHeight * cardScale)
                        .scaleEffect(colorScheme == .dark ? 0.95 : 1.0)
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.CardStyle.cornerRadius(for: AppConstants.CardSizes.extraLarge)))
                        .modifier(DarkModeGoldGlow(size: AppConstants.CardSizes.extraLarge))
                                .cardShadow(size: AppConstants.CardSizes.extraLarge)
                }
            } else {
                if let uiImage = ImageManager.shared.loadCardImage(for: currentCard) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: floatingCardHeight * cardScale)
                        .scaleEffect(colorScheme == .dark ? 0.95 : 1.0)
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.CardStyle.cornerRadius(for: AppConstants.CardSizes.extraLarge)))
                        .modifier(DarkModeGoldGlow(size: AppConstants.CardSizes.extraLarge))
                                .cardShadow(size: AppConstants.CardSizes.extraLarge)
                }
            }
        }
        .position(cardPosition)
        .opacity(cardOpacity)
    }

    // MARK: - Tutorial Modal Content
    private var tutorialModalContent: some View {
        Group {
            if currentStep == 0 {
                // Welcome step: longer text, allow scroll
                ScrollView {
                    VStack(spacing: AppConstants.Spacing.cardPadding) {
                        welcomeScreenContent
                    }
                    .padding(.vertical, AppConstants.Spacing.ornament)
                    .padding(.horizontal, AppConstants.Spacing.cardPadding)
                }
                .scrollIndicators(.hidden)
            } else {
                // Card steps: fixed-height layout so Spacer() distributes space properly
                cardTutorialContent
                    .padding(.vertical, AppConstants.Spacing.ornament)
                    .padding(.horizontal, AppConstants.Spacing.cardPadding)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: AppConstants.CornerRadius.modal)
                .fill(AppTheme.backgroundColor)
        )
        .cornerRadius(AppConstants.CornerRadius.modal)
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.CornerRadius.modal)
                .stroke(Color(UIColor { traitCollection in
                    traitCollection.userInterfaceStyle == .dark
                        ? UIColor(red: 0.855, green: 0.745, blue: 0.565, alpha: 1.0)  // #DABE90 gold
                        : UIColor.clear
                }), lineWidth: 1.5)
        )
        .overlay(alignment: .topTrailing) {
            if currentStep > 0 {
                Button(action: skipTutorial) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20))
                        .foregroundColor(AppTheme.primaryText)
                        .frame(width: AppConstants.ButtonSizes.closeButton, height: AppConstants.ButtonSizes.closeButton)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.top, 12)
                .padding(.trailing, 12)
                .accessibilityLabel("Skip tutorial")
                .accessibilityHint("Close tutorial and go to app")
            }
        }
        .frame(maxWidth: 500)
        .frame(height: availableScreenHeight
            - (currentStep == 0 ? AppConstants.Spacing.ornament : AppConstants.Spacing.page)
            - AppConstants.Spacing.ornament)
        .padding(.horizontal, AppConstants.Spacing.pageInset)
        .padding(.top, currentStep == 0 ? AppConstants.Spacing.ornament : AppConstants.Spacing.page)
        .padding(.bottom, AppConstants.Spacing.ornament)
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    guard !isTransitioning else { return }
                    let horizontalDistance = value.translation.width
                    if horizontalDistance < -50 {
                        // Swipe left - advance
                        if currentStep < 4 {
                            advanceStep()
                        }
                    } else if horizontalDistance > 50 {
                        // Swipe right - go back
                        if currentStep > 1 {
                            goBack()
                        }
                    }
                }
        )
    }

    // MARK: - Welcome Screen Content
    private var welcomeScreenContent: some View {
        VStack(spacing: 0) {
            if let appLogo = UIImage(named: "sevensisters") {
                HStack {
                    Spacer()
                    Image(uiImage: appLogo)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 280)
                        .opacity(showWelcomeTitle ? 0.9 : 0)
                        .animation(.easeInOut(duration: 0.9), value: showWelcomeTitle)
                    Spacer()
                }
                .padding(.vertical, AppConstants.Spacing.ornament)
            }

            VStack(alignment: .leading, spacing: AppConstants.Spacing.small) {
                (Text("Long before").bold() + Text(" Carl Jung or the Tarot, the 52 cards, representing universal archetypes, could be used for charting the seasons and planetary movements."))
                    .font(.custom("Iowan Old Style", size: 16))
                    .tracking(0.8)
                    .foregroundColor(AppTheme.primaryText)
                    .lineSpacing(AppConstants.Typography.bodyLineSpacing)
                    .padding(.bottom, 12)

                (Text("The Seven Sisters,").bold() + Text(" or the Pleiades, were also these same ancestor's guide from above. The Cards offer themes that can to shed light on  navigate."))
                    .font(.custom("Iowan Old Style", size: 16))
                    .tracking(0.8)
                    .foregroundColor(AppTheme.primaryText)
                    .lineSpacing(AppConstants.Typography.bodyLineSpacing)
                    .padding(.bottom, 12)

                Text("This system is not designed to predict outcomes: any meanings you find here are the echoes of your own self-discovery. Interpretations are for historical reference and entertainment only. Never advice.")
                    .font(.custom("Iowan Old Style", size: 16))
                    .tracking(0.8)
                    .foregroundColor(AppTheme.primaryText)
                    .lineSpacing(AppConstants.Typography.bodyLineSpacing)

                HStack {
                    Spacer()
                    SimpleDivider(width: 180)
                    Spacer()
                }
                .padding(.top, 10)
                .padding(.bottom, 6)

                Text("Next, the tutorial will show you around the app. You can view it again, and find more resources in the Settings Menu.")
                    .font(.custom("Iowan Old Style", size: 16))
                    .tracking(0.8)
                    .foregroundColor(AppTheme.primaryText)
                    .lineSpacing(AppConstants.Typography.bodyLineSpacing)
            }
            .frame(maxWidth: 310)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, AppConstants.Spacing.pageInset)
            .opacity(showWelcomeText ? 1 : 0)
            .animation(.easeInOut(duration: 0.7), value: showWelcomeText)

            Spacer()
                .frame(height: 20)

            Spacer()

            Button(action: advanceStep) {
                Text("Continue")
                    .font(.custom("Iowan Old Style", size: 17))
                    .tracking(0.5)
                    .foregroundColor(Color(UIColor { traitCollection in
                        traitCollection.userInterfaceStyle == .dark
                            ? UIColor.black
                            : UIColor.white
                    }))
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(AppTheme.darkAccent)
                    .cornerRadius(AppConstants.CornerRadius.button)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            .modifier(DarkModeGoldGlow(size: AppConstants.CardSizes.extraLarge))
            .accessibilityLabel("Continue")
            .accessibilityHint("Proceed to tutorial")
            .opacity(showWelcomeBody ? 1 : 0)
            .animation(.easeInOut(duration: 0.6), value: showWelcomeBody)

            Spacer()
                .frame(height: 30)
        }
    }

    // MARK: - Card Tutorial Content
    // This view fills the modal's fixed height (no ScrollView parent), so Spacer()
    // correctly distributes the remaining space between the three zones:
    //   1. Card zone  — clear space for the floating card above the text
    //   2. Content zone — title + ornament + description
    //   3. Button zone — Continue/Begin + progress dots
    // Close button occupies ~44pt at top of modal (12pt padding + 32pt button).
    // Card zone must start below this.
    private var closeButtonClearance: CGFloat { 44 }

    private var cardTutorialContent: some View {
        VStack(spacing: 0) {

            // ── Zone 1: Card space ──────────────────────────────────────────
            // Extra top padding ensures the card top clears the X button.
            // The zone height = floatingCardHeight so the card never overlaps the title.
            Color.clear
                .frame(height: floatingCardHeight)
                .padding(.top, closeButtonClearance)

            // Gap between card bottom and title — equal to gap above ornament below title
            Spacer().frame(height: AppConstants.Spacing.ornament)

            // ── Zone 2: Title ───────────────────────────────────────────────
            Text(tutorialSteps[currentStep].cardTypeHeader)
                .font(.custom("Iowan Old Style", size: 22))
                .foregroundColor(AppTheme.primaryText)
                .multilineTextAlignment(.center)
                .opacity(showContent ? 1 : 0)
                .animation(.easeInOut(duration: 0.4), value: showContent)

            // Equal space above and below ornament line
            Spacer().frame(height: AppConstants.Spacing.ornament)

            // ── Zone 2: Ornament + description ─────────────────────────────
            VStack(spacing: AppConstants.Spacing.section) {
                if let lineImage = UIImage(named: "linedesign") {
                    Image(uiImage: lineImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180)
                }

                Text(tutorialSteps[currentStep].description)
                    .font(.custom("Iowan Old Style", size: 16))
                    .lineSpacing(AppConstants.Typography.bodyLineSpacing)
                    .tracking(0.8)
                    .foregroundColor(AppTheme.primaryText)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 25)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .opacity(showContent ? 1 : 0)
            .animation(.easeInOut(duration: 0.4), value: showContent)

            // Settings note (step 4 only)
            if currentStep == 4 {
                Text("To learn more about the Cards, or to revisit this tutorial, go to Settings.")
                    .font(.custom("Iowan Old Style", size: 15))
                    .foregroundColor(AppTheme.primaryText)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 30)
                    .padding(.top, AppConstants.Spacing.section)
                    .opacity(showSettingsText ? 1 : 0)
                    .animation(.easeInOut(duration: 0.4), value: showSettingsText)
            }

            Spacer()  // pushes buttons to bottom

            // ── Zone 3: Buttons ─────────────────────────────────────────────
            VStack(spacing: 12) {
                Button(action: advanceStep) {
                    Text(currentStep < 4 ? "Continue" : "Begin")
                        .font(.custom("Iowan Old Style", size: 18))
                        .foregroundColor(Color(UIColor { traitCollection in
                            traitCollection.userInterfaceStyle == .dark
                                ? UIColor.black
                                : UIColor.white
                        }))
                        .padding(.horizontal, 50)
                        .padding(.vertical, 12)
                        .background(AppTheme.darkAccent)
                        .cornerRadius(AppConstants.CornerRadius.button)
                        .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 2)
                }
                .accessibilityLabel(currentStep < 4 ? "Continue" : "Begin using the app")
                .accessibilityHint(currentStep < 4 ? "Go to next tutorial step" : "Close tutorial and start using the app")

                // Progress dots (tappable)
                HStack(spacing: 6) {
                    ForEach(1..<5, id: \.self) { index in
                        Circle()
                            .fill(index == currentStep ? AppTheme.primaryText : AppTheme.primaryText.opacity(0.15))
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == currentStep ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentStep)
                            .frame(width: 28, height: 44)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                guard !isTransitioning else { return }
                                if index > currentStep && currentStep < 4 {
                                    advanceStep()
                                } else if index < currentStep && currentStep > 1 {
                                    goBack()
                                }
                            }
                            .accessibilityLabel("Step \(index) of 4")
                            .accessibilityHint(index == currentStep ? "Current step" : "Tap to go to step \(index)")
                    }
                }
                .padding(.top, 4)
                .padding(.bottom, 8)
            }
            .opacity(showButtons ? 1 : 0)
            .animation(.easeInOut(duration: 0.4), value: showButtons)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helper Functions
    private func startTutorial() {
        guard !hasStarted else { return }
        hasStarted = true

        if currentStep == 0 {
            // Hold on background color, then star image fades in slowly
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    starSplashOpacity = 1.0
                }

                // Hold, then fade out slowly
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        starSplashOpacity = 0
                    }

                    // Modal opens directly after star fades — homeview comes later
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        withAnimation(.easeInOut(duration: 0.6)) {
                            showOverlay = true
                            backgroundOpacity = 0.65
                        }

                        // 1. App Logo fades in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            withAnimation(.easeInOut(duration: 0.9)) {
                                showWelcomeTitle = true
                            }
                        }

                        // 2. Line design fades in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                            withAnimation(.easeInOut(duration: 0.7)) {
                                showWelcomeLineDesign = true
                            }
                        }

                        // 3. Text fades in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                            withAnimation(.easeInOut(duration: 0.7)) {
                                showWelcomeText = true
                            }
                        }

                        // 4. Buttons fade in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
                            withAnimation(.easeInOut(duration: 0.6)) {
                                showWelcomeBody = true
                            }
                        }
                    }
                }
            }
        }
    }

    private func skipTutorial() {
        guard !isTransitioning else { return }
        isTransitioning = true

        withAnimation(.easeOut(duration: 0.3)) {
            showWelcomeTitle = false
            showWelcomeLineDesign = false
            showWelcomeText = false
            showWelcomeBody = false
            showContent = false
            showSettingsText = false
            showButtons = false
            cardOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.4)) {
                backgroundOpacity = 0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                showFloatingCard = false
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showOverlay = false
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    isPresented = false
                    onComplete()
                }
            }
        }
    }

    private var currentCard: Card {
        switch currentStep {
        case 1: return birthCard
        case 2: return solarCard
        case 3: return fiftytwoCard
        default: return dailyCard
        }
    }
    
    private func sourceCardFrame(for step: Int) -> CGRect {
        switch step {
        case 1: return birthCardFrame
        case 2: return solarCardFrame
        case 3: return fiftytwoCardFrame
        case 4: return dailyCardFrame
        default: return .zero
        }
    }

    private func yOffsetForStep(_ step: Int) -> CGFloat {
        return 0
    }
    
    // MARK: - Unified animation constants
    // All card transitions use these values so every step feels identical.
    private let cardFlyDuration: Double = 0.70      // gentle easeInOut card travel
    private let bgFadeDuration: Double  = 0.50      // dim/undim backdrop
    private let contentFadeDuration: Double = 0.35  // text/buttons fade
    // Pre-flight pause (0.4) + fly (0.70) + 0.15s hold before content appears
    private let contentFadeDelay: Double = 0.85
    private let buttonFadeDelay: Double  = 0.20

    // Return animation — smooth easeInOut, no spring
    private let cardReturnDuration: Double = 0.80

    // Overlay hide speed when leaving the welcome step
    private let overlayHideDuration: Double = 0.80

    private func animateCardTransition(to nextStep: Int) {
        let sourceFrame = sourceCardFrame(for: nextStep)
        guard sourceFrame != .zero else { return }

        let yOffset = yOffsetForStep(nextStep)
        cardPosition = CGPoint(x: sourceFrame.midX, y: sourceFrame.midY + yOffset)
        cardScale    = sourceFrame.height / floatingCardHeight
        cardOpacity  = 1
        cardShadowRadius  = 5
        cardShadowOpacity = 0.2
        showFloatingCard  = true

        // Dim the homeview while card is in flight — modal stays hidden until card lands
        withAnimation(.easeInOut(duration: bgFadeDuration)) {
            backgroundOpacity = 0.65
        }

        // Brief pause before card lifts, then flows gently across the visible homeview
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeInOut(duration: cardFlyDuration)) {
                cardPosition      = modalCardPosition
                cardScale         = 1.0
                cardShadowRadius  = 12
                cardShadowOpacity = 0.3
            }

            // Card lands + hold, then modal fades in 100% opaque
            DispatchQueue.main.asyncAfter(deadline: .now() + contentFadeDelay) {
                withAnimation(.easeInOut(duration: 0.35)) {
                    showOverlay = true
                }

                // Content fades in just after modal is fully opaque
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.easeInOut(duration: self.contentFadeDuration)) {
                        showContent = true
                    }
                }
            }

            // Buttons appear just after content
            DispatchQueue.main.asyncAfter(deadline: .now() + contentFadeDelay + 0.2 + buttonFadeDelay) {
                withAnimation(.easeInOut(duration: self.contentFadeDuration)) {
                    showButtons = true
                    if nextStep == 4 { showSettingsText = true }
                }
                isTransitioning = false
            }
        }
    }

    private func advanceStep() {
        guard !isTransitioning else { return }
        isTransitioning = true

        if currentStep == 0 {
            // Phase 1: Fade out welcome content
            withAnimation(.easeOut(duration: 0.4)) {
                showWelcomeTitle = false
                showWelcomeLineDesign = false
                showWelcomeText = false
                showWelcomeBody = false
            }

            // Phase 2: Fade out background dim
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    backgroundOpacity = 0
                }

                // Phase 3: Hide modal
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeInOut(duration: overlayHideDuration)) {
                        showOverlay = false
                    }

                    // Phase 4: Home view fades in gently
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeInOut(duration: 0.9)) {
                            homeBackgroundOpacity = 1.0
                        }

                        // Phase 5: Start first card after home settles
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                            currentStep = 1

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                animateCardTransition(to: 1)
                            }
                        }
                    }
                }
            }
        } else if currentStep < 4 {
            // Fade out content immediately
            withAnimation(.easeOut(duration: contentFadeDuration)) {
                showContent = false
                showSettingsText = false
                showButtons = false
            }

            // Dim out and return card to background
            DispatchQueue.main.asyncAfter(deadline: .now() + contentFadeDuration) {
                withAnimation(.easeInOut(duration: self.bgFadeDuration)) {
                    backgroundOpacity = 0
                }

                let currentFrame = sourceCardFrame(for: currentStep)
                let yOffset = yOffsetForStep(currentStep)

                withAnimation(.easeInOut(duration: self.cardReturnDuration)) {
                    cardPosition      = CGPoint(x: currentFrame.midX, y: currentFrame.midY + yOffset)
                    cardScale         = currentFrame.height / floatingCardHeight
                    cardShadowRadius  = 5
                    cardShadowOpacity = 0.2
                    showOverlay       = false
                }

                // Card lands back, then fire next step
                DispatchQueue.main.asyncAfter(deadline: .now() + self.cardReturnDuration + 0.1) {
                    showFloatingCard = false
                    let nextStep = currentStep + 1
                    currentStep = nextStep
                    animateCardTransition(to: nextStep)
                }
            }
        } else {
            // Final step - close tutorial - dismiss everything immediately for clean transition
            withAnimation(.easeOut(duration: 0.2)) {
                showContent = false
                showSettingsText = false
                showButtons = false
                cardOpacity = 0
                showFloatingCard = false
                showOverlay = false
                backgroundOpacity = 0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isPresented = false
                onComplete()
            }
        }
    }
    
    private func goBack() {
        guard !isTransitioning && currentStep > 1 else { return }
        isTransitioning = true

        withAnimation(.easeOut(duration: contentFadeDuration)) {
            showContent = false
            showSettingsText = false
            showButtons = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + contentFadeDuration) {
            withAnimation(.easeInOut(duration: self.bgFadeDuration)) {
                backgroundOpacity = 0
            }

            let currentFrame = sourceCardFrame(for: currentStep)
            let yOffset = yOffsetForStep(currentStep)

            withAnimation(.easeInOut(duration: self.cardReturnDuration)) {
                cardPosition      = CGPoint(x: currentFrame.midX, y: currentFrame.midY + yOffset)
                cardScale         = currentFrame.height / floatingCardHeight
                cardShadowRadius  = 5
                cardShadowOpacity = 0.2
                showOverlay       = false
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + self.cardReturnDuration + 0.1) {
                showFloatingCard = false
                let previousStep = currentStep - 1
                currentStep = previousStep
                animateCardTransition(to: previousStep)
            }
        }
    }
}

struct TutorialStep {
    let cardTypeHeader: String
    let description: String
}

// MARK: - PreferenceKeys for Frame Capture

struct BirthCardFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

struct SolarCardFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

struct fiftytwoCardFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

struct DailyCardFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}


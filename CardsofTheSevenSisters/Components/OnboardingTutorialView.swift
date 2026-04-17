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
                // Static background image of home view
                staticHomeViewBackground

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
                .fill(AppTheme.backgroundColor.opacity(0.95))
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

            VStack(alignment: .leading, spacing: AppConstants.Spacing.tight) {
                (Text("Long before").bold() + Text(" Carl Jung or the Tarot, the 52 cards, representing universal archetypes, could be used for charting the seasons and planetary movements."))
                    .font(.custom("Iowan Old Style", size: 17))
                    .tracking(0.3)
                    .foregroundColor(AppTheme.primaryText)
                    .lineSpacing(AppConstants.Typography.adaptiveLineSpacing)

                (Text("The Seven Sisters,").bold() + Text(" or the Pleiades, were also these same ancestor's guide from above. The Cards offer themes that can to shed light on  navigate."))
                    .font(.custom("Iowan Old Style", size: 17))
                    .tracking(0.3)
                    .foregroundColor(AppTheme.primaryText)
                    .lineSpacing(AppConstants.Typography.adaptiveLineSpacing)

                Text("This system is not designed to predict outcomes: any meanings you find here are the echoes of your own self-discovery. Interpretations are for historical reference and entertainment only. Never advice.")
                    .font(.custom("Iowan Old Style", size: 17))
                    .tracking(0.3)
                    .foregroundColor(AppTheme.primaryText)
                    .lineSpacing(AppConstants.Typography.adaptiveLineSpacing)

                HStack {
                    Spacer()
                    SimpleDivider(width: 180)
                    Spacer()
                }
                .padding(.top, 10)
                .padding(.bottom, 6)

                Text("Next, the tutorial will show you around the app. You can view it again, and find more resources in the Settings Menu.")
                    .font(.custom("Iowan Old Style", size: 17))
                    .tracking(0.3)
                    .foregroundColor(AppTheme.primaryText)
                    .lineSpacing(AppConstants.Typography.adaptiveLineSpacing)
            }
            .frame(maxWidth: 340)
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
            // Wait 2 seconds to let users absorb the background cards, then show modal with dimming
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.6)) {
                    showOverlay = true
                    backgroundOpacity = 0.65
                }

                // 1. App Logo fades in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.easeInOut(duration: 0.9)) {
                        showWelcomeTitle = true
                    }
                }

                // 2. Line design fades in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                    withAnimation(.easeInOut(duration: 0.7)) {
                        showWelcomeLineDesign = true
                    }
                }

                // 3. Text fades in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                    withAnimation(.easeInOut(duration: 0.7)) {
                        showWelcomeText = true
                    }
                }

                // 4. Buttons fade in
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.1) {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        showWelcomeBody = true
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
        switch step {
        case 4: return 0 // Daily card - no offset needed
        default: return -62  // Small cards (1-3) - 62 pixels above natural position
        }
    }
    
    // MARK: - Unified animation constants
    // All card transitions use these values so every step feels identical.
    private let cardFlyDuration: Double = 0.55   // spring response for card travel
    private let cardFlyDamping: Double  = 0.82   // slight bounce, not overdamped
    private let bgFadeDuration: Double  = 0.35   // dim/undim backdrop
    private let contentFadeDuration: Double = 0.30  // text/buttons fade
    // Card lands → short pause → content appears
    private let contentFadeDelay: Double = 0.45
    // Content appears → buttons appear
    private let buttonFadeDelay: Double  = 0.15

    private func animateCardTransition(to nextStep: Int) {
        let sourceFrame = sourceCardFrame(for: nextStep)
        guard sourceFrame != .zero else { return }

        let yOffset: CGFloat = nextStep == 4 ? -62 : -62
        cardPosition = CGPoint(x: sourceFrame.midX, y: sourceFrame.midY + yOffset)
        cardScale    = sourceFrame.height / floatingCardHeight
        cardOpacity  = 1
        cardShadowRadius  = 5
        cardShadowOpacity = 0.2
        showFloatingCard  = true

        // Overlay fades in as card starts moving
        withAnimation(.easeOut(duration: bgFadeDuration)) {
            showOverlay = true
        }

        // Card flies to modal position
        withAnimation(.spring(response: cardFlyDuration, dampingFraction: cardFlyDamping)) {
            cardPosition      = modalCardPosition
            cardScale         = 1.0
            cardShadowRadius  = 12
            cardShadowOpacity = 0.3
        }

        // Background dims while card is in flight
        withAnimation(.easeInOut(duration: bgFadeDuration).delay(0.1)) {
            backgroundOpacity = 0.65
        }

        // Content fades in after card lands
        DispatchQueue.main.asyncAfter(deadline: .now() + contentFadeDelay) {
            withAnimation(.easeInOut(duration: self.contentFadeDuration)) {
                showContent = true
            }
        }

        // Buttons appear just after content
        DispatchQueue.main.asyncAfter(deadline: .now() + contentFadeDelay + buttonFadeDelay) {
            withAnimation(.easeInOut(duration: self.contentFadeDuration)) {
                showButtons = true
                if nextStep == 4 { showSettingsText = true }
            }
            isTransitioning = false
        }
    }

    private func advanceStep() {
        guard !isTransitioning else { return }
        isTransitioning = true

        if currentStep == 0 {
            // Slower transition for first slide
            // Phase 1: Fade out welcome content
            withAnimation(.easeOut(duration: 0.4)) {
                showWelcomeTitle = false
                showWelcomeLineDesign = false
                showWelcomeText = false
                showWelcomeBody = false
            }

            // Phase 2: Fade out background (overlap with content fade for smooth transition)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    backgroundOpacity = 0
                }

                // Phase 3: Hide overlay - give user time to see home view
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring(response: 0.8, dampingFraction: 1.0)) {
                        showOverlay = false
                    }

                    // Phase 4: Wait longer before showing first card
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        currentStep = 1

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            animateCardTransition(to: 1)
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

                withAnimation(.spring(response: self.cardFlyDuration, dampingFraction: self.cardFlyDamping)) {
                    cardPosition      = CGPoint(x: currentFrame.midX, y: currentFrame.midY + yOffset)
                    cardScale         = currentFrame.height / floatingCardHeight
                    cardShadowRadius  = 5
                    cardShadowOpacity = 0.2
                    showOverlay       = false
                }

                // Card lands back, then fire next step
                DispatchQueue.main.asyncAfter(deadline: .now() + self.cardFlyDuration + 0.1) {
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

            withAnimation(.spring(response: self.cardFlyDuration, dampingFraction: self.cardFlyDamping)) {
                cardPosition      = CGPoint(x: currentFrame.midX, y: currentFrame.midY + yOffset)
                cardScale         = currentFrame.height / floatingCardHeight
                cardShadowRadius  = 5
                cardShadowOpacity = 0.2
                showOverlay       = false
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + self.cardFlyDuration + 0.1) {
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

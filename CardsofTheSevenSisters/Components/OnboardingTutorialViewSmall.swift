import SwiftUI

struct OnboardingTutorialViewSmall: View {
    @Binding var isPresented: Bool
    @State private var currentStep: Int = 0
    @State private var showContent: Bool = false
    @State private var showOverlay: Bool = false
    @State private var backgroundOpacity: Double = 0
    @State private var isTransitioning: Bool = false

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

    // Modal card position
    @State private var modalCardPosition: CGPoint = .zero

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
            description: "Big change comes from small steps. Again, the 7 Planets are here to keep us aligned. This card sets a weekly check-in with each."
        ),
    ]

    var body: some View {
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
                    .frame(width: 224)
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
        .onAppear {
            startTutorial()
        }
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
                .padding(.horizontal, AppConstants.Spacing.medium)
                .padding(.vertical, AppConstants.Spacing.medium)

                // Welcome text
                Text("Welcome, \(userName.isEmpty ? "Guest" : userName)")
                    .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.extraLarge + 2))
                    .foregroundColor(AppTheme.primaryText)
                    .padding(.bottom, AppConstants.Spacing.medium)
                    .opacity(showOverlay ? 0 : 1)
                    .animation(.easeOut(duration: 0.3), value: showOverlay)

                if let lineImage = UIImage(named: "linedesign") {
                    Image(uiImage: lineImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180)
                        .padding(.top, AppConstants.Spacing.small)
                        .padding(.bottom, AppConstants.Spacing.small)
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
                    .padding(.bottom, 4)
                    .opacity(showOverlay ? 0 : 1)
                    .animation(.easeOut(duration: 0.3), value: showOverlay)

                    VStack(spacing: 0) {
                        Spacer(minLength: 2)

                        // Daily card back placeholder (no pulse effect for step 4)
                        if let cardBackImage = UIImage(named: "cardback") {
                            Image(uiImage: cardBackImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 160, height: 224)
                                .clipShape(RoundedRectangle(cornerRadius: AppConstants.CardStyle.cornerRadius(for: CGSize(width: 160, height: 224))))
                                .modifier(DarkModeGoldGlow(size: CGSize(width: 160, height: 224)))
                                .cardShadow(size: CGSize(width: 160, height: 224))
                                .opacity((currentStep == 4 && showFloatingCard) ? 0 : 1)
                                .animation(.none, value: showFloatingCard)
                                .background(
                                    GeometryReader { geo in
                                        Color.clear.preference(key: DailyCardFramePreferenceKey.self, value: geo.frame(in: .global))
                                    }
                                )
                                .onPreferenceChange(DailyCardFramePreferenceKey.self) { frame in
                                    dailyCardFrame = frame
                                }
                        }

                        Spacer(minLength: 8)

                        Text("Tap Card to Reveal")
                            .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.headline + 2))
                            .foregroundColor(AppTheme.primaryText)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 2)

                        Spacer(minLength: 4)

                        if let lineImageD = UIImage(named: "linedesignd") {
                            Image(uiImage: lineImageD)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 180)
                                .padding(.bottom, AppConstants.Spacing.sectionSpacing)
                        }
                    }

                    // Three small cards row
                    HStack(alignment: .top, spacing: AppConstants.Spacing.small) {
                        // Birth card
                        VStack(spacing: AppConstants.Spacing.small) {
                            if let cardImage = ImageManager.shared.loadCardImage(for: birthCard) {
                                Image(uiImage: cardImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 75, height: 105)
                                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.CardStyle.cornerRadius(for: AppConstants.CardSizes.extraLarge)))
                                    .modifier(DarkModeGoldGlow(size: AppConstants.CardSizes.extraLarge))
                                .cardShadow(size: AppConstants.CardSizes.extraLarge)
                                    .scaleEffect(highlightedCardStep == 1 ? 1.08 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: highlightedCardStep)
                                    .opacity((currentStep == 1 && showFloatingCard) ? 0 : 1)
                                    .animation(.none, value: showFloatingCard)
                                    .background(
                                        GeometryReader { geo in
                                            Color.clear.preference(key: BirthCardFramePreferenceKey.self, value: geo.frame(in: .global))
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
                                    .scaledToFit()
                                    .frame(width: 75, height: 105)
                                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.CardStyle.cornerRadius(for: AppConstants.CardSizes.extraLarge)))
                                    .modifier(DarkModeGoldGlow(size: AppConstants.CardSizes.extraLarge))
                                .cardShadow(size: AppConstants.CardSizes.extraLarge)
                                    .scaleEffect(highlightedCardStep == 2 ? 1.08 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: highlightedCardStep)
                                    .opacity((currentStep == 2 && showFloatingCard) ? 0 : 1)
                                    .animation(.none, value: showFloatingCard)
                                    .background(
                                        GeometryReader { geo in
                                            Color.clear.preference(key: SolarCardFramePreferenceKey.self, value: geo.frame(in: .global))
                                        }
                                    )
                                    .onPreferenceChange(SolarCardFramePreferenceKey.self) { frame in
                                        solarCardFrame = frame
                                    }
                            }
                            Text("Yearly Cycle")
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
                                    .scaledToFit()
                                    .frame(width: 75, height: 105)
                                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.CardStyle.cornerRadius(for: AppConstants.CardSizes.extraLarge)))
                                    .modifier(DarkModeGoldGlow(size: AppConstants.CardSizes.extraLarge))
                                .cardShadow(size: AppConstants.CardSizes.extraLarge)
                                    .scaleEffect(highlightedCardStep == 3 ? 1.08 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: highlightedCardStep)
                                    .opacity((currentStep == 3 && showFloatingCard) ? 0 : 1)
                                    .animation(.none, value: showFloatingCard)
                                    .background(
                                        GeometryReader { geo in
                                            Color.clear.preference(key: fiftytwoCardFramePreferenceKey.self, value: geo.frame(in: .global))
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
                    .padding(.horizontal, AppConstants.Spacing.medium)
                    .padding(.top, AppConstants.Spacing.small)
                    .opacity(showOverlay ? 0.65 : 1.0)
                    .blur(radius: showOverlay ? 2 : 0)
                    .animation(.easeInOut(duration: 0.3), value: showOverlay)
                }
            }
        }
        .background(AppTheme.backgroundColor)
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Floating Card
    private var floatingCard: some View {
        let cardHeight: CGFloat = 145  // Sized to fit modal without scrolling

        return Group {
            if currentStep == 4 {
                if let cardBackImage = UIImage(named: "cardback") {
                    Image(uiImage: cardBackImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: cardHeight * cardScale)
                        .scaleEffect(colorScheme == .dark ? 0.95 : 1.0)
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.CardStyle.cornerRadius(for: AppConstants.CardSizes.extraLarge)))
                        .modifier(DarkModeGoldGlow(size: AppConstants.CardSizes.extraLarge))
                                .cardShadow(size: AppConstants.CardSizes.extraLarge)
                }
            } else {
                if let uiImage = ImageManager.shared.loadCardImage(for: currentCard) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: cardHeight * cardScale)
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
                ScrollView {
                    VStack(spacing: 15) {
                        welcomeScreenContent
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    .padding(.horizontal, 15)
                }
                .scrollIndicators(.hidden)
            } else {
                VStack(spacing: 15) {
                    cardTutorialContent
                }
                .padding(.top, 16)
                .padding(.bottom, 12)
                .padding(.horizontal, 15)
            }
        }
        .background(
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: AppConstants.CornerRadius.modal)
                    .fill(AppTheme.backgroundColor)
                    .onAppear {
                        // Modal card position - center in placeholder area
                        let frame = geo.frame(in: .global)
                        modalCardPosition = CGPoint(
                            x: frame.midX,
                            y: frame.minY + 85
                        )
                    }
            }
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
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.primaryText)
                        .frame(width: 28, height: 28)
                        .background(AppConstants.Colors.capsuleButton)
                        .clipShape(Circle())
                        .contentShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 12)
                .padding(.trailing, 12)
                .accessibilityLabel("Skip tutorial")
                .accessibilityHint("Close tutorial and go to app")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 40)
        .padding(.bottom, currentStep == 0 ? 40 : 70)
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
                        .frame(width: 224)
                        .opacity(showWelcomeTitle ? 0.9 : 0)
                        .animation(.easeInOut(duration: 0.9), value: showWelcomeTitle)
                    Spacer()
                }
                .padding(.top, 3)
                .padding(.bottom, 12)
            }

            VStack(alignment: .leading, spacing: 6) {
                (Text("Long before").bold() + Text(" Carl Jung or the Tarot, the 52 cards represented universal archetypes that as a deck, could be used to chart the seasons and planetary movements."))
                    .font(.custom("Iowan Old Style", size: 13))
                    .tracking(0.1)
                    .foregroundColor(AppTheme.primaryText)
                    .lineSpacing(5)
                    .padding(.bottom, 10)

                (Text("The Seven Sisters,").bold() + Text(" or the Pleiades, have guided our ancestors home for millennia. The Cards can offer a fixed reference to reflect, and when met by your own inner compass, can illuminate deep insight."))
                    .font(.custom("Iowan Old Style", size: 13))
                    .tracking(0.1)
                    .foregroundColor(AppTheme.primaryText)
                    .lineSpacing(5)
                    .padding(.bottom, 10)

                Text("This system is not designed to predict outcomes: any meanings you find here are the echoes of your own self-discovery. Interpretations are for historical reference and entertainment only. Never advice.")
                    .font(.custom("Iowan Old Style", size: 13))
                    .tracking(0.1)
                    .foregroundColor(AppTheme.primaryText)
                    .lineSpacing(5)

                HStack {
                    Spacer()
                    SimpleDivider(width: 140)
                    Spacer()
                }
                .padding(.vertical, 5)

                Text("Next, the tutorial will show you around the app. You can view it again, and find more resources in the Settings Menu.")
                    .font(.custom("Iowan Old Style", size: 13))
                    .tracking(0.1)
                    .foregroundColor(AppTheme.primaryText)
            }
            .frame(maxWidth: 260)
            .frame(maxWidth: .infinity)
            .padding(.leading, 24)
            .padding(.trailing, 8)
            .opacity(showWelcomeText ? 1 : 0)
            .animation(.easeInOut(duration: 0.7), value: showWelcomeText)

            Spacer()
                .frame(height: 20)

            Button(action: advanceStep) {
                Text("Continue")
                    .font(.custom("Iowan Old Style", size: 12))
                    .foregroundColor(Color(UIColor { traitCollection in
                        traitCollection.userInterfaceStyle == .dark
                            ? UIColor.black
                            : UIColor.white
                    }))
                    .padding(.horizontal, 27)
                    .padding(.vertical, 6)
                    .background(AppTheme.darkAccent)
                    .cornerRadius(AppConstants.CornerRadius.button)
                    .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 2)
            }
            .accessibilityLabel("Continue")
            .accessibilityHint("Proceed to tutorial")
            .opacity(showWelcomeBody ? 1 : 0)
            .animation(.easeInOut(duration: 0.6), value: showWelcomeBody)
        }
    }

    // MARK: - Card Tutorial Content
    private var cardTutorialContent: some View {
        VStack(spacing: 0) {
            // Invisible placeholder for card (actual card is floating)
            Color.clear
                .frame(height: 145)
                .padding(.bottom, 38)

            Text(tutorialSteps[currentStep].cardTypeHeader)
                .font(.custom("Iowan Old Style", size: 16))
                .foregroundColor(AppTheme.primaryText)
                .multilineTextAlignment(.center)
                .opacity(showContent ? 1 : 0)
                .animation(.easeInOut(duration: 0.4), value: showContent)

            Spacer(minLength: 8)
                .layoutPriority(-1)

            // Text content
            VStack(spacing: AppConstants.Spacing.ornament) {
                LineBreak(width: 280)

                Text(tutorialSteps[currentStep].description)
                    .font(.custom("Iowan Old Style", size: 15))
                    .lineSpacing(AppConstants.Typography.bodyLineSpacing)
                    .tracking(0.5)
                    .foregroundColor(AppTheme.primaryText)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 4)
                    .fixedSize(horizontal: false, vertical: false)

                LineBreak("linedesignd", width: 280)
            }
            .opacity(showContent ? 1 : 0)
            .animation(.easeInOut(duration: 0.4), value: showContent)
            .layoutPriority(-1)

            Spacer(minLength: 10)
                .layoutPriority(-1)

            // Settings text for final tile
            if currentStep == 4 {
                Text("To learn more, or revisit this tutorial, go to Settings.")
                    .font(.custom("Iowan Old Style", size: 13))
                    .foregroundColor(AppTheme.primaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: false)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
                    .opacity(showSettingsText ? 1 : 0)
                    .animation(.easeInOut(duration: 0.4), value: showSettingsText)
            }

            // Bottom button section - always visible with layout priority
            VStack(spacing: 12) {
                // Continue/Begin button
                Button(action: advanceStep) {
                    Text(currentStep < 4 ? "Continue" : "Begin")
                        .font(.custom("Iowan Old Style", size: 16))
                        .foregroundColor(Color(UIColor { traitCollection in
                            traitCollection.userInterfaceStyle == .dark
                                ? UIColor.black
                                : UIColor.white
                        }))
                        .padding(.horizontal, 44)
                        .padding(.vertical, 10)
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
                .padding(.top, 5)
                .padding(.bottom, 20)
            }
            .layoutPriority(1)
            .opacity(showButtons ? 1 : 0)
            .animation(.easeInOut(duration: 0.4), value: showButtons)
        }
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
                withAnimation(.easeInOut(duration: overlayHideDuration)) {
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

    private func yOffsetForStep(_ step: Int, isReturn: Bool = false) -> CGFloat {
        return 0
    }

    // MARK: - Unified animation constants
    private let cardFlyDuration: Double = 0.70
    private let bgFadeDuration: Double  = 0.50
    private let contentFadeDuration: Double = 0.35
    private let contentFadeDelay: Double = 0.85   // fly (0.70) + 0.15s hold
    private let buttonFadeDelay: Double  = 0.20
    private let cardReturnDuration: Double = 0.80
    private let overlayHideDuration: Double = 0.80

    private func animateCardTransition(to nextStep: Int) {
        let sourceFrame = sourceCardFrame(for: nextStep)
        guard sourceFrame != .zero else { return }

        let targetHeight: CGFloat = 145
        let yOffset = yOffsetForStep(nextStep)
        cardPosition = CGPoint(x: sourceFrame.midX, y: sourceFrame.midY + yOffset)
        cardScale    = sourceFrame.height / targetHeight
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
            // Phase 1: Fade out all content together
            withAnimation(.easeOut(duration: 0.2)) {
                showContent = false
                showSettingsText = false
                showButtons = false
            }

            // Phase 2: Hide overlay and fade background together, then animate card back
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                let currentFrame = sourceCardFrame(for: currentStep)
                let yOffset = yOffsetForStep(currentStep, isReturn: true)
                let cardHeight: CGFloat = 145

                // Hide overlay and fade background simultaneously so homeview is visible
                withAnimation(.easeInOut(duration: 0.4)) {
                    showOverlay = false
                    backgroundOpacity = 0
                }

                // Animate card back to background position
                withAnimation(.easeInOut(duration: self.cardReturnDuration)) {
                    cardPosition = CGPoint(x: currentFrame.midX, y: currentFrame.midY + yOffset)
                    cardScale = currentFrame.height / cardHeight
                    cardShadowRadius = 5
                    cardShadowOpacity = 0.2
                }

                // Hide floating card after animation completes
                DispatchQueue.main.asyncAfter(deadline: .now() + self.cardReturnDuration + 0.1) {
                    showFloatingCard = false
                    let nextStep = currentStep + 1
                    currentStep = nextStep

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        animateCardTransition(to: nextStep)
                    }
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

        // Fade out content
        withAnimation(.easeOut(duration: 0.2)) {
            showContent = false
            showSettingsText = false
            showButtons = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let currentFrame = sourceCardFrame(for: currentStep)
            let yOffset = yOffsetForStep(currentStep, isReturn: true)
            let cardHeight: CGFloat = 145

            // Hide overlay and fade background simultaneously so homeview is visible
            withAnimation(.easeInOut(duration: 0.4)) {
                showOverlay = false
                backgroundOpacity = 0
            }

            // Animate card back to background position
            withAnimation(.easeInOut(duration: self.cardReturnDuration)) {
                cardPosition = CGPoint(x: currentFrame.midX, y: currentFrame.midY + yOffset)
                cardScale = currentFrame.height / cardHeight
                cardShadowRadius = 5
                cardShadowOpacity = 0.2
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + self.cardReturnDuration + 0.1) {
                showFloatingCard = false
                let previousStep = currentStep - 1
                currentStep = previousStep

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    animateCardTransition(to: previousStep)
                }
            }
        }
    }
}

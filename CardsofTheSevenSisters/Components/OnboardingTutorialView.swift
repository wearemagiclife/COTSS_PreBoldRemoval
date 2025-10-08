import SwiftUI

struct OnboardingTutorialView: View {
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
    @State private var astralCardFrame: CGRect = .zero
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

    let birthCard: Card
    let solarCard: Card
    let astralCard: Card
    let dailyCard: Card
    let userName: String
    let onComplete: () -> Void

    private let tutorialSteps = [
        TutorialStep(
            cardTypeHeader: "WELCOME",
            description: "" // This will be handled separately for the welcome screen
        ),
        TutorialStep(
            cardTypeHeader: "YOUR LIFE SPREAD",
            description: "This archetype gives insight to lifelong motifs.Your Birth Card, or Sun Card, is based on your birthday, and used to calculate every other card in your Spread "
        ),
        TutorialStep(
            cardTypeHeader: "YOUR YEARLY SPREAD",
            description: "Each birthday, we get a fresh start and a new Yearly Card to grow and learn from. This Card follows you for the 365-day cycle around the Sun."
        ),
        TutorialStep(
            cardTypeHeader: "YOUR 52-DAY CYCLE",
            description: "There are 7 Planetary Periods in a year, that each offer a 52 Day Card to help us explore the many aspects of each Yearly Cycle."
        ),
        TutorialStep(
            cardTypeHeader: "YOUR DAILY CARD",
            description: "Big change comes from small steps. Again, the 7 Planets are here keep us aligned. Your Daily Card sets a weekly check in with each one."
        ),
    ]

    var body: some View {
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
                        .foregroundColor(.black)
                }
                .padding(.horizontal, AppConstants.Spacing.medium)
                .padding(.vertical, AppConstants.Spacing.medium)

                // Welcome text
                Text("Welcome, \(userName.isEmpty ? "Guest" : userName)")
                    .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.extraLarge + 2))
                    .foregroundColor(.black)
                    .padding(.bottom, AppConstants.Spacing.medium)
                    .opacity(showOverlay ? 0 : 1)
                    .animation(.easeOut(duration: 0.3), value: showOverlay)

                if let lineImage = UIImage(named: "linedesign") {
                    Image(uiImage: lineImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: AppConstants.Scaling.w(280), height: 22)
                        .padding(.top, AppConstants.Spacing.small)
                        .padding(.bottom, AppConstants.Spacing.small)
                }

                // Cards section
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        Text("TODAY'S CYCLE")
                            .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.title))
                            .foregroundColor(.black)
                        Spacer()
                    }
                    .padding(.bottom, AppConstants.Spacing.small)
                    .opacity(showOverlay ? 0 : 1)
                    .animation(.easeOut(duration: 0.3), value: showOverlay)

                    VStack(spacing: 20) {
                        // Daily card back placeholder (no pulse effect for step 4)
                        if let cardBackImage = UIImage(named: "cardback") {
                            Image(uiImage: cardBackImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: AppConstants.CardSizes.extraLarge.width, height: AppConstants.CardSizes.extraLarge.height)
                                .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.cardLarge))
                                .cardShadow(isLarge: true)
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

                        Text("Tap to Reveal")
                            .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.headline + 2))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .opacity((showFloatingCard && currentStep >= 1 && currentStep <= 3) ? 0 : 1)
                            .animation(.easeOut(duration: 0.2), value: showFloatingCard)
                    }
                    .padding(.vertical, 20)

                    if let lineImageD = UIImage(named: "linedesignd") {
                        Image(uiImage: lineImageD)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: AppConstants.Scaling.w(280), height: 22)
                            .padding(.bottom, AppConstants.Spacing.sectionSpacing)
                    }

                    // Three small cards row
                    HStack(alignment: .top, spacing: AppConstants.Spacing.small) {
                        // Birth card
                        VStack(spacing: AppConstants.Spacing.small) {
                            if let cardImage = ImageManager.shared.loadCardImage(for: birthCard) {
                                Image(uiImage: cardImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: AppConstants.CardSizes.small.width, height: AppConstants.CardSizes.small.height)
                                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card))
                                    .cardShadow(isLarge: true)
                                    .scaleEffect(highlightedCardStep == 1 ? 1.12 : 1.0)
                                    .animation(.easeInOut(duration: 0.5), value: highlightedCardStep)
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
                                .foregroundColor(.black)
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
                                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card))
                                    .cardShadow(isLarge: true)
                                    .scaleEffect(highlightedCardStep == 2 ? 1.12 : 1.0)
                                    .animation(.easeInOut(duration: 0.5), value: highlightedCardStep)
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
                                .foregroundColor(.black)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity)

                        // Astral card
                        VStack(spacing: AppConstants.Spacing.small) {
                            if let cardImage = ImageManager.shared.loadCardImage(for: astralCard) {
                                Image(uiImage: cardImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: AppConstants.CardSizes.small.width, height: AppConstants.CardSizes.small.height)
                                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card))
                                    .cardShadow(isLarge: true)
                                    .scaleEffect(highlightedCardStep == 3 ? 1.12 : 1.0)
                                    .animation(.easeInOut(duration: 0.5), value: highlightedCardStep)
                                    .opacity((currentStep == 3 && showFloatingCard) ? 0 : 1)
                                    .animation(.none, value: showFloatingCard)
                                    .background(
                                        GeometryReader { geo in
                                            Color.clear.preference(key: AstralCardFramePreferenceKey.self, value: geo.frame(in: .global))
                                        }
                                    )
                                    .onPreferenceChange(AstralCardFramePreferenceKey.self) { frame in
                                        astralCardFrame = frame
                                    }
                            }
                            Text("52-Day Cycle")
                                .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.body))
                                .foregroundColor(.black)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, AppConstants.Spacing.medium)
                    .padding(.bottom, AppConstants.Scaling.h(62))
                    .opacity(showOverlay ? 0.65 : 1.0)
                    .blur(radius: showOverlay ? 2 : 0)
                    .animation(.easeInOut(duration: 0.3), value: showOverlay)
                }

                Spacer()
            }
        }
        .background(Color(red: 0.91, green: 0.82, blue: 0.63))
        .ignoresSafeArea(edges: .bottom)
    }
    
    // MARK: - Floating Card
    private var floatingCard: some View {
        Group {
            if currentStep == 4 {
                if let cardBackImage = UIImage(named: "cardback") {
                    Image(uiImage: cardBackImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 240 * cardScale)
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.cardLarge))
                        .shadow(color: .black.opacity(cardShadowOpacity), radius: cardShadowRadius, x: 0, y: cardShadowRadius / 2)
                }
            } else {
                if let uiImage = ImageManager.shared.loadCardImage(for: currentCard) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 240 * cardScale)
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.cardLarge))
                        .shadow(color: .black.opacity(cardShadowOpacity), radius: cardShadowRadius, x: 0, y: cardShadowRadius / 2)
                }
            }
        }
        .position(cardPosition)
        .opacity(cardOpacity)
    }

    // MARK: - Tutorial Modal Content
    private var tutorialModalContent: some View {
        ScrollView {
            VStack(spacing: 25) {
                if currentStep == 0 {
                    welcomeScreenContent
                } else {
                    cardTutorialContent
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
        .background(
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: AppConstants.CornerRadius.modal)
                    .fill(Color(red: 0.86, green: 0.77, blue: 0.57).opacity(0.95))
                    .onAppear {
                        // Modal card position - center in placeholder area
                        let frame = geo.frame(in: .global)
                        modalCardPosition = CGPoint(
                            x: frame.midX,
                            y: frame.minY + 90
                        )
                    }
            }
        )
        .cornerRadius(AppConstants.CornerRadius.modal)
        .padding(.horizontal, 25)
        .padding(.top, 44)
        .padding(.bottom, 20)
    }

    // MARK: - Welcome Screen Content
    private var welcomeScreenContent: some View {
        GeometryReader { geometry in
            let isSmallScreen = geometry.size.height < 700
            let logoSize: CGFloat = isSmallScreen ? 180 : 218
            let textSpacing: CGFloat = isSmallScreen ? 10 : 12

            VStack(spacing: 10) {
                Spacer()

                if let appLogo = UIImage(named: "apptitle") {
                    Image(uiImage: appLogo)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: logoSize)
                        .opacity(showWelcomeTitle ? 1 : 0)
                        .animation(.easeInOut(duration: 0.9), value: showWelcomeTitle)
                }

                Spacer()

            VStack(spacing: 6) {
                if let lineImage = UIImage(named: "linedesign") {
                    Image(uiImage: lineImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200)
                        .opacity(showWelcomeLineDesign ? 1 : 0)
                        .animation(.easeInOut(duration: 0.7), value: showWelcomeLineDesign)
                }

                VStack(alignment: .leading, spacing: textSpacing) {
                Text("For centuries, The Deck of Cards charted the planet's movements and shaped the archetypal roles that became the foundation for the Tarot and Jung. Like a constellation, Your Cards offer a fixed pattern that you can navigate by.")
                    .font(.custom("Iowan Old Style", size: isSmallScreen ? 15 : 16))
                    .tracking(0.2)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)
                    .lineLimit(5)
                    .minimumScaleFactor(0.85)

                Text("Cardology isn't designed to predict futures or outcomes. Any meanings you find here are the echoes of your own self-discovery. Interpretations are here for historical reference and entertainment only, never advice.")
                    .font(.custom("Iowan Old Style", size: isSmallScreen ? 15 : 16))
                    .tracking(0.2)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)
                    .lineLimit(5)
                    .minimumScaleFactor(0.85)

                    Text("The tutorial will introduce The Cards and help you find your way around. You can access it and more information anytime in the Settings menu.")
                        .font(.custom("Iowan Old Style", size: isSmallScreen ? 15 : 16))
                        .tracking(0.2)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.leading)
                        .lineLimit(4)
                        .minimumScaleFactor(0.85)
                }
                .padding(.horizontal, isSmallScreen ? 20 : 25)
                .padding(.vertical, 4)
                .opacity(showWelcomeText ? 1 : 0)
                .animation(.easeInOut(duration: 0.7), value: showWelcomeText)

                if let lineImageD = UIImage(named: "linedesignd") {
                    Image(uiImage: lineImageD)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200)
                        .opacity(showWelcomeText ? 1 : 0)
                        .animation(.easeInOut(duration: 0.7), value: showWelcomeText)
                }
            }

            Spacer()

            Button(action: skipTutorial) {
                Text("Skip")
                    .font(.custom("Iowan Old Style", size: 16))
                    .foregroundColor(.black)
            }
            .opacity(showWelcomeBody ? 1 : 0)
            .animation(.easeInOut(duration: 0.6), value: showWelcomeBody)
            .padding(.bottom, isSmallScreen ? 4 : 8)

            Button(action: advanceStep) {
                Text("Continue")
                    .font(.custom("Iowan Old Style", size: 18))
                    .foregroundColor(.white)
                    .padding(.horizontal, isSmallScreen ? 40 : 50)
                    .padding(.vertical, isSmallScreen ? 10 : 12)
                    .background(AppTheme.darkAccent.opacity(0.7))
                    .cornerRadius(AppConstants.CornerRadius.button)
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
            }
            .opacity(showWelcomeBody ? 1 : 0)
            .animation(.easeInOut(duration: 0.6), value: showWelcomeBody)

            Spacer()
                .frame(height: 20)
            }
        }
    }

    // MARK: - Card Tutorial Content
    private var cardTutorialContent: some View {
        GeometryReader { geometry in
            let isSmallScreen = geometry.size.height < 700
            let cardPlaceholderHeight: CGFloat = isSmallScreen ? 200 : 240
            let topPadding: CGFloat = isSmallScreen ? 15 : 30
            let spacerHeight: CGFloat = isSmallScreen ? 8 : 15

            VStack(spacing: 10) {
                // Invisible placeholder for card (actual card is floating)
                Color.clear
                    .frame(height: cardPlaceholderHeight)

                Text(tutorialSteps[currentStep].cardTypeHeader)
                    .font(.custom("Iowan Old Style", size: 22))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeInOut(duration: 0.4), value: showContent)
                    .padding(.top, topPadding)
                    .padding(.horizontal, 20)

                Spacer()
                    .frame(height: spacerHeight)

            // Text content with fixed height for consistent button positioning
            VStack(spacing: 6) {
                if let lineImage = UIImage(named: "linedesign") {
                    Image(uiImage: lineImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 22)
                }

                Text(tutorialSteps[currentStep].description)
                    .font(.custom("Iowan Old Style", size: isSmallScreen ? 16 : 17))
                    .tracking(0.5)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)
                    .lineLimit(6)
                    .minimumScaleFactor(0.85)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 4)
                    .frame(minHeight: isSmallScreen ? 90 : 100, maxHeight: isSmallScreen ? 120 : 140, alignment: .top)

                if let lineImageD = UIImage(named: "linedesignd") {
                    Image(uiImage: lineImageD)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 22)
                }
            }
            .opacity(showContent ? 1 : 0)
            .animation(.easeInOut(duration: 0.4), value: showContent)

            Spacer()

            // Settings text for final tile (or invisible spacer for consistent button position)
            Group {
                if currentStep == 4 {
                    Text("To learn more about the Cards, or to revisit this tutorial, go to Settings.")
                        .font(.custom("Iowan Old Style", size: 15))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .minimumScaleFactor(0.9)
                        .padding(.horizontal, 25)
                        .padding(.bottom, 20)
                        .opacity(showSettingsText ? 1 : 0)
                        .animation(.easeInOut(duration: 0.4), value: showSettingsText)
                } else {
                    // Invisible spacer with same text to maintain consistent button position
                    Text("To learn more about the Cards, or to revisit this tutorial, go to Settings.")
                        .font(.custom("Iowan Old Style", size: 16))
                        .foregroundColor(.clear)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .padding(.bottom, 20)
                }
            }

            VStack(spacing: 8) {
                // Skip button centered above Continue (visible on tiles 2-4, invisible spacer on tile 5)
                if currentStep < 4 {
                    Button(action: skipTutorial) {
                        Text("Skip")
                            .font(.custom("Iowan Old Style", size: 16))
                            .foregroundColor(.black)
                    }
                    .padding(.bottom, 5)
                } else {
                    // Invisible spacer on tile 5 to maintain consistent button position
                    Text("Skip")
                        .font(.custom("Iowan Old Style", size: 16))
                        .foregroundColor(.clear)
                        .padding(.bottom, 5)
                }

                // Continue/Begin button
                Button(action: advanceStep) {
                    Text(currentStep < 4 ? "Continue" : "Begin")
                        .font(.custom("Iowan Old Style", size: 18))
                        .foregroundColor(.white)
                        .padding(.horizontal, 50)
                        .padding(.vertical, 12)
                        .background(currentStep == 4 ? AppTheme.darkAccent : AppTheme.darkAccent.opacity(0.7))
                        .cornerRadius(AppConstants.CornerRadius.button)
                        .shadow(color: .black.opacity(currentStep == 4 ? 0.2 : 0.15), radius: currentStep == 4 ? 6 : 4, x: 0, y: 2)
                }

                // Progress dots with back button
                HStack(spacing: 20) {
                    // Back button - always present but invisible when not needed
                    Group {
                        if currentStep > 1 {
                            Button(action: goBack) {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("Back")
                                        .font(.custom("Iowan Old Style", size: 16))
                                }
                                .foregroundColor(.black)
                            }
                            .disabled(isTransitioning)
                        } else {
                            // Invisible spacer
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Back")
                                    .font(.custom("Iowan Old Style", size: 16))
                            }
                            .foregroundColor(.clear)
                        }
                    }
                    .frame(width: 50)

                    // Progress dots
                    HStack(spacing: 8) {
                        ForEach(1..<5, id: \.self) { index in
                            Circle()
                                .fill(index == currentStep ? Color.black : Color.black.opacity(0.15))
                                .frame(width: 8, height: 8)
                                .scaleEffect(index == currentStep ? 1.4 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentStep)
                        }
                    }

                    // Right spacer for symmetry
                    Color.clear.frame(width: 50)
                }
                .padding(.top, 4)
            }
            .opacity(showButtons ? 1 : 0)
            .animation(.easeInOut(duration: 0.4), value: showButtons)

            Spacer()
                .frame(height: 20)
            }
        }
    }

    // MARK: - Helper Functions
    private func startTutorial() {
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
        case 3: return astralCard
        default: return dailyCard
        }
    }
    
    private func sourceCardFrame(for step: Int) -> CGRect {
        switch step {
        case 1: return birthCardFrame
        case 2: return solarCardFrame
        case 3: return astralCardFrame
        case 4: return dailyCardFrame
        default: return .zero
        }
    }

    private func yOffsetForStep(_ step: Int) -> CGFloat {
        switch step {
        case 4: return AppConstants.Scaling.h(-62) // Daily card - same offset as small cards
        default: return AppConstants.Scaling.h(-62)  // Small cards (1-3)
        }
    }
    
    private func animateCardTransition(to nextStep: Int) {
        let sourceFrame = sourceCardFrame(for: nextStep)

        // Ensure we have a valid frame
        guard sourceFrame != .zero else {
            return
        }

        // Skip pulse for daily card (step 4), use pulse for small cards (1-3)
        if nextStep == 4 {
            // Daily card: no pulse, start animation immediately with smooth entry
            let sourceHeight = sourceFrame.height
            let targetHeight: CGFloat = 240
            let yOffset = yOffsetForStep(nextStep)

            // Start card at background position with upward offset to match visual position
            cardPosition = CGPoint(x: sourceFrame.midX, y: sourceFrame.midY + yOffset)
            cardScale = sourceHeight / targetHeight
            cardOpacity = 1
            cardShadowRadius = 5  // Small shadow to match background cards
            cardShadowOpacity = 0.2
            showFloatingCard = true

            // Start card movement and overlay fade in simultaneously
            withAnimation(.easeOut(duration: 0.5)) {
                showOverlay = true
            }

            // Smooth entry animation with easeIn for gradual momentum (matching small cards)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeIn(duration: 0.6)) {
                    cardPosition = modalCardPosition
                    cardScale = 1.0
                    cardShadowRadius = 12  // Larger shadow for modal card
                    cardShadowOpacity = 0.3
                }

                // Fade in background during animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        backgroundOpacity = 0.65
                    }
                }

                // Show content while card is still settling
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showContent = true
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        isTransitioning = false
                    }
                }

                // Fade in buttons after card animation completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showButtons = true
                    }

                    // Show settings text after buttons for step 4
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showSettingsText = true
                        }
                    }
                }
            }
        } else {
            // Small cards: use pulse effect for all small cards (steps 1-3)
            let shouldPulse = (nextStep >= 1 && nextStep <= 3)

            if shouldPulse {
                highlightedCardStep = nextStep
            }

            // Wait for pulse to complete (or skip if no pulse) before starting card animation
            let pulseDelay: Double = shouldPulse ? 0.6 : 0.0
            DispatchQueue.main.asyncAfter(deadline: .now() + pulseDelay) {
                if shouldPulse {
                    // Clear highlight immediately when animation starts for gradual momentum
                    highlightedCardStep = nil
                }

                // Show overlay after pulse completes
                withAnimation(.easeOut(duration: 0.5)) {
                    showOverlay = true
                }

                let sourceHeight = sourceFrame.height
                let targetHeight: CGFloat = 240

                // Start card at background position - offset to match visual position
                let yOffset: CGFloat = AppConstants.Scaling.h(-62)
                cardPosition = CGPoint(x: sourceFrame.midX, y: sourceFrame.midY + yOffset)
                cardScale = sourceHeight / targetHeight
                cardOpacity = 1
                cardShadowRadius = 5  // Small shadow to match background cards
                cardShadowOpacity = 0.2
                showFloatingCard = true

                // Animation timing - slightly faster
                let animationDuration: Double = 0.6
                let animationDelay: Double = 0.05

                // Animate to modal position - easeIn for gradual momentum gathering
                DispatchQueue.main.asyncAfter(deadline: .now() + animationDelay) {
                    withAnimation(.easeIn(duration: animationDuration)) {
                        cardPosition = modalCardPosition
                        cardScale = 1.0
                        cardShadowRadius = 12  // Larger shadow for modal card
                        cardShadowOpacity = 0.3
                    }

                    // Fade in background during animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeInOut(duration: 0.6)) {
                            backgroundOpacity = 0.65
                        }
                    }

                    // Show content while card is still settling (earlier for smoother transition)
                    let contentFadeDelay = nextStep == 1 ? 0.9 : 0.4
                    DispatchQueue.main.asyncAfter(deadline: .now() + contentFadeDelay) {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showContent = true
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            isTransitioning = false
                        }
                    }

                    // Fade in buttons after card animation completes
                    let buttonFadeDelay = animationDuration + 0.2
                    DispatchQueue.main.asyncAfter(deadline: .now() + buttonFadeDelay) {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showButtons = true
                        }
                    }
                }
            }
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
                            // Overlay will be shown inside animateCardTransition after pulse
                            animateCardTransition(to: 1)
                        }
                    }
                }
            }
        } else if currentStep < 4 {
            // Phase 1: Fade out content
            withAnimation(.easeOut(duration: 0.2)) {
                showContent = false
                showSettingsText = false
                showButtons = false
            }

            // Phase 2: Fade out background
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    backgroundOpacity = 0
                }

                // Phase 3: Animate card back to background and hide overlay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    let currentFrame = sourceCardFrame(for: currentStep)
                    let yOffset = yOffsetForStep(currentStep)

                    // Smooth return animation matching back button
                    withAnimation(.spring(response: 0.8, dampingFraction: 1.0)) {
                        cardPosition = CGPoint(x: currentFrame.midX, y: currentFrame.midY + yOffset)
                        cardScale = currentFrame.height / 240
                        cardShadowRadius = 5  // Return to small shadow
                        cardShadowOpacity = 0.2
                        showOverlay = false
                    }

                    // Hide floating card after spring animation completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        showFloatingCard = false
                        let nextStep = currentStep + 1
                        currentStep = nextStep

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            // Overlay will be shown inside animateCardTransition after pulse
                            animateCardTransition(to: nextStep)
                        }
                    }
                }
            }
        } else {
            // Final step - close tutorial - dismiss everything imm#imageLiteral(resourceName: "simulator_screenshot_BB4902A3-055E-49AC-93F4-7C97986EC104.png")ediately for clean transition
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
            withAnimation(.easeInOut(duration: 0.4)) {
                backgroundOpacity = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                let currentFrame = sourceCardFrame(for: currentStep)
                let yOffset = yOffsetForStep(currentStep)

                withAnimation(.spring(response: 0.8, dampingFraction: 1.0)) {
                    cardPosition = CGPoint(x: currentFrame.midX, y: currentFrame.midY + yOffset)
                    cardScale = currentFrame.height / 240
                    cardShadowRadius = 5  // Return to small shadow
                    cardShadowOpacity = 0.2
                    showOverlay = false
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showFloatingCard = false
                    let previousStep = currentStep - 1
                    currentStep = previousStep
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.spring(response: 0.8, dampingFraction: 1.0)) {
                            showOverlay = true
                        }
                        
                        animateCardTransition(to: previousStep)
                    }
                }
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

struct AstralCardFramePreferenceKey: PreferenceKey {
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

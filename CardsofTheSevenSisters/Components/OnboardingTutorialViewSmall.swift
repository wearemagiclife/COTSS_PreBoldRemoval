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
                            .foregroundColor(.black)
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

                        Spacer(minLength: 8)

                        Text("Tap to Reveal")
                            .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.headline + 2))
                            .foregroundColor(.black)
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
                                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card))
                                    .cardShadow(isLarge: true)
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
                                    .scaledToFit()
                                    .frame(width: 75, height: 105)
                                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card))
                                    .cardShadow(isLarge: true)
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
                                .foregroundColor(.black)
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
                                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card))
                                    .cardShadow(isLarge: true)
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
                                .foregroundColor(.black)
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
        .background(Color(red: 0.86, green: 0.75, blue: 0.55))
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
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.cardLarge))
                        .shadow(color: .black.opacity(cardShadowOpacity), radius: cardShadowRadius, x: 0, y: cardShadowRadius / 2)
                }
            } else {
                if let uiImage = ImageManager.shared.loadCardImage(for: currentCard) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: cardHeight * cardScale)
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
                    .fill(Color(red: 0.86, green: 0.77, blue: 0.57).opacity(0.95))
                    .onAppear {
                        // Modal card position - center in placeholder area
                        let frame = geo.frame(in: .global)
                        modalCardPosition = CGPoint(
                            x: frame.midX,
                            y: frame.minY + 80
                        )
                    }
            }
        )
        .cornerRadius(AppConstants.CornerRadius.modal)
        .overlay(alignment: .topTrailing) {
            Button(action: skipTutorial) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.primaryText)
                    .frame(width: 32, height: 28)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.90, green: 0.83, blue: 0.67))
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, 12)
            .padding(.trailing, 12)
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
        VStack(spacing: 10) {
            Spacer()

            VStack(spacing: 6) {
                Text("WHAT IS CHANCE?")
                    .font(.custom("Iowan Old Style", size: 18))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    .opacity(showWelcomeTitle ? 1 : 0)
                    .animation(.easeInOut(duration: 0.7), value: showWelcomeTitle)

                VStack(alignment: .leading, spacing: 12) {
                    Text("For centuries, The Deck of Cards was used to chart planetary movements. Long before Carl Jung or even the Tarot, each card was given a universal archetype. They can be used as a map to chart hidden universal currents, or like a constellation, they can help us navigate personal insights.")
                        .font(.custom("Iowan Old Style", size: 14))
                        .tracking(0.1)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.leading)

                    if let lineImageD = UIImage(named: "linedesignd") {
                        Image(uiImage: lineImageD)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 160, height: 16)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 8)
                            .padding(.bottom, 4)
                    }

                    Text("This system is not designed to predict futures or outcomes. Any meanings you find here are the echoes of your own self-discovery. Interpretations are here for historical reference and entertainment only. Never advice.")
                        .font(.custom("Iowan Old Style", size: 14))
                        .tracking(0.1)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.leading)

                    Text("The tutorial will introduce The Cards and help you find your way around the app. Go to the Settings Menu anytime to revisit this tutorial & learn more.")
                        .font(.custom("Iowan Old Style", size: 14))
                        .tracking(0.1)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 4)
                .opacity(showWelcomeText ? 1 : 0)
                .animation(.easeInOut(duration: 0.7), value: showWelcomeText)
            }

            Spacer()

            Button(action: advanceStep) {
                Text("Continue")
                    .font(.custom("Iowan Old Style", size: 14))
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 8)
                    .background(AppTheme.darkAccent.opacity(0.7))
                    .cornerRadius(AppConstants.CornerRadius.button)
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
            }
            .opacity(showWelcomeBody ? 1 : 0)
            .animation(.easeInOut(duration: 0.6), value: showWelcomeBody)

            Spacer()
                .frame(height: 10)
        }
    }

    // MARK: - Card Tutorial Content
    private var cardTutorialContent: some View {
        VStack(spacing: 0) {
            // Invisible placeholder for card (actual card is floating)
            Color.clear
                .frame(height: 145)
                .padding(.bottom, 10)

            Text(tutorialSteps[currentStep].cardTypeHeader)
                .font(.custom("Iowan Old Style", size: 18))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .opacity(showContent ? 1 : 0)
                .animation(.easeInOut(duration: 0.4), value: showContent)
                .padding(.top, 16)

            Spacer(minLength: 8)
                .layoutPriority(-1)

            // Text content
            VStack(spacing: 6) {
                LineBreak(width: 280)

                Text(tutorialSteps[currentStep].description)
                    .font(.custom("Iowan Old Style", size: 14))
                    .tracking(0.5)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 4)
                    .fixedSize(horizontal: false, vertical: true)

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
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 14)
                    .opacity(showSettingsText ? 1 : 0)
                    .animation(.easeInOut(duration: 0.4), value: showSettingsText)
                    .layoutPriority(-1)
            }

            // Bottom button section - always visible with layout priority
            VStack(spacing: 12) {
                // Continue/Begin button
                Button(action: advanceStep) {
                    Text(currentStep < 4 ? "Continue" : "Begin")
                        .font(.custom("Iowan Old Style", size: 16))
                        .foregroundColor(.white)
                        .padding(.horizontal, 44)
                        .padding(.vertical, 10)
                        .background(currentStep == 4 ? AppTheme.darkAccent : AppTheme.darkAccent.opacity(0.7))
                        .cornerRadius(AppConstants.CornerRadius.button)
                        .shadow(color: .black.opacity(currentStep == 4 ? 0.2 : 0.15), radius: currentStep == 4 ? 6 : 4, x: 0, y: 2)
                }

                // Progress dots (tappable)
                HStack(spacing: 12) {
                    ForEach(1..<5, id: \.self) { index in
                        Circle()
                            .fill(index == currentStep ? Color.black : Color.black.opacity(0.15))
                            .frame(width: 10, height: 10)
                            .scaleEffect(index == currentStep ? 1.3 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentStep)
                            .frame(width: 40, height: 44)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                guard !isTransitioning else { return }
                                if index > currentStep && currentStep < 4 {
                                    advanceStep()
                                } else if index < currentStep && currentStep > 1 {
                                    goBack()
                                }
                            }
                    }
                }
                .padding(.top, 10)
                .padding(.bottom, 24)
            }
            .layoutPriority(1)
            .opacity(showButtons ? 1 : 0)
            .animation(.easeInOut(duration: 0.4), value: showButtons)
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
        case 1, 2, 3: return -15  // Small cards need to return higher
        default: return 0
        }
    }

    private func animateCardTransition(to nextStep: Int) {
        let sourceFrame = sourceCardFrame(for: nextStep)

        // Ensure we have a valid frame
        guard sourceFrame != .zero else {
            return
        }

        let targetHeight: CGFloat = 145  // Sized to fit modal without scrolling

        // Skip pulse for daily card (step 4), use pulse for small cards (1-3)
        if nextStep == 4 {
            // Daily card: no pulse, start animation immediately with smooth entry
            let sourceHeight = sourceFrame.height

            // No offset for daily card on small screen
            cardPosition = CGPoint(x: sourceFrame.midX, y: sourceFrame.midY)
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

                    // Show settings text for step 4
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
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

            // Wait for pulse to complete and reverse before starting card animation
            // Pulse up takes 0.3s, then we clear it and let it animate back (0.3s), then card moves
            let pulseUpDelay: Double = shouldPulse ? 0.3 : 0.0
            DispatchQueue.main.asyncAfter(deadline: .now() + pulseUpDelay) {
                if shouldPulse {
                    // Clear highlight - card will animate back to normal size
                    highlightedCardStep = nil
                }

                // Wait for pulse to reverse before starting card movement
                let pulseDownDelay: Double = shouldPulse ? 0.3 : 0.0
                DispatchQueue.main.asyncAfter(deadline: .now() + pulseDownDelay) {
                    // Show overlay after pulse fully completes
                    withAnimation(.easeOut(duration: 0.5)) {
                        showOverlay = true
                    }

                    let sourceHeight = sourceFrame.height
                    let yOffset = yOffsetForStep(nextStep)

                    // Start card at background position (with offset for small cards)
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
            // Phase 1: Fade out all content together
            withAnimation(.easeOut(duration: 0.2)) {
                showContent = false
                showSettingsText = false
                showButtons = false
            }

            // Phase 2: Hide overlay and fade background together, then animate card back
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                let currentFrame = sourceCardFrame(for: currentStep)
                let yOffset = yOffsetForStep(currentStep)
                let cardHeight: CGFloat = 145

                // Hide overlay and fade background simultaneously so homeview is visible
                withAnimation(.easeInOut(duration: 0.4)) {
                    showOverlay = false
                    backgroundOpacity = 0
                }

                // Animate card back to background position
                withAnimation(.spring(response: 0.8, dampingFraction: 1.0)) {
                    cardPosition = CGPoint(x: currentFrame.midX, y: currentFrame.midY + yOffset)
                    cardScale = currentFrame.height / cardHeight
                    cardShadowRadius = 5  // Return to small shadow
                    cardShadowOpacity = 0.2
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
            let yOffset = yOffsetForStep(currentStep)
            let cardHeight: CGFloat = 145

            // Hide overlay and fade background simultaneously so homeview is visible
            withAnimation(.easeInOut(duration: 0.4)) {
                showOverlay = false
                backgroundOpacity = 0
            }

            // Animate card back to background position
            withAnimation(.spring(response: 0.8, dampingFraction: 1.0)) {
                cardPosition = CGPoint(x: currentFrame.midX, y: currentFrame.midY + yOffset)
                cardScale = currentFrame.height / cardHeight
                cardShadowRadius = 5  // Return to small shadow
                cardShadowOpacity = 0.2
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
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

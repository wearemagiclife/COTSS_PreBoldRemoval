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
                        .foregroundColor(AppTheme.primaryText)
                }
                .padding(.horizontal, AppConstants.Spacing.pageInset)
                .padding(.vertical, AppConstants.Spacing.ornament)

                // Welcome text
                Text("Welcome, \(userName.isEmpty ? "Guest" : userName)")
                    .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.extraLarge + 2))
                    .foregroundColor(AppTheme.primaryText)
                    .padding(.bottom, AppConstants.Spacing.tight)
                    .opacity(showOverlay ? 0 : 1)
                    .animation(.easeOut(duration: 0.3), value: showOverlay)

                if let lineImage = UIImage(named: "linedesign") {
                    Image(uiImage: lineImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 260)
                        .padding(.vertical, AppConstants.Spacing.ornament)
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
                                        Color.clear.preference(key: DailyCardFramePreferenceKey.self, value: geo.frame(in: .global))
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
                                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.CardStyle.cornerRadius(for: AppConstants.CardSizes.small)))
                                    .modifier(DarkModeGoldGlow(size: AppConstants.CardSizes.small))
                                .cardShadow(size: AppConstants.CardSizes.small)
                                    .scaleEffect(highlightedCardStep == 1 ? 1.15 : 1.0)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.65), value: highlightedCardStep)
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
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: AppConstants.CardSizes.small.width, height: AppConstants.CardSizes.small.height)
                                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.CardStyle.cornerRadius(for: AppConstants.CardSizes.small)))
                                    .modifier(DarkModeGoldGlow(size: AppConstants.CardSizes.small))
                                .cardShadow(size: AppConstants.CardSizes.small)
                                    .scaleEffect(highlightedCardStep == 2 ? 1.15 : 1.0)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.65), value: highlightedCardStep)
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
                                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.CardStyle.cornerRadius(for: AppConstants.CardSizes.small)))
                                    .modifier(DarkModeGoldGlow(size: AppConstants.CardSizes.small))
                                .cardShadow(size: AppConstants.CardSizes.small)
                                    .scaleEffect(highlightedCardStep == 3 ? 1.15 : 1.0)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.65), value: highlightedCardStep)
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
                    .padding(.horizontal, AppConstants.Spacing.pageInset)
                    .opacity(showOverlay ? 0.65 : 1.0)
                    .blur(radius: showOverlay ? 2 : 0)
                    .animation(.easeInOut(duration: 0.3), value: showOverlay)
                }

                Spacer()
            }
        }
        .background(AppTheme.backgroundColor)
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
                        .scaleEffect(colorScheme == .dark ? 0.95 : 1.0)
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.CardStyle.cornerRadius(for: AppConstants.CardSizes.large)))
                        .modifier(DarkModeGoldGlow(size: AppConstants.CardSizes.large))
                                .cardShadow(size: AppConstants.CardSizes.large)
                }
            } else {
                if let uiImage = ImageManager.shared.loadCardImage(for: currentCard) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 240 * cardScale)
                        .scaleEffect(colorScheme == .dark ? 0.95 : 1.0)
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.CardStyle.cornerRadius(for: AppConstants.CardSizes.large)))
                        .modifier(DarkModeGoldGlow(size: AppConstants.CardSizes.large))
                                .cardShadow(size: AppConstants.CardSizes.large)
                }
            }
        }
        .position(cardPosition)
        .opacity(cardOpacity)
    }

    // MARK: - Tutorial Modal Content
    private var tutorialModalContent: some View {
        ScrollView {
            VStack(spacing: AppConstants.Spacing.cardPadding) {
                if currentStep == 0 {
                    welcomeScreenContent
                } else {
                    cardTutorialContent
                }
            }
            .padding(.vertical, AppConstants.Spacing.ornament)
            .padding(.horizontal, AppConstants.Spacing.cardPadding)
        }
        .scrollIndicators(.hidden)
        .background(
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: AppConstants.CornerRadius.modal)
                    .fill(AppTheme.backgroundColor.opacity(0.95))
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
        .frame(height: currentStep == 0 ? UIScreen.main.bounds.height * 0.88 : nil)
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
            .modifier(DarkModeGoldGlow(size: AppConstants.CardSizes.small))
            .accessibilityLabel("Continue")
            .accessibilityHint("Proceed to tutorial")
            .opacity(showWelcomeBody ? 1 : 0)
            .animation(.easeInOut(duration: 0.6), value: showWelcomeBody)

            Spacer()
                .frame(height: 30)
        }
    }

    // MARK: - Card Tutorial Content
    private var cardTutorialContent: some View {
        VStack(spacing: 0) {
            // Invisible placeholder for card (actual card is floating)
            Color.clear
                .frame(height: 240)
                .padding(.top, 16)
                .padding(.bottom, 20)

            Text(tutorialSteps[currentStep].cardTypeHeader)
                .font(.custom("Iowan Old Style", size: 22))
                .foregroundColor(AppTheme.primaryText)
                .multilineTextAlignment(.center)
                .opacity(showContent ? 1 : 0)
                .animation(.easeInOut(duration: 0.4), value: showContent)
                .padding(.top, colorScheme == .dark ? 16 : 8)

            Spacer(minLength: 8)
                .layoutPriority(-1)

            // Text content
            VStack(spacing: 6) {
                if let lineImage = UIImage(named: "linedesign") {
                    Image(uiImage: lineImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 260)
                        .padding(.vertical, AppConstants.Spacing.ornament)
                }

                Text(tutorialSteps[currentStep].description)
                    .font(.custom("Iowan Old Style", size: colorScheme == .dark ? 18 : 16))
                    .lineSpacing(AppConstants.Typography.bodyLineSpacing)
                    .tracking(0.8)
                    .foregroundColor(AppTheme.primaryText)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 25)
                    .padding(.vertical, 4)
                    .fixedSize(horizontal: false, vertical: true)

                if let lineImageD = UIImage(named: "linedesignd") {
                    Image(uiImage: lineImageD)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 260)
                        .padding(.vertical, AppConstants.Spacing.ornament)
                }
            }
            .opacity(showContent ? 1 : 0)
            .animation(.easeInOut(duration: 0.4), value: showContent)
            .layoutPriority(-1)

            Spacer(minLength: 12)
                .layoutPriority(-1)

            // Settings text for final tile
            if currentStep == 4 {
                Text("To learn more about the Cards, or to revisit this tutorial, go to Settings.")
                    .font(.custom("Iowan Old Style", size: 15))
                    .foregroundColor(AppTheme.primaryText)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 20)
                    .opacity(showSettingsText ? 1 : 0)
                    .animation(.easeInOut(duration: 0.4), value: showSettingsText)
                    .layoutPriority(-1)
            }

            // Bottom button section - always visible with layout priority
            VStack(spacing: 12) {
                // Continue/Begin button
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
                .padding(.top, 12)
                .padding(.bottom, 24)
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
    
    private func animateCardTransition(to nextStep: Int) {
        let sourceFrame = sourceCardFrame(for: nextStep)

        // Ensure we have a valid frame
        guard sourceFrame != .zero else { return }

        // Skip pulse for daily card (step 4), use pulse for small cards (1-3)
        if nextStep == 4 {
            // Daily card: no pulse, start animation immediately
            let sourceHeight = sourceFrame.height
            let targetHeight: CGFloat = 240

            // Start card 62 pixels above background position to match visual alignment
            cardPosition = CGPoint(x: sourceFrame.midX, y: sourceFrame.midY - 62)
            cardScale = sourceHeight / targetHeight
            cardOpacity = 1
            cardShadowRadius = 5  // Small shadow to match background cards
            cardShadowOpacity = 0.2
            showFloatingCard = true

            // Start card movement and overlay fade in simultaneously
            withAnimation(.easeOut(duration: 0.5)) {
                showOverlay = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
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

                // Fade in buttons after card animation completes (buttons already visible for step 4)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    // Show settings text for step 4
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showSettingsText = true
                        }
                    }
                }
            }
        } else {
            // Small cards: use pulse effect only on first appearance (from welcome screen)
            let shouldPulse = (nextStep == 1) // Only pulse for first small card

            if shouldPulse {
                highlightedCardStep = nextStep
            }

            // Wait for pulse to complete (or skip if no pulse) before starting card animation
            let pulseDelay: Double = shouldPulse ? 0.5 : 0.0
            DispatchQueue.main.asyncAfter(deadline: .now() + pulseDelay) {
                if shouldPulse {
                    highlightedCardStep = nil
                }

                // Show overlay after pulse completes
                withAnimation(.easeOut(duration: 0.5)) {
                    showOverlay = true
                }

                let sourceHeight = sourceFrame.height
                let targetHeight: CGFloat = 240

                // Start card at background position - 62 pixels above for small cards
                let yOffset: CGFloat = -62
                cardPosition = CGPoint(x: sourceFrame.midX, y: sourceFrame.midY + yOffset)
                cardScale = sourceHeight / targetHeight
                cardOpacity = 1
                cardShadowRadius = 5  // Small shadow to match background cards
                cardShadowOpacity = 0.2
                showFloatingCard = true

                // Slower, more gradual animation for first slide
                let animationDuration: Double = nextStep == 1 ? 1.0 : 0.7
                let animationDelay: Double = 0.1

                // Animate to modal position with proper timing
                DispatchQueue.main.asyncAfter(deadline: .now() + animationDelay) {
                    withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
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
                            animateCardTransition(to: 1)
                        }
                    }
                }
            }
        } else if currentStep < 4 {
            // Phase 1: Fade out content (keep buttons visible when going to step 4)
            withAnimation(.easeOut(duration: 0.2)) {
                showContent = false
                showSettingsText = false
                if currentStep != 3 {
                    showButtons = false
                }
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

                    withAnimation(.spring(response: 0.8, dampingFraction: 1.0)) {
                        cardPosition = CGPoint(x: currentFrame.midX, y: currentFrame.midY + yOffset)
                        cardScale = currentFrame.height / 240
                        cardShadowRadius = 5  // Return to small shadow
                        cardShadowOpacity = 0.2
                        showOverlay = false
                    }

                    // Phase 4: Wait for card to reach background, then transition
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

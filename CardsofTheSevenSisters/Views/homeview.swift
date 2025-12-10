import SwiftUI
import AuthenticationServices

struct HomeView: View {
    @ObservedObject private var dataManager: DataManager = DataManager.shared
    @StateObject private var viewModel = HomeViewModel()

    @State private var showingSettings = false
    
    @State private var showTutorial = false
    @State private var showWelcome = false
    @State private var showContent = false
    
    var body: some View {
        Group {
            if dataManager.isProfileComplete {
                NavigationView {
                    GeometryReader { geometry in
                        let isSmallScreen = geometry.size.height < 700

                        ScrollView {
                            VStack(spacing: 0) {
                                headerView
                                welcomeSection
                                cardsGrid
                            }
                            .padding(.top, isSmallScreen ? 10 : 0)
                            .padding(.bottom, 62)
                        }
                    }
                    .background(AppTheme.backgroundColor)
                    .ignoresSafeArea(edges: .bottom)
                    .navigationBarHidden(true)
                    .onAppear {
                        viewModel.checkFirstLaunch()

                        if viewModel.showTutorial {
                            // Show tutorial immediately without homeview animations
                            showTutorial = true
                        } else {
                            // Stagger the fade-in animations only if not showing tutorial
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showWelcome = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                withAnimation(.easeInOut(duration: 1.0)) {
                                    showContent = true
                                }
                            }

                            if !dataManager.isDailyCardRevealed {
                                viewModel.startHomeAnimations()
                            }
                        }
                    }
                    .sheet(isPresented: $showingSettings) {
                        SettingsMenuView()
                    }
                    .fullScreenCover(isPresented: $showTutorial) {
                        OnboardingTutorialViewWrapper(
                            isPresented: $showTutorial,
                            birthCard: viewModel.userBirthCard,
                            solarCard: viewModel.userYearlyCard,
                            fiftytwoCard: viewModel.user52DayCard,
                            dailyCard: viewModel.userDailyCard,
                            userName: dataManager.userProfile.name,
                            onComplete: {
                                viewModel.completeTutorial()
                            }
                        )
                    }
                    .onChange(of: showTutorial) { oldValue, newValue in
                        if !newValue {
                            // Tutorial was dismissed, show home content
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showWelcome = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                withAnimation(.easeInOut(duration: 1.0)) {
                                    showContent = true
                                }
                            }
                        }
                    }
                }
                .navigationViewStyle(.stack)
            } else {
                ProfileSetupBlockingView()
            }
        }
        .errorFallback(message: viewModel.errorMessage)
    }
    
    private var headerView: some View {
        VStack(spacing: 0) {
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
    }
    
    private var welcomeSection: some View {
        VStack(spacing: 0) {
            Text("\(AppConstants.Strings.welcome), \(dataManager.userProfile.name.isEmpty ? "Guest" : dataManager.userProfile.name)")
                .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.extraLarge + 2))
                .foregroundColor(AppTheme.primaryText)
                .padding(.bottom, AppConstants.Spacing.tight)
                .opacity(showWelcome ? 1 : 0)

            LineBreak(width: 320)
                .padding(.vertical, AppConstants.Spacing.ornament)
                .opacity(showContent ? 1 : 0)
        }
    }
    
    private var cardsGrid: some View {
        let isSmallScreen = UIScreen.main.bounds.height < 700

        return VStack(spacing: 0) {
            HStack {
                Spacer()
                SectionHeader(AppConstants.Strings.yourDailyCard, fontSize: AppConstants.FontSizes.title)
                Spacer()
            }
            .padding(.bottom, AppConstants.Spacing.tight)

            VStack(spacing: 0) {
                let showTapText = !dataManager.isDailyCardRevealed && viewModel.showTapToReveal

                Spacer(minLength: isSmallScreen ? 2 : 4)

                DailyCardLarge(dailyCard: viewModel.userDailyCard)

                if showTapText {
                    Spacer(minLength: isSmallScreen ? 8 : AppConstants.Spacing.ornament)

                    Text(AppConstants.Strings.tapToReveal)
                        .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.headline + 2))
                        .foregroundColor(AppTheme.primaryText)
                        .multilineTextAlignment(.center)
                        .scaleEffect(viewModel.pulseScale)
                } else {
                    Spacer(minLength: isSmallScreen ? 2 : 4)
                }

                LineBreak("linedesignd", width: 320)
                    .padding(.vertical, AppConstants.Spacing.ornament)
            }

            HStack(spacing: AppConstants.Spacing.ornament) {
                ActualCardTileSmall(
                    card: viewModel.userBirthCard,
                    title: AppConstants.Strings.birthCard,
                    destination: LifeSpreadView()
                )

                ActualCardTileSmall(
                    card: viewModel.userYearlyCard,
                    title: AppConstants.Strings.yearlyCard,
                    destination: YearlySpreadView()
                )

                ActualCardTileSmall(
                    card: viewModel.user52DayCard,
                    title: AppConstants.Strings.fiftyTwoDayCycle,
                    destination: FiftyTwoDayCycleView()
                )
            }
            .padding(.horizontal, AppConstants.Spacing.pageInset)
            .padding(.top, isSmallScreen ? AppConstants.Spacing.tight : AppConstants.Spacing.ornament)
        }
        .opacity(showContent ? 1 : 0)
    }
}

struct ProfileSetupBlockingView: View {
    @ObservedObject private var dataManager: DataManager = DataManager.shared
    @ObservedObject private var authManager: AuthenticationManager = AuthenticationManager.shared
    @State private var showingProfileSheet = false
    @State private var showingGuestBirthdaySheet = false

    // Animation states
    @State private var showSubtitle = false
    @State private var showContent = false
    
    var body: some View {
        GeometryReader { geometry in
            let isIPad = geometry.size.width > 500

            ZStack {
                AppTheme.backgroundColor
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    if isIPad {
                        Spacer()
                    } else {
                        Spacer()
                            .frame(height: 68)
                    }

                    titleSection(for: geometry.size)

                    // Subtitle
                    Text("Cardology for Self-Discovery")
                        .padding(.top, AppConstants.Spacing.ornament)
                        .font(.custom("Iowan Old Style", size: dynamicFontSize(for: geometry.size, base: 20)))
                        .foregroundColor(AppTheme.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(showSubtitle ? 1 : 0)
                        .animation(.easeInOut(duration: 1.0).delay(0.5), value: showSubtitle)
                        .padding(.bottom, AppConstants.Spacing.section)

                    if !authManager.isSignedIn {
                        VStack(spacing: AppConstants.Spacing.ornament) {
                            // 1. Top linedesign above button
                            if let lineImage = UIImage(named: "linedesign") {
                                Image(uiImage: lineImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 260, height: 26)
                                    .opacity(showContent ? 1 : 0)
                                    .animation(.easeInOut(duration: 1.0).delay(0.8), value: showContent)
                            }

                            // 2. Sign in with Apple button
                            SignInWithAppleButton(
                                .signIn,
                                onRequest: { request in
                                    request.requestedScopes = [.email, .fullName]
                                },
                                onCompletion: { result in
                                    authManager.handleAuthorization(result)
                                }
                            )
                            .signInWithAppleButtonStyle(.black)
                            .frame(height: 45)
                            .frame(width: min(geometry.size.width * 0.63, 270))
                            .cornerRadius(AppConstants.CornerRadius.button)
                            .overlay(
                                AnimatedGoldBorder(cornerRadius: AppConstants.CornerRadius.button)
                            )
                            .opacity(showContent ? 1 : 0)
                            .animation(.easeInOut(duration: 1.0).delay(0.9), value: showContent)

                            // 3. Supporting text below button
                            Text("Sign in with Apple to access all features.")
                                .font(.custom("Iowan Old Style", size: dynamicFontSize(for: geometry.size, base: 16)))
                                .foregroundColor(AppTheme.primaryText)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, AppConstants.Spacing.page)
                                .opacity(showContent ? 1 : 0)
                                .animation(.easeInOut(duration: 1.0).delay(1.0), value: showContent)

                            // 4. Privacy section
                            VStack(alignment: .center, spacing: 4) {
                                Text("We do not collect your data.")
                                    .font(.custom("Iowan Old Style", size: dynamicFontSize(for: geometry.size, base: 14)))
                                    .foregroundColor(AppTheme.primaryText)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)

                                Button(action: {
                                    if let url = URL(string: "https://www.wearemagic.life/privacy-policy") {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    Text("View Privacy Policy")
                                        .font(.custom("Iowan Old Style", size: dynamicFontSize(for: geometry.size, base: 14)))
                                        .underline()
                                        .foregroundColor(AppTheme.primaryText)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .accessibilityLabel("View Privacy Policy")
                                .accessibilityHint("Opens privacy policy in browser")
                            }
                            .padding(.horizontal, AppConstants.Spacing.page)
                            .opacity(showContent ? 1 : 0)
                            .animation(.easeInOut(duration: 1.0).delay(1.1), value: showContent)

                            // 5. Bottom linedesignd divider
                            if let lineImage = UIImage(named: "linedesignd") {
                                Image(uiImage: lineImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 260, height: 26)
                                    .opacity(showContent ? 1 : 0)
                                    .animation(.easeInOut(duration: 1.0).delay(1.2), value: showContent)
                                    .accessibilityHidden(true)
                            }

                            // 6. Guest option with disclaimer
                            VStack(spacing: 6) {
                                Button(action: {
                                    showingGuestBirthdaySheet = true
                                }) {
                                    Text("Continue as a Guest")
                                        .font(.custom("Iowan Old Style", size: dynamicFontSize(for: geometry.size, base: 19)))
                                        .underline()
                                        .foregroundColor(AppTheme.primaryText)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .frame(minHeight: AppConstants.Accessibility.minimumTouchTarget)
                                        .contentShape(Rectangle())
                                }
                                .accessibilityLabel("Continue as a Guest")
                                .accessibilityHint("Use app without signing in, some features limited")

                                Text("Guest accounts require re-entering your birth date each session. Some features may be limited.")
                                    .font(.custom("Iowan Old Style", size: dynamicFontSize(for: geometry.size, base: 13)))
                                    .foregroundColor(AppTheme.primaryText)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.horizontal, AppConstants.Spacing.page)
                            }
                            .opacity(showContent ? 1 : 0)
                            .animation(.easeInOut(duration: 1.0).delay(1.3), value: showContent)
                        }
                    } else {
                        // When signed in, keep title/subtitle visible while sheet opens
                        Spacer()
                            .frame(height: 290)
                    }

                    Spacer()
                }
                .padding(.horizontal, AppConstants.Spacing.pageInset)
            }
            .sheet(isPresented: $showingProfileSheet) {
                ProfileSheet()
            }
            .sheet(isPresented: $showingGuestBirthdaySheet) {
                GuestBirthdaySheet()
            }
            .onChange(of: authManager.isSignedIn, initial: false) { oldValue, newValue in
                if newValue && !dataManager.isProfileComplete {
                    showingProfileSheet = true
                }
            }
            .onChange(of: dataManager.isProfileComplete, initial: false) { oldValue, newValue in
                if newValue {
                    showingProfileSheet = false
                }
            }
            .onAppear {
                // Start animations
                showSubtitle = true
                showContent = true

                // Auto-open the profile sheet when signed in but profile is incomplete
                if authManager.isSignedIn && !dataManager.isProfileComplete {
                    // Use a minimal delay to ensure the view hierarchy is ready
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showingProfileSheet = true
                    }
                }
            }
        }
    }
    
    private func titleSection(for size: CGSize) -> some View {
        let isIPad = size.width > 500
        let titleWidth = isIPad ? min(size.width * 0.5, 400) : min(size.width * 0.85, 340)

        return Group {
            if let titleImage = UIImage(named: "apptitle") {
                Image(uiImage: titleImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: titleWidth)
                    .accessibilityLabel("Cards of The Seven Sisters")
                    .accessibilityAddTraits(.isImage)
            } else {
                VStack(spacing: 4) {
                    Text("CARDS OF THE")
                        .font(.custom("Iowan Old Style", size: dynamicFontSize(for: size, base: 36)))
                        .foregroundColor(AppTheme.primaryText)
                        .tracking(3)
                        .multilineTextAlignment(.center)

                    Text("SEVEN SISTERS")
                        .font(.custom("Iowan Old Style", size: dynamicFontSize(for: size, base: 36)))
                        .foregroundColor(AppTheme.primaryText)
                        .tracking(3)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func dynamicFontSize(for size: CGSize, base: CGFloat) -> CGFloat {
        let scaleFactor = min(size.width / 390, 1.2)
        return base * scaleFactor
    }
}

struct DailyCardLarge: View {
    let dailyCard: Card
    @ObservedObject private var dataManager: DataManager = DataManager.shared
    @Environment(\.colorScheme) private var colorScheme

    // Smaller card size for SE and other small screens
    private var cardSize: CGSize {
        let screenHeight = UIScreen.main.bounds.height
        if screenHeight < 700 {
            // iPhone SE - use smaller size
            return CGSize(width: 160, height: 224)
        }
        return AppConstants.CardSizes.extraLarge
    }

    var body: some View {
        NavigationLink(destination: DailyCardView()) {
            Group {
                if dataManager.isDailyCardRevealed {
                    let cardImageName = dailyCard.imageName

                    if let cardImage = ImageManager.shared.loadCardImage(named: cardImageName) {
                        Image(uiImage: cardImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: cardSize.width, height: cardSize.height)
                            .scaleEffect(colorScheme == .dark ? 0.95 : 1.0)
                            .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.cardLarge))
                            .darkModeCardEffects(isLarge: true)
                            .accessibilityLabel("\(dailyCard.value) of \(dailyCard.suit.rawValue), your daily card")
                            .accessibilityAddTraits(.isImage)
                    } else {
                        RoundedRectangle(cornerRadius: AppConstants.CornerRadius.cardLarge)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: cardSize.width, height: cardSize.height)
                            .overlay(
                                Text("Card Image\nNot Found")
                                    .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.caption + 2))
                                    .foregroundColor(AppTheme.primaryText)
                                    .multilineTextAlignment(.center)
                            )
                            .darkModeCardEffects(isLarge: true)
                    }
                } else {
                    if let cardBackImage = UIImage(named: "cardback") {
                        Image(uiImage: cardBackImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: cardSize.width, height: cardSize.height)
                            .scaleEffect(colorScheme == .dark ? 0.95 : 1.0)
                            .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.cardLarge))
                            .darkModeCardEffects(isLarge: true)
                            .accessibilityLabel("Daily card, Tap Card to Reveal")
                            .accessibilityAddTraits(.isImage)
                            .accessibilityAddTraits(.isButton)
                    } else {
                        RoundedRectangle(cornerRadius: AppConstants.CornerRadius.cardLarge)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: cardSize.width, height: cardSize.height)
                            .overlay(
                                Text("Card Back\nNot Found")
                                    .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.caption + 2))
                                    .foregroundColor(AppTheme.primaryText)
                                    .multilineTextAlignment(.center)
                            )
                            .darkModeCardEffects(isLarge: true)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ActualCardTileSmall<Destination: View>: View {
    let card: Card
    let title: String
    let destination: Destination

    @Environment(\.colorScheme) private var colorScheme

    // Smaller size for SE screens
    private var cardSize: CGSize {
        let screenHeight = UIScreen.main.bounds.height
        if screenHeight < 700 {
            return CGSize(width: 75, height: 105)
        }
        return AppConstants.CardSizes.small
    }

    var body: some View {
        NavigationLink(destination: destination) {
            VStack(spacing: AppConstants.Spacing.small) {
                if let cardImage = ImageManager.shared.loadCardImage(for: card) {
                    Image(uiImage: cardImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: cardSize.width, height: cardSize.height)
                        .scaleEffect(colorScheme == .dark ? 0.95 : 1.0)
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card))
                        .darkModeCardEffects(isLarge: false)
                        .accessibilityLabel("\(card.value) of \(card.suit.rawValue), \(title)")
                        .accessibilityAddTraits(.isImage)
                } else {
                    RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: cardSize.width, height: cardSize.height)
                        .darkModeCardEffects(isLarge: false)
                        .overlay(
                            VStack {
                                Text(AppConstants.Strings.missingImage)
                                    .font(.custom("Iowan Old Style", size: 8))
                                    .foregroundColor(AppTheme.primaryText)
                                Text(card.name)
                                    .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.caption))
                                    .foregroundColor(AppTheme.primaryText)
                            }
                        )
                }

                Text(title)
                    .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.body))
                    .foregroundColor(AppTheme.primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Guest Birthday Sheet
struct GuestBirthdaySheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var dataManager = DataManager.shared
    @State private var birthDate = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
    @State private var dateText = ""
    @FocusState private var isTextFieldFocused: Bool

    private let fieldBackgroundColor = Color(red: 0.92, green: 0.87, blue: 0.78) // Soft tan

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("MMddyyyy")
        return formatter
    }

    private var formattedDate: String {
        return dateFormatter.string(from: birthDate)
    }

    private var localizedPlaceholder: String {
        // Create a sample date to show format pattern
        let sampleFormatter = DateFormatter()
        sampleFormatter.locale = Locale.current
        sampleFormatter.setLocalizedDateFormatFromTemplate("MMddyyyy")
        // Get the format pattern and convert to placeholder
        let pattern = sampleFormatter.dateFormat ?? "MM/dd/yyyy"
        return pattern
            .replacingOccurrences(of: "MM", with: "MM")
            .replacingOccurrences(of: "dd", with: "DD")
            .replacingOccurrences(of: "yyyy", with: "YYYY")
            .replacingOccurrences(of: "M", with: "M")
            .replacingOccurrences(of: "d", with: "D")
    }

    private func parseDate(_ text: String) -> Date? {
        return dateFormatter.date(from: text)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundColor
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppConstants.Spacing.ornament) {
                        Text("Enter Your Birthdate")
                            .font(.custom("Iowan Old Style", size: 22))
                            .foregroundColor(AppTheme.primaryText)

                        Text("Your birthday is used to calculate your personalized card readings.")
                            .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.body))
                            .foregroundColor(AppTheme.secondaryText)
                            .multilineTextAlignment(.center)

                        TextField(localizedPlaceholder, text: $dateText)
                            .font(.custom("Iowan Old Style", size: 20))
                            .foregroundColor(AppTheme.primaryText)
                            .multilineTextAlignment(.center)
                            .keyboardType(.numbersAndPunctuation)
                            .focused($isTextFieldFocused)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(fieldBackgroundColor)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
                            )
                            .padding(.horizontal, AppConstants.Spacing.section)
                            .onChange(of: dateText) { _, newValue in
                                if let date = parseDate(newValue) {
                                    birthDate = date
                                }
                            }
                            .onAppear {
                                dateText = formattedDate
                            }

                        DatePicker("", selection: $birthDate, displayedComponents: .date)
                            .datePickerStyle(WheelDatePickerStyle())
                            .labelsHidden()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(fieldBackgroundColor)
                            )
                            .onChange(of: birthDate) { _, _ in
                                if !isTextFieldFocused {
                                    dateText = formattedDate
                                }
                            }

                        Button(action: {
                            dataManager.signInAsGuest(birthDate: birthDate)
                            dismiss()
                        }) {
                            Text("Continue")
                                .font(.custom("Iowan Old Style", size: 19))
                                .tracking(0.5)
                                .foregroundColor(Color(UIColor { traitCollection in
                                    traitCollection.userInterfaceStyle == .dark
                                        ? UIColor.black
                                        : UIColor.white
                                }))
                                .padding(.horizontal, 50)
                                .padding(.vertical, 18)
                                .background(AppTheme.darkAccent)
                                .cornerRadius(30)
                                .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 2)
                        }
                        .accessibilityLabel("Continue")
                        .accessibilityHint("Save birth date and continue as guest")
                    }
                    .padding(.top, AppConstants.Spacing.pageInset)
                    .padding(.bottom, AppConstants.Spacing.section)
                    .padding(.horizontal, AppConstants.Spacing.pageInset)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        if UIScreen.main.bounds.height < 700 {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppTheme.primaryText)
                                .frame(width: 28, height: 28)
                                .background(AppConstants.Colors.capsuleButton)
                                .clipShape(Circle())
                                .contentShape(Circle())
                        } else {
                            Image(systemName: "xmark")
                                .font(.system(size: 20))
                                .foregroundColor(AppTheme.primaryText)
                                .frame(width: AppConstants.ButtonSizes.closeButton, height: AppConstants.ButtonSizes.closeButton)
                                .contentShape(Rectangle())
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close")
                    .accessibilityHint("Returns to home screen")
                }
            }
        }
    }
}

#Preview {
    HomeView()
}

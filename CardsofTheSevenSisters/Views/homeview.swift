import SwiftUI
import AuthenticationServices

struct HomeView: View {
    @StateObject private var dataManager: DataManager = DataManager.shared
    @StateObject private var viewModel = HomeViewModel()

    @State private var showingSettings = false
    
    @State private var showTutorial = false
    @State private var showWelcome = false
    @State private var showContent = false
    
    var body: some View {
        Group {
            if dataManager.isProfileComplete {
                NavigationView {
                    ScrollView {
                        VStack(spacing: 0) {
                            headerView
                            welcomeSection
                            cardsGrid
                        }
                        .padding(.bottom, AppConstants.Spacing.sectionSpacing)
                    }
                    .background(Color(red: 0.91, green: 0.82, blue: 0.63))
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
                        OnboardingTutorialView(
                            isPresented: $showTutorial,
                            birthCard: viewModel.userBirthCard,
                            solarCard: viewModel.userYearlyCard,
                            astralCard: viewModel.user52DayCard,
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
                        .foregroundColor(.black)
                }
                .accessibilityLabel("Settings")
                .accessibilityHint("Opens settings menu")
            }
            .padding(.horizontal, AppConstants.Spacing.medium)
            .padding(.vertical, AppConstants.Spacing.medium)
        }
    }
    
    private var welcomeSection: some View {
        VStack(spacing: 0) {
            Text("\(AppConstants.Strings.welcome), \(dataManager.userProfile.name.isEmpty ? "Guest" : dataManager.userProfile.name)")
                .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.extraLarge + 2))
                .foregroundColor(.black)
                .padding(.bottom, AppConstants.Spacing.medium)
                .opacity(showWelcome ? 1 : 0)

            LineBreak(height: 22)
                .frame(width: 280)
                .padding(.top, AppConstants.Spacing.small)
                .padding(.bottom, AppConstants.Spacing.small)
                .opacity(showContent ? 1 : 0)
        }
    }
    
    private var cardsGrid: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                SectionHeader(AppConstants.Strings.yourDailyCard, fontSize: AppConstants.FontSizes.title)
                Spacer()
            }
            .padding(.bottom, AppConstants.Spacing.small)

            VStack(spacing: 0) {
                Spacer(minLength: AppConstants.Spacing.small)

                DailyCardLarge(dailyCard: viewModel.userDailyCard)

                Spacer(minLength: AppConstants.Spacing.small)

                Text(dataManager.isDailyCardRevealed ? "Tap to View" : AppConstants.Strings.tapToReveal)
                    .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.headline + 2))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, AppConstants.Spacing.titleSpacing)
                    .scaleEffect(dataManager.isDailyCardRevealed ? 1.0 : viewModel.pulseScale)
                    .opacity(viewModel.showTapToReveal ? 1 : 0)

                LineBreak("linedesignd", height: 22)
                    .frame(width: AppConstants.Scaling.w(280))
                    .padding(.bottom, AppConstants.Spacing.sectionSpacing)
            }

            HStack(spacing: AppConstants.Spacing.small) {
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
            .padding(.horizontal, AppConstants.Spacing.medium)
            .padding(.bottom, AppConstants.Scaling.h(62))
        }
        .opacity(showContent ? 1 : 0)
    }
}

struct ProfileSetupBlockingView: View {
    @StateObject private var dataManager: DataManager = DataManager.shared
    @StateObject private var authManager: AuthenticationManager = AuthenticationManager.shared
    @State private var showingProfileSheet = false
    
    // Animation states
    @State private var showSubtitle = false
    @State private var showContent = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                AppTheme.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 68)

                    // Logo
                    titleSection(for: geometry.size)
                        .padding(.bottom, 21)

                    // Subtitle
                    Text("Cardology for Self-Discovery")
                        .font(.custom("Iowan Old Style", size: dynamicFontSize(for: geometry.size, base: 20)))
                        .foregroundColor(AppTheme.primaryText)
                        .opacity(showSubtitle ? 1 : 0)
                        .animation(.easeInOut(duration: 1.0).delay(0.5), value: showSubtitle)
                        .padding(.bottom, 42)

                    if !authManager.isSignedIn {
                        VStack(spacing: 20) {
                            // Top line design
                            if let lineImage = UIImage(named: "linedesign") {
                                Image(uiImage: lineImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 160, height: 22)
                                    .opacity(showContent ? 1 : 0)
                                    .animation(.easeInOut(duration: 1.0).delay(1.0), value: showContent)
                            }

                            // Main message
                            Text("Sign in to start your  journey")
                                .font(.custom("Iowan Old Style", size: dynamicFontSize(for: geometry.size, base: 18)))
                                .foregroundColor(AppTheme.primaryText)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, 40)
                                .opacity(showContent ? 1 : 0)
                                .animation(.easeInOut(duration: 1.0).delay(1.0), value:showContent)

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
                            .frame(height: 50)
                            .frame(width: min(geometry.size.width * 0.7, 280))
                            .cornerRadius(AppConstants.CornerRadius.button)
                            .opacity(showContent ? 1 : 0)
                            .animation(.easeInOut(duration: 1.0).delay(1.5), value: showContent)

                            // Bottom line design
                            if let lineImageD = UIImage(named: "linedesignd") {
                                Image(uiImage: lineImageD)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 160, height: 22)
                                    .opacity(showContent ? 1 : 0)
                                    .animation(.easeInOut(duration: 1.0).delay(1.5), value: showContent)
                            }
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            .sheet(isPresented: $showingProfileSheet) {
                ProfileSheet()
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
        let titleWidth = min(size.width * 0.85, 340)
        
        return Group {
            if let titleImage = UIImage(named: "apptitle") {
                Image(uiImage: titleImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: titleWidth)
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
    @StateObject private var dataManager: DataManager = DataManager.shared

    var body: some View {
        NavigationLink(destination: DailyCardView()) {
            Group {
                if dataManager.isDailyCardRevealed {
                    let cardImageName = dailyCard.imageName

                    if let cardImage = ImageManager.shared.loadCardImage(named: cardImageName) {
                        Image(uiImage: cardImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: AppConstants.CardSizes.extraLarge.width, height: AppConstants.CardSizes.extraLarge.height)
                            .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.cardLarge))
                            .cardShadow(isLarge: true)
                    } else {
                        RoundedRectangle(cornerRadius: AppConstants.CornerRadius.cardLarge)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: AppConstants.CardSizes.extraLarge.width, height: AppConstants.CardSizes.extraLarge.height)
                            .overlay(
                                Text("Card Image\nNot Found")
                                    .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.caption + 2))
                                    .foregroundColor(.black)
                                    .multilineTextAlignment(.center)
                            )
                            .cardShadow(isLarge: true)
                    }
                } else {
                    if let cardBackImage = UIImage(named: "cardback") {
                        Image(uiImage: cardBackImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: AppConstants.CardSizes.extraLarge.width, height: AppConstants.CardSizes.extraLarge.height)
                            .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.cardLarge))
                            .cardShadow(isLarge: true)
                    } else {
                        RoundedRectangle(cornerRadius: AppConstants.CornerRadius.cardLarge)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: AppConstants.CardSizes.extraLarge.width, height: AppConstants.CardSizes.extraLarge.height)
                            .overlay(
                                Text("Card Back\nNot Found")
                                    .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.caption + 2))
                                    .foregroundColor(.black)
                                    .multilineTextAlignment(.center)
                            )
                            .cardShadow(isLarge: true)
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

    var body: some View {
        NavigationLink(destination: destination) {
            VStack(spacing: AppConstants.Spacing.small) {
                if let cardImage = ImageManager.shared.loadCardImage(for: card) {
                    Image(uiImage: cardImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: AppConstants.CardSizes.small.width, height: AppConstants.CardSizes.small.height)
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card))
                        .cardShadow(isLarge: true)
                } else {
                    RoundedRectangle(cornerRadius: AppConstants.CornerRadius.card)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: AppConstants.CardSizes.small.width, height: AppConstants.CardSizes.small.height)
                        .cardShadow(isLarge: true)
                        .overlay(
                            VStack {
                                Text(AppConstants.Strings.missingImage)
                                    .font(.custom("Iowan Old Style", size: 8))
                                    .foregroundColor(.black)
                                Text(card.name)
                                    .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.caption))
                                    .foregroundColor(.black)
                            }
                        )
                }

                Text(title)
                    .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.body))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    HomeView()
}

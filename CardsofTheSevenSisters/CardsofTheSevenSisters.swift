import SwiftUI

@main
struct CardsOfTheSevenSisters: App {
    @State private var showSplash = true
    @ObservedObject private var appSettings = AppSettings.shared

    init() {
        setupGlobalAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                AppTheme.backgroundColor
                    .ignoresSafeArea(.all)

                if showSplash {
                    VintageSplashView(onStart: {
                        // Initialize managers right before transitioning to home
                        _ = AuthenticationManager.shared
                        _ = DataManager.shared
                        showSplash = false
                    })
                    .zIndex(1)
                } else {
                    HomeView()
                        .zIndex(0)
                        .environmentObject(AuthenticationManager.shared)
                        .environmentObject(DataManager.shared)
                        .environmentObject(SubscriptionManager.shared)
                }
            }
            .preferredColorScheme(appSettings.colorScheme)
            .onAppear {
                // Defer non-critical work
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    RatingService.shared.trackAppOpen()

                    if NotificationManager.shared.notificationsEnabled {
                        NotificationManager.shared.scheduleDailyNotification()
                    }
                }
            }
        }
    }
    
    private func setupGlobalAppearance() {
        // Adaptive background color
        let adaptiveBackground = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)  // true black
                : UIColor(red: 0.86, green: 0.75, blue: 0.55, alpha: 1.0)  // tan
        }

        // Adaptive text color
        let adaptiveText = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.95, green: 0.91, blue: 0.82, alpha: 1.0)  // cream
                : UIColor.black
        }

        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = adaptiveBackground
        navBarAppearance.titleTextAttributes = [
            .foregroundColor: adaptiveText,
            .font: UIFont(name: "Iowan Old Style", size: 24) ?? UIFont.systemFont(ofSize: 24)
        ]
        navBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: adaptiveText,
            .font: UIFont(name: "Iowan Old Style", size: 24) ?? UIFont.systemFont(ofSize: 24)
        ]

        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().prefersLargeTitles = false

        UIView.appearance().tintColor = adaptiveText

        UITabBar.appearance().backgroundColor = adaptiveBackground
        UITabBar.appearance().barTintColor = adaptiveBackground

        UITableView.appearance().backgroundColor = adaptiveBackground
        UITableViewCell.appearance().backgroundColor = adaptiveBackground

        UIScrollView.appearance().backgroundColor = adaptiveBackground
    }
}


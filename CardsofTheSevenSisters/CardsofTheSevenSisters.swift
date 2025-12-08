import SwiftUI

@main
struct CardsOfTheSevenSisters: App {
    @State private var showSplash = true

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
                    .preferredColorScheme(.light)
                    .zIndex(1)
                } else {
                    HomeView()
                        .preferredColorScheme(.light)
                        .zIndex(0)
                        .environmentObject(AuthenticationManager.shared)
                        .environmentObject(DataManager.shared)
                }
            }
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
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor(red: 0.86, green: 0.75, blue: 0.55, alpha: 1.0)
        navBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.black,
            .font: UIFont(name: "Iowan Old Style", size: 24) ?? UIFont.systemFont(ofSize: 24)
        ]
        navBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.black,
            .font: UIFont(name: "Iowan Old Style", size: 24) ?? UIFont.systemFont(ofSize: 24)
        ]
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().prefersLargeTitles = false
        
        UIView.appearance().tintColor = UIColor.black
        
        UITabBar.appearance().backgroundColor = UIColor(red: 0.86, green: 0.75, blue: 0.55, alpha: 1.0)
        UITabBar.appearance().barTintColor = UIColor(red: 0.86, green: 0.75, blue: 0.55, alpha: 1.0)
        
        UITableView.appearance().backgroundColor = UIColor(red: 0.86, green: 0.75, blue: 0.55, alpha: 1.0)
        UITableViewCell.appearance().backgroundColor = UIColor(red: 0.86, green: 0.75, blue: 0.55, alpha: 1.0)
        
        UIScrollView.appearance().backgroundColor = UIColor(red: 0.86, green: 0.75, blue: 0.55, alpha: 1.0)
    }
}


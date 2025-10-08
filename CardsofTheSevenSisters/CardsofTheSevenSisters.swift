import SwiftUI

@main
struct CardsOfTheSevenSisters: App {
    @State private var showSplash = true
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var notificationManager = NotificationManager.shared

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
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showSplash = false
                        }
                    })
                    .preferredColorScheme(.light)
                    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
                    .zIndex(1)
                } else {
                    HomeView()
                        .preferredColorScheme(.light)
                        .transition(.opacity.animation(.easeInOut(duration: 0.3)))
                        .zIndex(0)
                        .environmentObject(authManager)
                        .environmentObject(dataManager)
                }
            }
            .onAppear {
                // Optional: Verify Apple ID credentials are still valid
                // The authentication state is already restored automatically on init
                authManager.checkAuthenticationState()

                // Reschedule notifications if enabled
                if notificationManager.notificationsEnabled {
                    notificationManager.scheduleDailyNotification()
                }
            }
        }
    }
    
    private func setupGlobalAppearance() {
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor(red: 0.86, green: 0.77, blue: 0.57, alpha: 1.0)
        navBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.black,
            .font: UIFont(name: "Iowan Old Style", size: 20) ?? UIFont.systemFont(ofSize: 20)
        ]
        navBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.black,
            .font: UIFont(name: "Iowan Old Style", size: 34) ?? UIFont.systemFont(ofSize: 34)
        ]
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        
        UIView.appearance().tintColor = UIColor.black
        
        UITabBar.appearance().backgroundColor = UIColor(red: 0.86, green: 0.77, blue: 0.57, alpha: 1.0)
        UITabBar.appearance().barTintColor = UIColor(red: 0.86, green: 0.77, blue: 0.57, alpha: 1.0)
        
        UITableView.appearance().backgroundColor = UIColor(red: 0.86, green: 0.77, blue: 0.57, alpha: 1.0)
        UITableViewCell.appearance().backgroundColor = UIColor(red: 0.86, green: 0.77, blue: 0.57, alpha: 1.0)
        
        UIScrollView.appearance().backgroundColor = UIColor(red: 0.86, green: 0.77, blue: 0.57, alpha: 1.0)
    }
}

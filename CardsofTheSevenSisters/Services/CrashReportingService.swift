import Foundation

/// Crash reporting service - crashes are reported via App Store Connect
class CrashReportingService {
    static let shared = CrashReportingService()

    private init() {}

    func configure() {}
    func logError(_ error: Error, context: String? = nil) {}
    func log(_ message: String) {}
    func setUserID(_ userID: String) {}
    func setCustomValue(_ value: Any, forKey key: String) {}
    func logEvent(_ event: AppEvent) {}
}

extension CrashReportingService {
    enum AppEvent: String {
        case appLaunched = "app_launched"
        case onboardingCompleted = "onboarding_completed"
        case birthCardCalculated = "birth_card_calculated"
        case dailyCardViewed = "daily_card_viewed"
        case profileCreated = "profile_created"
        case notificationsEnabled = "notifications_enabled"
        case cardShared = "card_shared"
    }
}

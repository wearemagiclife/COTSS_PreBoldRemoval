import StoreKit
import SwiftUI

/// Service to handle App Store rating requests at optimal moments
class RatingService: ObservableObject {
    static let shared = RatingService()

    /// Set to true to present the custom rating prompt. HomeView observes this.
    @Published var shouldShowRatingPrompt = false

    private let defaults = UserDefaults.standard

    // Keys for tracking
    private let lastRatingRequestVersionKey = "lastRatingRequestVersion"
    private let appOpenCountKey = "appOpenCount"
    private let birthCardViewCountKey = "birthCardViewCount"
    private let dailyCardRevealCountKey = "dailyCardRevealCount"
    private let consecutiveDaysKey = "consecutiveDaysOpened"
    private let lastOpenDateKey = "lastAppOpenDate"
    private let firstOpenDateKey = "firstAppOpenDate"

    // Thresholds for requesting rating
    private let minimumAppOpens = 15
    private let minimumBirthCardViews = 8
    private let minimumDailyReveals = 10
    private let minimumConsecutiveDays = 5
    // Minimum number of days since first launch before ever showing the prompt
    private let minimumDaysSinceInstall = 7

    private init() {}

    // MARK: - Event Tracking

    /// Call this when app launches
    func trackAppOpen() {
        let count = defaults.integer(forKey: appOpenCountKey) + 1
        defaults.set(count, forKey: appOpenCountKey)

        // Record first open date if not already set
        if defaults.object(forKey: firstOpenDateKey) == nil {
            defaults.set(Date(), forKey: firstOpenDateKey)
        }

        updateConsecutiveDays()
    }

    /// Call when user views their birth card
    func trackBirthCardView() {
        let count = defaults.integer(forKey: birthCardViewCountKey) + 1
        defaults.set(count, forKey: birthCardViewCountKey)
        if count >= minimumBirthCardViews {
            considerRequestingRating()
        }
    }

    /// Call when user reveals daily card
    func trackDailyCardReveal() {
        let count = defaults.integer(forKey: dailyCardRevealCountKey) + 1
        defaults.set(count, forKey: dailyCardRevealCountKey)
        if count >= minimumDailyReveals {
            considerRequestingRating()
        }
    }

    /// Call when user completes onboarding
    func trackOnboardingComplete() {
        // Don't ask immediately after onboarding - too early
    }

    // MARK: - Consecutive Days Tracking

    private func updateConsecutiveDays() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastOpenData = defaults.object(forKey: lastOpenDateKey) as? Date {
            let lastOpen = calendar.startOfDay(for: lastOpenData)
            let daysDiff = calendar.dateComponents([.day], from: lastOpen, to: today).day ?? 0

            if daysDiff == 1 {
                // Consecutive day
                let streak = defaults.integer(forKey: consecutiveDaysKey) + 1
                defaults.set(streak, forKey: consecutiveDaysKey)

                // Good moment at 3+ day streak
                if streak >= minimumConsecutiveDays {
                    considerRequestingRating()
                }
            } else if daysDiff > 1 {
                // Streak broken
                defaults.set(1, forKey: consecutiveDaysKey)
            }
            // Same day - no change
        } else {
            // First open
            defaults.set(1, forKey: consecutiveDaysKey)
        }

        defaults.set(today, forKey: lastOpenDateKey)
    }

    // MARK: - Rating Request Logic

    private func considerRequestingRating() {
        // Don't ask if we already asked for this version
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let lastRequestedVersion = defaults.string(forKey: lastRatingRequestVersionKey) ?? ""

        if currentVersion == lastRequestedVersion {
            return
        }

        // Check minimum app opens
        let appOpens = defaults.integer(forKey: appOpenCountKey)
        if appOpens < minimumAppOpens {
            return
        }

        // Check minimum days since install
        if let firstOpen = defaults.object(forKey: firstOpenDateKey) as? Date {
            let daysSinceInstall = Calendar.current.dateComponents([.day], from: firstOpen, to: Date()).day ?? 0
            if daysSinceInstall < minimumDaysSinceInstall {
                return
            }
        } else {
            // First open date not recorded yet — too early
            return
        }

        // All conditions met - request rating
        requestRating()
    }

    private func requestRating() {
        // Mark that we requested for this version
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        defaults.set(currentVersion, forKey: lastRatingRequestVersionKey)

        // Show our custom prompt after a longer delay so it doesn't feel
        // like an interruption to whatever the user was just doing
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.shouldShowRatingPrompt = true
        }
    }

    // MARK: - Debug/Testing

    /// Reset all tracking (for testing)
    func resetTracking() {
        defaults.removeObject(forKey: lastRatingRequestVersionKey)
        defaults.removeObject(forKey: appOpenCountKey)
        defaults.removeObject(forKey: birthCardViewCountKey)
        defaults.removeObject(forKey: dailyCardRevealCountKey)
        defaults.removeObject(forKey: consecutiveDaysKey)
        defaults.removeObject(forKey: lastOpenDateKey)
        defaults.removeObject(forKey: firstOpenDateKey)
    }
}

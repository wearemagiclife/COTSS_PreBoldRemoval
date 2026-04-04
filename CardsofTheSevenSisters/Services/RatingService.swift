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

    // Thresholds for requesting rating
    private let minimumAppOpens = 5
    private let minimumBirthCardViews = 3
    private let minimumDailyReveals = 5
    private let minimumConsecutiveDays = 3

    private init() {}

    // MARK: - Event Tracking

    /// Call this when app launches
    func trackAppOpen() {
        let count = defaults.integer(forKey: appOpenCountKey) + 1
        defaults.set(count, forKey: appOpenCountKey)
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

        // All conditions met - request rating
        requestRating()
    }

    private func requestRating() {
        // Mark that we requested for this version
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        defaults.set(currentVersion, forKey: lastRatingRequestVersionKey)

        // Show our custom prompt after a brief delay so it doesn't interrupt
        // whatever interaction triggered the rating check
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
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
    }
}

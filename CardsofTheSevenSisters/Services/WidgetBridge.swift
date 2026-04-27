import Foundation

enum WidgetBridge {
    static let appGroupID = "group.com.CardsOfTheSevenSistersApp.CardsOfTheSevenSisters"

    enum Key {
        static let birthDate = "widget.birthDate"
        static let isSubscribed = "widget.isSubscribed"
        static let appearanceMode = "widget.appearanceMode"  // 0=system, 1=light, 2=dark
    }

    static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    static func writeBirthDate(_ date: Date?) {
        guard let defaults else { return }
        if let date { defaults.set(date, forKey: Key.birthDate) }
        else { defaults.removeObject(forKey: Key.birthDate) }
    }

    static func writeIsSubscribed(_ value: Bool) {
        defaults?.set(value, forKey: Key.isSubscribed)
    }

    static func readBirthDate() -> Date? {
        defaults?.object(forKey: Key.birthDate) as? Date
    }

    static func readIsSubscribed() -> Bool {
        defaults?.bool(forKey: Key.isSubscribed) ?? false
    }

    static func writeAppearanceMode(_ rawValue: Int) {
        defaults?.set(rawValue, forKey: Key.appearanceMode)
    }

    /// 0=system, 1=light, 2=dark. Defaults to 0 (system) if unset.
    static func readAppearanceMode() -> Int {
        defaults?.integer(forKey: Key.appearanceMode) ?? 0
    }
}

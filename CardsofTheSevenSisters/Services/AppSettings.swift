import SwiftUI
import WidgetKit

enum AppearanceMode: Int, CaseIterable {
    case system = 0
    case light = 1
    case dark = 2

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil  // Follow system
        case .light: return .light
        case .dark: return .dark
        }
    }
}

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private let appearanceModeKey = "appearanceMode"

    @Published var appearanceMode: AppearanceMode {
        didSet {
            UserDefaults.standard.set(appearanceMode.rawValue, forKey: appearanceModeKey)
            WidgetBridge.writeAppearanceMode(appearanceMode.rawValue)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    var colorScheme: ColorScheme? {
        appearanceMode.colorScheme
    }

    private init() {
        let savedValue = UserDefaults.standard.integer(forKey: appearanceModeKey)
        let mode = AppearanceMode(rawValue: savedValue) ?? .system
        self.appearanceMode = mode
        // Mirror current value to App Group on cold launch so the widget is
        // aligned even before any user toggle.
        WidgetBridge.writeAppearanceMode(mode.rawValue)
    }
}

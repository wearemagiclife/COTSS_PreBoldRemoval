import SwiftUI

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
        }
    }

    var colorScheme: ColorScheme? {
        appearanceMode.colorScheme
    }

    private init() {
        let savedValue = UserDefaults.standard.integer(forKey: appearanceModeKey)
        self.appearanceMode = AppearanceMode(rawValue: savedValue) ?? .system
    }
}

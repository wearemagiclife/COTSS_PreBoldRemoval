import Foundation
import Combine

class DescriptionRepository: ObservableObject {
    static let shared = DescriptionRepository()

    @Published var birthDescriptions: [String: String] = [:]
    @Published var dailyDescriptions: [String: String] = [:]
    @Published var fiftyTwoDescriptions: [String: String] = [:]
    @Published var yearlyDescriptions: [String: String] = [:]
    @Published var karmaCard1Descriptions: [String: String] = [:]
    @Published var karmaCard2Descriptions: [String: String] = [:]

    private var isLoading = false

    private init() {
        // Load all descriptions asynchronously in background
        loadAllDescriptionsAsync()
    }

    private func loadAllDescriptionsAsync() {
        guard !isLoading else { return }
        isLoading = true

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let birth = Self.loadJSON(named: "birth_descriptions")
            let daily = Self.loadJSON(named: "daily_descriptions")
            let fiftyTwo = Self.loadJSON(named: "fiftytwo_descriptions")
            let yearly = Self.loadJSON(named: "yearly_descriptions")
            let karma1 = Self.loadJSON(named: "karmacard1_descriptions")
            let karma2 = Self.loadJSON(named: "karmacard2_descriptions")

            DispatchQueue.main.async {
                self?.birthDescriptions = birth
                self?.dailyDescriptions = daily
                self?.fiftyTwoDescriptions = fiftyTwo
                self?.yearlyDescriptions = yearly
                self?.karmaCard1Descriptions = karma1
                self?.karmaCard2Descriptions = karma2
                self?.isLoading = false
            }
        }
    }

    private static func loadJSON(named filename: String) -> [String: String] {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            return [:]
        }
        do {
            let data = try Data(contentsOf: url)
            let dict = try JSONDecoder().decode([String: String].self, from: data)
            return dict
        } catch {
            return [:]
        }
    }

    // Ensure descriptions are loaded synchronously if needed
    func ensureLoaded() {
        // If descriptions are already loaded, return immediately
        guard birthDescriptions.isEmpty else { return }

        // Load synchronously on main thread
        birthDescriptions = Self.loadJSON(named: "birth_descriptions")
        dailyDescriptions = Self.loadJSON(named: "daily_descriptions")
        fiftyTwoDescriptions = Self.loadJSON(named: "fiftytwo_descriptions")
        yearlyDescriptions = Self.loadJSON(named: "yearly_descriptions")
        karmaCard1Descriptions = Self.loadJSON(named: "karmacard1_descriptions")
        karmaCard2Descriptions = Self.loadJSON(named: "karmacard2_descriptions")
    }
}

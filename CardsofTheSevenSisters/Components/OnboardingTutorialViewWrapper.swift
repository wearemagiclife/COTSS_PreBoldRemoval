import SwiftUI

/// Wrapper view that chooses between large and small screen onboarding tutorials based on screen height
struct OnboardingTutorialViewWrapper: View {
    @Binding var isPresented: Bool

    let birthCard: Card
    let solarCard: Card
    let fiftytwoCard: Card
    let dailyCard: Card
    let userName: String
    let onComplete: () -> Void

    var body: some View {
        GeometryReader { geometry in
            let screenHeight = geometry.size.height
            let isSmallScreen = screenHeight < 700  // iPhone SE: 667pt, iPhone 13 mini: 812pt

            if isSmallScreen {
                OnboardingTutorialViewSmall(
                    isPresented: $isPresented,
                    birthCard: birthCard,
                    solarCard: solarCard,
                    fiftytwoCard: fiftytwoCard,
                    dailyCard: dailyCard,
                    userName: userName,
                    onComplete: onComplete
                )
            } else {
                OnboardingTutorialView(
                    isPresented: $isPresented,
                    birthCard: birthCard,
                    solarCard: solarCard,
                    fiftytwoCard: fiftytwoCard,
                    dailyCard: dailyCard,
                    userName: userName,
                    onComplete: onComplete
                )
            }
        }
    }
}

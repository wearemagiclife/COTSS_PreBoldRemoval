import SwiftUI
import WidgetKit

struct WidgetInfoView: View {
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var debugUnlocked: Bool = UserDefaults.standard.bool(forKey: "subscriptionDebugOverride")

    var body: some View {
        ZStack {
            AppTheme.backgroundColor.ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppConstants.Spacing.cardPadding) {

                    // MARK: - Header
                    VStack(spacing: 14) {

                        Text("Your Current Cards")
                            .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.title))
                            .foregroundColor(AppTheme.primaryText)
                            .multilineTextAlignment(.center)

                        Text("always in view.")
                            .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                            .foregroundColor(AppTheme.secondaryText)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .padding(.bottom, 4)

                    // MARK: - Preview Image (add WidgetPreview asset when ready)
                    if UIImage(named: "WidgetPreview") != nil {
                        Image("WidgetPreview")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(AppTheme.goldAccent.opacity(0.4), lineWidth: 1)
                            )
                    } else {
                        WidgetPlaceholderPreview()
                    }

                    // MARK: - What the Widget Shows
                    VStack(alignment: .leading, spacing: AppConstants.Spacing.tight) {
                        Text("Your current spread")
                            .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                            .foregroundColor(AppTheme.primaryText)
                            .padding(.bottom, 2)

                        Text("Our new widget features:")
                            .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.callout))
                            .foregroundColor(AppTheme.secondaryText)
                            .padding(.bottom, 2)

                        WidgetFeatureRow(
                            icon: "sun.max.fill",
                            title: "Your Daily Card",
                            description: "The card influencing your day, refreshed every morning."
                        )

                        WidgetFeatureRow(
                            icon: "globe",
                            title: "Today's Planetary Influence",
                            description: "The planetary energy currently in play alongside your daily card."
                        )

                        WidgetFeatureRow(
                            icon: "arrow.triangle.2.circlepath",
                            title: "52-Day Card",
                            description: "The card guiding your current 52-day planetary cycle."
                        )

                        WidgetFeatureRow(
                            icon: "calendar",
                            title: "This Year's Card",
                            description: "A long range theme to focus growth."
                        )
                    }
                    .padding(AppConstants.Spacing.tight)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(AppConstants.Colors.capsuleButton.opacity(0.96))
                            .shadow(color: .black.opacity(0.10), radius: 6, x: 0, y: 3)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(AppTheme.primaryText.opacity(0.10), lineWidth: 1)
                    )

                    // MARK: - How to Add
                    VStack(alignment: .leading, spacing: 10) {
                        Text("How to add it")
                            .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                            .foregroundColor(AppTheme.primaryText)
                            .padding(.bottom, 2)

                        WidgetStep(number: "1", text: "Long-press any empty space on your Home Screen until the icons jiggle.")
                        WidgetStep(number: "2", text: "Tap the + button in the top-left corner.")
                        WidgetStep(number: "3", text: "Search for \"Seven Sisters\" and choose your preferred widget size.")
                        WidgetStep(number: "4", text: "Tap Add Widget and place it wherever feels right.")
                    }
                    .padding(AppConstants.Spacing.tight)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(AppConstants.Colors.capsuleButton.opacity(0.96))
                            .shadow(color: .black.opacity(0.10), radius: 6, x: 0, y: 3)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(AppTheme.primaryText.opacity(0.10), lineWidth: 1)
                    )

                    // MARK: - CTA
                    if subscriptionManager.isSubscribed {
                        Text("Your widget is ready — add it from your Home Screen anytime.")
                            .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.callout))
                            .foregroundColor(AppTheme.goldAccent)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    } else {
                        NavigationLink {
                            SubscriptionView()
                                .environmentObject(subscriptionManager)
                        } label: {
                            Text("Subscribe to Unlock")
                                .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(GoldButtonStyle())
                        .padding(.top, 4)
                    }

                    #if DEBUG
                    // MARK: - Debug preview (Debug builds only)
                    VStack(spacing: 10) {
                        Button {
                            let next = !debugUnlocked
                            subscriptionManager.debugSubscriptionOverride = next
                            debugUnlocked = next
                            WidgetCenter.shared.reloadAllTimelines()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: debugUnlocked ? "checkmark.seal.fill" : "eye.fill")
                                Text(debugUnlocked ? "Widget Preview Unlocked" : "Preview Widget (Debug)")
                                    .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                        }
                        .buttonStyle(GoldButtonStyle())

                        Text(debugUnlocked
                             ? "Subscription override is ON. Tap again to turn off."
                             : "Skips the subscription check so you can test the widget on the simulator.")
                            .font(.custom("Iowan Old Style", size: 11))
                            .foregroundColor(AppTheme.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)
                    #endif
                }
                .padding(.horizontal, AppConstants.Spacing.cardPadding)
                .padding(.top, AppConstants.Spacing.tight)
                .padding(.bottom, AppConstants.Spacing.section)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppTheme.backgroundColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

// MARK: - Widget Placeholder

private struct WidgetPlaceholderPreview: View {
    private let gold = Color(red: 0.75, green: 0.60, blue: 0.35)

    var body: some View {
        ZStack {
            Color.black

            VStack(spacing: 10) {
                Text("YOUR CARDS")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(2)
                    .foregroundColor(gold.opacity(0.6))
                    .padding(.top, 18)

                let rows: [(String, String, String, String)] = [
                    ("sun.max.fill", "Daily", "globe", "Planet"),
                    ("arrow.triangle.2.circlepath", "52-Day", "calendar", "Yearly")
                ]

                VStack(spacing: 10) {
                    ForEach(rows, id: \.0) { row in
                        HStack(spacing: 14) {
                            ForEach([(row.0, row.1), (row.2, row.3)], id: \.0) { icon, label in
                                VStack(spacing: 5) {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(gold.opacity(0.6), lineWidth: 1)
                                        .frame(width: 64, height: 88)
                                        .overlay(
                                            Image(systemName: icon)
                                                .foregroundColor(gold.opacity(0.7))
                                                .font(.system(size: 18))
                                        )
                                        .shadow(color: gold.opacity(0.25), radius: 8)
                                    Text(label)
                                        .font(.system(size: 9))
                                        .foregroundColor(gold.opacity(0.7))
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 18)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(gold.opacity(0.35), lineWidth: 1)
        )
    }
}

// MARK: - Feature Row

private struct WidgetFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(AppTheme.goldAccent)
                .frame(width: 28)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.callout))
                    .foregroundColor(AppTheme.primaryText)
                Text(description)
                    .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.callout))
                    .foregroundColor(AppTheme.secondaryText)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Step Row

private struct WidgetStep: View {
    let number: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.goldAccent.opacity(0.15))
                    .overlay(Circle().stroke(AppTheme.goldAccent.opacity(0.4), lineWidth: 1))
                    .frame(width: 26, height: 26)
                Text(number)
                    .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.callout))
                    .foregroundColor(AppTheme.goldAccent)
            }

            Text(text)
                .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.callout))
                .foregroundColor(AppTheme.secondaryText)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 3)
        }
        .padding(.vertical, 4)
    }
}

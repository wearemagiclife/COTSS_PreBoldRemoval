import SwiftUI

struct WidgetInfoView: View {
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared

    var body: some View {
        ZStack {
            AppTheme.backgroundColor.ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppConstants.Spacing.cardPadding) {

                    // MARK: - Header
                    VStack(spacing: 14) {
                        Image(systemName: "rectangle.stack")
                            .font(.system(size: 48))
                            .foregroundColor(AppTheme.goldAccent)
                            .padding(.top, 12)

                        Text("Get the Widget")
                            .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.title))
                            .foregroundColor(AppTheme.primaryText)
                            .multilineTextAlignment(.center)

                        Text("Your current cards, always in view.")
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
                        Text("What you'll see")
                            .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                            .foregroundColor(AppTheme.primaryText)
                            .padding(.bottom, 2)

                        WidgetFeatureRow(
                            icon: "sun.max.fill",
                            title: "Today's Daily Card",
                            description: "Your card for the day is shown at a glance — no need to open the app."
                        )

                        WidgetFeatureRow(
                            icon: "arrow.triangle.2.circlepath",
                            title: "Your 52-Day Cycle Card",
                            description: "The card guiding your current planetary period, updated automatically when cycles shift."
                        )

                        WidgetFeatureRow(
                            icon: "star.fill",
                            title: "Your Birth Card",
                            description: "Your lifelong companion card, always present as a reminder of who you are."
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

            VStack(spacing: 12) {
                Text("YOUR CARDS")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(2)
                    .foregroundColor(gold.opacity(0.6))
                    .padding(.top, 20)

                HStack(spacing: 14) {
                    ForEach(["Daily", "52-Day", "Birth"], id: \.self) { label in
                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(gold.opacity(0.6), lineWidth: 1)
                                .frame(width: 60, height: 84)
                                .overlay(
                                    Image(systemName: label == "Daily" ? "sun.max.fill" : label == "52-Day" ? "arrow.triangle.2.circlepath" : "star.fill")
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
                .padding(.bottom, 20)
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

import SwiftUI

struct CalendarSyncView: View {
    @State private var isSyncing = false
    @State private var syncComplete = false
    @State private var syncFailed = false

    private let cardBackground = AppConstants.Colors.capsuleButton

    var body: some View {
        ZStack {
            AppTheme.backgroundColor.ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppConstants.Spacing.cardPadding) {

                    // MARK: - Header
                    VStack(spacing: 14) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 48))
                            .foregroundColor(AppTheme.goldAccent)
                            .padding(.top, 12)

                        Text("Sync to Your Calendar")
                            .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.title))
                            .foregroundColor(AppTheme.primaryText)
                            .multilineTextAlignment(.center)

                        Text("We can't help you see the future, but we can tell you which cards are coming up.")
                            .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                            .foregroundColor(AppTheme.secondaryText)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .padding(.bottom, 4)

                    // MARK: - What Gets Added
                    VStack(alignment: .leading, spacing: AppConstants.Spacing.tight) {
                        Text("What gets added")
                            .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                            .foregroundColor(AppTheme.primaryText)
                            .padding(.bottom, 2)

                        CalendarFeatureRow(
                            icon: "sun.max.fill",
                            title: "Your Daily Card",
                            description: "Every day of your subscription appears as an all-day event, so you can see your card at a glance without opening the app."
                        )

                        CalendarFeatureRow(
                            icon: "arrow.triangle.2.circlepath",
                            title: "52-Day Cycle Shifts",
                            description: "Each time a new planetary period begins, an event marks the transition and names the card that will guide the next 52 days."
                        )

                        CalendarFeatureRow(
                            icon: "birthday.cake",
                            title: "Your Yearly Card",
                            description: "On your birthday, a special event reveals the card that will accompany you through the coming year."
                        )
                    }
                    .padding(AppConstants.Spacing.tight)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(cardBackground.opacity(0.96))
                            .shadow(color: .black.opacity(0.10), radius: 6, x: 0, y: 3)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(AppTheme.primaryText.opacity(0.10), lineWidth: 1)
                    )

                    // MARK: - How It Works
                    VStack(alignment: .leading, spacing: 10) {
                        Text("How it works")
                            .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                            .foregroundColor(AppTheme.primaryText)
                            .padding(.bottom, 2)

                        Text("A dedicated \"Seven Sisters\" calendar is created for you — separate from your personal calendars so it stays tidy. Events are all-day, non-intrusive, and each one includes a note with a direct link back into the app.")
                            .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.callout))
                            .foregroundColor(AppTheme.secondaryText)
                            .lineSpacing(5)

                        Text("Events are added from today through the end of your current subscription period. You can re-sync at any time to refresh or extend your events after renewing.")
                            .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.callout))
                            .foregroundColor(AppTheme.secondaryText)
                            .lineSpacing(5)
                            .padding(.top, 2)

                        Text("Works with Apple Calendar (iCal) and Google Calendar — anywhere your iPhone calendars sync.")
                            .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.callout))
                            .foregroundColor(AppTheme.secondaryText)
                            .lineSpacing(5)
                            .padding(.top, 2)
                    }
                    .padding(AppConstants.Spacing.tight)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(cardBackground.opacity(0.96))
                            .shadow(color: .black.opacity(0.10), radius: 6, x: 0, y: 3)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(AppTheme.primaryText.opacity(0.10), lineWidth: 1)
                    )

                    // MARK: - CTA
                    VStack(spacing: 12) {
                        if syncComplete {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(AppTheme.goldAccent)
                                Text("Calendar synced successfully!")
                                    .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.callout))
                                    .foregroundColor(AppTheme.goldAccent)
                            }
                            .padding(.vertical, 8)
                        } else {
                            Button {
                                Task {
                                    isSyncing = true
                                    syncFailed = false
                                    let productID = SubscriptionManager.shared.activeProductID ?? ""
                                    let birthDate = DataManager.shared.userProfile.birthDate
                                    await CalendarSyncService.shared.syncCalendarEvents(for: productID, birthDate: birthDate)
                                    isSyncing = false
                                    syncComplete = true
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    if isSyncing {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                            .scaleEffect(0.85)
                                    }
                                    Text(isSyncing ? "Syncing…" : "Sync to Calendar")
                                        .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                            }
                            .buttonStyle(GoldButtonStyle())
                            .disabled(isSyncing)
                        }

                        Text("Seven Sisters will ask for Calendar access the first time you sync.")
                            .font(.custom("Iowan Old Style", size: 11))
                            .foregroundColor(AppTheme.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 4)
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

// MARK: - Feature Row

private struct CalendarFeatureRow: View {
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

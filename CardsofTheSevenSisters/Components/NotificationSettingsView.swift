//
//  NotificationSettingsView.swift
//  CardsofTheSevenSisters



import SwiftUI

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var notificationManager = NotificationManager.shared
    @ObservedObject private var dataManager = DataManager.shared
    private let cardBackground = AppConstants.Colors.capsuleButton

    var body: some View {
        ZStack {
            AppTheme.backgroundColor.ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppConstants.Spacing.cardPadding) {
                    if dataManager.isGuestMode {
                        VStack(spacing: AppConstants.Spacing.ornament) {
                            Image(systemName: "bell.slash")
                                .font(.system(size: 40))
                                .foregroundColor(AppTheme.secondaryText)

                            Text("Notifications not available for Guest Users")
                                .font(.custom("Iowan Old Style", size: 16))
                                .foregroundColor(AppTheme.primaryText)
                                .multilineTextAlignment(.center)

                            Text("Please sign in with Apple to enable notifications.")
                                .font(.custom("Iowan Old Style", size: 14))
                                .foregroundColor(AppTheme.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppConstants.Spacing.cardPadding)
                    } else {
                        VStack(alignment: .leading, spacing: AppConstants.Spacing.tight) {
                            Text("Reminders")
                                .font(.custom("Iowan Old Style", size: 20))
                                .foregroundColor(AppTheme.primaryText)

                            Toggle(isOn: $notificationManager.notificationsEnabled) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Daily Card Reminder")
                                        .font(.custom("Iowan Old Style", size: 18))
                                        .foregroundColor(AppTheme.primaryText)

                                    Text("Receive a Daily Card notification at 12:00 PM each day")
                                        .font(.custom("Iowan Old Style", size: 14))
                                        .foregroundColor(AppTheme.secondaryText)
                                }
                            }
                            .toggleStyle(SwitchToggleStyle(tint: AppTheme.darkAccent))
                            .padding(AppConstants.Spacing.tight)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(cardBackground.opacity(0.96))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(AppTheme.primaryText.opacity(0.10), lineWidth: 1)
                            )
                            .accessibilityLabel("Daily Card Reminder")
                            .accessibilityHint("Toggle daily notification at 12:00 PM")
                        }
                    }
                }
                .padding(.horizontal, AppConstants.Spacing.cardPadding)
                .padding(.top, AppConstants.Spacing.tight)
            }
        }
        .navigationBarBackButtonHidden(true)
        .standardNavigation(
            title: "Notifications",
            hasBackButton: true,
            backAction: { dismiss() }
        )
    }
}

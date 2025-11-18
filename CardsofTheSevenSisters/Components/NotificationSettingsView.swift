//
//  NotificationSettingsView.swift
//  CardsofTheSevenSisters



import SwiftUI

struct NotificationSettingsView: View {
    @ObservedObject private var notificationManager = NotificationManager.shared
    @ObservedObject private var dataManager = DataManager.shared
    private let fieldBackgroundColor = Color(red: 0.95, green: 0.90, blue: 0.78)

    var body: some View {
        Form {
            if dataManager.isGuestMode {
                Section {
                    VStack(spacing: 15) {
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
                    .padding(.vertical, 20)
                }
            } else {
                Section(header: Text("Reminders")
                    .font(.custom("Iowan Old Style", size: 20))
                    .foregroundColor(AppTheme.primaryText)) {

                    Toggle(isOn: $notificationManager.notificationsEnabled) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Daily Card Reminder")
                                .font(.custom("Iowan Old Style", size: 18))
                                .foregroundColor(AppTheme.primaryText)

                            Text("Receive a Daily Card notification at 12:00 PM each day")
                                .font(.custom("Iowan Old Style", size: 14))
                                .foregroundColor(AppTheme.secondaryText)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: AppTheme.darkAccent))
                    .accessibilityLabel("Daily Card Reminder")
                    .accessibilityHint("Toggle daily notification at 12:00 PM")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.backgroundColor.ignoresSafeArea())
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

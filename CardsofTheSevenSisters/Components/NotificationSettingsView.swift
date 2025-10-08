//
//  NotificationSettingsView.swift
//  CardsofTheSevenSisters
//
//  Created by Angela Whitehead on 11/14/25.
//


import SwiftUI

struct NotificationSettingsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    private let fieldBackgroundColor = Color(red: 0.95, green: 0.90, blue: 0.78)

    var body: some View {
        Form {
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
        .scrollContentBackground(.hidden)
        .background(AppTheme.backgroundColor.ignoresSafeArea())
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

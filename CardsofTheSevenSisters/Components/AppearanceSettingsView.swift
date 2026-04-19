import SwiftUI

struct AppearanceSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var appSettings = AppSettings.shared

    private let cardBackground = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.35, green: 0.30, blue: 0.24, alpha: 1.0)
            : UIColor(red: 0.90, green: 0.83, blue: 0.67, alpha: 1.0)
    })

    var body: some View {
        ZStack {
            Color.appLaunchBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppConstants.Spacing.cardPadding) {
                    VStack(spacing: AppConstants.Spacing.tight) {
                        ForEach(AppearanceMode.allCases, id: \.rawValue) { mode in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    appSettings.appearanceMode = mode
                                }
                            } label: {
                                AppearanceRow(
                                    mode: mode,
                                    isSelected: appSettings.appearanceMode == mode,
                                    cardBackground: cardBackground
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text("Choose how Cards of the Seven Sisters appears. System will match your device settings.")
                        .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.callout))
                        .foregroundColor(AppTheme.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, AppConstants.Spacing.tight)
                }
                .padding(.horizontal, AppConstants.Spacing.cardPadding)
                .padding(.bottom, AppConstants.Spacing.section)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20))
                        .foregroundColor(AppTheme.primaryText)
                        .frame(width: AppConstants.ButtonSizes.backButton, height: AppConstants.ButtonSizes.backButton)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")
            }
        }
        .toolbarBackground(Color.appLaunchBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

private struct AppearanceRow: View {
    let mode: AppearanceMode
    let isSelected: Bool
    let cardBackground: Color

    private var iconName: String {
        switch mode {
        case .system: return "gear"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    var body: some View {
        HStack(spacing: AppConstants.Spacing.ornament) {
            ZStack {
                Circle()
                    .strokeBorder(AppTheme.primaryText.opacity(0.25), lineWidth: 1)
                    .frame(width: 40, height: 40)

                Image(systemName: iconName)
                    .font(.system(size: AppConstants.FontSizes.subheadline, weight: .semibold))
                    .foregroundColor(AppTheme.primaryText)
            }

            Text(mode.displayName)
                .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                .foregroundColor(AppTheme.primaryText)

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(AppTheme.goldAccent)
            } else {
                Circle()
                    .strokeBorder(AppTheme.primaryText.opacity(0.3), lineWidth: 1.5)
                    .frame(width: 22, height: 22)
            }
        }
        .padding(AppConstants.Spacing.tight)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(cardBackground.opacity(0.96))
                .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isSelected ? AppTheme.goldAccent : AppTheme.primaryText.opacity(0.10), lineWidth: isSelected ? 2 : 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

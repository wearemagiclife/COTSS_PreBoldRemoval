import SwiftUI
import StoreKit

struct RateAppView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var hasRated = false

    var body: some View {
        ZStack {
            Color.appLaunchBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppConstants.Spacing.cardPadding) {

                    // MARK: - Stars
                    HStack(spacing: 10) {
                        ForEach(0..<5) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 28))
                                .foregroundColor(AppTheme.goldAccent)
                        }
                    }
                    .padding(.top, AppConstants.Spacing.section)

                    // MARK: - Title
                    Text("Enjoying Seven Sisters?")
                        .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.title))
                        .foregroundColor(AppTheme.primaryText)
                        .multilineTextAlignment(.center)

                    // MARK: - Subtitle
                    Text("Your review helps other seekers find their path. It only takes a moment.")
                        .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                        .foregroundColor(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, AppConstants.Spacing.section)

                    // MARK: - CTA
                    Button {
                        requestReview()
                    } label: {
                        Text("Rate on the App Store")
                            .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(GoldButtonStyle())
                    .padding(.horizontal, AppConstants.Spacing.section)
                    .padding(.top, AppConstants.Spacing.tight)

                    // MARK: - Maybe Later
                    Button {
                        dismiss()
                    } label: {
                        Text("Maybe Later")
                            .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.callout))
                            .foregroundColor(AppTheme.secondaryText)
                            .underline()
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, AppConstants.Spacing.section)
                }
                .padding(.horizontal, AppConstants.Spacing.cardPadding)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20))
                        .foregroundColor(AppTheme.primaryText)
                        .frame(
                            width: AppConstants.ButtonSizes.closeButton,
                            height: AppConstants.ButtonSizes.closeButton
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
                .accessibilityHint("Dismiss without rating")
            }
        }
        .toolbarBackground(Color.appLaunchBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private func requestReview() {
        if let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
        dismiss()
    }
}

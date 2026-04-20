import SwiftUI
import StoreKit

struct BillingIssueBanner: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.openURL) private var openURL

    var body: some View {
        if subscriptionManager.hasBillingIssue {
            Button {
                openURL(URL(string: "https://apps.apple.com/account/subscriptions")!)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.black)
                        .font(.system(size: 15, weight: .semibold))

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Payment issue")
                            .font(.custom("Iowan Old Style", size: 13))
                            .foregroundColor(.black)
                            .fontWeight(.semibold)
                        Text("Tap to update your billing info")
                            .font(.custom("Iowan Old Style", size: 11))
                            .foregroundColor(.black.opacity(0.75))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.black.opacity(0.6))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(AppTheme.goldAccent)
                .cornerRadius(12)
                .padding(.horizontal, AppConstants.Spacing.cardPadding)
                .padding(.top, 8)
            }
            .buttonStyle(.plain)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

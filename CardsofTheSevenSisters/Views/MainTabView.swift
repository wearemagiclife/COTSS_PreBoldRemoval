import SwiftUI

private enum AppTab {
    case home, calendar
}

struct MainTabView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        ZStack {
            HomeView()
                .opacity(selectedTab == .home ? 1 : 0)
                .allowsHitTesting(selectedTab == .home)

            SubscriberCalendarView()
                .opacity(selectedTab == .calendar ? 1 : 0)
                .allowsHitTesting(selectedTab == .calendar)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            navBar
        }
    }

    @Environment(\.colorScheme) private var colorScheme

    private var navBar: some View {
        HStack(spacing: 32) {
            navPill(for: .home)
            navPill(for: .calendar)
        }
        .frame(maxWidth: .infinity)
        .background(AppTheme.backgroundColor)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppTheme.primaryText.opacity(0.08))
                .frame(height: 0.5)
        }
    }

    private func navPill(for tab: AppTab) -> some View {
        let activeOpacity: Double = colorScheme == .dark ? 0.45 : 0.72
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
        } label: {
            Capsule()
                .fill(selectedTab == tab
                      ? AppTheme.goldAccent.opacity(activeOpacity)
                      : AppTheme.primaryText.opacity(0.13))
                .frame(width: 64, height: 3)
                .padding(.horizontal, 18)
                .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

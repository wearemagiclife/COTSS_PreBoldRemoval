import SwiftUI

private enum AppTab {
    case home, calendar
}

struct MainTabView: View {
    @State private var selectedTab: AppTab = .home
    @State private var isNavExpanded: Bool = false
    @State private var hideTask: Task<Void, Never>? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab content
            HomeView()
                .opacity(selectedTab == .home ? 1 : 0)
                .allowsHitTesting(selectedTab == .home)

            SubscriberCalendarView()
                .opacity(selectedTab == .calendar ? 1 : 0)
                .allowsHitTesting(selectedTab == .calendar)

            // Collapsed hint + expanded nav bar
            navBar
        }
        .ignoresSafeArea(edges: .bottom)
    }

    @Environment(\.colorScheme) private var colorScheme

    private var navBar: some View {
        VStack(spacing: 0) {
            // Expanded tab pills — only visible when expanded
            if isNavExpanded {
                HStack(spacing: 32) {
                    navPill(for: .home)
                    navPill(for: .calendar)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(AppTheme.backgroundColor)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(AppTheme.primaryText.opacity(0.08))
                        .frame(height: 0.5)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Always-visible collapsed hint strip
            Button {
                withAnimation(.easeInOut(duration: 0.22)) {
                    isNavExpanded.toggle()
                }
                if isNavExpanded {
                    scheduleAutoHide()
                } else {
                    hideTask?.cancel()
                }
            } label: {
                HStack(spacing: 32) {
                    collapsedPill(for: .home)
                    collapsedPill(for: .calendar)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 6)
                .padding(.bottom, 8)
                .background(AppTheme.backgroundColor.opacity(isNavExpanded ? 0 : 0.85))
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())

            // Safe area fill
            AppTheme.backgroundColor
                .frame(height: safeAreaBottomInset())
        }
    }

    private func collapsedPill(for tab: AppTab) -> some View {
        let activeOpacity: Double = colorScheme == .dark ? 0.45 : 0.72
        return Capsule()
            .fill(selectedTab == tab
                  ? AppTheme.goldAccent.opacity(activeOpacity)
                  : AppTheme.primaryText.opacity(0.13))
            .frame(width: 64, height: 3)
            .padding(.horizontal, 18)
    }

    private func navPill(for tab: AppTab) -> some View {
        let activeOpacity: Double = colorScheme == .dark ? 0.45 : 0.72
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
            scheduleAutoHide()
        } label: {
            Capsule()
                .fill(selectedTab == tab
                      ? AppTheme.goldAccent.opacity(activeOpacity)
                      : AppTheme.primaryText.opacity(0.13))
                .frame(width: 64, height: 3)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }

    private func scheduleAutoHide() {
        hideTask?.cancel()
        hideTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.22)) {
                    isNavExpanded = false
                }
            }
        }
    }

    private func safeAreaBottomInset() -> CGFloat {
        (UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.bottom) ?? 0
    }
}

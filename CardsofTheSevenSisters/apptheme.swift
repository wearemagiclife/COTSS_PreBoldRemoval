import SwiftUI

extension Color {
    static let appLaunchBackground = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)  // true black
            : UIColor(red: 0.86, green: 0.77, blue: 0.57, alpha: 1.0)  // tan
    })
}

struct AppTheme {
    static let backgroundColor = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)  // true black
            : UIColor(red: 0.86, green: 0.75, blue: 0.55, alpha: 1.0)  // tan
    })
    static let cardBackground = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.25, green: 0.22, blue: 0.18, alpha: 1.0)  // dark tan
            : UIColor(red: 0.95, green: 0.91, blue: 0.82, alpha: 1.0)  // cream
    })
    static let darkAccent = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.95, green: 0.91, blue: 0.82, alpha: 1.0)  // cream for dark mode
            : UIColor.black
    })
    static let primaryText = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.95, green: 0.91, blue: 0.82, alpha: 1.0)  // cream for dark mode
            : UIColor.black
    })
    static let secondaryText = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.95, green: 0.91, blue: 0.82, alpha: 0.7)  // cream 70%
            : UIColor.black.withAlphaComponent(0.7)
    })
    static let accentColor = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.95, green: 0.91, blue: 0.82, alpha: 0.8)  // cream 80%
            : UIColor.black.withAlphaComponent(0.8)
    })
    static let goldAccent = Color(red: 0.83, green: 0.69, blue: 0.22)
    
    static let largeTitle = Font.custom("Iowan Old Style", size: 34)
    static let title = Font.custom("Iowan Old Style", size: 22)
    static let headline = Font.custom("Iowan Old Style", size: 18)
    static let body = Font.custom("Iowan Old Style", size: 16)
    static let caption = Font.custom("Iowan Old Style", size: 12)
    static let bookTitle = Font.custom("Iowan Old Style", size: 28)
    
    static let paddingSmall: CGFloat = 8
    static let paddingMedium: CGFloat = 16
    static let paddingLarge: CGFloat = 24
    static let cornerRadius: CGFloat = 8
    
}

extension View {
    func appBackground() -> some View {
        self.background(AppTheme.backgroundColor)
    }
    
    func bookTitleStyle() -> some View {
        self
            .font(AppTheme.bookTitle)
            .foregroundColor(AppTheme.primaryText)
            .multilineTextAlignment(.center)
    }
    
    func titleStyle() -> some View {
        self
            .font(AppTheme.title)
            .foregroundColor(AppTheme.primaryText)
            .multilineTextAlignment(.center)
    }
    
    func headlineStyle() -> some View {
        self
            .font(AppTheme.headline)
            .foregroundColor(AppTheme.primaryText)
            .multilineTextAlignment(.center)
    }
    
    func bodyStyle() -> some View {
        self
            .font(AppTheme.body)
            .foregroundColor(AppTheme.primaryText)
            .multilineTextAlignment(.leading)
    }
    
    func captionStyle() -> some View {
        self
            .font(AppTheme.caption)
            .foregroundColor(AppTheme.secondaryText)
            .multilineTextAlignment(.leading)
    }
    
    func goldTextStyle() -> some View {
        self
            .font(AppTheme.headline)
            .foregroundColor(AppTheme.goldAccent)
    }
    
    func cardPadding() -> some View {
        self.padding(AppTheme.paddingMedium)
    }
    
    func sectionPadding() -> some View {
        self.padding(AppTheme.paddingLarge)
    }
    
    func customNavigation() -> some View {
        self
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
    }
}

struct VintageButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.headline)
            .foregroundColor(AppTheme.cardBackground)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(AppTheme.darkAccent)
            .cornerRadius(25)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 3)
    }
}

struct GoldButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.headline)
            .foregroundColor(AppTheme.primaryText)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(AppTheme.goldAccent)
            .cornerRadius(AppTheme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(AppTheme.darkAccent, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

struct SecondaryVintageButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.body)
            .foregroundColor(AppTheme.accentColor)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(AppTheme.accentColor, lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

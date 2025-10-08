import SwiftUI

extension Color {
    static var appLaunchBackground: Color {
        Color(red: 0.86, green: 0.77, blue: 0.57)
    }
}

struct AppTheme {
    static let backgroundColor = Color(red: 0.86, green: 0.75, blue: 0.55)
    static let cardBackground = Color(red: 0.95, green: 0.91, blue: 0.82)
    static let darkAccent = Color.black
    static let shadowColor = Color.black.opacity(0.3)
    static let primaryText = Color.black
    static let secondaryText = Color.black.opacity(0.7)
    static let accentColor = Color.black.opacity(0.8)
    static let goldAccent = Color(red: 0.83, green: 0.69, blue: 0.22)
    
    static let largeTitle = Font.custom("Iowan Old Style", size: 34)
    static let title = Font.custom("Iowan Old Style", size: 22)
    static let headline = Font.custom("Iowan Old Style", size: 18)
    static let body = Font.custom("Iowan Old Style", size: 16)
    static let caption = Font.custom("Iowan Old Style", size: 12)
    static let mysticalTitle = Font.custom("Iowan Old Style", size: 28)
    
    static let paddingSmall: CGFloat = 8
    static let paddingMedium: CGFloat = 16
    static let paddingLarge: CGFloat = 24
    static let cornerRadius: CGFloat = 8
    
    static let cardShadow = Shadow(color: shadowColor, radius: 4, x: 0, y: 2)
    static let lightShadow = Shadow(color: shadowColor, radius: 2, x: 0, y: 1)
    static let deepShadow = Shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 3)
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

extension View {
    func appBackground() -> some View {
        self.background(AppTheme.backgroundColor)
    }
    
    func cardBackground() -> some View {
        self
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cornerRadius)
            .shadow(color: AppTheme.cardShadow.color,
                   radius: AppTheme.cardShadow.radius,
                   x: AppTheme.cardShadow.x,
                   y: AppTheme.cardShadow.y)
    }
    
    func lightCardBackground() -> some View {
        self
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cornerRadius)
            .shadow(color: AppTheme.lightShadow.color,
                   radius: AppTheme.lightShadow.radius,
                   x: AppTheme.lightShadow.x,
                   y: AppTheme.lightShadow.y)
    }
    
    func vintageCardBackground() -> some View {
        self
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(AppTheme.darkAccent.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: AppTheme.deepShadow.color,
                   radius: AppTheme.deepShadow.radius,
                   x: AppTheme.deepShadow.x,
                   y: AppTheme.deepShadow.y)
    }
    
    func mysticalTitleStyle() -> some View {
        self
            .font(AppTheme.mysticalTitle)
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
            .shadow(color: AppTheme.deepShadow.color,
                   radius: AppTheme.deepShadow.radius,
                   x: AppTheme.deepShadow.x,
                   y: AppTheme.deepShadow.y)
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
            .shadow(color: AppTheme.cardShadow.color,
                   radius: AppTheme.cardShadow.radius,
                   x: AppTheme.cardShadow.x,
                   y: AppTheme.cardShadow.y)
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

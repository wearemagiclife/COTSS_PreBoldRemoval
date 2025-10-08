import SwiftUI

struct AccessibleCard: ViewModifier {
    let card: Card
    let action: String
    
    func body(content: Content) -> some View {
        content
            .accessibilityLabel("\(card.value) of \(card.suit.rawValue)")
            .accessibilityHint(action)
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("card_\(card.id)")
    }
}

struct AccessibleButton: ViewModifier {
    let label: String
    let hint: String
    let identifier: String?
    
    func body(content: Content) -> some View {
        content
            .frame(minWidth: AppConstants.Accessibility.minimumTouchTarget,
                   minHeight: AppConstants.Accessibility.minimumTouchTarget)
            .contentShape(Rectangle())
            .accessibilityLabel(label)
            .accessibilityHint(hint)
            .accessibilityIdentifier(identifier ?? label.lowercased().replacingOccurrences(of: " ", with: "_"))
    }
}

struct DynamicTypeModifier: ViewModifier {
    let baseSize: CGFloat
    let textStyle: UIFont.TextStyle
    @Environment(\.sizeCategory) var sizeCategory
    
    func body(content: Content) -> some View {
        content
            .font(.custom("Iowan Old Style",
                         size: scaledSize))
            .dynamicTypeSize(.large ... .accessibility3)
    }
    
    private var scaledSize: CGFloat {
        let metrics = UIFontMetrics(forTextStyle: textStyle)
        return metrics.scaledValue(for: baseSize)
    }
}

struct ReduceMotionModifier<Value: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    let animation: Animation?
    let value: Value

    func body(content: Content) -> some View {
        content
            .animation(
                reduceMotion
                ? .easeInOut(duration: AppConstants.Animation.reducedMotionDuration)
                : animation,
                value: value
            )
    }
}

struct CardDetailAnimation: ViewModifier {
    @Binding var isVisible: Bool
    @Binding var isAnimated: Bool
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimated ? 1 : 0.8)
            .opacity(isAnimated ? 1 : 0)
            .animation(reduceMotion ?
                      .easeInOut(duration: AppConstants.Animation.reducedMotionDuration) :
                      .easeInOut(duration: AppConstants.Animation.cardDetailDuration),
                      value: isAnimated)
    }
}

struct CardTapAnimation: ViewModifier {
    let action: () -> Void
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    func body(content: Content) -> some View {
        Button(action: action) {
            content
        }
        .buttonStyle(AccessibleCardButtonStyle(reduceMotion: reduceMotion))
    }
}

struct AccessibleCardButtonStyle: ButtonStyle {
    let reduceMotion: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.95 : 1.0)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct StandardNavigation: ViewModifier {
    let title: String
    let hasBackButton: Bool
    let backAction: (() -> Void)?
    let trailingContent: (() -> AnyView)?
    @Environment(\.sizeCategory) var sizeCategory
    
    init(title: String, hasBackButton: Bool = true, backAction: (() -> Void)? = nil, trailingContent: (() -> AnyView)? = nil) {
        self.title = title
        self.hasBackButton = hasBackButton
        self.backAction = backAction
        self.trailingContent = trailingContent
    }
    
    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(hasBackButton)
            .toolbar {
                if hasBackButton {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: backAction ?? {}) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20))
                                .foregroundColor(.black)
                                .frame(width: AppConstants.Accessibility.minimumTouchTarget,
                                      height: AppConstants.Accessibility.minimumTouchTarget)
                                .contentShape(Rectangle())
                        }
                        .accessibilityLabel(AppConstants.Accessibility.Labels.backButton)
                        .accessibilityHint(AppConstants.Accessibility.Hints.doubleTapToClose)
                        .accessibilityIdentifier(AppConstants.Accessibility.Identifiers.backButton)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(.custom("Iowan Old Style", size: scaledTitleSize))
                        .foregroundColor(.black)
                        
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }
                
                if let trailingContent = trailingContent {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        trailingContent()
                    }
                }
            }
    }
    
    private var scaledTitleSize: CGFloat {
        let metrics = UIFontMetrics(forTextStyle: .title2)
        return metrics.scaledValue(for: AppConstants.FontSizes.title)
    }
}

struct CardShadow: ViewModifier {
    let isLarge: Bool
    @Environment(\.colorSchemeContrast) var contrast
    
    func body(content: Content) -> some View {
        content
            .shadow(
                color: shadowColor,
                radius: isLarge ? AppConstants.Shadow.detailRadius : AppConstants.Shadow.cardRadius,
                x: isLarge ? AppConstants.Shadow.detailOffset.width : AppConstants.Shadow.cardOffset.width,
                y: isLarge ? AppConstants.Shadow.detailOffset.height : AppConstants.Shadow.cardOffset.height
            )
    }
    
    private var shadowColor: Color {
        let baseOpacity = isLarge ? AppConstants.Shadow.detailOpacity : AppConstants.Shadow.cardOpacity
        let adjustedOpacity = contrast == .increased ? baseOpacity * 1.5 : baseOpacity
        return Color.black.opacity(adjustedOpacity)
    }
}

struct ErrorFallback: ViewModifier {
    let errorMessage: String
    let retryAction: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: .constant(!errorMessage.isEmpty)) {
                if let retryAction = retryAction {
                    Button("Retry", action: retryAction)
                        .accessibilityLabel("Retry action")
                }
                Button("OK") { }
                    .accessibilityLabel("Dismiss error")
            } message: {
                Text(errorMessage)
            }
    }
}

struct HideFromAccessibility: ViewModifier {
    func body(content: Content) -> some View {
        content
            .accessibilityHidden(true)
    }
}

extension View {
    func cardDetailAnimation(isVisible: Binding<Bool>, isAnimated: Binding<Bool>) -> some View {
        modifier(CardDetailAnimation(isVisible: isVisible, isAnimated: isAnimated))
    }
    
    func cardTap(action: @escaping () -> Void) -> some View {
        modifier(CardTapAnimation(action: action))
    }
    
    func standardNavigation(
        title: String,
        hasBackButton: Bool = true,
        backAction: (() -> Void)? = nil,
        trailingContent: (() -> AnyView)? = nil
    ) -> some View {
        modifier(StandardNavigation(
            title: title,
            hasBackButton: hasBackButton,
            backAction: backAction,
            trailingContent: trailingContent
        ))
    }
    
    func cardShadow(isLarge: Bool = false) -> some View {
        modifier(CardShadow(isLarge: isLarge))
    }
    
    func errorFallback(message: String, retryAction: (() -> Void)? = nil) -> some View {
        modifier(ErrorFallback(errorMessage: message, retryAction: retryAction))
    }
    
    func accessibleCard(_ card: Card, action: String = AppConstants.Accessibility.Hints.doubleTapToView) -> some View {
        modifier(AccessibleCard(card: card, action: action))
    }
    
    func accessibleButton(_ label: String, hint: String = AppConstants.Accessibility.Hints.doubleTapToOpen, identifier: String? = nil) -> some View {
        modifier(AccessibleButton(label: label, hint: hint, identifier: identifier))
    }
    
    func dynamicType(baseSize: CGFloat, textStyle: UIFont.TextStyle = .body) -> some View {
        modifier(DynamicTypeModifier(baseSize: baseSize, textStyle: textStyle))
    }
    
    func reduceMotionAnimation<Value: Equatable>(_ animation: Animation?, value: Value) -> some View {
        modifier(ReduceMotionModifier(animation: animation, value: value))
    }
    
    func hideFromAccessibility() -> some View {
        modifier(HideFromAccessibility())
    }
    
    func decorativeImage() -> some View {
        self
            .accessibilityHidden(true)
            .accessibilityElement(children: .ignore)
    }
}

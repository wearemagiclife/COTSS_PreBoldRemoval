import SwiftUI

// MARK: - Animated Gold Border with Sheen

/// A gold border with a periodic angled sheen animation that sweeps across the button face
struct AnimatedGoldBorder: View {
    let cornerRadius: CGFloat
    let lineWidth: CGFloat
    let sweepDuration: Double
    let initialDelay: Double
    let pausePattern: [Double]  // Cycling pause durations: [8, 10, 9]

    @State private var shimmerPosition: CGFloat = -1.0
    @State private var cycleIndex: Int = 0

    init(cornerRadius: CGFloat, lineWidth: CGFloat = 0.75, sweepDuration: Double = 2.5, initialDelay: Double = 2.0, pausePattern: [Double] = [8.0, 10.0, 9.0]) {
        self.cornerRadius = cornerRadius
        self.lineWidth = lineWidth
        self.sweepDuration = sweepDuration
        self.initialDelay = initialDelay
        self.pausePattern = pausePattern
    }

    var body: some View {
        ZStack {
            // Angled sheen sweeping across button face
            GeometryReader { geometry in
                // Wide angled band that sweeps left to right
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: .clear, location: 0.0),
                                .init(color: .clear, location: 0.46),
                                .init(color: .white.opacity(0.15), location: 0.49),
                                .init(color: .white.opacity(0.25), location: 0.5),
                                .init(color: .white.opacity(0.15), location: 0.51),
                                .init(color: .clear, location: 0.54),
                                .init(color: .clear, location: 1.0)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * 3)
                    .rotationEffect(.degrees(25))
                    .offset(x: shimmerPosition * geometry.size.width * 2.5)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .allowsHitTesting(false)

            // Gold border
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(AppTheme.goldAccent.opacity(0.8), lineWidth: lineWidth)
        }
        .onAppear {
            // Wait for card elements to load before first glint
            DispatchQueue.main.asyncAfter(deadline: .now() + initialDelay) {
                startShimmerCycle()
            }
        }
    }

    private func startShimmerCycle() {
        // Reset position
        shimmerPosition = -1.0

        // Sweep across
        withAnimation(.easeInOut(duration: sweepDuration)) {
            shimmerPosition = 1.0
        }

        // Get current pause duration from pattern
        let currentPause = pausePattern[cycleIndex % pausePattern.count]
        cycleIndex += 1

        // Schedule next cycle after sweep + pause
        DispatchQueue.main.asyncAfter(deadline: .now() + sweepDuration + currentPause) {
            startShimmerCycle()
        }
    }
}

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

    private var isSmallScreen: Bool {
        UIScreen.main.bounds.height < 700
    }

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
                    if #available(iOS 26.0, *) {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: backAction ?? {}) {
                                if isSmallScreen {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(AppTheme.primaryText)
                                        .frame(width: 28, height: 28)
                                        .contentShape(Rectangle())
                                } else {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 20))
                                        .foregroundColor(AppTheme.primaryText)
                                        .frame(width: AppConstants.ButtonSizes.backButton, height: AppConstants.ButtonSizes.backButton)
                                        .contentShape(Rectangle())
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(AppConstants.Accessibility.Labels.backButton)
                            .accessibilityHint(AppConstants.Accessibility.Hints.doubleTapToClose)
                            .accessibilityIdentifier(AppConstants.Accessibility.Identifiers.backButton)
                        }
                        .sharedBackgroundVisibility(.hidden)
                    } else {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: backAction ?? {}) {
                                if isSmallScreen {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(AppTheme.primaryText)
                                        .frame(width: 28, height: 28)
                                        .contentShape(Rectangle())
                                } else {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 20))
                                        .foregroundColor(AppTheme.primaryText)
                                        .frame(width: AppConstants.ButtonSizes.backButton, height: AppConstants.ButtonSizes.backButton)
                                        .contentShape(Rectangle())
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(AppConstants.Accessibility.Labels.backButton)
                            .accessibilityHint(AppConstants.Accessibility.Hints.doubleTapToClose)
                            .accessibilityIdentifier(AppConstants.Accessibility.Identifiers.backButton)
                        }
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(.custom("Iowan Old Style", size: 18))
                        .foregroundColor(AppTheme.primaryText)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                        .frame(maxWidth: 220)
                }
                
                if let trailingContent = trailingContent {
                    if #available(iOS 26.0, *) {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            trailingContent()
                        }
                        .sharedBackgroundVisibility(.hidden)
                    } else {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            trailingContent()
                        }
                    }
                }
            }
    }
    
    private var scaledTitleSize: CGFloat {
        let metrics = UIFontMetrics(forTextStyle: .headline)
        return metrics.scaledValue(for: 20)
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

// MARK: - Dark Mode Gold Glow

/// Adds a subtle metallic gold glow behind cards in dark mode only.
/// This is a separate layer from the regular shadow - tighter radius for metallic effect.
struct DarkModeGoldGlow: ViewModifier {
    let isLarge: Bool
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.colorSchemeContrast) var contrast

    func body(content: Content) -> some View {
        content
            .shadow(
                color: glowColor,
                radius: glowRadius,
                x: 0,
                y: isLarge ? 1 : 0.5
            )
    }

    private var glowColor: Color {
        guard colorScheme == .dark else { return .clear }
        let baseOpacity = isLarge ? AppConstants.DarkModeEffects.glowOpacityLarge : AppConstants.DarkModeEffects.glowOpacitySmall
        let adjustedOpacity = contrast == .increased ? baseOpacity * 1.3 : baseOpacity
        return AppTheme.goldAccent.opacity(adjustedOpacity)
    }

    private var glowRadius: CGFloat {
        guard colorScheme == .dark else { return 0 }
        return isLarge ? AppConstants.DarkModeEffects.glowRadiusLarge : AppConstants.DarkModeEffects.glowRadiusSmall
    }
}

// MARK: - DarkModeCardEffects

/// Combined modifier that applies all card visual effects:
/// - Black shadow (always, for depth)
/// - Gold glow (dark mode only, tight radius for metallic effect)
/// - Glossy shine effect with 3D tilt (dark mode only)
struct DarkModeCardEffects: ViewModifier {
    let isLarge: Bool
    let glossIntensity: Double

    init(isLarge: Bool = false, glossIntensity: Double = AppConstants.DarkModeEffects.glossIntensity) {
        self.isLarge = isLarge
        self.glossIntensity = glossIntensity
    }

    func body(content: Content) -> some View {
        content
            .modifier(DarkModeGoldGlow(isLarge: isLarge))  // Gold glow (dark mode only)
            .cardShadow(isLarge: isLarge)                   // Black shadow (always)
            .cardGloss(intensity: glossIntensity)           // Gloss + 3D tilt (dark mode only)
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

    /// Applies all dark mode card effects: gold glow shadow + glossy shine with 3D tilt.
    /// In light mode, only the standard shadow is applied.
    func darkModeCardEffects(isLarge: Bool = false, glossIntensity: Double = AppConstants.DarkModeEffects.glossIntensity) -> some View {
        modifier(DarkModeCardEffects(isLarge: isLarge, glossIntensity: glossIntensity))
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

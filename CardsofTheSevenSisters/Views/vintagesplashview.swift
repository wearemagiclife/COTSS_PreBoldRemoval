import SwiftUI

struct VintageSplashView: View {
    let onStart: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var showCards = false
    @State private var showButton = false
    @State private var isTransitioning = false
    @State private var showCardSheen = false
    @State private var buttonSheenPosition: CGFloat = -2.0
    @State private var cardScales: [CGFloat] = Array(repeating: 0.0, count: 7)
    @State private var cardOffsets: [CGSize] = Array(repeating: .zero, count: 7)
    @State private var cardRotations: [Double] = Array(repeating: 0, count: 7)
    
    let cardNames = ["2♠", "5♣", "4♥", "Q♠", "4♠", "5♦", "2♥"]
    let cardImageNames = ["2s", "5c", "4h", "qs", "4s", "5d", "2h"]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                AppTheme.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 68)

                    titleSection(for: geometry.size)
                        .padding(.bottom, 21)

                    cardAnimationArea(for: geometry.size)

                    Spacer()

                    startButton
                        .padding(.bottom, geometry.size.height * 0.1)

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
            }
            .onAppear {
                startAnimation(for: geometry.size)
            }
        }
    }
    
    private func titleSection(for size: CGSize) -> some View {
        let isIPad = size.width > 500
        let titleWidth = isIPad ? min(size.width * 0.5, 400) : min(size.width * 0.85, 340)

        return Group {
            if let titleImage = UIImage(named: "apptitle") {
                Image(uiImage: titleImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: titleWidth)
                    .opacity(showButton ? 1 : 0)
                    .animation(.easeInOut(duration: 1.2).delay(1.5), value: showButton)
                    .accessibilityLabel("Cards of The Seven Sisters")
                    .accessibilityAddTraits(.isHeader)
            } else {
                VStack(spacing: 4) {
                    Text("CARDS OF THE")
                        .font(.custom("Iowan Old Style", size: dynamicFontSize(for: size, base: 36)))
                        .foregroundColor(AppTheme.primaryText)
                        .tracking(3)
                        .multilineTextAlignment(.center)
                        .opacity(showButton ? 1 : 0)
                        .animation(.easeInOut(duration: 1.0).delay(1.5), value: showButton)

                    Text("SEVEN SISTERS")
                        .font(.custom("Iowan Old Style", size: dynamicFontSize(for: size, base: 36)))
                        .foregroundColor(AppTheme.primaryText)
                        .tracking(3)
                        .multilineTextAlignment(.center)
                        .opacity(showButton ? 1 : 0)
                        .animation(.easeInOut(duration: 1.0).delay(1.7), value: showButton)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func cardAnimationArea(for size: CGSize) -> some View {
        let isIPad = size.width > 500
        let ellipseWidth = isIPad ? min(size.width * 0.45, 400) : min(size.width * 0.75, 320)
        let ellipseHeight = ellipseWidth * 0.75 // Maintain aspect ratio
        let scaleFactor = min(size.width / 390, 1.3) // Cap at 1.3 for iPad

        return ZStack {
            Ellipse()
                .fill(Color(UIColor { traitCollection in
                    traitCollection.userInterfaceStyle == .dark
                        ? UIColor(red: 0.49, green: 0.396, blue: 0.267, alpha: 0.70)  // #7D6544 dusky gold at 70% opacity in dark mode
                        : UIColor.black  // black in light mode (original)
                }))
                .frame(width: ellipseWidth, height: ellipseHeight)
                .scaleEffect(showCards ? 1.0 : 0.3)
                .animation(.easeOut(duration: 0.8).delay(0.5), value: showCards)
                .opacity(isTransitioning ? 0 : 1)
                .accessibilityHidden(true)
            
            ForEach(0..<cardNames.count, id: \.self) { index in
                if index != 3 {
                    VintageCardImageView(
                        imageName: cardImageNames[index],
                        isCenter: false,
                        scaleFactor: scaleFactor,
                        showSheen: showCardSheen,
                        sheenDelay: Double(index) * 0.15
                    )
                    .scaleEffect(cardScales[index])
                    .offset(cardOffsets[index])
                    .rotationEffect(.degrees(cardRotations[index]))
                    .animation(
                        .spring(response: 0.8, dampingFraction: 0.6)
                        .delay(Double(index) * 0.1 + 1.0),
                        value: cardScales[index]
                    )
                    .animation(
                        .spring(response: 0.8, dampingFraction: 0.6)
                        .delay(Double(index) * 0.1 + 1.0),
                        value: cardOffsets[index]
                    )
                    .opacity(isTransitioning ? 0 : 1)
                    .accessibilityHidden(true)
                }
            }

            VintageCardImageView(
                imageName: cardImageNames[3],
                isCenter: true,
                scaleFactor: scaleFactor,
                showSheen: showCardSheen,
                sheenDelay: 0.3
            )
            .scaleEffect(cardScales[3])
            .offset(cardOffsets[3])
            .rotationEffect(.degrees(cardRotations[3]))
            .animation(
                .spring(response: 0.8, dampingFraction: 0.6),
                value: cardScales[3]
            )
            .opacity(isTransitioning ? 0 : 1)
            .accessibilityHidden(true)
        }
        .frame(height: ellipseHeight + 50)
    }
    
    private var startButton: some View {
        Button(action: {
            isTransitioning = true
            onStart()
        }) {
            Text("Let's Begin")
                .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.headline))
                .fontWeight(.regular)
                .tracking(0.5)
                .foregroundColor(Color(UIColor { traitCollection in
                    traitCollection.userInterfaceStyle == .dark
                        ? UIColor(red: 0.855, green: 0.745, blue: 0.565, alpha: 1.0)  // #DABE90 matches app title gold
                        : UIColor.white  // White text on black button in light mode
                }))
                .padding(.horizontal, 50)
                .padding(.vertical, AppConstants.Spacing.medium)
                .background(Color(UIColor { traitCollection in
                    traitCollection.userInterfaceStyle == .dark
                        ? UIColor.black  // black background in dark mode
                        : UIColor.black.withAlphaComponent(0.7)  // black in light mode
                }))
                .overlay(
                    RoundedRectangle(cornerRadius: AppConstants.CornerRadius.button)
                        .stroke(Color(UIColor { traitCollection in
                            traitCollection.userInterfaceStyle == .dark
                                ? UIColor(red: 0.855, green: 0.745, blue: 0.565, alpha: 1.0)  // #DABE90 matches app title gold
                                : UIColor.clear  // no border in light mode
                        }), lineWidth: 1)
                )
                .overlay(
                    buttonSheenOverlay
                )
                .cornerRadius(AppConstants.CornerRadius.button)
                .multilineTextAlignment(.center)
        }
        .scaleEffect(1.0)
        .cardShadow(size: AppConstants.CardSizes.large)
        .opacity(showButton && !isTransitioning ? 1 : 0)
        .animation(.easeInOut(duration: 1.0).delay(2.5), value: showButton)
        .animation(.easeOut(duration: 0.3), value: isTransitioning)
        .accessibilityLabel("Let's Begin")
        .accessibilityHint("Start using the app")
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    private var buttonSheenOverlay: some View {
        if colorScheme == .dark {
            GeometryReader { geometry in
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: .clear, location: 0.0),
                                .init(color: .clear, location: 0.35),
                                .init(color: .white.opacity(0.25), location: 0.48),
                                .init(color: .white.opacity(0.4), location: 0.5),
                                .init(color: .white.opacity(0.25), location: 0.52),
                                .init(color: .clear, location: 0.65),
                                .init(color: .clear, location: 1.0)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * 2.5, height: geometry.size.height * 3)
                    .rotationEffect(.degrees(25))
                    .offset(x: buttonSheenPosition * geometry.size.width * 1.5)
            }
            .clipped()
            .allowsHitTesting(false)
        }
    }
    
    private func startAnimation(for size: CGSize) {
        let scaleFactor = min(size.width / 390, 1.3) // Cap at 1.3 for iPad

        // Center card animates in first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            cardScales[3] = 1.0
            cardOffsets[3] = .zero
            cardRotations[3] = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showCards = true

            // Responsive card positions based on screen width
            let positions: [CGSize] = [
                CGSize(width: -120 * scaleFactor, height: -30 * scaleFactor),
                CGSize(width: -80 * scaleFactor, height: 40 * scaleFactor),
                CGSize(width: -40 * scaleFactor, height: -60 * scaleFactor),
                CGSize(width: 0, height: 0),
                CGSize(width: 40 * scaleFactor, height: -60 * scaleFactor),
                CGSize(width: 80 * scaleFactor, height: 40 * scaleFactor),
                CGSize(width: 120 * scaleFactor, height: -30 * scaleFactor)
            ]

            let rotations: [Double] = [-25, -15, -10, 0, 10, 15, 25]

            for index in 0..<cardNames.count {
                if index != 3 {
                    cardScales[index] = 1.0
                    cardOffsets[index] = positions[index]
                    cardRotations[index] = rotations[index]
                }
            }
        }

        // Button appears after cards settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            showButton = true
        }

        // Trigger card sheen after button fully visible (dark mode only)
        // Button: showButton at 1.2s + 2.5s delay + 1.0s fade = 4.7s
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            showCardSheen = true
        }

        // Trigger button sheen after card sheen completes (dark mode only)
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.5) {
            withAnimation(.easeInOut(duration: 3.5)) {
                buttonSheenPosition = 1.0
            }
        }
    }
    
    private func dynamicFontSize(for size: CGSize, base: CGFloat) -> CGFloat {
        let scaleFactor = min(size.width / 390, 1.2) // Don't scale up too much on iPads
        return base * scaleFactor
    }
}

struct VintageCardImageView: View {
    let imageName: String
    let isCenter: Bool
    let scaleFactor: CGFloat
    var showSheen: Bool = false
    var sheenDelay: Double = 0

    @Environment(\.colorScheme) private var colorScheme
    @State private var sheenPosition: CGFloat = -1.0

    private var cappedScale: CGFloat {
        min(scaleFactor, 1.3)
    }

    private var cardWidth: CGFloat {
        let baseWidth: CGFloat = isCenter ? 121 : 91
        return baseWidth * cappedScale
    }

    private var cardHeight: CGFloat {
        let baseHeight: CGFloat = isCenter ? 170 : 128
        return baseHeight * cappedScale
    }

    var body: some View {
        Group {
            if let image = ImageManager.shared.loadCardImage(named: imageName) {
                if colorScheme == .dark {
                    // Dark mode style with sheen
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .scaleEffect(1.00)
                        .frame(width: cardWidth, height: cardHeight)
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.small))
                        .overlay(
                            cardSheenOverlay
                        )
                        .scaleEffect(0.95)
                        .cardShadow(size: CGSize(width: cardWidth, height: cardHeight))
                        .accessibilityHidden(true)
                } else {
                    // Light mode style (from Documents version)
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: cardWidth, height: cardHeight)
                        .scaleEffect(1.08)
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.small))
                        .cardShadow(size: CGSize(width: cardWidth, height: cardHeight))
                        .accessibilityHidden(true)
                }
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: AppConstants.CornerRadius.small)
                        .fill(Color.white)
                        .frame(width: cardWidth, height: cardHeight)
                        .cardShadow(size: CGSize(width: cardWidth, height: cardHeight))

                    VStack {
                        Text(AppConstants.Strings.missingImage)
                            .font(.system(size: AppConstants.FontSizes.caption * scaleFactor))
                            .foregroundColor(.red)
                        Text(imageName)
                            .font(.system(size: AppConstants.FontSizes.caption * scaleFactor, weight: .heavy))
                            .foregroundColor(AppTheme.primaryText)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.small))
            }
        }
        .onChange(of: showSheen) { _, newValue in
            if newValue && colorScheme == .dark {
                DispatchQueue.main.asyncAfter(deadline: .now() + sheenDelay) {
                    withAnimation(.easeInOut(duration: 1.5)) {
                        sheenPosition = 1.0
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var cardSheenOverlay: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: .clear, location: 0.42),
                            .init(color: .white.opacity(0.2), location: 0.48),
                            .init(color: .white.opacity(0.35), location: 0.5),
                            .init(color: .white.opacity(0.2), location: 0.52),
                            .init(color: .clear, location: 0.58),
                            .init(color: .clear, location: 1.0)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: geometry.size.width * 3)
                .rotationEffect(.degrees(25))
                .offset(x: sheenPosition * geometry.size.width * 2)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.small))
        .allowsHitTesting(false)
    }
}
#Preview {
    VintageSplashView(onStart: {})
}

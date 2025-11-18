import SwiftUI

struct VintageSplashView: View {
    let onStart: () -> Void

    @State private var showCards = false
    @State private var showButton = false
    @State private var isTransitioning = false
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
                        .padding(.bottom, geometry.size.height * 0.1) // 10% from bottom
                    
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
        let titleWidth = min(size.width * 0.85, 340) // 85% of screen width, max 340
        
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
        let ellipseWidth = min(size.width * 0.75, 320) // 80% of screen width, max 320
        let ellipseHeight = ellipseWidth * 0.75 // Maintain aspect ratio
        let scaleFactor = size.width / 390 // iPhone 14 Pro width as base
        
        return ZStack {
            Ellipse()
                .fill(AppTheme.darkAccent)
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
                        scaleFactor: scaleFactor
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
                scaleFactor: scaleFactor
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
                .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                .tracking(0.5)
                .foregroundColor(.white)
                .padding(.horizontal, 50)
                .padding(.vertical, AppConstants.Spacing.medium)
                .background(AppTheme.darkAccent.opacity(0.7))
                .cornerRadius(AppConstants.CornerRadius.button)
                .multilineTextAlignment(.center)
        }
        .scaleEffect(1.0)
        .cardShadow(isLarge: true)
        .opacity(showButton ? 1 : 0)
        .animation(.easeInOut(duration: 1.0).delay(2.5), value: showButton)
    }
    
    private func startAnimation(for size: CGSize) {
        let scaleFactor = size.width / 390 // iPhone 14 Pro width as base
        
        cardScales[3] = 1.0
        cardOffsets[3] = .zero
        cardRotations[3] = 0
        
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            showButton = true
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
    
    private var cardWidth: CGFloat {
        let baseWidth: CGFloat = isCenter ? 121 : 91
        return baseWidth * scaleFactor
    }
    
    private var cardHeight: CGFloat {
        let baseHeight: CGFloat = isCenter ? 170 : 128
        return baseHeight * scaleFactor
    }
    
    var body: some View {
        Group {
            if let image = ImageManager.shared.loadCardImage(named: imageName) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: cardWidth, height: cardHeight)
                    .scaleEffect(1.05)
                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.small))
                    .cardShadow()
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: AppConstants.CornerRadius.small)
                        .fill(Color.white)
                        .frame(width: cardWidth, height: cardHeight)
                        .cardShadow()
                    
                    VStack {
                        Text(AppConstants.Strings.missingImage)
                            .font(.system(size: AppConstants.FontSizes.caption * scaleFactor))
                            .foregroundColor(.red)
                        Text(imageName)
                            .font(.system(size: AppConstants.FontSizes.caption * scaleFactor, weight: .heavy))
                            .foregroundColor(.black)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.small))
            }
        }
    }
}
#Preview {
    VintageSplashView(onStart: {})
}

import SwiftUI
import UIKit

struct AppConstants {

    // MARK: - Screen Scaling (iPhone 16 as design reference: 393 x 852 points)

    struct Scaling {
        /// Design reference device dimensions (iPhone 16)
        private static let referenceWidth: CGFloat = 393.0
        private static let referenceHeight: CGFloat = 852.0

        /// Current screen dimensions
        private static var screenWidth: CGFloat {
            UIScreen.main.bounds.width
        }

        private static var screenHeight: CGFloat {
            UIScreen.main.bounds.height
        }

        /// Width-based scale factor (iPhone 16 = 1.0, iPhone 17 Pro Max ≈ 1.12)
        static var widthScale: CGFloat {
            screenWidth / referenceWidth
        }

        /// Height-based scale factor
        static var heightScale: CGFloat {
            screenHeight / referenceHeight
        }

        /// Average scale factor (balanced)
        static var scale: CGFloat {
            (widthScale + heightScale) / 2.0
        }

        /// Minimum scale (more conservative, prevents over-scaling)
        static var minScale: CGFloat {
            min(widthScale, heightScale)
        }

        // MARK: - Scaling Functions

        /// Scale width value for current screen
        static func w(_ value: CGFloat) -> CGFloat {
            value * widthScale
        }

        /// Scale height value for current screen
        static func h(_ value: CGFloat) -> CGFloat {
            value * heightScale
        }

        /// Scale value using average scale
        static func s(_ value: CGFloat) -> CGFloat {
            value * scale
        }

        /// Scale font size (uses minScale to prevent oversized text)
        static func font(_ fontSize: CGFloat) -> CGFloat {
            fontSize * minScale
        }

        /// Scale spacing/padding
        static func spacing(_ spacing: CGFloat) -> CGFloat {
            spacing * scale
        }

        /// Scale CGSize proportionally
        static func size(_ size: CGSize) -> CGSize {
            CGSize(width: w(size.width), height: h(size.height))
        }
    }

    
    struct CardSizes {
        static let aspect: CGFloat = 3.5 / 2.5 // ≈ 1.4

        // Design reference sizes (for iPhone 16)
        private static let extraLargeBase = CGSize(width: 202, height: 284)
        private static let largeWidthBase: CGFloat = 156
        private static let mediumWidthBase: CGFloat = 120
        private static let smallWidthBase: CGFloat = 91
        private static let tinyWidthBase: CGFloat = 80
        private static let detailHeightBase: CGFloat = 300
        private static let detailHeightCollapsedBase: CGFloat = 150

        // Maximum sizes to prevent overlap with text (safety constraints)
        private static let maxDailyCardHeight: CGFloat = 520 // Prevents overlap with "Tap Card to Reveal"

        // Scaled sizes for current screen
        static var extraLarge: CGSize {
            Scaling.size(extraLargeBase)
        }

        // Extra large with max height constraint (for daily card on home screen)
        static var extraLargeSafe: CGSize {
            let scaled = Scaling.size(extraLargeBase)
            let height = min(scaled.height, maxDailyCardHeight)
            let width = height / aspect
            return CGSize(width: width, height: height)
        }

        static var largeWidth: CGFloat {
            Scaling.w(largeWidthBase)
        }

        static var large: CGSize {
            CGSize(width: largeWidth, height: largeWidth * aspect)
        }

        // Large paired cards (for daily view side-by-side layout) - 5% smaller than large
        private static let largePairedWidthBase: CGFloat = 148  // 156 * 0.95

        static var largePairedWidth: CGFloat {
            Scaling.w(largePairedWidthBase)
        }

        static var largePaired: CGSize {
            CGSize(width: largePairedWidth, height: largePairedWidth * aspect)
        }

        static var mediumWidth: CGFloat {
            Scaling.w(mediumWidthBase)
        }

        static var medium: CGSize {
            CGSize(width: mediumWidth, height: mediumWidth * aspect)
        }

        static var smallWidth: CGFloat {
            Scaling.w(smallWidthBase)
        }

        static var small: CGSize {
            CGSize(width: smallWidth, height: smallWidth * aspect)
        }

        static var tinyWidth: CGFloat {
            Scaling.w(tinyWidthBase)
        }

        static var tiny: CGSize {
            CGSize(width: tinyWidth, height: tinyWidth * aspect)
        }

        static var detailHeight: CGFloat {
            Scaling.h(detailHeightBase)
        }

        static var detailHeightCollapsed: CGFloat {
            Scaling.h(detailHeightCollapsedBase)
        }

        // Aliases for clarity
        static var portraitLarge: CGSize { large }
        static var portraitMedium: CGSize { medium }
        static var portraitSmall: CGSize { small }
        static var portraitTiny: CGSize { tiny }
    }
    
    struct CardStyle {
        /// All card visual properties scale proportionally from card width.
        /// 6% matches physical playing card corner-to-width ratio.
        static func cornerRadius(for size: CGSize) -> CGFloat {
            (size.width * 0.06).rounded()
        }
        static func shadowRadius(for size: CGSize) -> CGFloat {
            max(2, (size.width * 0.025).rounded())
        }
        static func shadowOffset(for size: CGSize) -> CGSize {
            CGSize(width: 0, height: max(1, (size.width * 0.015).rounded()))
        }
        static func glowRadius(for size: CGSize) -> CGFloat {
            (size.width * 0.06).rounded()
        }
    }
    
    struct Animation {
        static let cardDetailDuration: Double = 0.5
        static let cardDetailFastDuration: Double = 0.4
        static let springResponse: Double = 0.55
        static let springDamping: Double = 0.8
        static let fadeInDuration: Double = 1.0
        static let pulseScale: CGFloat = 1.08
        static let pulseDuration: Double = 0.6
        
        static let detailShowDelay: Double = 0.2
        static let detailDismissDelay: Double = 0.4
        
        static let reducedMotionDuration: Double = 0.2
        static let reducedMotionSpring: Double = 0.3
    }
    
    struct Spacing {
        // ==============================================
        // TYPOGRAPHIC SPACING SCALE (12 / 18 / 28 / 40)
        // Creates consistent vertical rhythm for book-like layouts
        // ==============================================
        private static let tightBase: CGFloat = 12      // title → subtitle, label → field
        private static let ornamentBase: CGFloat = 18   // around dividers, medium gaps
        private static let sectionBase: CGFloat = 28    // between major content blocks
        private static let pageBase: CGFloat = 40       // large gaps, page-level separation
        private static let pageInsetBase: CGFloat = 24  // outer page margins
        private static let cardPaddingBase: CGFloat = 20 // inner card/modal padding

        // New typographic scale
        static var tight: CGFloat { Scaling.spacing(tightBase) }
        static var ornament: CGFloat { Scaling.spacing(ornamentBase) }
        static var section: CGFloat { Scaling.spacing(sectionBase) }
        static var page: CGFloat { Scaling.spacing(pageBase) }
        static var pageInset: CGFloat { Scaling.spacing(pageInsetBase) }
        static var cardPadding: CGFloat { Scaling.spacing(cardPaddingBase) }

        // ==============================================
        // LEGACY VALUES (for backward compatibility)
        // ==============================================
        private static let tinyBase: CGFloat = 4
        private static let smallBase: CGFloat = 8
        private static let mediumBase: CGFloat = 16
        private static let largeBase: CGFloat = 24
        private static let extraLargeBase: CGFloat = 40
        private static let cardSpacingBase: CGFloat = 40
        private static let sectionSpacingBase: CGFloat = 20
        private static let titleSpacingBase: CGFloat = 8

        static var tiny: CGFloat { Scaling.spacing(tinyBase) }
        static var small: CGFloat { Scaling.spacing(smallBase) }
        static var medium: CGFloat { Scaling.spacing(mediumBase) }
        static var large: CGFloat { Scaling.spacing(largeBase) }
        static var extraLarge: CGFloat { Scaling.spacing(extraLargeBase) }
        static var cardSpacing: CGFloat { Scaling.spacing(cardSpacingBase) }
        static var sectionSpacing: CGFloat { Scaling.spacing(sectionSpacingBase) }
        static var titleSpacing: CGFloat { Scaling.spacing(titleSpacingBase) }
    }
    
    struct CornerRadius {
        static let modal: CGFloat = 25
        static let button: CGFloat = 25
        static let small: CGFloat = 10
    }

    struct Colors {
        /// Standard capsule button background color (adaptive tan/beige)
        static let capsuleButton = Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.35, green: 0.30, blue: 0.24, alpha: 1.0)  // dark tan
                : UIColor(red: 0.90, green: 0.83, blue: 0.67, alpha: 1.0)  // tan
        })
    }

    struct ButtonSizes {
        /// Close button size (X buttons)
        static let closeButton: CGFloat = 44
        /// Back button size (chevron buttons)
        static let backButton: CGFloat = 44
    }
    
    struct FontSizes {
        static func dynamicSize(for textStyle: UIFont.TextStyle) -> CGFloat {
            UIFont.preferredFont(forTextStyle: textStyle).pointSize
        }

        // Design reference font sizes (for iPhone 16)
        private static let extraLargeBase: CGFloat = 32
        private static let largeBase: CGFloat = 25
        private static let titleBase: CGFloat = 21
        private static let headlineBase: CGFloat = 20
        private static let subheadlineBase: CGFloat = 18
        private static let bodyBase: CGFloat = 16
        private static let calloutBase: CGFloat = 14
        private static let captionBase: CGFloat = 11

        // Scaled font sizes for current screen
        static var extraLarge: CGFloat { Scaling.font(extraLargeBase) }
        static var large: CGFloat { Scaling.font(largeBase) }
        static var title: CGFloat { Scaling.font(titleBase) }
        static var headline: CGFloat { Scaling.font(headlineBase) }
        static var subheadline: CGFloat { Scaling.font(subheadlineBase) }
        static var body: CGFloat { Scaling.font(bodyBase) }
        static var callout: CGFloat { Scaling.font(calloutBase) }
        static var caption: CGFloat { Scaling.font(captionBase) }

        // Dynamic font sizes (system-based, already scales)
        static var dynamicExtraLarge: CGFloat {
            dynamicSize(for: .largeTitle)
        }
        static var dynamicLarge: CGFloat {
            dynamicSize(for: .title1)
        }
        static var dynamicTitle: CGFloat {
            dynamicSize(for: .title2)
        }
        static var dynamicHeadline: CGFloat {
            dynamicSize(for: .headline)
        }
        static var dynamicBody: CGFloat {
            dynamicSize(for: .body)
        }
    }

    // MARK: - Typography (Line Spacing & Paragraph Rhythm)

    struct Typography {
        /// Standard line spacing for body text (~1.35 line height ratio)
        static let bodyLineSpacing: CGFloat = 5

        /// Increased line spacing for iPad/larger displays
        static let bodyLineSpacingLarge: CGFloat = 7

        /// Paragraph spacing between text blocks
        static let paragraphSpacing: CGFloat = 12

        /// Returns appropriate line spacing based on device
        static var adaptiveLineSpacing: CGFloat {
            UIDevice.current.userInterfaceIdiom == .pad ? bodyLineSpacingLarge : bodyLineSpacing
        }
    }

    struct Shadow {
        static let cardOpacity: Double = 0.15
        static let detailOpacity: Double = 0.3
        static let overlayOpacity: Double = 0.5
    }

    // MARK: - Dark Mode Effects

    /// Constants for dark mode visual effects on cards
    struct DarkModeEffects {
        // Gold glow opacity — radius is derived via CardStyle.glowRadius(for:)
        static let glowOpacitySmall: Double = 0.45
        static let glowOpacityLarge: Double = 0.5

        // Gloss effect settings
        static let glossIntensity: Double = 0.4
        static let maxRotationDegrees: Double = 3.0
    }
    
    struct Strings {
        static let close = "Close"
        static let reset = "Reset"
        static let tapToReveal = "Tap Card to Reveal"
        static let welcome = "Welcome"
        static let yourDailyCard = "TODAY'S CARD"
        static let karmaConnections = "Life Connections"
        static let birthCard = "Birth Card"
        static let yearlyCard = "Yearly Card"
        static let lastYear = "Last Year"
        static let nextYear = "Next Year"
        static let fiftyTwoDayCycle = "52-Day Card"
        static let lastFiftyTwoDays = "Last 52 Days"
        static let nextFiftyTwoDays = "Next 52 Days"
        static let dailyInfluence = "Your Daily Card"
        static let yearlyInfluence = "Your Yearly Spread"
        static let fiftyTwoDayInfluence = "Your 52-Day Card"
        static let exploring = "Exploring Cards for"
        static let missingImage = "Missing:"
    }
    
    struct Accessibility {
        static let minimumTouchTarget: CGFloat = 44
        
        struct Labels {
            static func cardLabel(rank: String, suit: String) -> String {
                "\(rank) of \(suit)"
            }
            static let shareButton = "Share card"
            static let backButton = "Go back"
            static let settingsButton = "Settings"
            static let closeModal = "Close card details"
            static let revealCard = "Reveal Today's Card"
            static let viewCard = "View card details"
        }
        
        struct Hints {
            static let doubleTapToView = "Double tap to view details"
            static let doubleTapToReveal = "Double Tap Card to Reveal"
            static let doubleTapToShare = "Double tap to share"
            static let doubleTapToClose = "Double tap to close"
            static let doubleTapToOpen = "Double tap to open"
        }
        
        struct Identifiers {
            static let dailyCard = "daily_card"
            static let birthCard = "birth_card"
            static let yearlyCard = "yearly_card"
            static let shareButton = "share_button"
            static let settingsButton = "settings_button"
            static let backButton = "back_button"
            static let closeButton = "close_button"
        }
        
        struct Contrast {
            static let minimumNormalText: Double = 4.5
            static let minimumLargeText: Double = 3.0
        }
    }
    
    struct PlanetDescriptions {
        static func getDescription(for planet: String) -> (title: String, description: String) {
            switch planet.lowercased() {
            case "mercury":
                return ("Exploration & Curiosity", "Mercury is the quicksilver of the cosmos: restless, bright, and endlessly adaptable. As it’s associated with the mind and the early years of life, you may notice this period is full of beginnings and fresh ideas. Ideas can be found all around you and new thoughts waiting at the edge of your consciousness, so keep your ear to the ground. Closest to the Sun, this is always the first planetary period of a new cycle and represents the mind. Treat it like a calibration window. Is your mind at peace?")
            case "venus":
                return ("Personal Magnetism", "Venus is the principle of attraction: what you value, you magnetize. This period invites you to examine alignment between your inner worth and outer choices. Where are you calling in what matters? To take advantage of this cycle: polish the barrier between you and the world, simplify what steals your calm, and make room to receive. Ask: Where would a small act of beauty or clearer boundary change the shape of this year? Who deserves genuine appreciation from you now, and are you allowing yourself to be valued in return?")
            case "mars":
                return ("Initiate with Passion", "Mars is the planet of bold ignition: stamina, courage, and concentrated will. First, you might feel it in the body—the itch to move, make, or master. Then it strikes the mind, flooding it with sharp ideas. This period marks a stark shift from what came before. While Mars is physical, its influence now strengthens your mental and intuitive circuits. Activates quick thinking, imagination, and the kind of high-voltage clarity that makes strategies and schemes flow like lightning. It’s an excellent window for writing, invention, repairs, business planning, and mental artistry. Think: screenplays, startups, blueprints. This is also the realm of mechanical and technical skills, engineering, competitive sports, defense, and tactical leadership. Precision matters.")
            case "jupiter":
                return ("Growth Pattern", "Jupiter is the principle of growth, expansion, and possibility. It magnifies opportunities that require vision and courage, encourages optimism, and invites you to step into a broader vision of what life can be. Jupiter reminds us that progress often comes by saying yes to growth, learning, and the courage to aim higher.")
            case "saturn":
                return ("Structure & Mastery", "Saturn is the principle of accountability, discipline, and structure. It brings focus to responsibility and endurance. It asks us to prioritize the long-term work of building something that lasts.\n\nIts influence can feel heavy at times, yet it clarifies where commitment and persistence yield real strength. Saturn reminds us that growth often comes through limits, challenges, and the steady practice of integrity.")
            case "uranus":
                return ("Breakthroughs & Innovation", "Uranus is the principle of disruption, innovation, and awakening. It is known to challenge convention, and sparks sudden shifts that open new possibilities.\n\nIts influence can feel unexpected, but it clears space for originality, independence, and higher truth. Uranus reminds us that breakthroughs often require shaking loose what no longer fits.")
            case "neptune":
                return ("Integration & Transcendence", "Neptune is the principle of vision, intuition, and imagination. It dissolves boundaries, heightens sensitivity, and opens awareness to realms beyond the ordinary. Its influence can blur lines between clarity and illusion, but also provides access to inspiration, compassion, and deep inner truth.Neptune reminds us that meaning is often found by looking inward, trusting subtle signals, and creating from a place of openness.")
            case "pluto":
                return ("The Transformer", "Pluto represents transformation, power, and rebirth. This planet affects deep psychological changes and your ability to regenerate and evolve.")
            default:
                return ("The Unknown", "This planetary influence brings unique energies and lessons into your experience.")
            }
        }
    }}

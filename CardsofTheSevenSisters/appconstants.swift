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
        private static let maxDailyCardHeight: CGFloat = 520 // Prevents overlap with "Tap To Reveal"

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
        /// Returns the recommended corner radius constant for a given card size.
        /// Uses width comparisons with a small tolerance to avoid floating errors.
        static func cornerRadius(for size: CGSize) -> CGFloat {
            let w = size.width
            // Large silhouettes
            if abs(w - AppConstants.CardSizes.extraLarge.width) < 0.5 ||
                abs(w - AppConstants.CardSizes.large.width) < 0.5 {
                return AppConstants.CornerRadius.cardLarge
            }
            // Medium/small silhouettes
            if abs(w - AppConstants.CardSizes.medium.width) < 0.5 ||
                abs(w - AppConstants.CardSizes.small.width) < 0.5 ||
                abs(w - AppConstants.CardSizes.tiny.width) < 0.5 {
                return AppConstants.CornerRadius.card
            }
            // Default to small radius if unknown
            return AppConstants.CornerRadius.card
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
        // Design reference spacing (for iPhone 16)
        private static let tinyBase: CGFloat = 4
        private static let smallBase: CGFloat = 8
        private static let mediumBase: CGFloat = 16
        private static let largeBase: CGFloat = 24
        private static let extraLargeBase: CGFloat = 40
        private static let cardSpacingBase: CGFloat = 40
        private static let sectionSpacingBase: CGFloat = 20
        private static let titleSpacingBase: CGFloat = 8

        // Scaled spacing for current screen
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
        static let card: CGFloat = 12
        static let cardLarge: CGFloat = 12
        static let cardDetail: CGFloat = 16
        static let modal: CGFloat = 25
        static let button: CGFloat = 25
        static let small: CGFloat = 10
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
    
    struct Shadow {
        static let cardOpacity: Double = 0.15
        static let cardRadius: CGFloat = 3
        static let cardOffset = CGSize(width: 0, height: 2)
        
        static let detailOpacity: Double = 0.3
        static let detailRadius: CGFloat = 10
        static let detailOffset = CGSize(width: 0, height: 5)
        
        static let overlayOpacity: Double = 0.5
    }
    
    struct Strings {
        static let close = "Close"
        static let reset = "Reset"
        static let tapToReveal = "Tap To Reveal"
        static let welcome = "Welcome"
        static let yourDailyCard = "TODAY'S CYCLE"
        static let karmaConnections = "Life Connections"
        static let lastCycle = "Your Last Cycle"
        static let nextCycle = "Your Next Cycle"
        static let birthCard = "Birth Card"
        static let yearlyCard = "Yearly Cycle"
        static let fiftyTwoDayCycle = "52-Day Cycle"
        static let dailyInfluence = "Today's Cycle"
        static let yearlyInfluence = "Your Yearly Spread"
        static let fiftyTwoDayInfluence = "Your 52-Day Spread"
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
            static let revealCard = "Reveal Today's Cycle"
            static let viewCard = "View card details"
        }
        
        struct Hints {
            static let doubleTapToView = "Double tap to view details"
            static let doubleTapToReveal = "Double tap to reveal"
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
                return ("Exploration & Curiosity", "Mercury is the quicksilver of the cosmos—restless, bright, and endlessly adaptable. It sparks beginnings of thought, words, and action, rippling outward into connections, choices, and fresh momentum.\n\nMercury is the force of change and renewal, moving swiftly through both mind and matter.")
            case "venus":
                return ("Personal Magnetism", "Venus's influence is magnetic, drawing attention to where balance, care, and intentionality can transform both inner and outer worlds.\n\nIt invites us to align our choices with what we truly value, to recognize the worth in ourselves and others, and to allow beauty and harmony to guide how we create, relate, and live.")
            case "mars":
                return ("Initiate with Passion", "Mars is the principle of drive, courage, and decisive action. It sharpens ambition, fuels competitive spirit, and directs energy toward movement and achievement.\n\nIts influence tests our willingness to take risks, face conflict, and apply determination in pursuit of progress.\n\nIf you're looking for a sign to begin something new, Mars reminds us that momentum is built by acting with clarity and purpose.")
            case "jupiter":
                return ("Growth Pattern", "Jupiter is the principle of growth, expansion, and possibility. It magnifies opportunities that require vision and courage, encourages optimism, and invites you to step into a broader vision of what life can be.\n\nJupiter reminds us that progress often comes by saying yes to growth, learning, and the courage to aim higher.")
            case "saturn":
                return ("Structure & Mastery", "Saturn is the principle of accountability, discipline, and structure. It brings focus to responsibility, endurance, and the long-term work of building something lasting.\n\nIts influence can feel heavy at times, yet it clarifies where commitment and persistence yield real strength.\n\nSaturn reminds us that growth often comes through limits, challenges, and the steady practice of integrity.")
            case "uranus":
                return ("Breakthroughs & Innovation", "Uranus is the principle of disruption, innovation, and awakening. It breaks patterns, challenges convention, and sparks sudden shifts that open new possibilities.\n\nIts influence can feel unexpected, but it clears space for originality, independence, and higher truth.\n\nUranus reminds us that breakthroughs often require shaking loose what no longer fits.")
            case "neptune":
                return ("Integration & Transcendence", "Neptune is the principle of vision, intuition, and imagination. It dissolves boundaries, heightens sensitivity, and opens awareness to realms beyond the ordinary.\n\nIts influence can blur lines between clarity and illusion, but also provides access to inspiration, compassion, and deep inner truth.\n\nNeptune reminds us that meaning is often found by looking inward, trusting subtle signals, and creating from a place of openness.")
            case "pluto":
                return ("The Transformer", "Pluto represents transformation, power, and rebirth. This planet affects deep psychological changes and your ability to regenerate and evolve.")
            default:
                return ("The Unknown", "This planetary influence brings unique energies and lessons into your experience.")
            }
        }
    }}




import SwiftUI
import UIKit
import LinkPresentation
import AuthenticationServices

// MARK: - Justified Text View (for block text alignment)

struct JustifiedTextView: UIViewRepresentable {
    let attributedText: NSAttributedString
    let textColor: UIColor

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .justified
        label.lineBreakMode = .byWordWrapping
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }

    func updateUIView(_ uiView: UILabel, context: Context) {
        let mutableAttr = NSMutableAttributedString(attributedString: attributedText)

        // Apply paragraph style for justification
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .justified
        paragraphStyle.lineSpacing = 4

        mutableAttr.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: mutableAttr.length))

        uiView.attributedText = mutableAttr
    }
}

// MARK: - Guest Share Blocked View

struct GuestShareBlockedView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var authManager = AuthenticationManager.shared

    var body: some View {
        ZStack {
            // Blurred background
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "square.and.arrow.up.trianglebadge.exclamationmark")
                    .font(.system(size: 50))
                    .foregroundColor(.white)

                Text("Feature not available for Guest Users")
                    .font(.custom("Iowan Old Style", size: 20))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("Please register for access.")
                    .font(.custom("Iowan Old Style", size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)

                SignInWithAppleButton(
                    .signIn,
                    onRequest: { request in
                        request.requestedScopes = [.email, .fullName]
                    },
                    onCompletion: { result in
                        authManager.handleAuthorization(result)
                        if case .success = result {
                            // Clear guest mode when signing in
                            DataManager.shared.isGuestMode = false
                            dismiss()
                        }
                    }
                )
                .signInWithAppleButtonStyle(.white)
                .frame(height: 44)
                .frame(width: 240)
                .cornerRadius(8)
                .overlay(
                    AnimatedGoldBorder(cornerRadius: 8)
                )
                .padding(.top, 10)

                Button("Cancel") {
                    dismiss()
                }
                .font(.custom("Iowan Old Style", size: 16))
                .foregroundColor(.white.opacity(0.8))
                .padding(.top, 10)
            }
            .padding(30)
        }
    }
}

// MARK: - Core Share Content Model

struct ShareCardContent: Identifiable, Hashable {
    var id: UUID = .init()
    var title: String
    var subtitle: String
    var excerpt: String
    var date: Date
    var image: Image

    static func == (lhs: ShareCardContent, rhs: ShareCardContent) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Export Size

enum ShareCardExportSize: CaseIterable {
    case portrait1080x1350
    case square1200
    case story1080x1920

    var dimensions: CGSize {
        switch self {
        case .portrait1080x1350:
            return CGSize(width: 1080, height: 1350)
        case .square1200:
            return CGSize(width: 1200, height: 1200)
        case .story1080x1920:
            return CGSize(width: 1080, height: 1920)
        }
    }

    var aspectRatio: CGFloat {
        let size = dimensions
        return size.width / size.height
    }
}

// MARK: - Share Output Format (for choosing export size)
enum ShareExportFormat {
    case square1200
    case portrait1080x1440
    case deviceScreen

    var proposedSize: CGSize {
        switch self {
        case .square1200:
            return CGSize(width: 1200, height: 1200)
        case .portrait1080x1440:
            return CGSize(width: 1080, height: 1440)
        case .deviceScreen:
            let size = UIScreen.main.bounds.size
            return CGSize(width: size.width, height: size.height)
        }
    }
}

// MARK: - Single Card Share (Birth / Yearly / etc.)

struct SingleCardShareView: View {
    let card: Card
    let cardTitle: String
    let cardDescription: String
    let spreadType: String // e.g., "Birth Card", "Yearly Card"
    let subtitle: String?   // Optional subtitle like date or year
    let overrideImage: UIImage?

    private let inkColor = Color.black
    private let backgroundColor = Color(red: 0.86, green: 0.77, blue: 0.57)

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Header
                VStack(spacing: 4) {
                    Text("\(spreadType)")
                        .font(.custom("Iowan Old Style", size: 38))
                        .fontWeight(.bold)
                        .foregroundColor(inkColor)

                    // Subtitle - larger and bold
                    Text("by Cards of The Seven Sisters")
                        .font(.custom("Iowan Old Style", size: 32))
                        .fontWeight(.bold)
                        .foregroundColor(inkColor.opacity(0.85))

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.custom("Iowan Old Style", size: 18))
                            .foregroundColor(inkColor.opacity(0.7))
                            .padding(.top, 2)
                    }
                }

                // Line design above card
                if let lineImage = UIImage(named: "linedesign") {
                    Image(uiImage: lineImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 160)
                        .padding(.vertical, 4)
                }

                // Card image
                VStack(spacing: 12) {
                    if let overrideImage = overrideImage {
                        Image(uiImage: overrideImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 320)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                    } else if let cardImage = ImageManager.shared.loadCardImage(for: card) {
                        Image(uiImage: cardImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 320)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                    }
                }

                // Line design below card
                if let lineImage = UIImage(named: "linedesignd") {
                    Image(uiImage: lineImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 160)
                        .padding(.vertical, 4)
                }

                // Card description - first paragraph only, bold card name
                boldedTextSingle(firstParagraphSingle(cardDescription), boldWord: cardTitle, fontSize: 28)
                    .lineSpacing(1)
                    .frame(maxWidth: 1000, alignment: .leading)
                    .padding(.horizontal, 40)

                Spacer()

                // Footer blurb - 22pt
                Text("The Cards of The Seven Sisters App helps to translate the archetypes of each cycle to help you identify rhythms for personal growth and rest across areas of your life. No divination, no prediction.")
                    .font(.custom("Iowan Old Style", size: 22))
                    .foregroundColor(inkColor.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                // Footer CTA - 28pt bold
                Text("find yours at sevensisters.cards")
                    .font(.custom("Iowan Old Style", size: 28))
                    .fontWeight(.bold)
                    .foregroundColor(inkColor)
                    .padding(.bottom, 20)
            }
            .padding(40)
        }
        .frame(width: 1200, height: 1200)
    }

    // Get only the first paragraph of text
    private func firstParagraphSingle(_ text: String) -> String {
        let paragraphs = text.components(separatedBy: "\n\n")
        return paragraphs.first ?? text
    }

    // Helper to bold a word within text
    private func boldedTextSingle(_ text: String, boldWord: String, fontSize size: CGFloat) -> Text {
        let font = Font.custom("Iowan Old Style", size: size)
        let boldFont = Font.custom("Iowan Old Style", size: size).bold()

        if let range = text.range(of: boldWord, options: .caseInsensitive) {
            let before = String(text[..<range.lowerBound])
            let match = String(text[range])
            let after = String(text[range.upperBound...])

            return Text(before).font(font).foregroundColor(Color.black) +
                   Text(match).font(boldFont).foregroundColor(Color.black) +
                   Text(after).font(font).foregroundColor(Color.black)
        } else {
            return Text(text).font(font).foregroundColor(Color.black)
        }
    }
}

// MARK: - fiftytwo Cycle (Card + Planet spread)

struct fiftytwoCycleShareView: View {
    // Core content
    let cycleCard: Card
    let cycleCardTitle: String
    let cycleCardDescription: String
    let planetName: String
    let planetTitle: String
    let planetDescription: String
    let cycleInfo: String // e.g., "Mercury Phase – Jan 1 to Feb 21"

    // Presentation labels (editable)
    let headerTitle: String
    let headerSubtitle: String
    let contextLabel: String? // e.g., "Last Cycle", "Current Cycle", "Next Cycle"
    let cycleSectionTitle: String // e.g., "Cycle Card"
    let planetSectionTitle: String // e.g., "Planetary Influence"
    let footerBlurb: String
    let footerCTA: String

    private let inkColor = Color.black
    private let backgroundColor = Color(red: 0.86, green: 0.77, blue: 0.57)

    var body: some View {
        GeometryReader { geometry in
            let imageWidth = geometry.size.width * 0.22
            let imageHeight = imageWidth * 1.4

            ZStack {
                backgroundColor
                    .ignoresSafeArea()

                VStack(spacing: space(12, geometry)) {
                    // Header
                    Text(headerTitle)
                        .font(.custom("Iowan Old Style", size: fontSize(38, geometry)))
                        .fontWeight(.bold)
                        .foregroundColor(inkColor)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.8)

                    // Subtitle - larger and bold
                    Text(headerSubtitle)
                        .font(.custom("Iowan Old Style", size: fontSize(32, geometry)))
                        .fontWeight(.bold)
                        .foregroundColor(inkColor.opacity(0.85))

                    // Two columns: image centered over text
                    HStack(alignment: .top, spacing: 0) {
                        // Card column
                        VStack(spacing: space(16, geometry)) {
                            if let cardImage = ImageManager.shared.loadCardImage(for: cycleCard) {
                                Image(uiImage: cardImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: imageWidth, height: imageHeight)
                                    .cornerRadius(8)
                                    .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
                            }

                            boldedText52(firstParagraph52(cycleCardDescription), boldWord: cycleCardTitle, fontSize: fontSize(28, geometry))
                                .lineSpacing(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.leading, space(16, geometry))
                        .padding(.trailing, space(8, geometry))

                        // Divider - only as tall as text area
                        GeometryReader { dividerGeometry in
                            Rectangle()
                                .fill(inkColor.opacity(0.25))
                                .frame(width: 1)
                        }
                        .frame(width: 1)
                        .padding(.top, imageHeight + space(16, geometry))

                        // Planet column
                        VStack(spacing: space(16, geometry)) {
                            if let planetImage = ImageManager.shared.loadPlanetImage(for: planetName) {
                                Image(uiImage: planetImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: imageWidth, height: imageHeight)
                                    .cornerRadius(8)
                                    .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
                            }

                            boldedText52(singleParagraphSpacing52(planetDescription), boldWord: planetName, fontSize: fontSize(28, geometry))
                                .lineSpacing(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.leading, space(8, geometry))
                        .padding(.trailing, space(16, geometry))
                    }
                    .padding(.horizontal, space(8, geometry))

                    Spacer(minLength: space(8, geometry))

                    // Footer blurb - 22pt
                    Text(footerBlurb)
                        .font(.custom("Iowan Old Style", size: fontSize(22, geometry)))
                        .foregroundColor(inkColor.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, space(16, geometry))

                    // Footer CTA - 28pt bold
                    Text(footerCTA)
                        .font(.custom("Iowan Old Style", size: fontSize(28, geometry)))
                        .fontWeight(.bold)
                        .foregroundColor(inkColor)
                    .padding(.bottom, space(16, geometry))
                }
                .padding(space(32, geometry))
            }
        }
    }

    // MARK: - Title builder
    private func combinedTitle(_ cardTitle: String, planetName: String) -> String {
        let lower = cardTitle.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let needsThe = !lower.hasPrefix("the ")
        let prefix = needsThe ? "The " : ""
        return "\(prefix)\(cardTitle) in \(planetName.capitalized)"
    }

    // MARK: - Dynamic scaling helpers (1200x1200 base)
    private func scale(for geometry: GeometryProxy) -> CGFloat {
        let base = min(geometry.size.width, geometry.size.height)
        return max(0.9, min(1.6, base / 1080.0))
    }

    private func fontSize(_ base: CGFloat, _ geometry: GeometryProxy) -> CGFloat {
        base * scale(for: geometry)
    }

    private func space(_ base: CGFloat, _ geometry: GeometryProxy) -> CGFloat {
        base * scale(for: geometry)
    }

    // Get only the first paragraph of text
    private func firstParagraph52(_ text: String) -> String {
        let paragraphs = text.components(separatedBy: "\n\n")
        return paragraphs.first ?? text
    }

    // Convert double line breaks to single
    private func singleParagraphSpacing52(_ text: String) -> String {
        return text.replacingOccurrences(of: "\n\n", with: "\n")
    }

    // Helper to bold a word within text
    private func boldedText52(_ text: String, boldWord: String, fontSize size: CGFloat) -> Text {
        let font = Font.custom("Iowan Old Style", size: size)
        let boldFont = Font.custom("Iowan Old Style", size: size).bold()

        // Try to find the word (case-insensitive)
        if let range = text.range(of: boldWord, options: .caseInsensitive) {
            let before = String(text[..<range.lowerBound])
            let match = String(text[range])
            let after = String(text[range.upperBound...])

            return Text(before).font(font).foregroundColor(Color.black) +
                   Text(match).font(boldFont).foregroundColor(Color.black) +
                   Text(after).font(font).foregroundColor(Color.black)
        } else {
            return Text(text).font(font).foregroundColor(Color.black)
        }
    }
}

// MARK: - Life Spread Share (Spread = Birth + Karma cards)

struct LifeSpreadShareView: View {
    /// Spread-level title, e.g. "Your Life Spread"
    let headerTitle: String

    /// Birth card (one card in the spread)
    let birthCard: Card
    let birthCardTitle: String
    let birthCardDescription: String

    /// Karma card (another card in the spread)
    let karmaCard: Card
    let karmaCardTitle: String
    let karmaCardDescription: String

    let birthDate: Date
    let userName: String

    private var headingText: String {
        let trimmed = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return headerTitle
        }
        if trimmed.lowercased().hasSuffix("s") {
            return "\(trimmed)’ Life Spread"
        } else {
            return "\(trimmed)’s Life Spread"
        }
    }

    private let inkColor = Color.black
    private let backgroundColor = Color(red: 0.86, green: 0.77, blue: 0.57)

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 16) {
                // Header
                VStack(spacing: 4) {
                    Text(headingText)
                        .font(.custom("Iowan Old Style", size: 38))
                        .fontWeight(.bold)
                        .foregroundColor(inkColor)

                    // Subtitle - larger and bold
                    Text("by Cards of The Seven Sisters")
                        .font(.custom("Iowan Old Style", size: 32))
                        .fontWeight(.bold)
                        .foregroundColor(inkColor.opacity(0.85))
                }
                .padding(.bottom, 8)

                // Birth Card block
                HStack(alignment: .top, spacing: 20) {
                    if let cardImage = ImageManager.shared.loadCardImage(for: birthCard) {
                        Image(uiImage: cardImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 280)
                            .cornerRadius(10)
                            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("BIRTH CARD")
                            .font(.custom("Iowan Old Style", size: 32))
                            .fontWeight(.bold)
                            .foregroundColor(inkColor)

                        boldedTextLife(firstParagraphLife(birthCardDescription), boldWord: birthCardTitle, fontSize: 28)
                            .lineSpacing(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 40)

                // Simple divider line between cards
                Rectangle()
                    .fill(inkColor.opacity(0.3))
                    .frame(width: 400, height: 1)
                    .padding(.vertical, 8)

                // Karma Card block
                HStack(alignment: .top, spacing: 20) {
                    if let cardImage = ImageManager.shared.loadCardImage(for: karmaCard) {
                        Image(uiImage: cardImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 280)
                            .cornerRadius(10)
                            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("KARMA CARD")
                            .font(.custom("Iowan Old Style", size: 32))
                            .fontWeight(.bold)
                            .foregroundColor(inkColor)

                        boldedTextLife(firstParagraphLife(karmaCardDescription), boldWord: karmaCardTitle, fontSize: 28)
                            .lineSpacing(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 40)
                .padding(.top, 8)

                Spacer()

                // Footer blurb - 22pt
                Text("The Cards of The Seven Sisters App helps to translate the archetypes of each cycle to help you identify rhythms for personal growth and rest across areas of your life. No divination, no prediction.")
                    .font(.custom("Iowan Old Style", size: 22))
                    .foregroundColor(inkColor.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                // Footer CTA - 28pt bold
                Text("find yours at sevensisters.cards")
                    .font(.custom("Iowan Old Style", size: 28))
                    .fontWeight(.bold)
                    .foregroundColor(inkColor)
                    .padding(.bottom, 20)
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 40)
        }
        .frame(
            width: ShareCardExportSize.portrait1080x1350.dimensions.width,
            height: ShareCardExportSize.portrait1080x1350.dimensions.height
        )
    }

    // Get only the first paragraph of text
    private func firstParagraphLife(_ text: String) -> String {
        let paragraphs = text.components(separatedBy: "\n\n")
        return paragraphs.first ?? text
    }

    // Helper to bold a word within text
    private func boldedTextLife(_ text: String, boldWord: String, fontSize size: CGFloat) -> Text {
        let font = Font.custom("Iowan Old Style", size: size)
        let boldFont = Font.custom("Iowan Old Style", size: size).bold()

        if let range = text.range(of: boldWord, options: .caseInsensitive) {
            let before = String(text[..<range.lowerBound])
            let match = String(text[range])
            let after = String(text[range.upperBound...])

            return Text(before).font(font).foregroundColor(Color.black) +
                   Text(match).font(boldFont).foregroundColor(Color.black) +
                   Text(after).font(font).foregroundColor(Color.black)
        } else {
            return Text(text).font(font).foregroundColor(Color.black)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Daily Card Share (Daily spread)

struct DailyCardShareView: View {
    let dailyCard: Card
    let dailyCardTitle: String
    let dailyCardDescription: String
    let planetName: String
    let planetTitle: String
    let planetDescription: String
    let date: Date
    let cardTypeName: String // e.g., "Daily Card", "Tomorrow's Card"

    private let inkColor = Color.black
    private let backgroundColor = Color(red: 0.86, green: 0.77, blue: 0.57)

    var body: some View {
        GeometryReader { geometry in
            let imageWidth = geometry.size.width * 0.22
            let imageHeight = imageWidth * 1.4

            ZStack {
                backgroundColor
                    .ignoresSafeArea()

                VStack(spacing: space(12, geometry)) {
                    // Header: Title with date (no "Your")
                    Text("\(cardTypeName) for \(formatDateWithSlashes(date))")
                        .font(.custom("Iowan Old Style", size: fontSize(38, geometry)))
                        .fontWeight(.bold)
                        .foregroundColor(inkColor)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.8)

                    // Subtitle - larger and bold
                    Text("by Cards of The Seven Sisters")
                        .font(.custom("Iowan Old Style", size: fontSize(32, geometry)))
                        .fontWeight(.bold)
                        .foregroundColor(inkColor.opacity(0.85))

                    // Two columns: image centered over text
                    HStack(alignment: .top, spacing: 0) {
                        // Card column
                        VStack(spacing: space(16, geometry)) {
                            if let cardImage = ImageManager.shared.loadCardImage(for: dailyCard) {
                                Image(uiImage: cardImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: imageWidth, height: imageHeight)
                                    .cornerRadius(8)
                                    .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
                            }

                            boldedText(firstParagraph(dailyCardDescription), boldWord: dailyCardTitle, fontSize: fontSize(28, geometry))
                                .lineSpacing(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.leading, space(16, geometry))
                        .padding(.trailing, space(8, geometry))

                        // Divider - only as tall as text area
                        GeometryReader { dividerGeometry in
                            Rectangle()
                                .fill(inkColor.opacity(0.25))
                                .frame(width: 1)
                        }
                        .frame(width: 1)
                        .padding(.top, imageHeight + space(16, geometry))

                        // Planet column
                        VStack(spacing: space(16, geometry)) {
                            if let planetImage = ImageManager.shared.loadPlanetImage(for: planetName) {
                                Image(uiImage: planetImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: imageWidth, height: imageHeight)
                                    .cornerRadius(8)
                                    .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
                            }

                            boldedText(singleParagraphSpacing(planetDescription), boldWord: planetName, fontSize: fontSize(28, geometry))
                                .lineSpacing(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.leading, space(8, geometry))
                        .padding(.trailing, space(16, geometry))
                    }
                    .padding(.horizontal, space(8, geometry))

                    Spacer(minLength: space(8, geometry))

                    // Footer blurb - 22pt
                    Text("The Cards of The Seven Sisters App helps to translate the archetypes of each cycle to help you identify rhythms for personal growth and rest across areas of your life. No divination, no prediction.")
                        .font(.custom("Iowan Old Style", size: fontSize(22, geometry)))
                        .foregroundColor(inkColor.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, space(16, geometry))

                    // Footer CTA - 28pt bold
                    Text("find yours at sevensisters.cards")
                        .font(.custom("Iowan Old Style", size: fontSize(28, geometry)))
                        .fontWeight(.bold)
                        .foregroundColor(inkColor)
                }
                .padding(space(24, geometry))
            }
        }
    }

    // Convert double line breaks to single
    private func singleParagraphSpacing(_ text: String) -> String {
        return text.replacingOccurrences(of: "\n\n", with: "\n")
    }

    // Get only the first paragraph of text
    private func firstParagraph(_ text: String) -> String {
        let paragraphs = text.components(separatedBy: "\n\n")
        return paragraphs.first ?? text
    }

    private func formatDateWithSlashes(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("Mdyyyy")
        return formatter.string(from: date)
    }


    // Helper to bold a word within text
    private func boldedText(_ text: String, boldWord: String, fontSize size: CGFloat) -> Text {
        let font = Font.custom("Iowan Old Style", size: size)
        let boldFont = Font.custom("Iowan Old Style", size: size).bold()

        // Try to find the word (case-insensitive)
        if let range = text.range(of: boldWord, options: .caseInsensitive) {
            let before = String(text[..<range.lowerBound])
            let match = String(text[range])
            let after = String(text[range.upperBound...])

            return Text(before).font(font).foregroundColor(inkColor) +
                   Text(match).font(boldFont).foregroundColor(inkColor) +
                   Text(after).font(font).foregroundColor(inkColor)
        } else {
            return Text(text).font(font).foregroundColor(inkColor)
        }
    }

    // Convert "ACE OF SPADES" to "Ace of Spades"
    private func toTitleCase(_ text: String) -> String {
        let lowercaseWords = ["of", "the", "in", "and", "or", "a", "an"]
        let words = text.lowercased().split(separator: " ")
        var result: [String] = []
        for (index, word) in words.enumerated() {
            if index == 0 || !lowercaseWords.contains(String(word)) {
                result.append(word.prefix(1).uppercased() + word.dropFirst())
            } else {
                result.append(String(word))
            }
        }
        return result.joined(separator: " ")
    }

    // MARK: - Title builder
    private func combinedTitle(_ cardTitle: String, planetName: String) -> String {
        let lower = cardTitle.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let needsThe = !lower.hasPrefix("the ")
        let prefix = needsThe ? "The " : ""
        return "\(prefix)\(cardTitle) in \(planetName.capitalized)"
    }

    // MARK: - Dynamic scaling helpers (1200x1200 base)
    private func scale(for geometry: GeometryProxy) -> CGFloat {
        let base = min(geometry.size.width, geometry.size.height)
        return max(0.9, min(1.6, base / 1080.0))
    }

    private func fontSize(_ base: CGFloat, _ geometry: GeometryProxy) -> CGFloat {
        base * scale(for: geometry)
    }

    private func space(_ base: CGFloat, _ geometry: GeometryProxy) -> CGFloat {
        base * scale(for: geometry)
    }
}

// MARK: - Generic Share Card View (for modal text-based sharing)

struct ShareCardView: View {
    let content: ShareCardContent
    let exportSize: ShareCardExportSize

    private let inkColor = Color.black
    private let backgroundColor = Color(red: 0.86, green: 0.77, blue: 0.57)

    init(content: ShareCardContent, exportSize: ShareCardExportSize = .portrait1080x1350) {
        self.content = content
        self.exportSize = exportSize
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 25)
                    .fill(backgroundColor)

                ScrollView {
                    VStack(spacing: 0) {
                        cardImageSection(in: geometry)
                        contentSection(in: geometry)
                        footerSection(in: geometry)
                    }
                    .padding(30)
                }
                .scrollIndicators(.hidden)
            }
        }
        .aspectRatio(exportSize.aspectRatio, contentMode: .fit)
    }

    private func cardImageSection(in geometry: GeometryProxy) -> some View {
        let availableWidth = max(200, geometry.size.width - 60)
        let imageHeight = max(200, min(availableWidth * 0.6, 300))
        let imageWidth = max(160, availableWidth * 0.7)

        return content.image
            .resizable()
            .aspectRatio(16 / 20, contentMode: .fit)
            .frame(width: imageWidth, height: imageHeight)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
            .padding(.bottom, dynamicSpacing(base: 25, geometry: geometry))
    }

    private func contentSection(in geometry: GeometryProxy) -> some View {
        VStack(spacing: dynamicSpacing(base: 15, geometry: geometry)) {
            Text(content.title.uppercased())
                .font(titleFont(for: geometry))
                .foregroundColor(inkColor)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.7)

            Text(content.subtitle.lowercased())
                .font(subtitleFont(for: geometry))
                .foregroundColor(inkColor)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.8)

            if let lineImage = UIImage(named: "linedesign") {
                Image(uiImage: lineImage)
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120)
                    .foregroundColor(inkColor.opacity(0.6))
                    .padding(.vertical, dynamicSpacing(base: 8, geometry: geometry))
            }

            Text(content.excerpt)
                .font(bodyFont(for: geometry))
                .foregroundColor(inkColor)
                .multilineTextAlignment(.leading)
                .lineSpacing(1)
                .lineLimit(nil)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, dynamicSpacing(base: 25, geometry: geometry))
    }

    private func footerSection(in geometry: GeometryProxy) -> some View {
        HStack {
            Text(formattedDate)
                .font(footerFont(for: geometry))
                .foregroundColor(inkColor.opacity(0.7))

            Spacer()
        }
        .padding(.top, dynamicSpacing(base: 30, geometry: geometry))
    }

    private func dynamicSpacing(base: CGFloat, geometry: GeometryProxy) -> CGFloat {
        let scale = min(geometry.size.width, geometry.size.height) / 500.0
        return base * max(0.8, min(1.8, scale))
    }

    private func titleFont(for geometry: GeometryProxy) -> Font {
        let baseSize: CGFloat = 32
        let scaledSize = baseSize * fontScale(for: geometry)
        return .custom("Iowan Old Style", size: scaledSize)
    }

    private func subtitleFont(for geometry: GeometryProxy) -> Font {
        let baseSize: CGFloat = 22
        let scaledSize = baseSize * fontScale(for: geometry)
        return .custom("Iowan Old Style", size: scaledSize)
    }

    private func bodyFont(for geometry: GeometryProxy) -> Font {
        let baseSize: CGFloat = 18
        let scaledSize = baseSize * fontScale(for: geometry)
        return .custom("Iowan Old Style", size: scaledSize)
    }

    private func footerFont(for geometry: GeometryProxy) -> Font {
        let baseSize: CGFloat = 14
        let scaledSize = baseSize * fontScale(for: geometry)
        return .custom("Iowan Old Style", size: scaledSize)
    }

    private func fontScale(for geometry: GeometryProxy) -> CGFloat {
        let scale = min(geometry.size.width, geometry.size.height) / 500.0
        return max(0.8, min(1.6, scale))
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: content.date)
    }
}

// MARK: - Renderer Helpers

enum ShareCardRenderer {
    static func renderPNG(content: ShareCardContent, size: ShareCardExportSize) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                do {
                    let shareView = ShareCardView(content: content, exportSize: size)
                    let renderer = ImageRenderer(content: shareView)

                    renderer.proposedSize = .init(size.dimensions)
                    renderer.scale = 1.0

                    guard let uiImage = renderer.uiImage else {
                        continuation.resume(throwing: ShareCardError.renderingFailed)
                        return
                    }

                    let tempDirectory = FileManager.default.temporaryDirectory
                    let filename = "sharecard_\(content.id.uuidString).png"
                    let fileURL = tempDirectory.appendingPathComponent(filename)

                    guard let pngData = uiImage.pngData() else {
                        continuation.resume(throwing: ShareCardError.pngConversionFailed)
                        return
                    }

                    try pngData.write(to: fileURL)
                    continuation.resume(returning: fileURL)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    static func renderUIImage(content: ShareCardContent, size: ShareCardExportSize) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                let shareView = ShareCardView(content: content, exportSize: size)
                let renderer = ImageRenderer(content: shareView)

                renderer.proposedSize = .init(size.dimensions)
                renderer.scale = 2.0

                guard let uiImage = renderer.uiImage else {
                    continuation.resume(throwing: ShareCardError.renderingFailed)
                    return
                }

                continuation.resume(returning: uiImage)
            }
        }
    }
}

enum ShareCardError: LocalizedError {
    case renderingFailed
    case pngConversionFailed

    var errorDescription: String? {
        switch self {
        case .renderingFailed:
            return "Failed to render share card"
        case .pngConversionFailed:
            return "Failed to convert to PNG"
        }
    }
}

// MARK: - Activity Item Source (thumbnail & metadata)

class ShareCardActivityItemSource: NSObject, UIActivityItemSource {
    let image: UIImage
    let fileURL: URL
    let subject: String

    init(image: UIImage, fileURL: URL, subject: String) {
        self.image = image
        self.fileURL = fileURL
        self.subject = subject
        super.init()
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return fileURL
    }

    func activityViewController(
        _ activityViewController: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {
        return fileURL
    }

    func activityViewController(
        _ activityViewController: UIActivityViewController,
        subjectForActivityType activityType: UIActivity.ActivityType?
    ) -> String {
        return subject
    }

    func activityViewControllerLinkMetadata(
        _ activityViewController: UIActivityViewController
    ) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = subject

        if let url = URL(string: "https://sevensisters.cards") {
            metadata.url = url
            metadata.originalURL = url
        }

        metadata.imageProvider = NSItemProvider(object: image)
        metadata.iconProvider = NSItemProvider(object: image)

        return metadata
    }
}

// MARK: - ShareSheet Wrapper (used by all share links)

struct ShareSheetWrapper: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Share Link: Daily Card

struct DailyCardShareLink: View {
    let dailyCard: Card
    let dailyCardTitle: String
    let dailyCardDescription: String
    let planetName: String
    let planetTitle: String
    let planetDescription: String
    let date: Date
    let cardTypeName: String // e.g., "Daily Card"

    @State private var isLoading = false
    @State private var isShowingShareSheet = false
    @State private var isShowingGuestBlockedView = false
    @State private var shareItems: [Any] = []
    @State private var errorMessage: String?

    var body: some View {
        Button(action: {
            if DataManager.shared.isGuestMode {
                isShowingGuestBlockedView = true
            } else {
                shareCard(format: .portrait1080x1440)
            }
        }) {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                    .frame(width: 44, height: 44)
            } else {
                if UIScreen.main.bounds.height < 700 {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.primaryText)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                } else if let shareIcon = UIImage(named: "share_icon") {
                    Image(uiImage: shareIcon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundColor(AppTheme.primaryText)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                } else {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 20))
                        .foregroundColor(AppTheme.primaryText)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .accessibilityLabel("Share")
        .sheet(isPresented: $isShowingShareSheet) {
            if !shareItems.isEmpty {
                ShareSheetWrapper(activityItems: shareItems)
                    .ignoresSafeArea()
            }
        }
        .fullScreenCover(isPresented: $isShowingGuestBlockedView) {
            GuestShareBlockedView()
        }
        .alert("Share Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
    }

    private func shareCard(format: ShareExportFormat) {
        isLoading = true
        Task {
            do {
                let shareView = DailyCardShareView(
                    dailyCard: dailyCard,
                    dailyCardTitle: dailyCardTitle,
                    dailyCardDescription: dailyCardDescription,
                    planetName: planetName,
                    planetTitle: planetTitle,
                    planetDescription: planetDescription,
                    date: date,
                    cardTypeName: cardTypeName
                )

                let renderer = ImageRenderer(content: shareView)
                renderer.proposedSize = ProposedViewSize(width: format.proposedSize.width, height: format.proposedSize.height)
                renderer.scale = 2.0

                guard let renderedImage = renderer.uiImage else {
                    throw ShareCardError.renderingFailed
                }

                let imageWithoutAlpha = removeAlphaChannel(from: renderedImage)

                guard let imageData = imageWithoutAlpha.jpegData(compressionQuality: 0.9) else {
                    throw ShareCardError.pngConversionFailed
                }

                let tempDir = FileManager.default.temporaryDirectory
                let cleanedName = cardTypeName.replacingOccurrences(of: "'", with: "").replacingOccurrences(of: " ", with: "")
                let fileName = "\(cleanedName)xSevenSisters.jpg"
                let fileURL = tempDir.appendingPathComponent(fileName)

                try imageData.write(to: fileURL)

                await MainActor.run {
                    let activityItemSource = ShareCardActivityItemSource(
                        image: imageWithoutAlpha,
                        fileURL: fileURL,
                        subject: "\(cleanedName)xSevenSisters"
                    )

                    self.shareItems = [activityItemSource]
                    isLoading = false
                    isShowingShareSheet = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func removeAlphaChannel(from image: UIImage) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = true
        format.scale = image.scale

        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: image.size))
            image.draw(at: .zero)
        }
    }
}

// MARK: - Share Link: Life Spread (Birth + Karma spread)

struct LifeSpreadShareLink: View {
    let birthCard: Card
    let birthCardTitle: String
    let birthCardDescription: String
    let karmaCard: Card
    let karmaCardTitle: String
    let karmaCardDescription: String
    let birthDate: Date
    let userName: String
    /// Spread-level heading, e.g. "Your Life Spread"
    let headerTitle: String

    @State private var isLoading = false
    @State private var isShowingShareSheet = false
    @State private var isShowingGuestBlockedView = false
    @State private var shareItems: [Any] = []
    @State private var errorMessage: String?

    var body: some View {
        Button(action: {
            if DataManager.shared.isGuestMode {
                isShowingGuestBlockedView = true
            } else {
                shareCard()
            }
        }) {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                    .frame(width: 44, height: 44)
            } else {
                if UIScreen.main.bounds.height < 700 {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.primaryText)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                } else if let shareIcon = UIImage(named: "share_icon") {
                    Image(uiImage: shareIcon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundColor(AppTheme.primaryText)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                } else {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 20))
                        .foregroundColor(AppTheme.primaryText)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .accessibilityLabel("Share")
        .sheet(isPresented: $isShowingShareSheet) {
            if !shareItems.isEmpty {
                ShareSheetWrapper(activityItems: shareItems)
                    .ignoresSafeArea()
            }
        }
        .fullScreenCover(isPresented: $isShowingGuestBlockedView) {
            GuestShareBlockedView()
        }
        .alert("Share Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
    }

    private func shareCard() {
        isLoading = true

        Task {
            do {
                await MainActor.run {
                    DescriptionRepository.shared.ensureLoaded()
                }

                let shareView = LifeSpreadShareView(
                    headerTitle: headerTitle,
                    birthCard: birthCard,
                    birthCardTitle: birthCardTitle,
                    birthCardDescription: birthCardDescription,
                    karmaCard: karmaCard,
                    karmaCardTitle: karmaCardTitle,
                    karmaCardDescription: karmaCardDescription,
                    birthDate: birthDate,
                    userName: userName
                )

                let size = ShareCardExportSize.portrait1080x1350.dimensions
                let renderer = ImageRenderer(content: shareView)
                renderer.proposedSize = ProposedViewSize(width: size.width, height: size.height)
                renderer.scale = 2.0

                guard let renderedImage = renderer.uiImage else {
                    throw ShareCardError.renderingFailed
                }

                let imageWithoutAlpha = removeAlphaChannel(from: renderedImage)

                guard let imageData = imageWithoutAlpha.jpegData(compressionQuality: 0.9) else {
                    throw ShareCardError.pngConversionFailed
                }

                let tempDir = FileManager.default.temporaryDirectory
                let fileName = "MyLifeSpreadxSevenSisters.jpg"
                let fileURL = tempDir.appendingPathComponent(fileName)

                try imageData.write(to: fileURL)

                await MainActor.run {
                    let activityItemSource = ShareCardActivityItemSource(
                        image: imageWithoutAlpha,
                        fileURL: fileURL,
                        subject: "MyLifeSpreadxSevenSisters"
                    )

                    self.shareItems = [activityItemSource]
                    isLoading = false
                    isShowingShareSheet = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func removeAlphaChannel(from image: UIImage) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = true
        format.scale = image.scale

        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: image.size))
            image.draw(at: .zero)
        }
    }
}

// MARK: - Share Link: fiftytwo Cycle

struct fiftytwoCycleShareLink: View {
    // Core content
    let cycleCard: Card
    let cycleCardTitle: String
    let cycleCardDescription: String
    let planetName: String
    let planetTitle: String
    let planetDescription: String
    let cycleInfo: String

    // Presentation labels (optional/overridable)
    var headerTitle: String = "Current 52-Day Cycle"
    var headerSubtitle: String = "by Cards of The Seven Sisters"
    var contextLabel: String? = nil
    var cycleSectionTitle: String = "Cycle Card"
    var planetSectionTitle: String = "Planetary Card"
    var footerBlurb: String = "The Cards of The Seven Sisters App helps to translate the archetypes of each cycle to help you identify rhythms for personal growth and rest across areas of your life. No divination, no prediction."
    var footerCTA: String = "find yours at sevensisters.cards"

    @State private var isLoading = false
    @State private var isShowingShareSheet = false
    @State private var isShowingGuestBlockedView = false
    @State private var shareItems: [Any] = []
    @State private var errorMessage: String?

    var body: some View {
        Button(action: {
            if DataManager.shared.isGuestMode {
                isShowingGuestBlockedView = true
            } else {
                shareCard(format: .portrait1080x1440)
            }
        }) {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                    .frame(width: 44, height: 44)
            } else {
                if UIScreen.main.bounds.height < 700 {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.primaryText)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                } else if let shareIcon = UIImage(named: "share_icon") {
                    Image(uiImage: shareIcon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundColor(AppTheme.primaryText)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                } else {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 20))
                        .foregroundColor(AppTheme.primaryText)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .accessibilityLabel("Share")
        .sheet(isPresented: $isShowingShareSheet) {
            if !shareItems.isEmpty {
                ShareSheetWrapper(activityItems: shareItems)
                    .ignoresSafeArea()
            }
        }
        .fullScreenCover(isPresented: $isShowingGuestBlockedView) {
            GuestShareBlockedView()
        }
        .alert("Share Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
    }

    private func shareCard(format: ShareExportFormat) {
        isLoading = true
        Task {
            do {
                await MainActor.run {
                    DescriptionRepository.shared.ensureLoaded()
                }

                let repo = DescriptionRepository.shared
                let correctDescription = repo.fiftyTwoDescriptions[String(cycleCard.id)] ?? "No 52-day description available."

                let shareView = fiftytwoCycleShareView(
                    cycleCard: cycleCard,
                    cycleCardTitle: cycleCardTitle,
                    cycleCardDescription: correctDescription,
                    planetName: planetName,
                    planetTitle: planetTitle,
                    planetDescription: planetDescription,
                    cycleInfo: cycleInfo,
                    headerTitle: headerTitle,
                    headerSubtitle: headerSubtitle,
                    contextLabel: contextLabel,
                    cycleSectionTitle: cycleSectionTitle,
                    planetSectionTitle: planetSectionTitle,
                    footerBlurb: footerBlurb,
                    footerCTA: footerCTA
                )

                let renderer = ImageRenderer(content: shareView)
                renderer.proposedSize = ProposedViewSize(width: format.proposedSize.width, height: format.proposedSize.height)
                renderer.scale = 2.0

                guard let renderedImage = renderer.uiImage else {
                    throw ShareCardError.renderingFailed
                }

                let imageWithoutAlpha = removeAlphaChannel(from: renderedImage)

                guard let imageData = imageWithoutAlpha.jpegData(compressionQuality: 0.9) else {
                    throw ShareCardError.pngConversionFailed
                }

                let tempDir = FileManager.default.temporaryDirectory
                let cleanedName = "My" + headerTitle.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
                let fileName = "\(cleanedName)xSevenSisters.jpg"
                let fileURL = tempDir.appendingPathComponent(fileName)

                try imageData.write(to: fileURL)

                await MainActor.run {
                    let activityItemSource = ShareCardActivityItemSource(
                        image: imageWithoutAlpha,
                        fileURL: fileURL,
                        subject: "\(cleanedName)xSevenSisters"
                    )

                    self.shareItems = [activityItemSource]
                    isLoading = false
                    isShowingShareSheet = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func removeAlphaChannel(from image: UIImage) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = true
        format.scale = image.scale

        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: image.size))
            image.draw(at: .zero)
        }
    }
}

// MARK: - Share Link: Generic Single Card (Birth / Yearly etc.)

struct SingleCardShareLink: View {
    let card: Card
    let cardTitle: String
    let cardDescription: String
    let spreadType: String  // e.g., "Birth Card"
    let subtitle: String?    // Optional subtitle
    var overrideImage: UIImage? = nil

    @State private var isLoading = false
    @State private var isShowingShareSheet = false
    @State private var isShowingGuestBlockedView = false
    @State private var shareItems: [Any] = []
    @State private var errorMessage: String?

    var body: some View {
        Button(action: {
            if DataManager.shared.isGuestMode {
                isShowingGuestBlockedView = true
            } else {
                shareCard()
            }
        }) {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                    .frame(width: 44, height: 44)
            } else {
                if UIScreen.main.bounds.height < 700 {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.primaryText)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                } else if let shareIcon = UIImage(named: "share_icon") {
                    Image(uiImage: shareIcon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundColor(AppTheme.primaryText)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                } else {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 20))
                        .foregroundColor(AppTheme.primaryText)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .accessibilityLabel("Share")
        .sheet(isPresented: $isShowingShareSheet) {
            if !shareItems.isEmpty {
                ShareSheetWrapper(activityItems: shareItems)
                    .ignoresSafeArea()
            }
        }
        .fullScreenCover(isPresented: $isShowingGuestBlockedView) {
            GuestShareBlockedView()
        }
        .alert("Share Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
    }

    private func shareCard() {
        isLoading = true
        Task {
            do {
                let shareView = SingleCardShareView(
                    card: card,
                    cardTitle: cardTitle,
                    cardDescription: cardDescription,
                    spreadType: spreadType,
                    subtitle: subtitle,
                    overrideImage: overrideImage
                )

                let renderer = ImageRenderer(content: shareView)
                renderer.proposedSize = ProposedViewSize(width: 1200, height: 1200)
                renderer.scale = 2.0

                guard let renderedImage = renderer.uiImage else {
                    throw ShareCardError.renderingFailed
                }

                let imageWithoutAlpha = removeAlphaChannel(from: renderedImage)

                guard let imageData = imageWithoutAlpha.jpegData(compressionQuality: 0.9) else {
                    throw ShareCardError.pngConversionFailed
                }

                let tempDir = FileManager.default.temporaryDirectory
                let needsMy = spreadType.contains("Birth") || spreadType.contains("Karma")
                let cleanedType = spreadType.replacingOccurrences(of: "'", with: "").replacingOccurrences(of: " ", with: "")
                let baseName = needsMy ? "My\(cleanedType)" : cleanedType
                let fileName = "\(baseName)xSevenSisters.jpg"
                let fileURL = tempDir.appendingPathComponent(fileName)

                try imageData.write(to: fileURL)

                await MainActor.run {
                    let activityItemSource = ShareCardActivityItemSource(
                        image: imageWithoutAlpha,
                        fileURL: fileURL,
                        subject: "\(baseName)xSevenSisters"
                    )

                    self.shareItems = [activityItemSource]
                    isLoading = false
                    isShowingShareSheet = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func removeAlphaChannel(from image: UIImage) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = true
        format.scale = image.scale

        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: image.size))
            image.draw(at: .zero)
        }
    }
}

// MARK: - Support extensions

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

extension ShareCardContent {
    static func fromModal(
        card: Card,
        cardType: CardType,
        contentType: DetailContentType?,
        date: Date = Date()
    ) -> ShareCardContent {

        var cardName = ""
        var cardTitle = ""
        var description = ""
        var image: Image = Image(systemName: "questionmark.card")

        if case .planetary(let planet) = contentType {
            let planetInfo = AppConstants.PlanetDescriptions.getDescription(for: planet)
            cardName = planet.uppercased()
            cardTitle = planetInfo.title
            description = planetInfo.description

            if let planetImage = ImageManager.shared.loadPlanetImage(for: planet) {
                image = Image(uiImage: planetImage)
            }
        } else {
            if let def = getCardDefinition(by: card.id) {
                cardName = def.name
                cardTitle = def.title
            }

            if let cardImage = ImageManager.shared.loadCardImage(for: card) {
                image = Image(uiImage: cardImage)
            }

            let repo = DescriptionRepository.shared
            let cardID = String(card.id)

            switch contentType {
            case .karma(let karmaDescription):
                description = karmaDescription
            default:
                switch cardType {
                case .daily:
                    description = repo.dailyDescriptions[cardID] ?? "No daily description available."
                case .birth:
                    description = repo.birthDescriptions[cardID] ?? "No birth description available."
                case .yearly:
                    description = repo.yearlyDescriptions[cardID] ?? "No yearly description available."
                case .fiftyTwoDay:
                    description = repo.fiftyTwoDescriptions[cardID] ?? "No 52-day description available."
                case .planetary:
                    description = "Error: Should be handled above"
                }
            }
        }

        return ShareCardContent(
            title: cardName,
            subtitle: cardTitle,
            excerpt: description,
            date: date,
            image: image
        )
    }
}


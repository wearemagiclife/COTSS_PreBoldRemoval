import SwiftUI
import UIKit
import LinkPresentation

// MARK: - Native share sheet wrapper

@MainActor
struct LifeSpreadShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - 3:4 Life Spread share card (Birth + Karma)

struct LifeSpreadShareCardView: View {
    let birthCard: Card
    let birthCardTitle: String
    let birthCardSubtitle: String

    let karma1Cards: [Card]
    let karma2Cards: [Card]

    let primaryKarmaTitle: String
    let primaryKarmaDescription: String

    let birthDate: Date
    let userName: String

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: birthDate)
    }

    var body: some View {
        ZStack {
            // Full parchment background
            Color(red: 0.86, green: 0.77, blue: 0.57)
                .ignoresSafeArea()

            VStack {
                Spacer(minLength: 40)

                ZStack {
                    // Border box
                    Rectangle()
                        .stroke(Color.black, lineWidth: 3)

                    VStack(spacing: AppConstants.Spacing.sectionSpacing) {

                        // HEADER
                        VStack(spacing: AppConstants.Spacing.small) {
                            Text("\(userName.isEmpty ? "you" : userName)'s Life Spread")
                                .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.dynamicTitle))
                                .bold()
                                .multilineTextAlignment(.center)

                            Text(formattedDate)
                                .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                                .multilineTextAlignment(.center)
                        }

                        // BIRTH CARD SECTION
                        VStack(spacing: AppConstants.Spacing.small) {
                            Text("Your Birth Card")
                                .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                                .bold()

                            TappableCard(
                                card: birthCard,
                                size: AppConstants.CardSizes.large,
                                action: {}
                            )
                        }

                        // FIRST KARMA ROW
                        if !karma1Cards.isEmpty {
                            VStack(spacing: AppConstants.Spacing.small) {

                                LineBreak("linedesign", width: 180)

                                Text("First Karmic Connections")
                                    .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                                    .bold()

                                HStack(spacing: AppConstants.Spacing.medium) {
                                    ForEach(karma1Cards, id: \.id) { card in
                                        TappableCard(
                                            card: card,
                                            size: AppConstants.CardSizes.medium,
                                            action: {}
                                        )
                                    }
                                }
                            }
                        }

                        // SECOND KARMA ROW – HORIZONTAL
                        if !karma2Cards.isEmpty {
                            VStack(spacing: AppConstants.Spacing.small) {

                                LineBreak("linedesign", width: 180)

                                Text("Second Karmic Connections")
                                    .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                                    .bold()

                                HStack(spacing: AppConstants.Spacing.medium) {
                                    ForEach(karma2Cards, id: \.id) { card in
                                        TappableCard(
                                            card: card,
                                            size: AppConstants.CardSizes.medium,
                                            action: {}
                                        )
                                    }
                                }

                                Spacer(minLength: 10)

                                Text("find yours at sevensisters.cards")
                                    .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                                    .multilineTextAlignment(.center)
                            }
                        }

                        LineBreak("linedesignd", width: 180)
                    }
                    .padding(AppConstants.Spacing.large)
                }
                .frame(width: 720, height: 960) // inner poster (still 3:4)

                Spacer(minLength: 40)
            }
            .padding()
        }
        // Outer export canvas – 3:4
        .frame(width: 900, height: 1200)
    }
}

// MARK: - 3:4 single birth card share card

struct BirthCardShareCardView: View {
    let card: Card
    let cardTitle: String
    let cardDescription: String
    let spreadType: String
    let subtitle: String

    var body: some View {
        ZStack {
            Color(red: 0.86, green: 0.77, blue: 0.57)
                .ignoresSafeArea()

            VStack {
                Spacer(minLength: 40)

                ZStack {
                    Rectangle()
                        .stroke(Color.black, lineWidth: 3)

                    VStack(spacing: AppConstants.Spacing.sectionSpacing) {
                        VStack(spacing: AppConstants.Spacing.small) {
                            Text(spreadType)
                                .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.dynamicHeadline))
                                .bold()
                                .multilineTextAlignment(.center)

                            if !subtitle.isEmpty {
                                Text(subtitle)
                                    .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                            }

                            Text("find yours at sevensisters.cards")
                                .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                                .multilineTextAlignment(.center)
                        }

                        TappableCard(
                            card: card,
                            size: AppConstants.CardSizes.large,
                            action: {}
                        )

                        LineBreak("linedesignd", width: 180)

                        Text(cardTitle)
                            .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                            .bold()
                            .multilineTextAlignment(.center)

                        Text(cardDescription)
                            .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.body))
                            .multilineTextAlignment(.leading)
                            .lineLimit(nil)
                            .minimumScaleFactor(0.8)

                        LineBreak("linedesignd", width: 180)

                        VStack(spacing: 4) {
                            Text("Our App helps to translate the archetypes of each cycle to help you identify rhythms for personal growth and rest across areas of your life. No divination, no prediction.")
                                .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))

                            Text("find yours at sevensisters.cards")
                                .font(.custom("Iowan Old Style", size: AppConstants.FontSizes.subheadline))
                                .bold()
                        }
                    }
                    .padding(AppConstants.Spacing.large)
                }
                .frame(width: 720, height: 960)

                Spacer(minLength: 40)
            }
            .padding()
        }
        .frame(width: 900, height: 1200)
    }
}

// MARK: - Legacy Share Buttons (you can keep or delete if unused)

// These are no longer used by LifeSpreadView after the refactor,
// but leaving them here is harmless and may be used by other screens.

@MainActor
struct LifeSpreadShareButton: View {
    let birthCard: Card
    let birthCardTitle: String
    let birthCardSubtitle: String

    let karma1Cards: [Card]
    let karma2Cards: [Card]

    let primaryKarmaTitle: String
    let primaryKarmaDescription: String

    let birthDate: Date
    let userName: String

    @State private var shareItems: [Any] = []
    @State private var isShowingShare = false
    @State private var isLoading = false

    var body: some View {
        Button {
            shareCard()
        } label: {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
            } else {
                if let shareIcon = UIImage(named: "share_icon") {
                    Image(uiImage: shareIcon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                } else {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 20))
                }
            }
        }
        .disabled(isLoading)
        .sheet(isPresented: $isShowingShare) {
            if !shareItems.isEmpty {
                LifeSpreadShareSheet(activityItems: shareItems)
            }
        }
    }

    private func shareCard() {
        isLoading = true

        Task {
            do {
                let shareView = LifeSpreadShareCardView(
                    birthCard: birthCard,
                    birthCardTitle: birthCardTitle,
                    birthCardSubtitle: birthCardSubtitle,
                    karma1Cards: karma1Cards,
                    karma2Cards: karma2Cards,
                    primaryKarmaTitle: primaryKarmaTitle,
                    primaryKarmaDescription: primaryKarmaDescription,
                    birthDate: birthDate,
                    userName: userName
                )

                let renderer = ImageRenderer(content: shareView)
                renderer.proposedSize = ProposedViewSize(width: 900, height: 1200)
                renderer.scale = 2.0

                guard let renderedImage = renderer.uiImage else {
                    await MainActor.run { isLoading = false }
                    return
                }

                let imageWithoutAlpha = removeAlphaChannel(from: renderedImage)

                guard let imageData = imageWithoutAlpha.jpegData(compressionQuality: 0.9) else {
                    await MainActor.run { isLoading = false }
                    return
                }

                let tempDir = FileManager.default.temporaryDirectory
                let fileName = "My Life Spread by Cards of The Seven Sisters.jpg"
                let fileURL = tempDir.appendingPathComponent(fileName)

                try imageData.write(to: fileURL)

                await MainActor.run {
                    let activityItemSource = ShareCardActivityItemSource(
                        image: imageWithoutAlpha,
                        fileURL: fileURL,
                        subject: "My Life Spread by Cards of The Seven Sisters"
                    )

                    self.shareItems = [activityItemSource]
                    isLoading = false
                    isShowingShare = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
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

@MainActor
struct BirthCardShareButton: View {
    let card: Card
    let cardTitle: String
    let cardDescription: String
    let spreadType: String
    let subtitle: String

    @State private var shareItems: [Any] = []
    @State private var isShowingShare = false
    @State private var isLoading = false

    var body: some View {
        Button {
            shareCard()
        } label: {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
            } else {
                if let shareIcon = UIImage(named: "share_icon") {
                    Image(uiImage: shareIcon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                } else {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 20))
                }
            }
        }
        .disabled(isLoading)
        .sheet(isPresented: $isShowingShare) {
            if !shareItems.isEmpty {
                LifeSpreadShareSheet(activityItems: shareItems)
            }
        }
    }

    private func shareCard() {
        isLoading = true

        Task {
            do {
                let shareView = BirthCardShareCardView(
                    card: card,
                    cardTitle: cardTitle,
                    cardDescription: cardDescription,
                    spreadType: spreadType,
                    subtitle: subtitle
                )

                let renderer = ImageRenderer(content: shareView)
                renderer.proposedSize = ProposedViewSize(width: 900, height: 1200)
                renderer.scale = 2.0

                guard let renderedImage = renderer.uiImage else {
                    await MainActor.run { isLoading = false }
                    return
                }

                let imageWithoutAlpha = removeAlphaChannel(from: renderedImage)

                guard let imageData = imageWithoutAlpha.jpegData(compressionQuality: 0.9) else {
                    await MainActor.run { isLoading = false }
                    return
                }

                let tempDir = FileManager.default.temporaryDirectory
                let fileName = "My \(spreadType) by Cards of The Seven Sisters.jpg"
                let fileURL = tempDir.appendingPathComponent(fileName)

                try imageData.write(to: fileURL)

                await MainActor.run {
                    let activityItemSource = ShareCardActivityItemSource(
                        image: imageWithoutAlpha,
                        fileURL: fileURL,
                        subject: "My \(spreadType) by Cards of The Seven Sisters"
                    )

                    self.shareItems = [activityItemSource]
                    isLoading = false
                    isShowingShare = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
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

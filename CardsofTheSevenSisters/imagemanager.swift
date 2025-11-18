import UIKit
import SwiftUI

class ImageManager: ObservableObject {
    static let shared = ImageManager()

    private var imageCache: [String: UIImage] = [:]
    private var accessOrder: [String] = []  // Track access order for LRU
    private let maxCacheSize = 30
    private let cacheQueue = DispatchQueue(label: "ImageCacheQueue", attributes: .concurrent)

    private init() {}
    
    func loadCardImage(for card: Card) -> UIImage? {
        return loadImage(named: card.imageName)
    }
    
    func loadCardImage(named imageName: String) -> UIImage? {
        return loadImage(named: imageName)
    }
    
    func loadPlanetImage(for planet: String) -> UIImage? {
        let imageName = planet.lowercased()
        return loadImage(named: imageName)
    }
    
    private func loadImage(named imageName: String) -> UIImage? {
        if let cachedImage = getCachedImage(named: imageName) {
            return cachedImage
        }
        
        let image = attemptImageLoad(named: imageName)
        setCachedImage(image, named: imageName)
        return image
    }
    
    private func attemptImageLoad(named imageName: String) -> UIImage? {
        // Try exact name first (most common case - assets use lowercase)
        if let image = UIImage(named: imageName) {
            return image
        }
        // Fallback to lowercase for legacy calls
        if let image = UIImage(named: imageName.lowercased()) {
            return image
        }
        return nil
    }
    
    private func getCachedImage(named imageName: String) -> UIImage? {
        return cacheQueue.sync {
            if let image = imageCache[imageName] {
                // Move to end (most recently used)
                accessOrder.removeAll { $0 == imageName }
                accessOrder.append(imageName)
                return image
            }
            return nil
        }
    }

    private func setCachedImage(_ image: UIImage?, named imageName: String) {
        cacheQueue.async(flags: .barrier) {
            // Update access order
            self.accessOrder.removeAll { $0 == imageName }
            self.accessOrder.append(imageName)

            // Evict oldest if over limit
            while self.accessOrder.count > self.maxCacheSize {
                let oldest = self.accessOrder.removeFirst()
                self.imageCache.removeValue(forKey: oldest)
            }

            self.imageCache[imageName] = image
        }
    }
    
    func clearCache() {
        cacheQueue.async(flags: .barrier) {
            self.imageCache.removeAll()
            self.accessOrder.removeAll()
        }
    }

    func preloadAllCards() {
        DispatchQueue.global(qos: .userInitiated).async {
            let suits = ["h", "d", "c", "s"]
            let ranks = ["a", "2", "3", "4", "5", "6", "7", "8", "9", "10", "j", "q", "k"]

            for suit in suits {
                for rank in ranks {
                    _ = self.loadImage(named: "\(rank)\(suit)")
                }
            }
            // Load special cards
            _ = self.loadImage(named: "joker")
            _ = self.loadImage(named: "cardback")
        }
    }
    
    struct CachedImage: View {
        let imageName: String
        let width: CGFloat?
        let height: CGFloat?
        let cornerRadius: CGFloat
        let accessibilityLabel: String?
        let isDecorative: Bool
        
        @Environment(\.sizeCategory) var sizeCategory
        
        init(_ imageName: String,
             width: CGFloat? = nil,
             height: CGFloat? = nil,
             cornerRadius: CGFloat = 12,
             accessibilityLabel: String? = nil,
             isDecorative: Bool = false) {
            self.imageName = imageName
            self.width = width
            self.height = height
            self.cornerRadius = cornerRadius
            self.accessibilityLabel = accessibilityLabel
            self.isDecorative = isDecorative
        }
        
        var body: some View {
            Group {
                if let image = ImageManager.shared.loadImage(named: imageName) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: scaledWidth, height: scaledHeight)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                        .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
                        .accessibilityElement()
                        .if(!isDecorative) { view in
                            view.accessibilityLabel(accessibilityLabel ?? imageName)
                                .accessibilityAddTraits(.isImage)
                        }
                        .if(isDecorative) { view in
                            view.accessibilityHidden(true)
                        }
                } else {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: scaledWidth, height: scaledHeight)
                        .overlay(
                            VStack {
                                Text("Missing:")
                                    .font(.caption2)
                                    .foregroundColor(.red)
                                Text(imageName)
                                    .font(.caption)
                                    
                                    .foregroundColor(.black)
                            }
                        )
                        .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
                        .accessibilityLabel("Missing image: \(imageName)")
                        .accessibilityAddTraits(.isImage)
                }
            }
            .frame(minWidth: isDecorative ? nil : AppConstants.Accessibility.minimumTouchTarget,
                   minHeight: isDecorative ? nil : AppConstants.Accessibility.minimumTouchTarget)
        }
        
        private var scaledWidth: CGFloat? {
            guard let width = width else { return nil }
            return sizeCategory.isAccessibilityCategory ? width * 1.3 : width
        }
        
        private var scaledHeight: CGFloat? {
            guard let height = height else { return nil }
            return sizeCategory.isAccessibilityCategory ? height * 1.3 : height
        }
    }
    
    struct CachedCardImage: View {
        let card: Card
        let width: CGFloat?
        let height: CGFloat?
        let cornerRadius: CGFloat
        
        @Environment(\.sizeCategory) var sizeCategory
        
        init(card: Card, width: CGFloat? = nil, height: CGFloat? = nil, cornerRadius: CGFloat = 12) {
            self.card = card
            self.width = width
            self.height = height
            self.cornerRadius = cornerRadius
        }
        
        var body: some View {
            CachedImage(
                card.imageName,
                width: width,
                height: height,
                cornerRadius: cornerRadius,
                accessibilityLabel: cardAccessibilityLabel
            )
        }
        
        private var cardAccessibilityLabel: String {
            let valueName = cardValueName(card.value)
            return "\(valueName) of \(card.suit.rawValue)"
        }
        
        private func cardValueName(_ value: String) -> String {
            switch value.uppercased() {
            case "A": return "Ace"
            case "K": return "King"
            case "Q": return "Queen"
            case "J": return "Jack"
            default: return value
            }
        }
    }
}

extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

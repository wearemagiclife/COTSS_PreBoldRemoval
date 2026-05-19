import Foundation
import SwiftUI

@MainActor
final class DeepLinkRouter: ObservableObject {
    enum Destination: String {
        case home
        case daily
        case planet
        case cycle52
        case yearly
        case subscribe
        case setup
    }

    @Published var pendingDestination: Destination?

    func handle(_ url: URL) {
        guard url.scheme == "sevensistersapp",
              let host = url.host,
              let destination = Destination(rawValue: host) else {
            return
        }
        pendingDestination = destination
    }

    func clear() {
        pendingDestination = nil
    }
}

import SwiftUI
import CoreMotion

// MARK: - DeviceMotionManager

/// Singleton class that manages CoreMotion device motion updates for card gloss effects.
/// Provides normalized pitch and roll values with smoothing for fluid animations.
class DeviceMotionManager: ObservableObject {
    static let shared = DeviceMotionManager()

    private let motionManager = CMMotionManager()
    private var updateTimer: Timer?

    /// Normalized pitch value (-1 to 1), forward/back tilt
    @Published var pitch: Double = 0
    /// Normalized roll value (-1 to 1), left/right tilt
    @Published var roll: Double = 0

    /// Maximum tilt angle for normalization (radians, ~15 degrees)
    private let maxTilt: Double = 0.26
    /// Smoothing factor for motion data (lower = smoother but laggier)
    private let smoothingFactor: Double = 0.15

    private init() {}

    /// Starts device motion updates at 60Hz
    func startUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }
        guard !motionManager.isDeviceMotionActive else { return }

        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates()

        // Use timer for smoother, throttled updates (30Hz for UI)
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.updateMotionData()
        }
    }

    /// Stops device motion updates and resets to neutral position
    func stopUpdates() {
        updateTimer?.invalidate()
        updateTimer = nil
        motionManager.stopDeviceMotionUpdates()

        // Reset to neutral with animation
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.3)) {
                self.pitch = 0
                self.roll = 0
            }
        }
    }

    private func updateMotionData() {
        guard let motion = motionManager.deviceMotion else { return }

        let attitude = motion.attitude

        // Normalize and clamp values
        let normalizedPitch = clamp(attitude.pitch / maxTilt, -1, 1)
        let normalizedRoll = clamp(attitude.roll / maxTilt, -1, 1)

        // Apply smoothing for fluid motion
        DispatchQueue.main.async {
            self.pitch = self.pitch + (normalizedPitch - self.pitch) * self.smoothingFactor
            self.roll = self.roll + (normalizedRoll - self.roll) * self.smoothingFactor
        }
    }

    private func clamp(_ value: Double, _ min: Double, _ max: Double) -> Double {
        Swift.min(Swift.max(value, min), max)
    }
}

// MARK: - CardGlossEffect

/// A view modifier that adds a realistic glossy shine effect to cards.
/// The gloss follows device tilt using inverted motion mapping for realistic reflections.
struct CardGlossEffect: ViewModifier {
    @ObservedObject var motionManager: DeviceMotionManager
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    /// Intensity of the gloss effect (0.0 to 1.0)
    let intensity: Double

    /// Maximum 3D rotation angle in degrees
    private let maxRotation: Double = 3.0

    init(motionManager: DeviceMotionManager = .shared, intensity: Double = 0.4) {
        self.motionManager = motionManager
        self.intensity = intensity
    }

    func body(content: Content) -> some View {
        let shouldApply = colorScheme == .dark && !reduceMotion

        content
            // Apply subtle 3D rotation based on device tilt
            .rotation3DEffect(
                .degrees(shouldApply ? motionManager.pitch * maxRotation : 0),
                axis: (x: 1, y: 0, z: 0),
                perspective: 0.5
            )
            .rotation3DEffect(
                .degrees(shouldApply ? motionManager.roll * maxRotation : 0),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.5
            )
            // Apply glossy overlay
            .overlay(
                Group {
                    if shouldApply {
                        glossOverlay
                    }
                }
            )
            .onAppear {
                if shouldApply {
                    motionManager.startUpdates()
                }
            }
            .onDisappear {
                motionManager.stopUpdates()
            }
            .onChange(of: colorScheme) { oldValue, newValue in
                if newValue == .dark && !reduceMotion {
                    motionManager.startUpdates()
                } else {
                    motionManager.stopUpdates()
                }
            }
    }

    /// The glossy overlay combining radial light spot and linear sheen
    @ViewBuilder
    private var glossOverlay: some View {
        GeometryReader { geometry in
            // Get card's position on screen for position-based light offset
            let screenWidth = UIScreen.main.bounds.width
            let screenHeight = UIScreen.main.bounds.height
            let frame = geometry.frame(in: .global)
            let cardCenterX = frame.midX
            let cardCenterY = frame.midY

            // Calculate position offset (cards further from center get shifted light)
            // Range: -0.15 to +0.15 based on screen position
            let positionOffsetX = ((cardCenterX / screenWidth) - 0.5) * 0.3
            let positionOffsetY = ((cardCenterY / screenHeight) - 0.5) * 0.2

            ZStack {
                // Primary radial light spot that follows device tilt
                // Inverted mapping: tilt right = light moves left (like real reflections)
                // Position offset: cards in different locations catch light differently
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(intensity * 0.15),
                        Color.white.opacity(intensity * 0.05),
                        Color.clear
                    ]),
                    center: UnitPoint(
                        x: 0.5 - motionManager.roll * 0.3 + positionOffsetX,  // Inverted roll + position
                        y: 0.5 - motionManager.pitch * 0.3 + positionOffsetY  // Inverted pitch + position
                    ),
                    startRadius: 0,
                    endRadius: max(geometry.size.width, geometry.size.height) * 0.6
                )

                // Secondary linear sheen for additional depth
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .clear, location: 0.0),
                        .init(color: .clear, location: 0.3),
                        .init(color: Color.white.opacity(intensity * 0.03), location: 0.45),
                        .init(color: Color.white.opacity(intensity * 0.06), location: 0.5),
                        .init(color: Color.white.opacity(intensity * 0.03), location: 0.55),
                        .init(color: .clear, location: 0.7),
                        .init(color: .clear, location: 1.0)
                    ]),
                    startPoint: UnitPoint(
                        x: 0.0 - motionManager.roll * 0.2 + positionOffsetX,
                        y: 0.0 - motionManager.pitch * 0.2 + positionOffsetY
                    ),
                    endPoint: UnitPoint(
                        x: 1.0 - motionManager.roll * 0.2 + positionOffsetX,
                        y: 1.0 - motionManager.pitch * 0.2 + positionOffsetY
                    )
                )
                .blendMode(.overlay)
            }
            .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.CornerRadius.cardLarge, style: .continuous))
    }
}

// MARK: - View Extension

extension View {
    /// Applies a realistic glossy shine effect that responds to device tilt.
    /// Only active in dark mode and respects accessibility reduce motion setting.
    /// - Parameters:
    ///   - motionManager: The motion manager instance (defaults to shared singleton)
    ///   - intensity: The intensity of the gloss effect (0.0 to 1.0, default 0.4)
    func cardGloss(motionManager: DeviceMotionManager = .shared, intensity: Double = 0.4) -> some View {
        modifier(CardGlossEffect(motionManager: motionManager, intensity: intensity))
    }
}

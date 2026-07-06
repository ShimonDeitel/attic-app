import SwiftUI
import UIKit

/// Attic's design language: a dusty attic at golden hour. Deep roof-beam
/// browns, aged brass, candlelight, kraft paper. Serif throughout.
enum AtticTheme {
    // MARK: Palette
    static let night = Color(red: 0.078, green: 0.058, blue: 0.043)
    static let wood = Color(red: 0.145, green: 0.106, blue: 0.075)
    static let woodLight = Color(red: 0.235, green: 0.176, blue: 0.121)
    static let brass = Color(red: 0.69, green: 0.55, blue: 0.34)
    static let brassBright = Color(red: 0.91, green: 0.77, blue: 0.55)
    static let candle = Color(red: 1.0, green: 0.85, blue: 0.62)
    static let parchment = Color(red: 0.953, green: 0.914, blue: 0.835)
    static let parchmentDeep = Color(red: 0.878, green: 0.816, blue: 0.702)
    static let ink = Color(red: 0.165, green: 0.125, blue: 0.086)
    static let inkSoft = Color(red: 0.165, green: 0.125, blue: 0.086).opacity(0.62)
    /// Old rubber-stamp red for the value reveal.
    static let stamp = Color(red: 0.604, green: 0.208, blue: 0.157)

    static let brassGradient = LinearGradient(
        colors: [brassBright, brass, brassBright.opacity(0.85)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    // MARK: Type
    static func display(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
    static func text(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
    /// Small-caps style label (tracking applied at call site).
    static func label(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .serif)
    }
}

enum Haptics {
    static func tap() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func thud() { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
    static func stamp() { UIImpactFeedbackGenerator(style: .heavy).impactOccurred() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
}

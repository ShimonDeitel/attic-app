import SwiftUI

/// A brass magnifying loupe sweeping a slow Lissajous path over the captured
/// photo while identification runs. The glass genuinely magnifies what is
/// beneath it (scale anchored at the lens point, masked to the lens circle).
struct LoupeSweepView: View {
    let image: UIImage

    private let lensDiameter: CGFloat = 132
    private let magnification: CGFloat = 1.45

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let size = geo.size
                let pos = CGPoint(
                    x: size.width * (0.5 + 0.28 * sin(t * 1.15)),
                    y: size.height * (0.5 + 0.28 * sin(t * 0.82 + 1.4))
                )

                ZStack {
                    baseImage(size: size)
                        .opacity(0.9)

                    // Magnified layer, visible only through the lens.
                    baseImage(size: size)
                        .scaleEffect(
                            magnification,
                            anchor: UnitPoint(
                                x: pos.x / max(size.width, 1),
                                y: pos.y / max(size.height, 1)
                            )
                        )
                        .mask(
                            Circle()
                                .frame(width: lensDiameter, height: lensDiameter)
                                .position(pos)
                        )

                    lens(at: pos)
                }
            }
        }
        .clipped()
    }

    private func baseImage(size: CGSize) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: size.width, height: size.height)
            .clipped()
    }

    private func lens(at pos: CGPoint) -> some View {
        ZStack {
            // Warm glow spilling from the glass.
            Circle()
                .fill(
                    RadialGradient(
                        colors: [AtticTheme.candle.opacity(0.28), .clear],
                        center: .center,
                        startRadius: lensDiameter * 0.2,
                        endRadius: lensDiameter * 0.85
                    )
                )
                .frame(width: lensDiameter * 1.7, height: lensDiameter * 1.7)
                .blendMode(.plusLighter)

            // Brass rim.
            Circle()
                .strokeBorder(AtticTheme.brassGradient, lineWidth: 5)
                .frame(width: lensDiameter, height: lensDiameter)
                .shadow(color: AtticTheme.night.opacity(0.55), radius: 10, y: 5)

            // Glass sheen.
            Circle()
                .trim(from: 0.56, to: 0.74)
                .stroke(
                    Color.white.opacity(0.4),
                    style: StrokeStyle(lineWidth: 7, lineCap: .round)
                )
                .frame(width: lensDiameter - 26, height: lensDiameter - 26)
                .blur(radius: 2)

            // Handle, trailing down-right from the rim.
            Capsule()
                .fill(AtticTheme.brassGradient)
                .frame(width: 12, height: lensDiameter * 0.52)
                .offset(y: lensDiameter * 0.72)
                .rotationEffect(.degrees(-42))
                .shadow(color: AtticTheme.night.opacity(0.5), radius: 8, y: 4)
        }
        .position(pos)
        .allowsHitTesting(false)
    }
}

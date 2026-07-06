import SwiftUI

/// A kraft-paper price tag that flips in on its string, then stamps the
/// value range with a heavy haptic thunk.
struct TagRevealView: View {
    let result: ScanResult
    var onDetails: () -> Void
    var onNext: () -> Void

    @State private var flipped = false
    @State private var stamped = false

    var body: some View {
        VStack(spacing: 22) {
            tag
                .rotation3DEffect(
                    .degrees(flipped ? 0 : 88),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.55
                )

            HStack(spacing: 14) {
                Button(action: onDetails) {
                    Text("In the Attic")
                        .font(AtticTheme.text(16, weight: .semibold))
                        .foregroundStyle(AtticTheme.parchment)
                        .padding(.vertical, 13)
                        .padding(.horizontal, 22)
                        .background(
                            Capsule().strokeBorder(AtticTheme.brass, lineWidth: 1.5)
                        )
                }

                Button {
                    Haptics.tap()
                    onNext()
                } label: {
                    Text("Scan next")
                        .font(AtticTheme.text(16, weight: .semibold))
                        .foregroundStyle(AtticTheme.ink)
                        .padding(.vertical, 13)
                        .padding(.horizontal, 28)
                        .background(Capsule().fill(AtticTheme.brassGradient))
                }
            }
            .opacity(stamped ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.72).delay(0.05)) {
                flipped = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) {
                    stamped = true
                }
                Haptics.stamp()
            }
        }
    }

    private var tag: some View {
        VStack(spacing: 14) {
            // Eyelet + string stub.
            ZStack {
                Circle()
                    .strokeBorder(AtticTheme.brass, lineWidth: 3)
                    .frame(width: 18, height: 18)
                StringShape()
                    .stroke(AtticTheme.parchmentDeep, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 60, height: 34)
                    .offset(y: -26)
            }
            .padding(.top, 18)

            Text(result.name)
                .font(AtticTheme.display(26))
                .foregroundStyle(AtticTheme.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            VStack(spacing: 4) {
                if !result.era.isEmpty {
                    Text(result.era)
                        .font(AtticTheme.text(15).italic())
                        .foregroundStyle(AtticTheme.inkSoft)
                }
                if !result.maker.isEmpty {
                    Text(result.maker)
                        .font(AtticTheme.text(14))
                        .foregroundStyle(AtticTheme.inkSoft)
                }
            }

            DashedLine()
                .stroke(AtticTheme.inkSoft.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
                .frame(height: 1)
                .padding(.horizontal, 28)

            // The stamp.
            VStack(spacing: 3) {
                Text(valueRangeText)
                    .font(AtticTheme.display(30, weight: .bold))
                Text("ESTIMATED SOLD PRICE")
                    .font(AtticTheme.label(9))
                    .tracking(2.4)
            }
            .foregroundStyle(AtticTheme.stamp)
            .padding(.vertical, 12)
            .padding(.horizontal, 18)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(AtticTheme.stamp.opacity(0.8), lineWidth: 2.5)
            )
            .rotationEffect(.degrees(-3))
            .scaleEffect(stamped ? 1 : 1.7)
            .opacity(stamped ? 1 : 0)

            VStack(spacing: 3) {
                Text("Confidence: \(confidenceLabel)")
                    .font(AtticTheme.text(13))
                Text("An estimate, not an appraisal.")
                    .font(AtticTheme.text(12).italic())
            }
            .foregroundStyle(AtticTheme.inkSoft)
            .padding(.bottom, 22)
        }
        .frame(maxWidth: 320)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [AtticTheme.parchment, AtticTheme.parchmentDeep],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .shadow(color: AtticTheme.night.opacity(0.6), radius: 24, y: 12)
        )
    }

    private var valueRangeText: String {
        let low = Self.currency(result.valueLow)
        let high = Self.currency(result.valueHigh)
        return "\(low) to \(high)"
    }

    private var confidenceLabel: String {
        switch result.confidence {
        case 0.7...: return "high"
        case 0.4..<0.7: return "fair"
        default: return "low"
        }
    }

    private static func currency(_ value: Double) -> String {
        value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }
}

private struct StringShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.2)
        )
        return p
    }
}

private struct DashedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return p
    }
}

import SwiftUI
import StoreKit

/// Attic Pro. Shown after the moment of value (first scan result), never on
/// first launch. Transparent pricing, no trial traps (Apple guideline 5.6).
struct PaywallView: View {
    @Environment(StoreManager.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var selectedProductID: String?
    @State private var isPurchasing = false

    // Live legal pages are a submission blocker; the links render once these
    // URLs exist (see MILLION_QUEUE.md shared-infrastructure notes).
    private static let privacyURL: URL? = nil
    private static let termsURL: URL? = nil

    var body: some View {
        ZStack {
            AtticBackdrop(intensity: 0.6)

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AtticTheme.parchment.opacity(0.6))
                            .padding(10)
                            .background(Circle().fill(AtticTheme.woodLight.opacity(0.5)))
                    }
                    .accessibilityLabel("Close")
                }
                .padding(.top, 14)
                .padding(.horizontal, 20)

                ScrollView {
                    VStack(spacing: 22) {
                        keyMark
                        titleBlock
                        if store.isPro {
                            proActive
                        } else {
                            offerBlock
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 30)
                }
            }
        }
        .task {
            if store.products.isEmpty { await store.loadProducts() }
            if selectedProductID == nil {
                selectedProductID = store.products.last?.id ?? StoreManager.yearlyProductID
            }
        }
    }

    // MARK: Header art

    private var keyMark: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [AtticTheme.candle.opacity(0.25), .clear],
                        center: .center, startRadius: 6, endRadius: 70
                    )
                )
                .frame(width: 130, height: 130)
                .blendMode(.plusLighter)
            Circle()
                .strokeBorder(AtticTheme.brassGradient, lineWidth: 3)
                .frame(width: 84, height: 84)
            Image(systemName: "key.fill")
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(AtticTheme.brassBright)
                .rotationEffect(.degrees(-45))
        }
        .padding(.top, 4)
    }

    private var titleBlock: some View {
        VStack(spacing: 8) {
            Text("Attic Pro")
                .font(AtticTheme.display(32, weight: .bold))
                .foregroundStyle(AtticTheme.parchment)
            Text("Every find, identified and valued.")
                .font(AtticTheme.text(15).italic())
                .foregroundStyle(AtticTheme.parchment.opacity(0.6))
        }
    }

    // MARK: Offer

    private var offerBlock: some View {
        VStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 12) {
                bullet("Unlimited identifications")
                bullet("Sold-price value ranges on every find")
                bullet("Your whole attic, totaled")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if store.products.isEmpty {
                if store.isLoadingProducts {
                    ProgressView()
                        .tint(AtticTheme.brassBright)
                        .padding(.vertical, 26)
                } else {
                    VStack(spacing: 10) {
                        Text("Prices are hiding somewhere up here.")
                            .font(AtticTheme.text(14).italic())
                            .foregroundStyle(AtticTheme.parchment.opacity(0.6))
                        Button("Try again") {
                            Task { await store.loadProducts() }
                        }
                        .font(AtticTheme.text(15, weight: .semibold))
                        .foregroundStyle(AtticTheme.brassBright)
                    }
                    .padding(.vertical, 16)
                }
            } else {
                VStack(spacing: 12) {
                    ForEach(store.products) { product in
                        productCard(product)
                    }
                }
            }

            purchaseButton

            Button("Restore purchases") {
                Task { await store.restorePurchases() }
            }
            .font(AtticTheme.text(14))
            .foregroundStyle(AtticTheme.parchment.opacity(0.55))

            if let message = store.lastErrorMessage {
                Text(message)
                    .font(AtticTheme.text(12))
                    .foregroundStyle(AtticTheme.stamp)
                    .multilineTextAlignment(.center)
            }

            footnote
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AtticTheme.brassBright)
            Text(text)
                .font(AtticTheme.text(15))
                .foregroundStyle(AtticTheme.parchment.opacity(0.85))
        }
    }

    private func productCard(_ product: Product) -> some View {
        let isSelected = selectedProductID == product.id
        let isYearly = product.subscription?.subscriptionPeriod.unit == .year

        return Button {
            Haptics.tap()
            selectedProductID = product.id
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(isYearly ? "Yearly" : "Monthly")
                        .font(AtticTheme.text(17, weight: .semibold))
                        .foregroundStyle(AtticTheme.ink)
                    if isYearly, let monthly = yearlyPerMonthText(product) {
                        Text("\(monthly) a month")
                            .font(AtticTheme.text(12))
                            .foregroundStyle(AtticTheme.inkSoft)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text(product.displayPrice)
                        .font(AtticTheme.display(19, weight: .bold))
                        .foregroundStyle(AtticTheme.ink)
                    Text(isYearly ? "per year" : "per month")
                        .font(AtticTheme.text(11))
                        .foregroundStyle(AtticTheme.inkSoft)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [AtticTheme.parchment, AtticTheme.parchmentDeep],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        isSelected ? AtticTheme.brassBright : AtticTheme.brass.opacity(0.25),
                        lineWidth: isSelected ? 2.5 : 1
                    )
            )
            .overlay(alignment: .topTrailing) {
                if isYearly, let savings = yearlySavingsText {
                    Text(savings)
                        .font(AtticTheme.label(10))
                        .tracking(1)
                        .foregroundStyle(AtticTheme.ink)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(AtticTheme.brassBright))
                        .offset(x: -10, y: -9)
                }
            }
        }
        .buttonStyle(.plain)
    }

    /// Honest math from live StoreKit prices, never hardcoded copy.
    private func yearlyPerMonthText(_ yearly: Product) -> String? {
        let perMonth = yearly.price / 12
        return perMonth.formatted(yearly.priceFormatStyle.precision(.fractionLength(2)))
    }

    private var yearlySavingsText: String? {
        guard
            let monthly = store.products.first(where: { $0.subscription?.subscriptionPeriod.unit == .month }),
            let yearly = store.products.first(where: { $0.subscription?.subscriptionPeriod.unit == .year }),
            monthly.price > 0
        else { return nil }
        let fullYear = monthly.price * 12
        guard fullYear > yearly.price else { return nil }
        let fraction = (fullYear - yearly.price) / fullYear
        let percent = Int((NSDecimalNumber(decimal: fraction).doubleValue * 100).rounded())
        return "SAVE \(percent)%"
    }

    private var purchaseButton: some View {
        Button {
            guard let product = store.products.first(where: { $0.id == selectedProductID }) else { return }
            Haptics.thud()
            isPurchasing = true
            Task {
                defer { isPurchasing = false }
                let success = await store.purchase(product)
                if success {
                    Haptics.success()
                    dismiss()
                }
            }
        } label: {
            ZStack {
                Capsule()
                    .fill(AtticTheme.brassGradient)
                    .frame(height: 56)
                    .shadow(color: AtticTheme.candle.opacity(0.3), radius: 14)
                if isPurchasing {
                    ProgressView().tint(AtticTheme.ink)
                } else {
                    Text("Unlock the Attic")
                        .font(AtticTheme.text(18, weight: .bold))
                        .foregroundStyle(AtticTheme.ink)
                }
            }
        }
        .disabled(isPurchasing || store.products.isEmpty || selectedProductID == nil)
        .opacity(store.products.isEmpty ? 0.35 : 1)
        .buttonStyle(PressableButtonStyle())
    }

    private var footnote: some View {
        VStack(spacing: 8) {
            Text("Auto-renews until cancelled. Cancel anytime in Settings.")
                .font(AtticTheme.text(11))
                .foregroundStyle(AtticTheme.parchment.opacity(0.4))
                .multilineTextAlignment(.center)
            HStack(spacing: 18) {
                if let url = Self.privacyURL {
                    Link("Privacy", destination: url)
                }
                if let url = Self.termsURL {
                    Link("Terms", destination: url)
                }
            }
            .font(AtticTheme.text(11))
            .foregroundStyle(AtticTheme.parchment.opacity(0.4))
        }
    }

    // MARK: Pro active

    private var proActive: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 40))
                .foregroundStyle(AtticTheme.brassBright)
            Text("The attic is yours.")
                .font(AtticTheme.display(20))
                .foregroundStyle(AtticTheme.parchment)
            Text("Unlimited looks, forever renewed.")
                .font(AtticTheme.text(14).italic())
                .foregroundStyle(AtticTheme.parchment.opacity(0.6))
        }
        .padding(.vertical, 30)
    }
}

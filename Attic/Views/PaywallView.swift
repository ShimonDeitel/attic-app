import SwiftUI
import StoreKit

// PLACEHOLDER UI — functional purchase list only, no design. The real
// paywall (shown after first scan result, transparent pricing) is designed
// separately later.
struct PaywallView: View {
    @Environment(StoreManager.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var purchasingProductID: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Unlimited scans, high-res mark analysis, and PDF inventory export.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Attic Pro") {
                    if store.isPro {
                        Label("Pro is active", systemImage: "checkmark.seal.fill")
                    } else if store.products.isEmpty {
                        if store.isLoadingProducts {
                            ProgressView()
                        } else {
                            Text("Products unavailable.")
                                .foregroundStyle(.secondary)
                            Button("Retry") {
                                Task { await store.loadProducts() }
                            }
                        }
                    } else {
                        ForEach(store.products) { product in
                            Button {
                                purchase(product)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(product.displayName)
                                        Text(product.description)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if purchasingProductID == product.id {
                                        ProgressView()
                                    } else {
                                        Text(product.displayPrice)
                                            .fontWeight(.semibold)
                                    }
                                }
                            }
                            .disabled(purchasingProductID != nil)
                        }
                    }
                }

                Section {
                    Button("Restore Purchases") {
                        Task { await store.restorePurchases() }
                    }
                }

                if let message = store.lastErrorMessage {
                    Section {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Attic Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func purchase(_ product: Product) {
        purchasingProductID = product.id
        Task {
            defer { purchasingProductID = nil }
            let success = await store.purchase(product)
            if success { dismiss() }
        }
    }
}

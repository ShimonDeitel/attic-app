import SwiftUI
import SwiftData

/// The attic inventory: a brass plaque totaling the estate, and every find
/// resting on parchment cards. Pushed from the home screen.
struct InventoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CollectionItem.createdAt, order: .reverse) private var items: [CollectionItem]

    private var totalLow: Double { items.reduce(0) { $0 + $1.valueLow } }
    private var totalHigh: Double { items.reduce(0) { $0 + $1.valueHigh } }

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
    ]

    var body: some View {
        ZStack {
            AtticBackdrop(intensity: 0.45)

            if items.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 18) {
                        plaque
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(items) { item in
                                NavigationLink(value: item) {
                                    ItemCard(item: item)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        modelContext.delete(item)
                                    } label: {
                                        Label("Remove from the attic", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("THE ATTIC")
                    .font(AtticTheme.label(14))
                    .tracking(3)
                    .foregroundStyle(AtticTheme.parchment)
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationDestination(for: CollectionItem.self) { item in
            ItemDetailView(item: item)
        }
    }

    // MARK: Plaque

    private var plaque: some View {
        VStack(spacing: 6) {
            Text("ESTIMATED ESTATE")
                .font(AtticTheme.label(10))
                .tracking(3)
                .foregroundStyle(AtticTheme.brass)
            Text(midEstimateText)
                .font(AtticTheme.display(38, weight: .bold))
                .foregroundStyle(AtticTheme.parchment)
                .contentTransition(.numericText())
            Text("\(items.count) \(items.count == 1 ? "find" : "finds")  ·  \(rangeText)")
                .font(AtticTheme.text(13))
                .foregroundStyle(AtticTheme.parchment.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AtticTheme.woodLight.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(AtticTheme.brass.opacity(0.65), lineWidth: 1.5)
                )
        )
    }

    private var midEstimateText: String {
        let mid = (totalLow + totalHigh) / 2
        return "≈ " + mid.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }

    private var rangeText: String {
        let low = totalLow.formatted(.currency(code: "USD").precision(.fractionLength(0)))
        let high = totalHigh.formatted(.currency(code: "USD").precision(.fractionLength(0)))
        return "\(low) - \(high)"
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .strokeBorder(
                        AtticTheme.brass.opacity(0.5),
                        style: StrokeStyle(lineWidth: 1.5, dash: [7, 7])
                    )
                    .frame(width: 120, height: 120)
                Image(systemName: "archivebox")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(AtticTheme.brassBright.opacity(0.85))
            }
            Text("Nothing up here yet")
                .font(AtticTheme.display(22))
                .foregroundStyle(AtticTheme.parchment)
            Text("Scan your first find and it will\nwait for you on these shelves.")
                .font(AtticTheme.text(14).italic())
                .foregroundStyle(AtticTheme.parchment.opacity(0.55))
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Item card

private struct ItemCard: View {
    let item: CollectionItem

    var body: some View {
        VStack(spacing: 0) {
            photo
                .frame(height: 138)
                .frame(maxWidth: .infinity)
                .clipped()

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(AtticTheme.text(15, weight: .semibold))
                    .foregroundStyle(AtticTheme.ink)
                    .lineLimit(1)
                Text(rangeText)
                    .font(AtticTheme.text(12))
                    .foregroundStyle(AtticTheme.inkSoft)
                if !item.room.isEmpty {
                    Text(item.room)
                        .font(AtticTheme.text(11).italic())
                        .foregroundStyle(AtticTheme.inkSoft.opacity(0.8))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(AtticTheme.parchment)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(alignment: .topTrailing) {
            if item.worthSecondLook {
                Image(systemName: "seal.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(AtticTheme.ink)
                    .padding(6)
                    .background(Circle().fill(AtticTheme.brassBright))
                    .padding(8)
                    .accessibilityLabel("Worth a second look")
            }
        }
        // The shelf it rests on.
        .background(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 3)
                .fill(AtticTheme.woodLight)
                .frame(height: 6)
                .offset(y: 9)
                .shadow(color: AtticTheme.night.opacity(0.8), radius: 6, y: 4)
        }
        .shadow(color: AtticTheme.night.opacity(0.45), radius: 10, y: 6)
    }

    @ViewBuilder
    private var photo: some View {
        if let data = item.photoData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                AtticTheme.parchmentDeep
                Image(systemName: "photo")
                    .font(.system(size: 26))
                    .foregroundStyle(AtticTheme.inkSoft.opacity(0.5))
            }
        }
    }

    private var rangeText: String {
        let low = item.valueLow.formatted(.currency(code: "USD").precision(.fractionLength(0)))
        let high = item.valueHigh.formatted(.currency(code: "USD").precision(.fractionLength(0)))
        return "\(low) - \(high)"
    }
}

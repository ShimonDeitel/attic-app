import SwiftUI
import SwiftData

// PLACEHOLDER UI — plain list inventory. Rooms/boxes grouping UI and the
// bespoke design come later.
struct InventoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CollectionItem.createdAt, order: .reverse) private var items: [CollectionItem]

    private var totalLow: Double { items.reduce(0) { $0 + $1.valueLow } }
    private var totalHigh: Double { items.reduce(0) { $0 + $1.valueHigh } }

    var body: some View {
        NavigationStack {
            List {
                if !items.isEmpty {
                    Section {
                        LabeledContent("Estimated total") {
                            Text("\(totalLow, format: .currency(code: "USD")) - \(totalHigh, format: .currency(code: "USD"))")
                        }
                        LabeledContent("Items", value: "\(items.count)")
                    }
                }
                Section {
                    ForEach(items) { item in
                        NavigationLink(value: item) {
                            HStack(spacing: 12) {
                                thumbnail(for: item)
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 4) {
                                        Text(item.name)
                                            .lineLimit(1)
                                        if item.worthSecondLook {
                                            Image(systemName: "star.circle.fill")
                                                .foregroundStyle(.orange)
                                                .accessibilityLabel("Worth a second look")
                                        }
                                    }
                                    Text("\(item.valueLow, format: .currency(code: "USD")) - \(item.valueHigh, format: .currency(code: "USD"))")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                    if !item.room.isEmpty {
                                        Text(item.room)
                                            .font(.caption)
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                            }
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
            }
            .overlay {
                if items.isEmpty {
                    ContentUnavailableView(
                        "Nothing in the attic yet",
                        systemImage: "archivebox",
                        description: Text("Scan your first item to start your inventory.")
                    )
                }
            }
            .navigationTitle("Attic")
            .navigationDestination(for: CollectionItem.self) { item in
                ItemDetailView(item: item)
            }
        }
    }

    @ViewBuilder
    private func thumbnail(for item: CollectionItem) -> some View {
        if let data = item.photoData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemBackground))
                .frame(width: 44, height: 44)
                .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(items[index])
        }
    }
}

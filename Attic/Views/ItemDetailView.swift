import SwiftUI
import SwiftData

// PLACEHOLDER UI — plain form detail screen. The paper-tag design comes later.
struct ItemDetailView: View {
    @Bindable var item: CollectionItem

    var body: some View {
        Form {
            if let data = item.photoData, let image = UIImage(data: data) {
                Section {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .listRowBackground(Color.clear)
                }
            }

            Section("Identification") {
                TextField("Name", text: $item.name)
                LabeledContent("Era", value: item.era.isEmpty ? "Unknown" : item.era)
                LabeledContent("Maker", value: item.maker.isEmpty ? "Unknown" : item.maker)
                LabeledContent("Materials", value: item.materials.isEmpty ? "Unknown" : item.materials)
                LabeledContent("Confidence", value: "\(Int(item.confidence * 100))%")
            }

            Section("Value") {
                LabeledContent("Estimated range") {
                    Text("\(item.valueLow, format: .currency(code: "USD")) - \(item.valueHigh, format: .currency(code: "USD"))")
                }
                Toggle("Worth a second look", isOn: $item.worthSecondLook)
                if let url = item.ebaySoldListingsURL {
                    Link("See real eBay sold listings", destination: url)
                }
                Text("This is an estimate, not an appraisal.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Organize") {
                TextField("Room or box", text: $item.room)
                TextField("Notes", text: $item.notes, axis: .vertical)
                    .lineLimit(3...8)
            }

            Section {
                LabeledContent("Added", value: item.createdAt.formatted(date: .abbreviated, time: .shortened))
            }
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        // Real tap-outside keyboard dismiss (scrollDismissesKeyboard alone is
        // not sufficient per house convention).
        .simultaneousGesture(
            TapGesture().onEnded {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil
                )
            }
        )
    }
}

import SwiftUI
import SwiftData

/// One find, laid out like its own kraft tag: photo up top, identification
/// rows, the stamped value, then room and notes.
struct ItemDetailView: View {
    @Bindable var item: CollectionItem
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var confirmingDelete = false

    var body: some View {
        ZStack {
            AtticBackdrop(intensity: 0.35)

            ScrollView {
                VStack(spacing: 16) {
                    photoCard
                    identificationCard
                    valueCard
                    organizeCard
                    footer
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        // Real tap-outside keyboard dismiss (house convention:
        // scrollDismissesKeyboard alone is not sufficient).
        .simultaneousGesture(
            TapGesture().onEnded {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil
                )
            }
        )
        .confirmationDialog(
            "Remove this find from the attic?",
            isPresented: $confirmingDelete,
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                modelContext.delete(item)
                dismiss()
            }
        }
    }

    // MARK: Photo

    @ViewBuilder
    private var photoCard: some View {
        if let data = item.photoData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 260)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(AtticTheme.brass.opacity(0.6), lineWidth: 1.5)
                )
                .shadow(color: AtticTheme.night.opacity(0.5), radius: 14, y: 8)
        }
    }

    // MARK: Identification

    private var identificationCard: some View {
        parchmentCard {
            TextField("Name", text: $item.name)
                .font(AtticTheme.display(22))
                .foregroundStyle(AtticTheme.ink)

            fieldRow("ERA", value: item.era)
            fieldRow("MAKER", value: item.maker)
            fieldRow("MATERIALS", value: item.materials)
            fieldRow("CONFIDENCE", value: "\(Int(item.confidence * 100))%")
        }
    }

    private func fieldRow(_ label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(AtticTheme.label(10))
                .tracking(2)
                .foregroundStyle(AtticTheme.inkSoft.opacity(0.8))
                .frame(width: 96, alignment: .leading)
            Text(value.isEmpty ? "Unknown" : value)
                .font(AtticTheme.text(15))
                .foregroundStyle(value.isEmpty ? AtticTheme.inkSoft : AtticTheme.ink)
            Spacer(minLength: 0)
        }
    }

    // MARK: Value

    private var valueCard: some View {
        parchmentCard {
            VStack(alignment: .leading, spacing: 4) {
                Text("ESTIMATED SOLD PRICE")
                    .font(AtticTheme.label(10))
                    .tracking(2.4)
                    .foregroundStyle(AtticTheme.stamp.opacity(0.85))
                Text(rangeText)
                    .font(AtticTheme.display(30, weight: .bold))
                    .foregroundStyle(AtticTheme.stamp)
                Text("An estimate, not an appraisal.")
                    .font(AtticTheme.text(12).italic())
                    .foregroundStyle(AtticTheme.inkSoft)
            }

            if let url = item.ebaySoldListingsURL {
                Link(destination: url) {
                    HStack {
                        Text("See real sold prices")
                            .font(AtticTheme.text(15, weight: .semibold))
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(AtticTheme.ink)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Capsule().fill(AtticTheme.brassGradient))
                }
            }

            Toggle(isOn: $item.worthSecondLook) {
                HStack(spacing: 8) {
                    Image(systemName: "seal.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(AtticTheme.brass)
                    Text("Worth a second look")
                        .font(AtticTheme.text(15))
                        .foregroundStyle(AtticTheme.ink)
                }
            }
            .tint(AtticTheme.brass)
        }
    }

    private var rangeText: String {
        let low = item.valueLow.formatted(.currency(code: "USD").precision(.fractionLength(0)))
        let high = item.valueHigh.formatted(.currency(code: "USD").precision(.fractionLength(0)))
        return "\(low) to \(high)"
    }

    // MARK: Organize

    private var organizeCard: some View {
        parchmentCard {
            VStack(alignment: .leading, spacing: 6) {
                Text("WHERE IT LIVES")
                    .font(AtticTheme.label(10))
                    .tracking(2)
                    .foregroundStyle(AtticTheme.inkSoft.opacity(0.8))
                TextField("Room or box", text: $item.room)
                    .font(AtticTheme.text(15))
                    .foregroundStyle(AtticTheme.ink)
                    .padding(10)
                    .background(fieldBackground)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("NOTES")
                    .font(AtticTheme.label(10))
                    .tracking(2)
                    .foregroundStyle(AtticTheme.inkSoft.opacity(0.8))
                TextField("Family history, condition, hunches…", text: $item.notes, axis: .vertical)
                    .font(AtticTheme.text(15))
                    .foregroundStyle(AtticTheme.ink)
                    .lineLimit(3...8)
                    .padding(10)
                    .background(fieldBackground)
            }
        }
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(AtticTheme.parchmentDeep.opacity(0.45))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(AtticTheme.inkSoft.opacity(0.25), lineWidth: 1)
            )
    }

    // MARK: Footer

    private var footer: some View {
        VStack(spacing: 14) {
            Text("Found \(item.createdAt.formatted(date: .long, time: .omitted))")
                .font(AtticTheme.text(12).italic())
                .foregroundStyle(AtticTheme.parchment.opacity(0.45))
            Button(role: .destructive) {
                confirmingDelete = true
            } label: {
                Text("Remove from the attic")
                    .font(AtticTheme.text(14))
                    .foregroundStyle(AtticTheme.stamp.opacity(0.9))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 6)
    }

    // MARK: Card chrome

    private func parchmentCard(@ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [AtticTheme.parchment, AtticTheme.parchmentDeep],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .shadow(color: AtticTheme.night.opacity(0.4), radius: 10, y: 6)
        )
    }
}

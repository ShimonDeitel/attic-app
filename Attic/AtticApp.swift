import SwiftUI
import SwiftData

@main
struct AtticApp: App {
    @State private var store = StoreManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
        }
        .modelContainer(for: CollectionItem.self)
    }
}

/// Single-stack navigation: the attic (ScanView) is home; the inventory is a
/// door in its corner. No tab bar — two destinations don't earn one.
struct RootView: View {
    var body: some View {
        Group {
            #if DEBUG
            if let screen = ProcessInfo.processInfo.environment["ATTIC_SCREEN"] {
                DebugScreenHost(screen: screen)
            } else {
                mainNavigation
            }
            #else
            mainNavigation
            #endif
        }
        .tint(AtticTheme.brassBright)
        .preferredColorScheme(.dark)
    }

    private var mainNavigation: some View {
        NavigationStack {
            ScanView()
        }
    }
}

#if DEBUG
/// Dev-only direct screen routing for headless screenshot verification:
/// SIMCTL_CHILD_ATTIC_SCREEN=paywall|inventory|reveal xcrun simctl launch …
/// Never compiled into Release.
private struct DebugScreenHost: View {
    let screen: String
    @Environment(\.modelContext) private var context

    var body: some View {
        switch screen {
        case "paywall":
            PaywallView()
        case "inventory":
            NavigationStack { InventoryView() }
                .task { seedSamplesIfEmpty() }
        case "reveal":
            ZStack {
                AtticBackdrop()
                AtticTheme.night.opacity(0.72).ignoresSafeArea()
                TagRevealView(result: .debugSample, onDetails: {}, onNext: {})
                    .padding(.horizontal, 24)
            }
        default:
            NavigationStack { ScanView() }
        }
    }

    private func seedSamplesIfEmpty() {
        let count = (try? context.fetchCount(FetchDescriptor<CollectionItem>())) ?? 0
        guard count == 0 else { return }
        let samples: [CollectionItem] = [
            CollectionItem(
                name: "Victorian oil lamp", era: "Victorian, c. 1885", maker: "",
                materials: "brass, glass", valueLow: 60, valueHigh: 140,
                confidence: 0.74, searchTerm: "victorian brass oil lamp", room: "Hall closet"
            ),
            CollectionItem(
                name: "Jadeite mixing bowl", era: "1940s", maker: "Fire-King",
                materials: "jadeite glass", valueLow: 35, valueHigh: 80,
                confidence: 0.81, searchTerm: "fire king jadeite mixing bowl", room: "Kitchen"
            ),
            CollectionItem(
                name: "Mantel clock", era: "Art Deco, c. 1930", maker: "Seth Thomas",
                materials: "walnut, brass", valueLow: 220, valueHigh: 420,
                confidence: 0.66, searchTerm: "seth thomas art deco mantel clock",
                worthSecondLook: true
            ),
            CollectionItem(
                name: "Cast iron doorstop", era: "c. 1920", maker: "Hubley",
                materials: "cast iron", valueLow: 90, valueHigh: 260,
                confidence: 0.58, searchTerm: "hubley cast iron doorstop", room: "Attic, box 3"
            ),
        ]
        for sample in samples {
            context.insert(sample)
        }
    }
}

extension ScanResult {
    static let debugSample = ScanResult(
        name: "Seth Thomas mantel clock",
        era: "Art Deco, c. 1930",
        maker: "Seth Thomas",
        materials: "walnut, brass",
        valueLow: 220,
        valueHigh: 420,
        confidence: 0.78,
        searchTerm: "seth thomas art deco mantel clock"
    )
}
#endif

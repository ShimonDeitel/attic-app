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

// PLACEHOLDER UI — minimal navigation shell only. The bespoke attic-trunk
// design (dust motes, loupe sweep, tag flip) is built separately later.
struct RootView: View {
    var body: some View {
        TabView {
            ScanView()
                .tabItem { Label("Scan", systemImage: "viewfinder") }
            InventoryView()
                .tabItem { Label("Attic", systemImage: "archivebox") }
        }
    }
}

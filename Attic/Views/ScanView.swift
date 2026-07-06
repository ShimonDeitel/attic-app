import SwiftUI
import SwiftData

// PLACEHOLDER UI — functional scan flow only. The loupe-sweep animation and
// tag-flip value reveal are designed separately later.
struct ScanView: View {
    @Environment(StoreManager.self) private var store
    @Environment(\.modelContext) private var modelContext

    @State private var camera = CameraService()
    @State private var permissionGranted = false
    @State private var cameraSetupFailed = false
    @State private var isScanning = false
    @State private var showPaywall = false
    @State private var statusMessage: String?
    @State private var lastResult: ScanResult?

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                previewArea

                if let statusMessage {
                    Text(statusMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                if let lastResult {
                    // PLACEHOLDER UI — raw result readout.
                    VStack(spacing: 4) {
                        Text(lastResult.name).font(.headline)
                        Text("\(lastResult.valueLow, format: .currency(code: "USD")) - \(lastResult.valueHigh, format: .currency(code: "USD"))")
                        Text("Confidence \(Int(lastResult.confidence * 100))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 0)

                if !store.isPro {
                    Text("\(store.freeScansRemaining) free scan(s) left")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button(action: scanTapped) {
                    if isScanning {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Scan Item")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isScanning || !permissionGranted)

                Button("Switch Camera") {
                    do { try camera.switchCamera() } catch { statusMessage = error.localizedDescription }
                }
                .disabled(!permissionGranted || !camera.isConfigured)
            }
            .padding()
            .navigationTitle("Scan")
            .task { await setUpCamera() }
            .onDisappear { camera.stop() }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    @ViewBuilder
    private var previewArea: some View {
        if permissionGranted && camera.isConfigured {
            CameraPreview(session: camera.session)
                .frame(maxWidth: .infinity)
                .frame(height: 400)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            // PLACEHOLDER UI
            ContentUnavailableView(
                cameraSetupFailed ? "Camera unavailable" : "Camera access needed",
                systemImage: "camera",
                description: Text(cameraSetupFailed
                    ? "The camera could not be started (expected in the simulator)."
                    : "Attic needs the camera to identify your items.")
            )
            .frame(maxWidth: .infinity)
            .frame(height: 400)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func setUpCamera() async {
        permissionGranted = await CameraService.requestPermission()
        guard permissionGranted else { return }
        do {
            try camera.configure()
            camera.start()
        } catch {
            cameraSetupFailed = true
            statusMessage = error.localizedDescription
        }
    }

    private func scanTapped() {
        guard store.canScan else {
            showPaywall = true
            return
        }
        isScanning = true
        statusMessage = nil
        Task {
            defer { isScanning = false }
            do {
                let photo = try await camera.capturePhoto()
                guard let api = AtticAPI.makeDefault() else {
                    statusMessage = AtticAPI.APIError.notConfigured.localizedDescription
                    return
                }
                let result = try await api.identify(images: [photo])
                let item = CollectionItem(result: result, photoData: photo)
                modelContext.insert(item)
                store.recordScan()
                lastResult = result
                statusMessage = "Saved to your attic."
                // Paywall is shown after the first scan RESULT (moment of
                // value) once the free tier is exhausted.
                if !store.isPro && store.freeScansRemaining == 0 {
                    showPaywall = true
                }
            } catch {
                statusMessage = error.localizedDescription
            }
        }
    }
}

import SwiftUI
import SwiftData
import PhotosUI

/// Home: the attic. A brass loupe viewport onto the camera, dust drifting
/// through a shaft of light, and the archive door to the inventory.
struct ScanView: View {
    private enum Phase: Equatable {
        case idle
        case analyzing(UIImage)
        case revealed(ScanResult)
    }

    @Environment(StoreManager.self) private var store
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [CollectionItem]

    @State private var camera = CameraService()
    @State private var permissionGranted = false
    @State private var cameraSetupFailed = false

    @State private var phase: Phase = .idle
    @State private var captionIndex = 0
    @State private var errorMessage: String?
    @State private var showPaywall = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var detailItem: CollectionItem?
    @State private var lastSavedItem: CollectionItem?

    private let viewportDiameter: CGFloat = 308
    private static let captions = [
        "Looking closely…",
        "Reading maker's marks…",
        "Weighing the era…",
        "Checking what these sell for…",
    ]

    var body: some View {
        ZStack {
            AtticBackdrop()

            VStack(spacing: 0) {
                header
                Spacer(minLength: 12)
                viewport
                statusLine
                    .padding(.top, 26)
                Spacer(minLength: 12)
                controls
                    .padding(.bottom, 18)
            }
            .padding(.horizontal, 24)
        }
        .overlay { revealOverlay }
        .overlay(alignment: .bottom) { errorToast }
        .task { await setUpCamera() }
        .onDisappear { camera.stop() }
        .onChange(of: pickerItem) { _, newValue in
            guard let newValue else { return }
            pickerItem = nil
            handlePickedItem(newValue)
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .navigationDestination(item: $detailItem) { item in
            ItemDetailView(item: item)
        }
        .navigationDestination(for: CollectionItem.self) { item in
            ItemDetailView(item: item)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("ATTIC")
                    .font(AtticTheme.display(34, weight: .bold))
                    .tracking(7)
                    .foregroundStyle(AtticTheme.parchment)
                Text("what's your stuff worth?")
                    .font(AtticTheme.text(14).italic())
                    .foregroundStyle(AtticTheme.parchment.opacity(0.55))
            }
            Spacer()
            NavigationLink {
                InventoryView()
            } label: {
                ZStack(alignment: .topTrailing) {
                    Circle()
                        .strokeBorder(AtticTheme.brass, lineWidth: 1.5)
                        .frame(width: 48, height: 48)
                        .overlay(
                            Image(systemName: "archivebox")
                                .font(.system(size: 19))
                                .foregroundStyle(AtticTheme.brassBright)
                        )
                    if !items.isEmpty {
                        Text("\(items.count)")
                            .font(AtticTheme.label(11))
                            .foregroundStyle(AtticTheme.ink)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(AtticTheme.brassBright))
                            .offset(x: 6, y: -4)
                    }
                }
            }
            .accessibilityLabel("Your attic, \(items.count) items")
        }
        .padding(.top, 10)
    }

    // MARK: Viewport

    private var viewport: some View {
        ZStack {
            // Halo where the shaft hits the glass.
            Circle()
                .fill(
                    RadialGradient(
                        colors: [AtticTheme.candle.opacity(0.18), .clear],
                        center: .center,
                        startRadius: viewportDiameter * 0.32,
                        endRadius: viewportDiameter * 0.75
                    )
                )
                .frame(width: viewportDiameter * 1.45, height: viewportDiameter * 1.45)
                .blendMode(.plusLighter)

            viewportContent
                .frame(width: viewportDiameter, height: viewportDiameter)
                .clipShape(Circle())

            Circle()
                .strokeBorder(AtticTheme.brassGradient, lineWidth: 6)
                .frame(width: viewportDiameter, height: viewportDiameter)
                .shadow(color: AtticTheme.night.opacity(0.7), radius: 22, y: 10)
        }
        // The halo is wider than the screen; without pinning the layout size
        // to the ring, it inflates the whole VStack past the screen edges.
        .frame(width: viewportDiameter, height: viewportDiameter)
    }

    @ViewBuilder
    private var viewportContent: some View {
        switch phase {
        case .analyzing(let image):
            LoupeSweepView(image: image)
        case .idle, .revealed:
            if permissionGranted && camera.isConfigured {
                CameraPreview(session: camera.session)
            } else {
                emptyViewport
            }
        }
    }

    private var emptyViewport: some View {
        ZStack {
            RadialGradient(
                colors: [AtticTheme.woodLight.opacity(0.65), AtticTheme.night],
                center: .init(x: 0.62, y: 0.3),
                startRadius: 10, endRadius: viewportDiameter * 0.8
            )
            Circle()
                .strokeBorder(
                    AtticTheme.brass.opacity(0.5),
                    style: StrokeStyle(lineWidth: 1.5, dash: [7, 7])
                )
                .padding(26)
            VStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(AtticTheme.brassBright.opacity(0.9))
                Text(emptyViewportText)
                    .font(AtticTheme.text(15).italic())
                    .foregroundStyle(AtticTheme.parchment.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 42)
            }
        }
    }

    private var emptyViewportText: String {
        if cameraSetupFailed {
            return "No camera here.\nPick a photo below instead."
        }
        if !permissionGranted && CameraService.authorizationStatus == .denied {
            return "Camera access is off.\nEnable it in Settings, or pick a photo."
        }
        return "Point at anything old.\nInherited, thrifted, found."
    }

    // MARK: Status line

    @ViewBuilder
    private var statusLine: some View {
        switch phase {
        case .analyzing:
            Text(Self.captions[captionIndex % Self.captions.count])
                .font(AtticTheme.text(15).italic())
                .foregroundStyle(AtticTheme.candle.opacity(0.9))
                .transition(.opacity)
                .id(captionIndex)
        default:
            if store.isPro {
                plaque("THE ATTIC IS YOURS")
            } else {
                plaque(freeLooksText)
            }
        }
    }

    private var freeLooksText: String {
        let n = store.freeScansRemaining
        switch n {
        case 0: return "NO FREE LOOKS LEFT"
        case 1: return "1 FREE LOOK LEFT"
        default: return "\(n) FREE LOOKS LEFT"
        }
    }

    private func plaque(_ text: String) -> some View {
        Text(text)
            .font(AtticTheme.label(11))
            .tracking(2.2)
            .foregroundStyle(AtticTheme.brassBright)
            .padding(.vertical, 7)
            .padding(.horizontal, 16)
            .background(
                Capsule()
                    .fill(AtticTheme.woodLight.opacity(0.55))
                    .overlay(Capsule().strokeBorder(AtticTheme.brass.opacity(0.6), lineWidth: 1))
            )
    }

    // MARK: Controls

    private var controls: some View {
        HStack {
            PhotosPicker(selection: $pickerItem, matching: .images) {
                controlIcon("photo.on.rectangle.angled", label: "Photos")
            }
            .disabled(isBusy)

            Spacer()

            Button(action: scanTapped) {
                ZStack {
                    Circle()
                        .fill(AtticTheme.brassGradient)
                        .frame(width: 82, height: 82)
                        .shadow(color: AtticTheme.candle.opacity(0.35), radius: 18)
                    Circle()
                        .strokeBorder(AtticTheme.ink.opacity(0.35), lineWidth: 2)
                        .frame(width: 68, height: 68)
                    if isBusy {
                        ProgressView()
                            .tint(AtticTheme.ink)
                    } else {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 27, weight: .medium))
                            .foregroundStyle(AtticTheme.ink)
                    }
                }
            }
            .buttonStyle(PressableButtonStyle())
            .disabled(isBusy)
            .accessibilityLabel("Scan item")

            Spacer()

            Button {
                Haptics.tap()
                do { try camera.switchCamera() } catch { errorMessage = error.localizedDescription }
            } label: {
                controlIcon("arrow.triangle.2.circlepath.camera", label: "Flip")
            }
            .disabled(isBusy || !camera.isConfigured)
        }
        .padding(.horizontal, 14)
    }

    private func controlIcon(_ systemName: String, label: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: systemName)
                .font(.system(size: 21))
            Text(label)
                .font(AtticTheme.text(11))
        }
        .foregroundStyle(AtticTheme.parchment.opacity(0.65))
        .frame(width: 58)
    }

    private var isBusy: Bool {
        if case .analyzing = phase { return true }
        return false
    }

    // MARK: Reveal overlay

    @ViewBuilder
    private var revealOverlay: some View {
        if case .revealed(let result) = phase {
            ZStack {
                AtticTheme.night.opacity(0.72)
                    .ignoresSafeArea()
                TagRevealView(
                    result: result,
                    onDetails: {
                        phase = .idle
                        detailItem = lastSavedItem
                    },
                    onNext: {
                        phase = .idle
                        if !store.isPro && store.freeScansRemaining == 0 {
                            showPaywall = true
                        }
                    }
                )
                .padding(.horizontal, 24)
            }
            .transition(.opacity)
        }
    }

    // MARK: Error toast

    @ViewBuilder
    private var errorToast: some View {
        if let errorMessage {
            Text(errorMessage)
                .font(AtticTheme.text(13))
                .foregroundStyle(AtticTheme.ink)
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12).fill(AtticTheme.parchment)
                )
                .padding(.horizontal, 30)
                .padding(.bottom, 116)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onTapGesture { self.errorMessage = nil }
                .task {
                    try? await Task.sleep(for: .seconds(5))
                    withAnimation { self.errorMessage = nil }
                }
        }
    }

    // MARK: Camera lifecycle

    /// Never prompts at launch: the permission ask happens in context, on the
    /// first scan tap. Here we only wire up a camera we're already allowed.
    private func setUpCamera() async {
        guard CameraService.authorizationStatus == .authorized else { return }
        permissionGranted = true
        startCameraSession()
    }

    private func startCameraSession() {
        do {
            try camera.configure()
            camera.start()
        } catch {
            cameraSetupFailed = true
        }
    }

    // MARK: Scan flow

    private func scanTapped() {
        guard store.canScan else {
            Haptics.warning()
            showPaywall = true
            return
        }
        // First tap asks for the camera in context; the live preview
        // appearing is that tap's payoff, the next tap scans.
        guard permissionGranted else {
            Task {
                permissionGranted = await CameraService.requestPermission()
                if permissionGranted {
                    startCameraSession()
                } else {
                    withAnimation {
                        errorMessage = "Camera access is off. Pick a photo below instead."
                    }
                }
            }
            return
        }
        guard camera.isConfigured else {
            errorMessage = "No camera here. Pick a photo below instead."
            return
        }
        Haptics.thud()
        Task {
            do {
                let photoData = try await camera.capturePhoto()
                await identify(photoData: photoData)
            } catch {
                withAnimation { errorMessage = error.localizedDescription }
            }
        }
    }

    private func handlePickedItem(_ item: PhotosPickerItem) {
        guard store.canScan else {
            Haptics.warning()
            showPaywall = true
            return
        }
        Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    withAnimation { errorMessage = "Could not read that photo." }
                    return
                }
                await identify(photoData: data)
            } catch {
                withAnimation { errorMessage = error.localizedDescription }
            }
        }
    }

    @MainActor
    private func identify(photoData: Data) async {
        guard let uiImage = UIImage(data: photoData) else {
            withAnimation { errorMessage = "Could not read that photo." }
            return
        }
        withAnimation { phase = .analyzing(uiImage) }
        captionIndex = 0
        let captionTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1.6))
                guard !Task.isCancelled else { break }
                withAnimation(.easeInOut(duration: 0.35)) { captionIndex += 1 }
            }
        }
        defer { captionTask.cancel() }

        guard let api = AtticAPI.makeDefault() else {
            withAnimation {
                phase = .idle
                errorMessage = AtticAPI.APIError.notConfigured.localizedDescription
            }
            return
        }
        do {
            let result = try await api.identify(images: [photoData])
            let item = CollectionItem(result: result, photoData: photoData)
            modelContext.insert(item)
            lastSavedItem = item
            store.recordScan()
            withAnimation(.easeOut(duration: 0.25)) { phase = .revealed(result) }
        } catch {
            Haptics.warning()
            withAnimation {
                phase = .idle
                errorMessage = error.localizedDescription
            }
        }
    }
}

/// Scale-down press feedback for the big brass button.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

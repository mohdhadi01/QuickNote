import AppKit
import SwiftUI
import Foundation

/// QA instrumentation: renders the app's real windows and hosted views to
/// flattened PNG files without requiring Screen Recording permission (the app
/// draws its own views). Activated with launch argument `-quicknote.debugSnapshot`.
@MainActor
enum DebugSnapshot {
    /// Sandbox-safe output directory inside the app container's temp space.
    static var directoryPath: String? {
        guard ProcessInfo.processInfo.arguments.contains("-quicknote.debugSnapshot") else { return nil }
        return URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("quicknote-snapshots", isDirectory: true).path
    }

    static func capture(window: NSWindow, name: String) {
        guard let directoryPath, let contentView = window.contentView else { return }
        capture(view: contentView, name: name)
    }

    static func capture(view: NSView, name: String) {
        guard directoryPath != nil else { return }
        guard let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return }
        view.cacheDisplay(in: view.bounds, to: rep)
        write(rep: rep, name: name)
    }

    /// Hosts a SwiftUI view in a real (hidden) window so AppKit-backed
    /// controls render faithfully, snapshots it, and tears the window down.
    static func captureHosted<V: View>(_ view: V, size: CGSize, name: String, appearance: NSAppearance?) {
        guard directoryPath != nil else { return }
        let window = NSWindow(
            contentRect: NSRect(x: 40, y: 200, width: size.width, height: size.height),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        window.appearance = appearance
        window.backgroundColor = .windowBackgroundColor
        window.contentView = NSHostingView(rootView: view)
        window.orderBack(nil)
        RunLoop.main.run(until: Date().addingTimeInterval(0.15))
        capture(window: window, name: name)
        window.orderOut(nil)
    }

    /// Captures the SwiftUI content of the glass capture panel directly
    /// (NSGlassEffectView itself does not participate in offscreen drawing).
    static func capturePanelContent(window: NSWindow, name: String) {
        func findViews(_ view: NSView, matching contains: String) -> [NSView] {
            var results: [NSView] = []
            if NSStringFromClass(type(of: view)).contains(contains) { results.append(view) }
            for subview in view.subviews {
                results.append(contentsOf: findViews(subview, matching: contains))
            }
            return results
        }
        guard let contentView = window.contentView else { return }
        let hostingViews = findViews(contentView, matching: "NSHostingView")
        let textViews = findViews(contentView, matching: "CaptureTextView")

        // Render hosting view via its layer for full fidelity.
        if let hosting = hostingViews.first, let layer = hosting.layer {
            let width = Int(layer.bounds.width * 2)
            let height = Int(layer.bounds.height * 2)
            if let rep = NSBitmapImageRep(
                bitmapDataPlanes: nil, pixelsWide: max(width, 1), pixelsHigh: max(height, 1),
                bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
            ) {
                NSGraphicsContext.saveGraphicsState()
                let ctx = NSGraphicsContext(bitmapImageRep: rep)
                NSGraphicsContext.current = ctx
                if let cg = ctx?.cgContext {
                    cg.scaleBy(x: 2, y: 2)
                    layer.render(in: cg)
                }
                NSGraphicsContext.restoreGraphicsState()
                write(rep: rep, name: name)
                return
            }
        }

        // Fallback: capture the editor text view itself.
        if let textView = textViews.first {
            capture(view: textView, name: name)
        }
    }

    private static func write(rep: NSBitmapImageRep, name: String) {
        guard let directoryPath else { return }
        guard let data = flattenOntoWhite(rep).representation(using: .png, properties: [:]) else { return }
        let directory = URL(fileURLWithPath: directoryPath, isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        do {
            try data.write(to: directory.appendingPathComponent("\(name).png"))
            Log.app.info("Snapshot written: \(name, privacy: .public)")
        } catch {
            Log.app.error("Snapshot write failed: \(String(describing: error), privacy: .public)")
        }
    }

    /// Translucent window regions (materials) composite over white so the
    /// PNG matches the default light desktop backdrop.
    private static func flattenOntoWhite(_ rep: NSBitmapImageRep) -> NSBitmapImageRep {
        guard let flattened = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: rep.pixelsWide,
            pixelsHigh: rep.pixelsHigh,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: false,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else { return rep }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: flattened)
        let size = NSSize(width: rep.pixelsWide, height: rep.pixelsHigh)
        NSColor.white.setFill()
        NSRect(origin: .zero, size: size).fill()
        let image = NSImage(size: size)
        image.addRepresentation(rep)
        image.draw(in: NSRect(origin: .zero, size: size))
        NSGraphicsContext.restoreGraphicsState()
        return flattened
    }
}

/// Drives the snapshot sequence: captures the main window, every Settings
/// tab, and the quick capture panel (empty + typed), in light then dark mode,
/// then terminates the app.
@MainActor
final class DebugSnapshotDriver {
    private let coordinator: AppCoordinator
    private let environment: AppEnvironment

    init(coordinator: AppCoordinator, environment: AppEnvironment) {
        self.coordinator = coordinator
        self.environment = environment
    }

    func run() {
        guard DebugSnapshot.directoryPath != nil else { return }
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await MainActor.run {
                NSApp.appearance = NSAppearance(named: .aqua)
                self?.appearance = NSAppearance(named: .aqua)
                self?.captureAll(suffix: "light")
            }
            try? await Task.sleep(nanoseconds: 800_000_000)
            await MainActor.run { self?.switchToDark() }
            try? await Task.sleep(nanoseconds: 800_000_000)
            await MainActor.run { self?.captureAll(suffix: "dark") }
            try? await Task.sleep(nanoseconds: 500_000_000)
            await MainActor.run {
                NSApp.appearance = nil
                NSApp.terminate(nil)
            }
        }
    }

    private var appearance: NSAppearance?

    private func switchToDark() {
        let dark = NSAppearance(named: .darkAqua)
        appearance = dark
        NSApp.appearance = dark
    }

    private func captureAll(suffix: String) {
        // 1. Main window (a regular NSWindow, not the capture panel).
        if let mainWindow = NSApp.windows.first(where: { !$0.isKind(of: NSPanel.self) && $0.isVisible && $0.contentView != nil }) {
            mainWindow.appearance = appearance
            DebugSnapshot.capture(window: mainWindow, name: "main-\(suffix)")
        }

        // 2. Settings tabs hosted in real windows with the app's services.
        DebugSnapshot.captureHosted(
            GeneralSettingsView().environmentObject(environment.loginItem),
            size: CGSize(width: 540, height: 340),
            name: "settings-general-\(suffix)",
            appearance: appearance
        )
        DebugSnapshot.captureHosted(
            QuickCaptureSettingsView()
                .environmentObject(environment.settings)
                .environment(environment.shortcutService),
            size: CGSize(width: 540, height: 340),
            name: "settings-capture-\(suffix)",
            appearance: appearance
        )
        DebugSnapshot.captureHosted(
            PrivacySettingsView().environmentObject(environment.settings),
            size: CGSize(width: 540, height: 340),
            name: "settings-privacy-\(suffix)",
            appearance: appearance
        )
        DebugSnapshot.captureHosted(
            AppearanceSettingsView().environmentObject(environment.settings),
            size: CGSize(width: 540, height: 340),
            name: "settings-appearance-\(suffix)",
            appearance: appearance
        )
        DebugSnapshot.captureHosted(
            AboutSettingsView()
                .background(Color(nsColor: .windowBackgroundColor)),
            size: CGSize(width: 540, height: 340),
            name: "settings-about-\(suffix)",
            appearance: appearance
        )
        DebugSnapshot.captureHosted(
            OnboardingView()
                .environmentObject(environment.settings)
                .environmentObject(AccessibilityEnvironmentFlags.shared)
                .background(Color(nsColor: .windowBackgroundColor)),
            size: CGSize(width: 560, height: 460),
            name: "onboarding-\(suffix)",
            appearance: appearance
        )

        // 3. Quick capture panel content, hosted in a plain window (the
        // NSGlassEffectView material itself cannot be captured offscreen).
        DebugSnapshot.captureHosted(
            QuickCaptureView(viewModel: environment.captureViewModel, flags: environment.flags, onTextViewReady: { _ in })
                .background(Color(nsColor: .windowBackgroundColor))
                .frame(width: DesignTokens.CapturePanel.initialWidth, height: DesignTokens.CapturePanel.initialHeight),
            size: CGSize(width: DesignTokens.CapturePanel.initialWidth, height: DesignTokens.CapturePanel.initialHeight),
            name: "capture-layout-\(suffix)",
            appearance: appearance
        )

        // 4. Live capture panel: type text and capture (best-effort pixels).
        environment.captureViewModel.text = "Remember to optimize the React Native animation.\nCheck frame timing on device tomorrow."
        coordinator.quickCaptureCoordinator.present()
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 900_000_000)
            await MainActor.run { self?.capturePanel(suffix: suffix) }
        }
    }

    private func capturePanel(suffix: String) {
        if let panel = NSApp.windows.first(where: { $0 is NSPanel && $0.isVisible }) {
            panel.appearance = appearance
            DebugSnapshot.capturePanelContent(window: panel, name: "capture-typed-\(suffix)")
        }
        coordinator.quickCaptureCoordinator.requestCancel()
    }
}

extension AppCoordinator {
    /// Launches the snapshot sequence when the debug flag is present (QA).
    @MainActor
    func runDebugSnapshotDriverIfNeeded(environment: AppEnvironment) {
        guard DebugSnapshot.directoryPath != nil else { return }
        let driver = DebugSnapshotDriver(coordinator: self, environment: environment)
        snapshotDriver = driver
        driver.run()
    }
}

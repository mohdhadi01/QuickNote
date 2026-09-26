import SwiftUI
import AppKit

@main
@MainActor
struct QuickNoteApp: App {
    @NSApplicationDelegateAdaptor(AppLifecycle.self) private var lifecycle
    @State private var environment: AppEnvironment
    @State private var coordinator: AppCoordinator

    init() {
        let env = AppEnvironment.bootstrap()
        _environment = State(initialValue: env)
        let appCoordinator = AppCoordinator(environment: env)
        _coordinator = State(initialValue: appCoordinator)
        lifecycle.coordinator = appCoordinator
        appCoordinator.runDebugSnapshotDriverIfNeeded(environment: env)
    }

    var body: some Scene {
        WindowGroup(id: "main") {
            AppRootView()
                .quickNoteEnvironment(environment, coordinator: coordinator)
        }
        .defaultSize(
            width: DesignTokens.MainWindow.defaultWidth,
            height: DesignTokens.MainWindow.defaultHeight
        )
        .windowResizability(.contentMinSize)

        Settings {
            SettingsView()
                .quickNoteEnvironment(environment, coordinator: coordinator)
        }

        MenuBarExtra("QuickNote", systemImage: "square.and.pencil") {
            MenuBarContentView()
                .quickNoteEnvironment(environment, coordinator: coordinator)
        }
        .menuBarExtraStyle(.menu)
    }
}

/// First launch shows onboarding inside the main window (spec §48); after
/// that, the notes workspace.
private struct AppRootView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @EnvironmentObject private var settings: SettingsService

    var body: some View {
        if settings.hasCompletedOnboarding {
            MainNotesView(
                viewModel: coordinator.notesViewModel,
                persistenceRecovery: coordinator.persistenceRecovery
            )
        } else {
            OnboardingView()
        }
    }
}

extension View {
    /// Injects the shared app services into a scene.
    @MainActor
    func quickNoteEnvironment(_ environment: AppEnvironment, coordinator: AppCoordinator) -> some View {
        self
            .environment(coordinator)
            .environment(environment.shortcutService)
            .environmentObject(environment.settings)
            .environmentObject(environment.flags)
            .environmentObject(environment.loginItem)
            .environmentObject(environment.notesViewModel)
    }
}

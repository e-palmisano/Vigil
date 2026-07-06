import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    @Published private(set) var lockState: LockState = .unlocked

    let lockManager: LockManager
    let settings: AppSettings
    let shortcutService: GlobalShortcutService
    let updaterService: UpdateCheckerService

    private let inputBlockingService: InputBlockingServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(settings: AppSettings = .shared) {
        self.settings = settings

        let inputBlocking = InputBlockingService()
        let displayManager = DisplayManagerService()
        let authentication = AuthenticationService()
        let sleepPrevention = SleepPreventionService()

        self.inputBlockingService = inputBlocking
        self.lockManager = LockManager(
            inputBlockingService: inputBlocking,
            displayManagerService: displayManager,
            authenticationService: authentication,
            sleepPreventionService: sleepPrevention,
            settings: settings
        )

        self.shortcutService = GlobalShortcutService(settings: settings)
        self.updaterService = UpdateCheckerService()

        lockManager.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] newState in
                self?.lockState = newState
            }
            .store(in: &cancellables)

        reregisterShortcuts()
        recoverLockStateIfNeeded()
        if settings.checkForUpdatesAtLaunch {
            updaterService.startPeriodicChecks()
        }
    }

    private func recoverLockStateIfNeeded() {
        guard settings.wasLockedOnExit else { return }
        let mode = LockMode(rawValue: settings.lockModeOnExit) ?? .obscured
        Task { try? await lockManager.lock(mode: mode) }
    }

    func reregisterShortcuts() {
        shortcutService.register(
            onLockVisible: { [weak self] in self?.lockVisible() },
            onLockObscured: { [weak self] in self?.lockObscured() }
        )
        // Unlock and emergency shortcuts are handled inside the input tap so
        // they fire while blocking; a global monitor never sees those events.
        inputBlockingService.setUnlockShortcut(settings.globalShortcutUnlock)
        inputBlockingService.setEmergencyShortcut(settings.emergencyShortcut)
    }

    func lockVisible() {
        Task { try? await lockManager.lock(mode: .visible) }
    }

    func lockObscured() {
        Task { try? await lockManager.lock(mode: .obscured) }
    }

    func unlock() {
        Task { await lockManager.unlock() }
    }

    func checkForUpdates() {
        updaterService.checkNow()
    }

    var isLocked: Bool { lockState.isLocked }

    var menuBarIcon: String { lockManager.menuBarIcon }
}

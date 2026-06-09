import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    @Published private(set) var lockState: LockState = .unlocked

    let lockManager: LockManager
    let settings: AppSettings
    let shortcutService: GlobalShortcutService

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

        lockManager.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] newState in
                self?.lockState = newState
            }
            .store(in: &cancellables)

        registerShortcuts()
        recoverLockStateIfNeeded()
    }

    private func recoverLockStateIfNeeded() {
        guard settings.wasLockedOnExit else { return }
        let mode = LockMode(rawValue: settings.lockModeOnExit) ?? .obscured
        Task { try? await lockManager.lock(mode: mode) }
    }

    private func registerShortcuts() {
        shortcutService.register(
            onLockVisible: { [weak self] in self?.lockVisible() },
            onLockObscured: { [weak self] in self?.lockObscured() },
            onEmergencyUnlock: { [weak self] in self?.lockManager.emergencyUnlock() }
        )
        inputBlockingService.setUnlockShortcut(settings.globalShortcutUnlock)
        // Detected inside the event tap: the NSEvent monitor registered above
        // never sees the emergency combo while input is being blocked.
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

    var isLocked: Bool { lockState.isLocked }

    var menuBarIcon: String { lockManager.menuBarIcon }
}

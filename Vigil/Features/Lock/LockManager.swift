import SwiftUI
import Combine
import IOKit.pwr_mgt

@MainActor
final class LockManager: ObservableObject {
    @Published private(set) var state: LockState = .unlocked

    private let inputBlockingService: InputBlockingServiceProtocol
    private let displayManagerService: DisplayManagerServiceProtocol
    private let authenticationService: AuthenticationServiceProtocol
    private let sleepPreventionService: SleepPreventionServiceProtocol
    private let settings: AppSettings

    private var sleepAssertionID: IOPMAssertionID?
    private var cancellables = Set<AnyCancellable>()

    init(
        inputBlockingService: InputBlockingServiceProtocol,
        displayManagerService: DisplayManagerServiceProtocol,
        authenticationService: AuthenticationServiceProtocol,
        sleepPreventionService: SleepPreventionServiceProtocol,
        settings: AppSettings = .shared
    ) {
        self.inputBlockingService = inputBlockingService
        self.displayManagerService = displayManagerService
        self.authenticationService = authenticationService
        self.sleepPreventionService = sleepPreventionService
        self.settings = settings

        inputBlockingService.onEventTapDisabled = { [weak self] in
            Task { @MainActor [weak self] in
                self?.handleEventTapDisabled()
            }
        }

        $state.sink { [weak self] newState in
            self?.persistStateForCrashRecovery(newState)
        }.store(in: &cancellables)
    }

    var menuBarIcon: String {
        switch state {
        case .unlocked: return "lock.open"
        case .locking, .lockedVisible, .lockedObscured, .unlocking: return "lock.fill"
        case .error: return "exclamationmark.lock"
        }
    }

    var isLocked: Bool { state.isLocked }

    func lock(mode: LockMode) async throws {
        guard state == .unlocked else { return }
        guard inputBlockingService.checkAccessibilityPermission() else {
            inputBlockingService.requestAccessibilityPermission()
            throw InputBlockingError.accessibilityPermissionDenied
        }

        state = .locking

        do {
            try inputBlockingService.startBlocking()
        } catch {
            state = .unlocked
            throw error
        }

        if settings.preventSleep {
            sleepAssertionID = try? sleepPreventionService.preventSleep(reason: "Vigil input lock active")
        }

        if mode == .obscured {
            displayManagerService.createOverlayWindows(
                style: settings.currentOverlayStyle,
                mode: mode,
                onUnlock: { [weak self] in
                    Task { @MainActor [weak self] in await self?.unlock() }
                }
            )
            state = .lockedObscured
        } else {
            state = .lockedVisible
        }
    }

    func unlock() async {
        guard state.isLocked else { return }
        let previousState = state
        state = .unlocking

        do {
            let success = try await authenticationService.authenticate(
                reason: "Authenticate to unlock Vigil"
            )
            if success {
                performUnlock()
            } else {
                state = previousState
            }
        } catch {
            state = previousState
        }
    }

    func emergencyUnlock() {
        performUnlock()
    }

    func switchMode(to mode: LockMode) async {
        guard state.isLocked else { return }
        if mode == .obscured && state == .lockedVisible {
            displayManagerService.createOverlayWindows(
                style: settings.currentOverlayStyle,
                mode: mode,
                onUnlock: { [weak self] in
                    Task { @MainActor [weak self] in await self?.unlock() }
                }
            )
            state = .lockedObscured
        } else if mode == .visible && state == .lockedObscured {
            displayManagerService.removeAllOverlayWindows()
            state = .lockedVisible
        }
    }

    func handleEventTapDisabled() {
        state = .error("eventTapDisabled")
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            if case .error = state {
                state = .unlocked
            }
        }
    }

    private func performUnlock() {
        inputBlockingService.stopBlocking()
        displayManagerService.removeAllOverlayWindows()
        if let id = sleepAssertionID {
            sleepPreventionService.allowSleep(assertionID: id)
            sleepAssertionID = nil
        }
        state = .unlocked
    }

    private func persistStateForCrashRecovery(_ newState: LockState) {
        switch newState {
        case .lockedVisible:
            settings.wasLockedOnExit = true
            settings.lockModeOnExit = LockMode.visible.rawValue
        case .lockedObscured:
            settings.wasLockedOnExit = true
            settings.lockModeOnExit = LockMode.obscured.rawValue
        case .unlocked:
            settings.wasLockedOnExit = false
        default:
            break
        }
    }
}

import SwiftUI
import Combine
import IOKit.pwr_mgt
import OSLog
import UserNotifications

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

        // Keep the input tap's clickable regions in sync with the actual
        // Vigil windows (badge / overlays), including on screen hot-plug.
        displayManagerService.onInteractiveFramesChanged = { [weak self] rects in
            self?.inputBlockingService.setInteractiveRects(rects)
        }

        inputBlockingService.onEventTapDisabled = { [weak self] in
            Task { @MainActor [weak self] in
                self?.handleEventTapDisabled()
            }
        }

        inputBlockingService.onUnlockShortcutPressed = { [weak self] in
            Task { @MainActor [weak self] in await self?.unlock() }
        }

        inputBlockingService.onEmergencyUnlockPressed = { [weak self] in
            Task { @MainActor [weak self] in self?.emergencyUnlock() }
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
            try inputBlockingService.startBlocking(mode: mode)
        } catch {
            state = .unlocked
            throw error
        }

        if settings.preventSleep {
            sleepAssertionID = try? sleepPreventionService.preventSleep(reason: "Vigil input lock active")
        }

        showLockPresentation(for: mode)
        state = state(for: mode)
    }

    func unlock() async {
        guard state.isLocked else { return }
        let previousState = state
        let previousMode = mode(for: previousState)
        state = .unlocking

        // LocalAuthentication presents a system-owned prompt. A screen-saver
        // level overlay and the HID event tap can otherwise cover the prompt
        // and swallow password input, leaving obscured mode impossible to exit.
        suspendInputAndPresentationForAuthentication()

        do {
            let success = try await authenticationService.authenticate(
                reason: "Authenticate to unlock Vigil"
            )
            if success {
                performUnlock()
            } else {
                restoreLock(afterFailedAuthenticationIn: previousMode, state: previousState)
            }
        } catch {
            restoreLock(afterFailedAuthenticationIn: previousMode, state: previousState)
        }
    }

    func emergencyUnlock() {
        performUnlock()
    }

    func switchMode(to mode: LockMode) async {
        guard state.isLocked else { return }
        if mode == .obscured && state == .lockedVisible {
            showLockPresentation(for: .obscured)
            state = .lockedObscured
        } else if mode == .visible && state == .lockedObscured {
            displayManagerService.removeAllOverlayWindows()
            showLockPresentation(for: .visible)
            state = .lockedVisible
        }
    }

    private let logger = Logger(subsystem: "com.palmi.vigil", category: "LockManager")

    func handleEventTapDisabled() {
        logger.error("CGEventTap was disabled by the system — input blocking stopped unexpectedly")
        // The tap is gone, so input already flows. Tear the rest of the lock
        // down too — otherwise overlays keep covering the screen, the sleep
        // assertion leaks, and the input service still holds a stale tap that
        // blocks the next startBlocking.
        teardownLockResources()
        state = .error("eventTapDisabled")
        postEventTapNotification()
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            if case .error = state {
                state = .unlocked
            }
        }
    }

    private func postEventTapNotification() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            let content = UNMutableNotificationContent()
            content.title = "Vigil: Input Monitoring Stopped"
            content.body = "The system disabled input blocking. Your machine may be briefly unprotected."
            content.sound = .defaultCritical
            let request = UNNotificationRequest(
                identifier: "vigil.eventTapDisabled",
                content: content,
                trigger: nil
            )
            center.add(request, withCompletionHandler: nil)
        }
    }

    private func showLockPresentation(for mode: LockMode) {
        if mode == .obscured {
            displayManagerService.createOverlayWindows(
                style: settings.currentOverlayStyle,
                mode: mode,
                isTouchIDAvailable: authenticationService.isTouchIDAvailable,
                onUnlock: { [weak self] in
                    Task { @MainActor [weak self] in await self?.unlock() }
                }
            )
        } else {
            displayManagerService.createBadgeWindow(
                isTouchIDAvailable: authenticationService.isTouchIDAvailable,
                onUnlock: { [weak self] in
                    Task { @MainActor [weak self] in await self?.unlock() }
                }
            )
        }
    }

    private func suspendInputAndPresentationForAuthentication() {
        inputBlockingService.stopBlocking()
        displayManagerService.removeAllOverlayWindows()
    }

    private func restoreLock(afterFailedAuthenticationIn mode: LockMode, state previousState: LockState) {
        do {
            try inputBlockingService.startBlocking(mode: mode)
        } catch {
            self.state = .error("eventTapCreationFailed")
            return
        }

        showLockPresentation(for: mode)
        state = previousState
    }

    private func performUnlock() {
        teardownLockResources()
        state = .unlocked
    }

    /// Releases every OS resource the lock holds: the input tap, the overlay
    /// windows, and the sleep assertion. Deliberately does not touch `state`,
    /// so callers can move to `.unlocked` or `.error` as appropriate.
    private func teardownLockResources() {
        inputBlockingService.stopBlocking()
        displayManagerService.removeAllOverlayWindows()
        if let id = sleepAssertionID {
            sleepPreventionService.allowSleep(assertionID: id)
            sleepAssertionID = nil
        }
    }

    private func mode(for state: LockState) -> LockMode {
        switch state {
        case .lockedVisible:
            return .visible
        case .lockedObscured:
            return .obscured
        default:
            return settings.lockMode
        }
    }

    private func state(for mode: LockMode) -> LockState {
        switch mode {
        case .visible:
            return .lockedVisible
        case .obscured:
            return .lockedObscured
        }
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

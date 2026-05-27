import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    @Published private(set) var lockState: LockState = .unlocked

    let lockManager: LockManager
    let settings: AppSettings

    private var cancellables = Set<AnyCancellable>()

    init(settings: AppSettings = .shared) {
        self.settings = settings

        let inputBlocking = InputBlockingService()
        let displayManager = DisplayManagerService()
        let authentication = AuthenticationService()
        let sleepPrevention = SleepPreventionService()

        self.lockManager = LockManager(
            inputBlockingService: inputBlocking,
            displayManagerService: displayManager,
            authenticationService: authentication,
            sleepPreventionService: sleepPrevention,
            settings: settings
        )

        lockManager.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] newState in
                self?.lockState = newState
            }
            .store(in: &cancellables)
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

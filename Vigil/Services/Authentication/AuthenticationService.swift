import Foundation
import LocalAuthentication
import AppKit

final class AuthenticationService: AuthenticationServiceProtocol {

    private var cachedTouchIDAvailable: Bool?
    private var wakeObserver: NSObjectProtocol?

    init() {
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in self?.cachedTouchIDAvailable = nil }
    }

    deinit {
        if let observer = wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }

    var isTouchIDAvailable: Bool {
        if let cached = cachedTouchIDAvailable { return cached }
        let context = LAContext()
        var error: NSError?
        let result = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        cachedTouchIDAvailable = result
        return result
    }

    func authenticateBiometricsOnly(reason: String) async throws -> Bool {
        let context = LAContext()
        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
        } catch let error as LAError {
            throw mapped(error)
        }
    }

    func authenticate(reason: String) async throws -> Bool {
        let context = LAContext()
        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
        } catch let error as LAError {
            throw mapped(error)
        }
    }

    private func mapped(_ error: LAError) -> AuthenticationError {
        switch error.code {
        case .userCancel, .appCancel, .systemCancel: return .cancelled
        case .biometryNotAvailable, .biometryNotEnrolled: return .notAvailable
        default: return .failed(error.localizedDescription)
        }
    }
}

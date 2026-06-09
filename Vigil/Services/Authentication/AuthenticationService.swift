import Foundation
import LocalAuthentication

final class AuthenticationService: AuthenticationServiceProtocol {

    var isTouchIDAvailable: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    func authenticateBiometricsOnly(reason: String) async throws -> Bool {
        try await evaluate(.deviceOwnerAuthenticationWithBiometrics, reason: reason)
    }

    func authenticate(reason: String) async throws -> Bool {
        try await evaluate(.deviceOwnerAuthentication, reason: reason)
    }

    private func evaluate(_ policy: LAPolicy, reason: String) async throws -> Bool {
        let context = LAContext()
        do {
            return try await context.evaluatePolicy(policy, localizedReason: reason)
        } catch let error as LAError {
            throw Self.mapped(error)
        }
    }

    private static func mapped(_ error: LAError) -> AuthenticationError {
        switch error.code {
        case .userCancel, .appCancel, .systemCancel:
            return .cancelled
        case .biometryNotAvailable, .biometryNotEnrolled:
            return .notAvailable
        default:
            return .failed(error.localizedDescription)
        }
    }
}

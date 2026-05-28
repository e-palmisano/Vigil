import Foundation
import LocalAuthentication

final class AuthenticationService: AuthenticationServiceProtocol {

    var isTouchIDAvailable: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    func authenticateBiometricsOnly(reason: String) async throws -> Bool {
        let context = LAContext()
        do {
            let result = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            return result
        } catch let error as LAError {
            switch error.code {
            case .userCancel, .appCancel, .systemCancel:
                throw AuthenticationError.cancelled
            case .biometryNotAvailable, .biometryNotEnrolled:
                throw AuthenticationError.notAvailable
            default:
                throw AuthenticationError.failed(error.localizedDescription)
            }
        }
    }

    func authenticate(reason: String) async throws -> Bool {
        let context = LAContext()
        do {
            let result = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            return result
        } catch let error as LAError {
            switch error.code {
            case .userCancel, .appCancel, .systemCancel:
                throw AuthenticationError.cancelled
            case .biometryNotAvailable, .biometryNotEnrolled:
                throw AuthenticationError.notAvailable
            default:
                throw AuthenticationError.failed(error.localizedDescription)
            }
        }
    }
}

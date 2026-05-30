import Foundation
@testable import Vigil

final class MockAuthenticationService: AuthenticationServiceProtocol {
    var isTouchIDAvailable: Bool = true
    var authResult: Bool = true
    var shouldThrow: Error?
    var callCount: Int = 0
    var onAuthenticate: (() -> Void)?

    var biometricsResult: Bool = true
    var shouldThrowBiometrics: Error?
    var biometricsOnlyCallCount: Int = 0
    var onAuthenticateBiometricsOnly: (() -> Void)?

    func authenticate(reason: String) async throws -> Bool {
        callCount += 1
        onAuthenticate?()
        if let error = shouldThrow { throw error }
        return authResult
    }

    func authenticateBiometricsOnly(reason: String) async throws -> Bool {
        biometricsOnlyCallCount += 1
        onAuthenticateBiometricsOnly?()
        if let error = shouldThrowBiometrics { throw error }
        return biometricsResult
    }
}

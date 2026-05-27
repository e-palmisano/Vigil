import Foundation
@testable import Vigil

final class MockAuthenticationService: AuthenticationServiceProtocol {
    var isTouchIDAvailable: Bool = true
    var authResult: Bool = true
    var shouldThrow: Error?
    var callCount: Int = 0

    func authenticate(reason: String) async throws -> Bool {
        callCount += 1
        if let error = shouldThrow { throw error }
        return authResult
    }
}

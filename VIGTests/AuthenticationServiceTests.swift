import XCTest
@testable import Vigil

final class AuthenticationServiceTests: XCTestCase {

    func testMockAuthSuccessReturnsTrue() async throws {
        let svc = MockAuthenticationService()
        svc.authResult = true
        let result = try await svc.authenticate(reason: "test")
        XCTAssertTrue(result)
        XCTAssertEqual(svc.callCount, 1)
    }

    func testMockAuthFailureReturnsFalse() async throws {
        let svc = MockAuthenticationService()
        svc.authResult = false
        let result = try await svc.authenticate(reason: "test")
        XCTAssertFalse(result)
    }

    func testMockAuthThrowsWhenConfigured() async {
        let svc = MockAuthenticationService()
        svc.shouldThrow = AuthenticationError.cancelled
        do {
            _ = try await svc.authenticate(reason: "test")
            XCTFail("Expected throw")
        } catch AuthenticationError.cancelled {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testMockTouchIDAvailabilityFlag() {
        let svc = MockAuthenticationService()
        svc.isTouchIDAvailable = false
        XCTAssertFalse(svc.isTouchIDAvailable)
    }

    @MainActor
    func testBiometricsOnlyCallsCorrectPolicy() async throws {
        let mock = MockAuthenticationService()
        mock.biometricsResult = true
        let result = try await mock.authenticateBiometricsOnly(reason: "test")
        XCTAssertTrue(result)
        XCTAssertEqual(mock.biometricsOnlyCallCount, 1)
    }

    @MainActor
    func testBiometricsOnlyPropagatesThrow() async {
        let mock = MockAuthenticationService()
        mock.shouldThrowBiometrics = AuthenticationError.notAvailable
        do {
            _ = try await mock.authenticateBiometricsOnly(reason: "test")
            XCTFail("Expected throw")
        } catch {
            XCTAssertEqual(mock.biometricsOnlyCallCount, 1)
        }
    }
}

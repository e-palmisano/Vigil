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
}

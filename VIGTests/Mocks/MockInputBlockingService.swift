import Foundation
@testable import Vigil

final class MockInputBlockingService: InputBlockingServiceProtocol {
    var isBlocking: Bool = false
    var onEventTapDisabled: (() -> Void)?
    var shouldThrow: Error?
    var startCallCount: Int = 0
    var stopCallCount: Int = 0
    var permissionGranted: Bool = true

    func startBlocking() throws {
        startCallCount += 1
        if let error = shouldThrow { throw error }
        isBlocking = true
    }

    func stopBlocking() {
        stopCallCount += 1
        isBlocking = false
    }

    func checkAccessibilityPermission() -> Bool { permissionGranted }
    func requestAccessibilityPermission() {}
}

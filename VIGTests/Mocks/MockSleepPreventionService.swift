import IOKit.pwr_mgt
@testable import Vigil

final class MockSleepPreventionService: SleepPreventionServiceProtocol {
    var preventCallCount: Int = 0
    var allowCallCount: Int = 0
    var shouldThrow: Error?
    private var nextAssertionID: IOPMAssertionID = 1

    func preventSleep(reason: String) throws -> IOPMAssertionID {
        preventCallCount += 1
        if let error = shouldThrow { throw error }
        let id = nextAssertionID
        nextAssertionID += 1
        return id
    }

    func allowSleep(assertionID: IOPMAssertionID) {
        allowCallCount += 1
    }
}

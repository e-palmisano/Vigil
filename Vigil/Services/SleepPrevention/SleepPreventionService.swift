import IOKit.pwr_mgt

final class SleepPreventionService: SleepPreventionServiceProtocol {

    func preventSleep(reason: String) throws -> IOPMAssertionID {
        var assertionID: IOPMAssertionID = 0
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason as CFString,
            &assertionID
        )
        guard result == kIOReturnSuccess else {
            throw SleepPreventionError.assertionFailed(result)
        }
        return assertionID
    }

    func allowSleep(assertionID: IOPMAssertionID) {
        IOPMAssertionRelease(assertionID)
    }
}

import IOKit.pwr_mgt

protocol SleepPreventionServiceProtocol: AnyObject {
    func preventSleep(reason: String) throws -> IOPMAssertionID
    func allowSleep(assertionID: IOPMAssertionID)
}

enum SleepPreventionError: Error {
    case assertionFailed(IOReturn)
}

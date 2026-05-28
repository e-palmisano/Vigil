import Foundation

protocol AuthenticationServiceProtocol: AnyObject {
    var isTouchIDAvailable: Bool { get }
    func authenticate(reason: String) async throws -> Bool
    func authenticateBiometricsOnly(reason: String) async throws -> Bool
}

enum AuthenticationError: Error {
    case notAvailable
    case cancelled
    case failed(String)
}

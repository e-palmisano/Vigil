import XCTest
@testable import Vigil

final class SettingsViewTests: XCTestCase {

    func testDefaultLockModeIsObscured() {
        let settings = AppSettings()
        XCTAssertEqual(settings.lockMode, .obscured)
    }

    func testOverlayStyleRoundTrips() {
        let settings = AppSettings()
        for style in OverlayStyle.allCases {
            settings.overlayStyle = style.rawValue
            XCTAssertEqual(settings.currentOverlayStyle, style)
        }
    }

    func testBadgePositionRoundTrips() {
        let settings = AppSettings()
        for pos in BadgePosition.allCases {
            settings.badgePosition = pos.rawValue
            XCTAssertEqual(settings.currentBadgePosition, pos)
        }
    }

    func testPreventSleepDefaultTrue() {
        let settings = AppSettings()
        XCTAssertTrue(settings.preventSleep)
    }

    func testAutoHideDelayDefaultFive() {
        let settings = AppSettings()
        XCTAssertEqual(settings.autoHideDelay, 5.0, accuracy: 0.001)
    }
}

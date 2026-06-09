import XCTest
@testable import Vigil

/// The badge frame math is pure: Cocoa global coordinates, origin bottom-left.
@MainActor
final class BadgePositionFrameTests: XCTestCase {

    private let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)
    private let size = CGSize(width: 260, height: 96)
    private let margin: CGFloat = 16

    private func frame(_ position: BadgePosition) -> CGRect {
        VisibleLockBadgeWindow.frame(for: position, in: screen, size: size, margin: margin)
    }

    func testBottomRight() {
        let f = frame(.bottomRight)
        XCTAssertEqual(f.origin, CGPoint(x: 1920 - 260 - 16, y: 16))
        XCTAssertEqual(f.size, size)
    }

    func testBottomLeft() {
        XCTAssertEqual(frame(.bottomLeft).origin, CGPoint(x: 16, y: 16))
    }

    func testTopRight() {
        XCTAssertEqual(frame(.topRight).origin, CGPoint(x: 1920 - 260 - 16, y: 1080 - 96 - 16))
    }

    func testTopLeft() {
        XCTAssertEqual(frame(.topLeft).origin, CGPoint(x: 16, y: 1080 - 96 - 16))
    }

    func testCenter() {
        XCTAssertEqual(frame(.center).origin, CGPoint(x: 960 - 130, y: 540 - 48))
    }

    func testRespectsVisibleFrameOffsetFromMenuBarAndDock() {
        // visibleFrame excludes the Dock (bottom) and menu bar (top).
        let visible = CGRect(x: 0, y: 70, width: 1920, height: 1080 - 70 - 25)
        let f = VisibleLockBadgeWindow.frame(for: .bottomLeft, in: visible, size: size, margin: margin)
        XCTAssertEqual(f.origin, CGPoint(x: 16, y: 70 + 16), "badge must sit above the Dock")
    }
}

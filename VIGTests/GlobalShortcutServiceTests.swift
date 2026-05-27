import XCTest
import AppKit
@testable import Vigil

final class GlobalShortcutServiceTests: XCTestCase {

    func testParsedShortcutCtrlCmdL() {
        let parsed = ParsedShortcut("ctrl+cmd+l")
        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed?.character, "l")
        XCTAssertTrue(parsed?.modifiers.contains(.control) ?? false)
        XCTAssertTrue(parsed?.modifiers.contains(.command) ?? false)
    }

    func testParsedShortcutAllModifiers() {
        let parsed = ParsedShortcut("ctrl+shift+cmd+opt+x")
        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed?.character, "x")
        XCTAssertTrue(parsed?.modifiers.contains(.control) ?? false)
        XCTAssertTrue(parsed?.modifiers.contains(.shift) ?? false)
        XCTAssertTrue(parsed?.modifiers.contains(.command) ?? false)
        XCTAssertTrue(parsed?.modifiers.contains(.option) ?? false)
    }

    func testParsedShortcutRejectsNoModifiers() {
        XCTAssertNil(ParsedShortcut("l"))
    }

    func testParsedShortcutRejectsMultiCharKey() {
        XCTAssertNil(ParsedShortcut("ctrl+cmd+lock"))
    }

    func testParsedShortcutEmptyString() {
        XCTAssertNil(ParsedShortcut(""))
    }

    func testDefaultShortcutsParseSuccessfully() {
        let settings = AppSettings()
        XCTAssertNotNil(ParsedShortcut(settings.globalShortcutVisible))
        XCTAssertNotNil(ParsedShortcut(settings.globalShortcutObscured))
        XCTAssertNotNil(ParsedShortcut(settings.emergencyShortcut))
    }
}

import Foundation
import ApplicationServices
import CoreGraphics
import AppKit

final class InputBlockingService: InputBlockingServiceProtocol {
    private(set) var isBlocking: Bool = false
    var onEventTapDisabled: (() -> Void)?
    var onUnlockShortcutPressed: (() -> Void)?
    var onEmergencyShortcutHeld: (() -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var watchdog: DispatchSourceTimer?
    private var watchdogFailures: Int = 0
    private var retainedSelfPointer: UnsafeMutableRawPointer?
    // Main-thread only: armed when the emergency combo goes down, fired
    // after `emergencyHoldDuration` unless a key-up / modifier change cancels it.
    private var emergencyHoldTimer: Timer?

    // State shared between the main thread and the tap thread → guarded by `stateLock`.
    private let stateLock = NSLock()
    private var interactiveRectsCG: [CGRect] = []
    private var unlockShortcut: ParsedShortcut?
    private var emergencyShortcut: ParsedShortcut?
    private var tapRunLoop: CFRunLoop?
    private var stopRequested = false

    // Passthrough marker: Vigil's own synthetic events carry this so the tap lets them through.
    static let vigilSourceUserData: Int64 = 0x5649474C // "VIGL"

    static let emergencyHoldDuration: TimeInterval = 3.0

    /// Converts a rect from Cocoa global coordinates (origin bottom-left, y up)
    /// to CoreGraphics event coordinates (origin top-left, y down), flipping
    /// about the primary display's top edge. `CGEvent.location` lives in this
    /// flipped space, so interactive rects must be converted before hit-testing.
    static func globalCGRect(from cocoaRect: CGRect, primaryHeight: CGFloat) -> CGRect {
        CGRect(
            x: cocoaRect.minX,
            y: primaryHeight - cocoaRect.maxY,
            width: cocoaRect.width,
            height: cocoaRect.height
        )
    }

    // Exposed for unit testing.
    static func eventMask(for mode: LockMode) -> CGEventMask {
        let keyboardTypes: [CGEventType] = [.keyDown, .keyUp, .flagsChanged]
        let scrollTypes: [CGEventType] = [.scrollWheel]

        let mouseTypes: [CGEventType] = [
            .leftMouseDown, .leftMouseUp,
            .rightMouseDown, .rightMouseUp,
            .otherMouseDown, .otherMouseUp
        ]
        // Mouse clicks are blocked at the HID level: interaction is allowed
        // only inside the unlock button / badge area. Mouse movement
        // (hover) is left unblocked so chrome auto-hide keeps working.
        let types = keyboardTypes + scrollTypes + mouseTypes
        return types.reduce(CGEventMask(0)) { $0 | (CGEventMask(1) << $1.rawValue) }
    }

    func checkAccessibilityPermission() -> Bool {
        AXIsProcessTrusted()
    }

    func requestAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true]
        AXIsProcessTrustedWithOptions(options)
    }

    func setUnlockShortcut(_ shortcutString: String?) {
        let parsed = shortcutString.flatMap { ParsedShortcut($0) }
        stateLock.lock()
        unlockShortcut = parsed
        stateLock.unlock()
    }

    func setEmergencyShortcut(_ shortcutString: String?) {
        let parsed = shortcutString.flatMap { ParsedShortcut($0) }
        stateLock.lock()
        emergencyShortcut = parsed
        stateLock.unlock()
    }

    func setInteractiveRects(_ rects: [CGRect]) {
        let primaryHeight = Self.primaryDisplayHeight()
        let flipped = rects.map { Self.globalCGRect(from: $0, primaryHeight: primaryHeight) }
        stateLock.lock()
        interactiveRectsCG = flipped
        stateLock.unlock()
    }

    func startBlocking(mode: LockMode = .obscured) throws {
        guard eventTap == nil else { return }

        let selfPtr = Unmanaged.passRetained(self).toOpaque()
        retainedSelfPointer = selfPtr

        let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: Self.eventMask(for: mode),
            callback: { _, type, event, userInfo -> Unmanaged<CGEvent>? in
                guard let ptr = userInfo else { return Unmanaged.passRetained(event) }
                // Valid for the lifetime of the tap: `retainedSelfPointer` keeps
                // the service alive until stopBlocking() releases it, and the
                // main-queue blocks below capture it strongly.
                let service = Unmanaged<InputBlockingService>.fromOpaque(ptr).takeUnretainedValue()

                if type == .tapDisabledByTimeout {
                    // `eventTap` is only mutated on the main thread — re-enable there.
                    DispatchQueue.main.async {
                        if let tap = service.eventTap {
                            CGEvent.tapEnable(tap: tap, enable: true)
                        }
                    }
                    return Unmanaged.passRetained(event)
                }

                if type == .tapDisabledByUserInput {
                    DispatchQueue.main.async { service.onEventTapDisabled?() }
                    return Unmanaged.passRetained(event)
                }

                // Pass through events originating from Vigil.
                if event.getIntegerValueField(.eventSourceUserData) == InputBlockingService.vigilSourceUserData {
                    return Unmanaged.passRetained(event)
                }

                // Allow mouse interaction only inside Vigil's own windows.
                if service.isMouseEvent(type) {
                    if service.isPointInInteractiveArea(event.location) {
                        return Unmanaged.passRetained(event)
                    }
                    return nil // eat the click
                }

                if type == .keyDown, let nsEvent = NSEvent(cgEvent: event) {
                    // Detect unlock shortcut — fires even while blocking.
                    if let shortcut = service.currentUnlockShortcut(), shortcut.matches(nsEvent) {
                        DispatchQueue.main.async { service.onUnlockShortcutPressed?() }
                        return nil // eat the event — don't let it reach apps
                    }
                    // Emergency combo must be detected here: NSEvent global
                    // monitors never see events this tap has already eaten.
                    if let emergency = service.currentEmergencyShortcut(), emergency.matches(nsEvent) {
                        if !nsEvent.isARepeat {
                            DispatchQueue.main.async { service.beginEmergencyHold() }
                        }
                        return nil
                    }
                }

                // Releasing any key or changing modifiers aborts a pending emergency hold.
                if type == .keyUp || type == .flagsChanged {
                    DispatchQueue.main.async { service.cancelEmergencyHold() }
                }

                return nil // eat the event
            },
            userInfo: selfPtr
        )

        guard let tap else {
            Unmanaged<InputBlockingService>.fromOpaque(selfPtr).release()
            retainedSelfPointer = nil
            throw InputBlockingError.eventTapCreationFailed
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.eventTap = tap
        self.runLoopSource = source

        stateLock.lock()
        stopRequested = false
        stateLock.unlock()

        let tapQueue = DispatchQueue(label: "vig.inputblocking", qos: .userInteractive)
        tapQueue.async { [weak self] in
            guard let self, let source else { return }
            let rl = CFRunLoopGetCurrent()
            self.stateLock.lock()
            // stopBlocking() may have run before this block: don't park the thread.
            let cancelled = self.stopRequested
            if !cancelled { self.tapRunLoop = rl }
            self.stateLock.unlock()
            guard !cancelled else { return }
            CFRunLoopAddSource(rl, source, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
            CFRunLoopRun()
        }

        isBlocking = true
        watchdogFailures = 0
        startWatchdog()
    }

    func stopBlocking() {
        stopWatchdog()
        cancelEmergencyHold()
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        stateLock.lock()
        stopRequested = true
        let rl = tapRunLoop
        tapRunLoop = nil
        stateLock.unlock()
        if let rl {
            // CFRunLoop is thread-safe: tear down the tap thread's loop from here.
            if let source = runLoopSource {
                CFRunLoopRemoveSource(rl, source, .commonModes)
            }
            CFRunLoopStop(rl)
        }
        if let ptr = retainedSelfPointer {
            Unmanaged<InputBlockingService>.fromOpaque(ptr).release()
            retainedSelfPointer = nil
        }
        eventTap = nil
        runLoopSource = nil
        isBlocking = false
    }

    // MARK: - Shortcuts (read from the tap thread)

    private func currentUnlockShortcut() -> ParsedShortcut? {
        stateLock.lock()
        defer { stateLock.unlock() }
        return unlockShortcut
    }

    private func currentEmergencyShortcut() -> ParsedShortcut? {
        stateLock.lock()
        defer { stateLock.unlock() }
        return emergencyShortcut
    }

    // MARK: - Emergency hold (main thread)

    private func beginEmergencyHold() {
        guard emergencyHoldTimer == nil else { return }
        emergencyHoldTimer = Timer.scheduledTimer(
            withTimeInterval: Self.emergencyHoldDuration,
            repeats: false
        ) { [weak self] _ in
            guard let self else { return }
            self.emergencyHoldTimer = nil
            self.onEmergencyShortcutHeld?()
        }
    }

    private func cancelEmergencyHold() {
        emergencyHoldTimer?.invalidate()
        emergencyHoldTimer = nil
    }

    // MARK: - Mouse event filtering

    private func isMouseEvent(_ type: CGEventType) -> Bool {
        switch type {
        case .leftMouseDown, .leftMouseUp,
             .rightMouseDown, .rightMouseUp,
             .otherMouseDown, .otherMouseUp:
            return true
        default:
            return false
        }
    }

    private func isPointInInteractiveArea(_ point: CGPoint) -> Bool {
        stateLock.lock()
        let rects = interactiveRectsCG
        stateLock.unlock()
        return rects.contains { $0.contains(point) }
    }

    /// Height of the primary display (origin == .zero) — the axis the
    /// Cocoa→CoreGraphics y-flip is measured against.
    private static func primaryDisplayHeight() -> CGFloat {
        let primary = NSScreen.screens.first { $0.frame.origin == .zero } ?? NSScreen.screens.first
        return primary?.frame.height ?? 0
    }

    // MARK: - Watchdog

    private func startWatchdog() {
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + 2, repeating: 2)
        timer.setEventHandler { [weak self] in self?.checkTapHealth() }
        timer.resume()
        watchdog = timer
    }

    private func stopWatchdog() {
        watchdog?.cancel()
        watchdog = nil
    }

    private func checkTapHealth() {
        guard let tap = eventTap else { return }
        if !CGEvent.tapIsEnabled(tap: tap) {
            watchdogFailures += 1
            if watchdogFailures >= 3 {
                onEventTapDisabled?()
            } else {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
        } else {
            watchdogFailures = 0
        }
    }
}

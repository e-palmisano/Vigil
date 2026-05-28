import Foundation
import ApplicationServices
import CoreGraphics
import AppKit

final class InputBlockingService: InputBlockingServiceProtocol {
    private(set) var isBlocking: Bool = false
    var onEventTapDisabled: (() -> Void)?
    var onUnlockShortcutPressed: (() -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var tapRunLoop: CFRunLoop?
    private var watchdog: DispatchSourceTimer?
    private var watchdogFailures: Int = 0
    private var retainedSelfPointer: UnsafeMutableRawPointer?
    private var unlockShortcut: ParsedShortcut?

    // Passthrough marker: Vigil's own synthetic events carry this so the tap lets them through.
    static let vigilSourceUserData: Int64 = 0x5649474C // "VIGL"

    private static func eventMask(for mode: LockMode) -> CGEventMask {
        let keyboardTypes: [CGEventType] = [.keyDown, .keyUp, .flagsChanged]
        let mouseTypes: [CGEventType] = [
            .leftMouseDown, .leftMouseUp, .leftMouseDragged,
            .rightMouseDown, .rightMouseUp, .rightMouseDragged,
            .otherMouseDown, .otherMouseUp, .otherMouseDragged,
            .mouseMoved
        ]
        let scrollTypes: [CGEventType] = [.scrollWheel]

        let types: [CGEventType]
        switch mode {
        case .obscured:
            types = keyboardTypes + mouseTypes + scrollTypes
        case .visible:
            types = keyboardTypes + scrollTypes
        }
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
        unlockShortcut = shortcutString.flatMap { ParsedShortcut($0) }
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
                let service = Unmanaged<InputBlockingService>.fromOpaque(ptr).takeUnretainedValue()

                if type == .tapDisabledByTimeout {
                    DispatchQueue.main.async { [weak service] in
                        if let tap = service?.eventTap {
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

                // Detect unlock shortcut — fires even while blocking.
                if type == .keyDown,
                   let shortcut = service.unlockShortcut,
                   let nsEvent = NSEvent(cgEvent: event),
                   shortcut.matches(nsEvent) {
                    DispatchQueue.main.async { service.onUnlockShortcutPressed?() }
                    return nil // eat the event — don't let it reach apps
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

        let tapQueue = DispatchQueue(label: "vig.inputblocking", qos: .userInteractive)
        tapQueue.async { [weak self] in
            guard let self, let source = self.runLoopSource, let tap = self.eventTap else { return }
            let rl = CFRunLoopGetCurrent()
            self.tapRunLoop = rl
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
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            if let rl = tapRunLoop {
                CFRunLoopRemoveSource(rl, source, .commonModes)
            } else {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            }
        }
        if let rl = tapRunLoop {
            CFRunLoopStop(rl)
            tapRunLoop = nil
        }
        if let ptr = retainedSelfPointer {
            Unmanaged<InputBlockingService>.fromOpaque(ptr).release()
            retainedSelfPointer = nil
        }
        eventTap = nil
        runLoopSource = nil
        isBlocking = false
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

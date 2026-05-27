import Foundation
import ApplicationServices
import CoreGraphics

final class InputBlockingService: InputBlockingServiceProtocol {
    private(set) var isBlocking: Bool = false
    var onEventTapDisabled: (() -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var watchdog: DispatchSourceTimer?
    private var watchdogFailures: Int = 0
    private var retainedSelfPointer: UnsafeMutableRawPointer?

    // Passthrough marker: Vigil's own synthetic events carry this so the tap lets them through.
    static let vigilSourceUserData: Int64 = 0x5649474C // "VIGL"

    private static let blockedEventMask: CGEventMask = {
        let types: [CGEventType] = [
            .keyDown, .keyUp, .flagsChanged,
            .leftMouseDown, .leftMouseUp, .leftMouseDragged,
            .rightMouseDown, .rightMouseUp, .rightMouseDragged,
            .otherMouseDown, .otherMouseUp, .otherMouseDragged,
            .mouseMoved, .scrollWheel
        ]
        return types.reduce(0) { $0 | (1 << $1.rawValue) }
    }()

    func checkAccessibilityPermission() -> Bool {
        AXIsProcessTrusted()
    }

    func requestAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true]
        AXIsProcessTrustedWithOptions(options)
    }

    func startBlocking() throws {
        guard eventTap == nil else { return }

        let selfPtr = Unmanaged.passRetained(self).toOpaque()
        retainedSelfPointer = selfPtr

        let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: Self.blockedEventMask,
            callback: { _, type, event, userInfo -> Unmanaged<CGEvent>? in
                guard let ptr = userInfo else { return Unmanaged.passRetained(event) }
                let service = Unmanaged<InputBlockingService>.fromOpaque(ptr).takeUnretainedValue()

                if type == .tapDisabledByTimeout {
                    // Re-enable from main queue using the stored CFMachPort reference.
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
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        eventTap = tap
        runLoopSource = source
        isBlocking = true
        watchdogFailures = 0
        startWatchdog()
    }

    func stopBlocking() {
        stopWatchdog()
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            }
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

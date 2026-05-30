import AppKit

/// An invisible full-screen view that swallows all mouse events.
/// Placed under the SwiftUI hosting view so that clicks on interactive
/// SwiftUI controls still work, while clicks on empty areas are consumed.
final class MouseBlockingView: NSView {

    override var isOpaque: Bool { true }

    // MARK: – Clicks

    override func mouseDown(with event: NSEvent) {
        // swallow
    }

    override func mouseUp(with event: NSEvent) {
        // swallow
    }

    override func rightMouseDown(with event: NSEvent) {
        // swallow
    }

    override func rightMouseUp(with event: NSEvent) {
        // swallow
    }

    override func otherMouseDown(with event: NSEvent) {
        // swallow
    }

    override func otherMouseUp(with event: NSEvent) {
        // swallow
    }

    // MARK: – Scroll / zoom / rotate

    override func scrollWheel(with event: NSEvent) {
        // swallow
    }

    override func magnify(with event: NSEvent) {
        // swallow
    }

    override func rotate(with event: NSEvent) {
        // swallow
    }

    override func swipe(with event: NSEvent) {
        // swallow
    }

    // MARK: – Dragging

    override func mouseDragged(with event: NSEvent) {
        // swallow
    }

    override func rightMouseDragged(with event: NSEvent) {
        // swallow
    }

    override func otherMouseDragged(with event: NSEvent) {
        // swallow
    }
}

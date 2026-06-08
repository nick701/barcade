import AppKit
import SwiftUI

struct ClickCaptureView: NSViewRepresentable {
    let onPrimaryClick: () -> Void
    let onSecondaryClick: () -> Void

    func makeNSView(context: Context) -> ClickCaptureNSView {
        let view = ClickCaptureNSView()
        view.onPrimaryClick = onPrimaryClick
        view.onSecondaryClick = onSecondaryClick
        return view
    }

    func updateNSView(_ nsView: ClickCaptureNSView, context: Context) {
        nsView.onPrimaryClick = onPrimaryClick
        nsView.onSecondaryClick = onSecondaryClick
    }
}

final class ClickCaptureNSView: NSView {
    var onPrimaryClick: (() -> Void)?
    var onSecondaryClick: (() -> Void)?

    override func mouseDown(with event: NSEvent) {
        onPrimaryClick?()
    }

    override func rightMouseDown(with event: NSEvent) {
        onSecondaryClick?()
    }
}

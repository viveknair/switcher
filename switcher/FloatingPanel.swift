import AppKit

class FloatingPanel: NSPanel {
    init(contentRect: NSRect, backing: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect,
                    styleMask: [.nonactivatingPanel, .titled, .resizable, .fullSizeContentView],
                    backing: backing,
                    defer: flag)
        
        configurePanel()
    }

    private func configurePanel() {
        // Configure panel properties
        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.fullScreenAuxiliary, .transient]
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = true
        isReleasedWhenClosed = false
        backgroundColor = .windowBackgroundColor
        hasShadow = true
        
        // Set corner radius
        self.appearance = NSAppearance(named: .vibrantDark)
        if let contentView = contentView {
            contentView.wantsLayer = true
            contentView.layer?.cornerRadius = 12
            contentView.layer?.masksToBounds = true
        }

        hideStandardButtons()
    }
    
    private func hideStandardButtons() {
        [.closeButton, .miniaturizeButton, .zoomButton].forEach { buttonType in
            standardWindowButton(buttonType)?.isHidden = true
        }
    }
    
    // Enable key and main window functionality
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

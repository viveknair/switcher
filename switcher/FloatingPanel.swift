import AppKit

class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
    
    init(contentRect: NSRect, backing: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect,
                  styleMask: [.borderless, .nonactivatingPanel],
                  backing: backing,
                  defer: flag)
        
        self.level = .popUpMenu
        self.isMovable = false
        self.isMovableByWindowBackground = false
        self.hasShadow = true
        self.backgroundColor = .windowBackgroundColor
        self.hidesOnDeactivate = false
        self.orderOut(nil)
    }
    
    override func resignKey() {
        // Don't hide when losing key window status
    }
    
    override func resignMain() {
        // Don't hide when losing main window status
    }
}

import Foundation
import Cocoa
import HotKey

class HotkeyManager {
    private let categorizer: AppCategorizer
    private var nextAppHotKey: HotKey?
    private var prevAppHotKey: HotKey?
    private var nextCategoryHotKey: HotKey?
    
    // Explicit state tracking
    private var isOptionKeyPressed = false
    private var lastModifierFlags: NSEvent.ModifierFlags = []
    private var isProcessingHotKey = false
    
    init(categorizer: AppCategorizer) {
        self.categorizer = categorizer
        print("🟡 [INIT] HotkeyManager initializing...")
        setupOptionKeyMonitoring()
        setupHotKeys()
        print("🟡 [INIT] HotkeyManager ready - Option state:", isOptionKeyPressed)
    }
    
    private func setupOptionKeyMonitoring() {
        // Monitor both local and global flag changes to ensure we catch all transitions
        NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagChange(event)
        }
        
        NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagChange(event)
            return event
        }
    }
    
    private func handleFlagChange(_ event: NSEvent) {
        // Capture previous state
        let previousFlags = lastModifierFlags
        let wasOptionPressed = isOptionKeyPressed
        
        // Get current state
        let currentFlags = event.modifierFlags
        
        // Check specifically for the Option key state
        let isOptionPressed = currentFlags.contains(.option)
        
        print("🟡 [STATE] Modifier flags changed:")
        print("  - Previous flags:", String(format: "0x%08X", previousFlags.rawValue))
        print("  - Current flags:", String(format: "0x%08X", currentFlags.rawValue))
        print("  - Option was pressed:", wasOptionPressed)
        print("  - Option is pressed:", isOptionPressed)
        
        // Only handle actual Option key state changes
        if isOptionPressed != wasOptionPressed {
            if isOptionPressed {
                // Clean Option press detected
                print("🟡 [TRANSITION] Option key PRESSED - enabling panel")
                isOptionKeyPressed = true
                categorizer.delegate?.showPanel()
            } else {
                // Clean Option release detected
                print("🟡 [TRANSITION] Option key RELEASED - hiding panel and switching app")
                isOptionKeyPressed = false
                categorizer.delegate?.hidePanel()
            }
        }
        
        // Always update last known state
        lastModifierFlags = currentFlags
    }
    
    private func setupHotKeys() {
        // Option + Tab for next app
        nextAppHotKey = HotKey(key: .tab, modifiers: [.option])
        nextAppHotKey?.keyDownHandler = { [weak self] in
            guard let self = self else { 
                print("🟡 [ERROR] Self was nil in Option+Tab handler")
                return 
            }
            
            print("🟡 [HOTKEY] Option+Tab triggered:")
            print("  - Option key state:", self.isOptionKeyPressed)
            print("  - Processing state:", self.isProcessingHotKey)
            
            // Only process if we're absolutely certain Option is pressed
            guard self.isOptionKeyPressed else {
                print("🟡 [REJECT] Option+Tab ignored - Option not pressed")
                return
            }
            
            // Prevent re-entry
            guard !self.isProcessingHotKey else {
                print("🟡 [REJECT] Option+Tab ignored - Already processing")
                return
            }
            
            self.isProcessingHotKey = true
            print("🟡 [ACCEPT] Processing Option+Tab - cycling to next app")
            
            if let appDelegate = self.categorizer.delegate as? AppDelegate {
                appDelegate.appViewModel.cycleToNextApp()
            }
            
            self.isProcessingHotKey = false
        }
        
        // Option + Shift + Tab for previous app
        prevAppHotKey = HotKey(key: .tab, modifiers: [.option, .shift])
        prevAppHotKey?.keyDownHandler = { [weak self] in
            guard let self = self,
                  self.isOptionKeyPressed else { return }
            
            print("🟡 [KEY] Option+Shift+Tab - cycling previous")
            if let appDelegate = self.categorizer.delegate as? AppDelegate {
                appDelegate.appViewModel.cycleToPreviousApp()
            }
        }
        
        // Option + Control + Space for next category
        nextCategoryHotKey = HotKey(key: .space, modifiers: [.option, .control])
        nextCategoryHotKey?.keyDownHandler = { [weak self] in
            guard let self = self,
                  self.isOptionKeyPressed else { return }
            
            print("🟡 [KEY] Option+Control+Space - next category")
            if let appDelegate = self.categorizer.delegate as? AppDelegate {
                appDelegate.appViewModel.jumpToNextCategory()
            }
        }
    }
} 

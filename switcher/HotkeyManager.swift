import Foundation
import Cocoa
import HotKey

class HotkeyManager {
    private let categorizer: AppCategorizer
    private var nextAppHotKey: HotKey?
    private var prevAppHotKey: HotKey?
    private var nextCategoryHotKey: HotKey?
    private var isOptionKeyPressed = false
    
    init(categorizer: AppCategorizer) {
        self.categorizer = categorizer
        setupOptionKeyMonitoring()
        setupHotKeys()
    }
    
    private func setupOptionKeyMonitoring() {
        NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            let isOption = event.modifierFlags.contains(.option)
            self?.isOptionKeyPressed = isOption
            
            if !isOption {
                self?.categorizer.delegate?.hidePanel()
            }
        }
    }
    
    private func setupHotKeys() {
        // Option + Tab for next app
        nextAppHotKey = HotKey(key: .tab, modifiers: [.option])
        nextAppHotKey?.keyDownHandler = { [weak self] in
            guard let self = self, self.isOptionKeyPressed else { return }
            self.categorizer.moveToNextApp()
        }
        
        // Option + Shift + Tab for previous app
        prevAppHotKey = HotKey(key: .tab, modifiers: [.option, .shift])
        prevAppHotKey?.keyDownHandler = { [weak self] in
            guard let self = self, self.isOptionKeyPressed else { return }
            self.categorizer.moveToPreviousApp()
        }
        
        // Option + Control + Space for next category
        nextCategoryHotKey = HotKey(key: .space, modifiers: [.option, .control])
        nextCategoryHotKey?.keyDownHandler = { [weak self] in
            guard let self = self, self.isOptionKeyPressed else { return }
            self.categorizer.moveToNextCategory()
        }
    }
} 
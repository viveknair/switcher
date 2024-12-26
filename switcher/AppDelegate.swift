//
//  AppDelegate.swift
//  switcher
//
//  Created by Vivek Nair on 4/28/22.
//

import Cocoa
import SwiftUI
import HotKey
import Settings
@_exported import class Settings.SettingsWindowController
import Foundation

@main
class AppDelegate: NSObject, NSApplicationDelegate {

  var appSwitcherPanel: FloatingPanel!
  private var hostingView: NSHostingView<ContentView>!
  private var appViewModel = AppViewModel()
  private var switcherHotKey: HotKey?
  private var backwardSwitcherHotKey: HotKey?
  private var categoryHotKey: HotKey?
  private var autoRepeatTimer: Timer?
  private var currentDirection: CycleDirection?
  private var statusItem: NSStatusItem!
  private var preferencesWindowController: SettingsWindowController?
  private var userDefaultsObserver: Any?

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    if !AXIsProcessTrusted() {
      let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
      AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    createFloatingPanel()
    setupHotKey()
    
    // Keep the app running in the background
    NSApp.setActivationPolicy(.accessory)
    
    // Remove the dock icon
    if let window = NSApp.windows.first {
        window.close()
    }
    
    setupStatusItem()
    
    setupUserDefaultsObserver()
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    // Clean up observer
    if let observer = userDefaultsObserver {
        NotificationCenter.default.removeObserver(observer)
    }
  }

  func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  private func createFloatingPanel() {
    // Use settings for window size
    appSwitcherPanel = FloatingPanel(
        contentRect: NSRect(x: 0, y: 0, width: UserSettings.windowWidth, height: UserSettings.windowHeight),
        backing: .buffered,
        defer: false
    )

    // Create ContentView with our pre-initialized view model
    let contentView = ContentView(viewModel: appViewModel)
    hostingView = NSHostingView(rootView: contentView)
    appSwitcherPanel.contentView = hostingView
    
    // Initial hide
    appSwitcherPanel.orderOut(nil)
  }
  
  private func setupHotKey() {
    // Create hot keys
    switcherHotKey = HotKey(key: .tab, modifiers: [.option])
    backwardSwitcherHotKey = HotKey(key: .tab, modifiers: [.option, .shift])
    categoryHotKey = HotKey(key: .space, modifiers: [.option, .control])
    
    // Handle option+tab key down - show panel and start cycling
    switcherHotKey?.keyDownHandler = { [weak self] in
        self?.handleTabDown(direction: .forward)
    }
    
    // Handle option+shift+tab key down
    backwardSwitcherHotKey?.keyDownHandler = { [weak self] in
        self?.handleTabDown(direction: .backward)
    }
    
    // Handle tab key up - stop auto-repeat
    switcherHotKey?.keyUpHandler = { [weak self] in
        self?.stopAutoRepeat()
    }
    
    backwardSwitcherHotKey?.keyUpHandler = { [weak self] in
        self?.stopAutoRepeat()
    }
    
    // Option+Ctrl+Space handler
    categoryHotKey?.keyDownHandler = { [weak self] in
        self?.handleCategoryJump()
    }
    
    // Monitor for option key up
    NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
        if event.modifierFlags.intersection(.option).isEmpty {
            self?.hidePanel()
            self?.stopAutoRepeat()
        }
    }
    
    categoryHotKey?.keyUpHandler = nil
  }
  
  private enum CycleDirection {
    case forward
    case backward
  }
  
  private func handleOptionTab(direction: CycleDirection) {
    if !appSwitcherPanel.isVisible {
        showPanel()
    }
    switch direction {
    case .forward:
        appViewModel.cycleToNextApp()
    case .backward:
        appViewModel.cycleToPreviousApp()
    }
  }
  
  private func showPanel() {
    appSwitcherPanel.center()
    appSwitcherPanel.orderFront(nil)
    appSwitcherPanel.makeKey()
    appViewModel.loadApps()
  }
  
  private func hidePanel() {
    appSwitcherPanel.orderOut(nil)
  }
  
  private func togglePanel() {
    if appSwitcherPanel.isVisible {
        appSwitcherPanel.orderOut(nil)
    } else {
        // Center the panel before showing it
        appSwitcherPanel.center()
        appSwitcherPanel.orderFront(nil)
        appSwitcherPanel.makeKey()
    }
  }
  
  private func handleCategoryJump() {
    if !appSwitcherPanel.isVisible {
        showPanel()
    }
    appViewModel.jumpToNextCategory()
  }
  
  private func handleTabDown(direction: CycleDirection) {
    if !appSwitcherPanel.isVisible {
        showPanel()
    }
    
    // Perform initial cycle
    handleOptionTab(direction: direction)
    
    // Store current direction
    currentDirection = direction
    
    // Start auto-repeat timer after delay
    autoRepeatTimer?.invalidate()
    autoRepeatTimer = Timer.scheduledTimer(withTimeInterval: initialRepeatDelay, repeats: false) { [weak self] _ in
        self?.startRepeating()
    }
  }
  
  private func startRepeating() {
    // Start the repeating timer
    autoRepeatTimer?.invalidate()
    autoRepeatTimer = Timer.scheduledTimer(withTimeInterval: repeatInterval, repeats: true) { [weak self] _ in
        guard let self = self, let direction = self.currentDirection else { return }
        self.handleOptionTab(direction: direction)
    }
  }
  
  private func stopAutoRepeat() {
    autoRepeatTimer?.invalidate()
    autoRepeatTimer = nil
    currentDirection = nil
  }
  
  private func setupStatusItem() {
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    
    if let button = statusItem.button {
        button.image = NSImage(systemSymbolName: "command", accessibilityDescription: "Switcher")
    }
    
    let menu = NSMenu()
    
    menu.addItem(NSMenuItem(title: "Settings", action: #selector(showPreferences), keyEquivalent: ","))
    menu.addItem(NSMenuItem.separator())
    menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    
    statusItem.menu = menu
  }
  
  @objc private func showPreferences() {
    let preferencesWindow = SettingsWindowController(
        panes: [
            Settings.Pane<GeneralPreferenceView>(
                identifier: Settings.PaneIdentifier("general"),
                title: "General",
                toolbarIcon: NSImage(systemSymbolName: "gear", accessibilityDescription: "General preferences") ?? NSImage(),
                contentView: { GeneralPreferenceView() }
            )
        ]
    )
    
    // Set minimum window size
    preferencesWindow.window?.minSize = NSSize(width: 600, height: 400)
    
    // Make window resizable
    preferencesWindow.window?.styleMask.insert(.resizable)
    
    // Set initial window size
    preferencesWindow.window?.setContentSize(NSSize(width: 600, height: 400))
    
    // Add close window delegate
    preferencesWindow.window?.delegate = self
    
    preferencesWindowController = preferencesWindow
    preferencesWindowController?.show()
  }
  
  // Update timer properties to use UserSettings
  private var initialRepeatDelay: TimeInterval {
    UserSettings.initialRepeatDelay
  }
  
  private var repeatInterval: TimeInterval {
    UserSettings.repeatInterval
  }
  
  private func setupUserDefaultsObserver() {
    // Store the observer reference
    userDefaultsObserver = NotificationCenter.default.addObserver(
        forName: UserDefaults.didChangeNotification,
        object: nil,
        queue: .main
    ) { [weak self] _ in
        guard let self = self,
              let panel = self.appSwitcherPanel,
              panel.isVisible else { return }  // Only update if panel exists and is visible
        
        // Update window size
        let newSize = NSSize(
            width: UserSettings.windowWidth,
            height: UserSettings.windowHeight
        )
        
        // Use setFrame instead of setContentSize for smoother resizing
        let newFrame = NSRect(
            origin: panel.frame.origin,
            size: newSize
        )
        panel.setFrame(newFrame, display: true, animate: true)
        panel.center()
    }
  }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if notification.object as? NSWindow == preferencesWindowController?.window {
            preferencesWindowController = nil
        }
    }
}

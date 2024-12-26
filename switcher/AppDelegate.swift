//
//  AppDelegate.swift
//  switcher
//
//  Created by Vivek Nair on 4/28/22.
//

import Cocoa
import SwiftUI
import HotKey

@main
class AppDelegate: NSObject, NSApplicationDelegate {

  var appSwitcherPanel: FloatingPanel!
  private var hostingView: NSHostingView<ContentView>!
  private var appViewModel = AppViewModel()
  private var switcherHotKey: HotKey?
  private var backwardSwitcherHotKey: HotKey?
  private var categoryHotKey: HotKey?

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
  }

  func applicationWillTerminate(_ aNotification: Notification) {
  }

  func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  private func createFloatingPanel() {
    // Create the window
    appSwitcherPanel = FloatingPanel(contentRect: NSRect(x: 0, y: 0, width: 600, height: 160), backing: .buffered, defer: false)

    // Create ContentView with our pre-initialized view model
    let contentView = ContentView(viewModel: appViewModel)
    hostingView = NSHostingView(rootView: contentView)
    appSwitcherPanel.contentView = hostingView
    
    // Initial hide
    appSwitcherPanel.orderOut(nil)
  }
  
  private func setupHotKey() {
    // Create hot keys for option+tab, option+shift+tab, and option+ctrl
    switcherHotKey = HotKey(key: .tab, modifiers: [.option])
    backwardSwitcherHotKey = HotKey(key: .tab, modifiers: [.option, .shift])
    categoryHotKey = HotKey(key: .space, modifiers: [.option, .control])
    
    // Handle option+tab - show panel and cycle forward
    switcherHotKey?.keyDownHandler = { [weak self] in
        self?.handleOptionTab(direction: .forward)
    }
    
    // Handle option+shift+tab - show panel and cycle backward
    backwardSwitcherHotKey?.keyDownHandler = { [weak self] in
        self?.handleOptionTab(direction: .backward)
    }
    
    // New handler for option+ctrl
    categoryHotKey?.keyDownHandler = { [weak self] in
        self?.handleCategoryJump()
    }
    
    // Monitor for option key up specifically
    NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
        // Check if option key was released
        if event.modifierFlags.intersection(.option).isEmpty {
            self?.hidePanel()
        }
    }
    
    // Remove the keyUpHandlers
    switcherHotKey?.keyUpHandler = nil
    backwardSwitcherHotKey?.keyUpHandler = nil
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
}

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

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    print("App launched, initializing...")
    
    if !AXIsProcessTrusted() {
      print("Requesting accessibility permissions...")
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
    
    print("Initialization complete")
  }

  func applicationWillTerminate(_ aNotification: Notification) {
  }

  func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  private func createFloatingPanel() {
    print("Creating floating panel")
    // Create the window
    appSwitcherPanel = FloatingPanel(contentRect: NSRect(x: 0, y: 0, width: 600, height: 160), backing: .buffered, defer: false)

    // Create ContentView with our pre-initialized view model
    let contentView = ContentView(viewModel: appViewModel)
    hostingView = NSHostingView(rootView: contentView)
    appSwitcherPanel.contentView = hostingView
    
    // Initial hide
    appSwitcherPanel.orderOut(nil)
    print("Floating panel created successfully")
  }
  
  private func setupHotKey() {
    // Create hot keys for both option+tab and option+shift+tab
    switcherHotKey = HotKey(key: .tab, modifiers: [.option])
    backwardSwitcherHotKey = HotKey(key: .tab, modifiers: [.option, .shift])
    
    // Handle option+tab - show panel and cycle forward
    switcherHotKey?.keyDownHandler = { [weak self] in
        print("Forward cycle")
        self?.handleOptionTab(direction: .forward)
    }
    
    // Handle option+shift+tab - show panel and cycle backward
    backwardSwitcherHotKey?.keyDownHandler = { [weak self] in
        print("Backward cycle")
        self?.handleOptionTab(direction: .backward)
    }
    
    // Monitor for option key up specifically
    NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
        // Check if option key was released
        if event.modifierFlags.intersection(.option).isEmpty {
            self?.hidePanel()
        }
    }
    
    // Remove the keyUpHandlers as we don't want to hide on tab release
    switcherHotKey?.keyUpHandler = nil
    backwardSwitcherHotKey?.keyUpHandler = nil
  }
  
  private enum CycleDirection {
    case forward
    case backward
  }
  
  private func handleOptionTab(direction: CycleDirection) {
    print("Handling Option + Tab with direction: \(direction)")
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
    print("Showing panel")
    appSwitcherPanel.center()
    appSwitcherPanel.orderFront(nil)
    appSwitcherPanel.makeKey()
    appViewModel.loadApps()
  }
  
  private func hidePanel() {
    print("Hiding panel")
    appSwitcherPanel.orderOut(nil)
  }
  
  private func togglePanel() {
    if appSwitcherPanel.isVisible {
      print("Hiding panel")
      appSwitcherPanel.orderOut(nil)
    } else {
      print("Showing panel")
      // Center the panel before showing it
      appSwitcherPanel.center()
      appSwitcherPanel.orderFront(nil)
      appSwitcherPanel.makeKey()
    }
  }
}

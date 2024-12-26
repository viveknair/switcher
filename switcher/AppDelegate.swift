//
//  AppDelegate.swift
//  switcher
//
//  Created by Vivek Nair on 4/28/22.
//

import Cocoa
import SwiftUI
import HotKey

enum CycleDirection {
    case forward
    case backward
}

class AppDelegate: NSObject, NSApplicationDelegate, AppCategorizerDelegate {
  let appSwitcherPanel: FloatingPanel
  private var hostingView: NSHostingView<ContentView>!
  var appViewModel = AppViewModel()
  private var preferencesWindow: NSWindow?
  private var hotkeyManager: HotkeyManager!
  private var appCategorizer: AppCategorizer!
  private var isHandlingOurOwnSwitch = false
  
  override init() {
    let panel = FloatingPanel(
      contentRect: NSRect(x: 0, y: 0, width: 800, height: 400),
      backing: .buffered,
      defer: false
    )
    
    panel.level = NSWindow.Level.popUpMenu
    panel.collectionBehavior = NSWindow.CollectionBehavior([.canJoinAllSpaces, .fullScreenAuxiliary])
    panel.isFloatingPanel = true
    panel.hidesOnDeactivate = false
    panel.orderOut(nil)
    
    self.appSwitcherPanel = panel
    
    super.init()
    
    appCategorizer = AppCategorizer()
    appCategorizer.delegate = self
    hotkeyManager = HotkeyManager(categorizer: appCategorizer)
    
    let contentView = ContentView(viewModel: appViewModel)
    hostingView = NSHostingView(rootView: contentView)
    panel.contentView = hostingView
    
    setupMenu()
  }
  
  private func setupMenu() {
    let mainMenu = NSMenu()
    
    let appMenu = NSMenu()
    let appMenuItem = NSMenuItem()
    appMenuItem.submenu = appMenu
    
    let prefsItem = NSMenuItem(title: "Preferences...", 
                              action: #selector(showPreferences), 
                              keyEquivalent: ",")
    appMenu.addItem(prefsItem)
    
    mainMenu.addItem(appMenuItem)
    NSApplication.shared.mainMenu = mainMenu
  }
  
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    NSApp.setActivationPolicy(.accessory)
    // Hide any window that might have been created
    NSApp.windows.forEach { $0.orderOut(nil) }
  }
  
  private func handleOptionTab(direction: CycleDirection) async {
    if !appSwitcherPanel.isVisible {
      await showPanel()
    }
    
    switch direction {
    case .forward:
      await appViewModel.cycleToNextApp()
    case .backward:
      await appViewModel.cycleToPreviousApp()
    }
  }
  
  private func showPanel() async {
    appSwitcherPanel.center()
    appSwitcherPanel.orderFront(nil)
    appSwitcherPanel.makeKey()
    await appViewModel.loadApps()
  }
  
  func applicationWillTerminate(_ aNotification: Notification) {
    // Clean up any resources if needed
  }
  
  func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
  
  @objc func showPreferences() {
    if let preferencesWindow = preferencesWindow {
      preferencesWindow.makeKeyAndOrderFront(nil)
      NSApp.activate(ignoringOtherApps: true)
      return
    }
    
    let preferencesView = PreferencesView()
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
      styleMask: [.titled, .closable, .miniaturizable, .resizable],
      backing: .buffered,
      defer: false
    )
    window.title = "Preferences"
    window.contentView = NSHostingView(rootView: preferencesView)
    window.center()
    window.setFrameAutosaveName("Preferences")
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
    
    preferencesWindow = window
  }
  
  // MARK: - AppCategorizerDelegate
  
  func showPanel() {
    Task { @MainActor in
      if !appSwitcherPanel.isVisible {
        await self.showPanel()
      }
    }
  }
  
  func hidePanel() {
    appSwitcherPanel.orderOut(nil)
    if isHandlingOurOwnSwitch, let bundleId = appViewModel.currentSelectedApp?.bundleIdentifier {
      appViewModel.switchToApp(bundleId)
    }
    isHandlingOurOwnSwitch = false
  }
  
  func cycleToNextApp() {
    Task { @MainActor in
      isHandlingOurOwnSwitch = true
      await appViewModel.cycleToNextApp()
    }
  }
  
  func cycleToPreviousApp() {
    Task { @MainActor in
      isHandlingOurOwnSwitch = true
      await appViewModel.cycleToPreviousApp()
    }
  }
  
  func jumpToNextCategory() {
    Task { @MainActor in
      isHandlingOurOwnSwitch = true
      await appViewModel.jumpToNextCategory()
    }
  }
}

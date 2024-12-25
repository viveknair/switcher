//
//  AppDelegate.swift
//  switcher
//
//  Created by Vivek Nair on 4/28/22.
//

import Cocoa
import SwiftUI
import CoreFoundation

@main
class AppDelegate: NSObject, NSApplicationDelegate {

  var appSwitcherPanel: FloatingPanel!
  var eventTap: CFMachPort?
  var runLoopSource: CFRunLoopSource?

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    print("App launched, setting up event tap...")
    
    // Request accessibility permissions
    if !AXIsProcessTrusted() {
      let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
      AXIsProcessTrustedWithOptions(options as CFDictionary)
      print("Requesting accessibility permissions...")
    }
    
    createFloatingPanel()
    setupEventTap()
    
    // Keep the app running in the background
    NSApp.setActivationPolicy(.accessory)
    
    // Initially hide the panel
    appSwitcherPanel.orderOut(nil)
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    if let eventTap = eventTap {
      CGEvent.tapEnable(tap: eventTap, enable: false)
      // Clean up run loop source if it exists
      if let source = runLoopSource {
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
      }
    }
  }

  func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  private func createFloatingPanel() {
      // Create the SwiftUI view that provides the window contents.
      // I've opted to ignore top safe area as well, since we're hiding the traffic icons
      let contentView = ContentView()
          .edgesIgnoringSafeArea(.top)
    
  
      // Create the window and set the content view.
      appSwitcherPanel = FloatingPanel(contentRect: NSRect(x: 0, y: 0, width: 600, height: 160), backing: .buffered, defer: false)

      appSwitcherPanel.contentView = NSHostingView(rootView: contentView)
      appSwitcherPanel.center()
  }
  
  private func setupEventTap() {
    let eventMask = (1 << CGEventType.keyDown.rawValue)
    
    let selfPtr = UnsafeMutableRawPointer(Unmanaged.passRetained(self).toOpaque())
    
    guard let eventTap = CGEvent.tapCreate(
      tap: .cgSessionEventTap,
      place: .headInsertEventTap,
      options: .defaultTap,
      eventsOfInterest: CGEventMask(eventMask),
      callback: { (proxy, type, event, ptr) -> Unmanaged<CGEvent>? in
        guard let ptr = ptr else { return Unmanaged.passUnretained(event) }
        let appDelegate = Unmanaged<AppDelegate>.fromOpaque(ptr).takeUnretainedValue()
        return appDelegate.handleEvent(proxy: proxy, type: type, event: event)
      },
      userInfo: selfPtr
    ) else {
      print("Failed to create event tap")
      Unmanaged<AppDelegate>.fromOpaque(selfPtr).release()
      return
    }
    
    self.eventTap = eventTap
    
    runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
    if let source = runLoopSource {
      CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
    }
    
    CGEvent.tapEnable(tap: eventTap, enable: true)
    print("Event tap setup complete")
  }
  
  public func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
    if type == .keyDown {
        guard let nsEvent = NSEvent(cgEvent: event) else {
            return Unmanaged.passUnretained(event)
        }
        
        let isOptionPressed = nsEvent.modifierFlags.contains(.option)
        let isTabKey = nsEvent.keyCode == 48 // Tab key code
        
        print("Key event - flags: \(nsEvent.modifierFlags), keyCode: \(nsEvent.keyCode)")
        
        if isOptionPressed && isTabKey {
            print("Option + Tab detected!")
            DispatchQueue.main.async { [weak self] in
                self?.togglePanel()
            }
            return nil // Consume the event
        }
    }
    return Unmanaged.passUnretained(event)
  }
  
  private func togglePanel() {
    if appSwitcherPanel.isVisible {
      print("Hiding panel")
      appSwitcherPanel.orderOut(nil)
    } else {
      print("Showing panel")
      appSwitcherPanel.orderFront(nil)
      appSwitcherPanel.makeKey()
    }
  }
}

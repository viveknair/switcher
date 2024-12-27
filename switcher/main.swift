import Cocoa

let delegate = AppDelegate()
NSApplication.shared.delegate = delegate

// Ensure app is activated at launch
NSApp.setActivationPolicy(.accessory)
NSApp.activate(ignoringOtherApps: true)

_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv) 

	

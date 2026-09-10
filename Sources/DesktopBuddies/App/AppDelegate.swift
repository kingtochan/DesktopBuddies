import AppKit
import SwiftUI

/// Main application delegate configuring background accessory mode, menu bar, and window coordination.
public final class AppDelegate: NSObject, NSApplicationDelegate {
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as an accessory app (resides in the menu bar and floats on desktop without cluttering Dock)
        NSApp.setActivationPolicy(.accessory)
        
        // Setup status bar item and menu
        StatusItemManager.shared.setup()
        
        // Start buddy window manager
        WindowManager.shared.start()
    }
    
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Do not quit when settings window closes; buddies stay active on desktop
        return false
    }
}

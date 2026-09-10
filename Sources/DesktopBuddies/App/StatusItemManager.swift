import AppKit
import SwiftUI

/// Manages the macOS Menu Bar Status Item (Tray Icon) and its menu actions.
@MainActor
public final class StatusItemManager: NSObject, NSMenuDelegate {
    public static let shared = StatusItemManager()
    
    private var statusItem: NSStatusItem?
    private var settingsWindowController: NSWindowController?
    
    private override init() {
        super.init()
    }
    
    public func setup() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            if let img = NSImage(systemSymbolName: "figure.walk.motion", accessibilityDescription: "Desktop Buddies") {
                img.isTemplate = true
                button.image = img
            } else {
                button.title = "🚶"
            }
            button.toolTip = "Desktop Buddies"
        }
        
        let menu = NSMenu()
        menu.delegate = self
        item.menu = menu
        self.statusItem = item
    }
    
    // Dynamically rebuild the menu each time it opens
    public func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        
        let count = BuddyManager.shared.buddies.count
        let header = NSMenuItem(title: "Desktop Buddies (\(count) active)", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        
        menu.addItem(NSMenuItem.separator())
        
        let addBuddyItem = NSMenuItem(title: "Add New Buddy", action: #selector(handleAddBuddy), keyEquivalent: "n")
        addBuddyItem.target = self
        menu.addItem(addBuddyItem)
        
        let uploadFaceItem = NSMenuItem(title: "Upload Face Photo...", action: #selector(handleUploadFace), keyEquivalent: "")
        uploadFaceItem.target = self
        menu.addItem(uploadFaceItem)
        
        let settingsItem = NSMenuItem(title: "Buddy Manager & Settings...", action: #selector(handleOpenSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Display Layer Submenu
        let layerSubmenu = NSMenu()
        let floatItem = NSMenuItem(title: "Float Over All Windows", action: #selector(handleSetFloating), keyEquivalent: "")
        floatItem.target = self
        floatItem.state = BuddyManager.shared.windowLevel == .floating ? .on : .off
        layerSubmenu.addItem(floatItem)
        
        let desktopItem = NSMenuItem(title: "On Desktop Wallpaper", action: #selector(handleSetDesktop), keyEquivalent: "")
        desktopItem.target = self
        desktopItem.state = BuddyManager.shared.windowLevel == .desktop ? .on : .off
        layerSubmenu.addItem(desktopItem)
        
        let layerParent = NSMenuItem(title: "Display Layer", action: nil, keyEquivalent: "")
        layerParent.submenu = layerSubmenu
        menu.addItem(layerParent)
        
        // Sound toggle
        let soundItem = NSMenuItem(
            title: SoundManager.shared.isMuted ? "Unmute Sound Effects" : "Mute Sound Effects",
            action: #selector(handleToggleSound),
            keyEquivalent: ""
        )
        soundItem.target = self
        menu.addItem(soundItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let wakeAllItem = NSMenuItem(title: "Wake All", action: #selector(handleWakeAll), keyEquivalent: "")
        wakeAllItem.target = self
        menu.addItem(wakeAllItem)
        
        let sleepAllItem = NSMenuItem(title: "Put All to Sleep", action: #selector(handleSleepAll), keyEquivalent: "")
        sleepAllItem.target = self
        menu.addItem(sleepAllItem)
        
        let resetItem = NSMenuItem(title: "Reset Positions to Bottom", action: #selector(handleResetPositions), keyEquivalent: "r")
        resetItem.target = self
        menu.addItem(resetItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit Desktop Buddies", action: #selector(handleQuit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }
    
    // MARK: - Actions
    
    @objc private func handleAddBuddy() {
        BuddyManager.shared.addBuddy()
    }
    
    @objc private func handleUploadFace() {
        if let firstBuddy = BuddyManager.shared.buddies.first {
            if let photoURL = FaceStorage.shared.promptUserForPhoto() {
                BuddyManager.shared.setFacePhoto(id: firstBuddy.id, imageURL: photoURL)
            }
        } else {
            handleOpenSettings()
        }
    }
    
    @objc public func handleOpenSettings() {
        if let controller = settingsWindowController, let window = controller.window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let hostingController = NSHostingController(rootView: SettingsWindow())
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Desktop Buddies Manager"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.center()
        window.setFrameAutosaveName("DesktopBuddiesSettingsWindow")
        
        let controller = NSWindowController(window: window)
        self.settingsWindowController = controller
        controller.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func handleSetFloating() {
        BuddyManager.shared.windowLevel = .floating
    }
    
    @objc private func handleSetDesktop() {
        BuddyManager.shared.windowLevel = .desktop
    }
    
    @objc private func handleToggleSound() {
        SoundManager.shared.isMuted.toggle()
    }
    
    @objc private func handleWakeAll() {
        BuddyManager.shared.setAllSleep(false)
    }
    
    @objc private func handleSleepAll() {
        BuddyManager.shared.setAllSleep(true)
    }
    
    @objc private func handleResetPositions() {
        BuddyManager.shared.resetAllPositions()
    }
    
    @objc private func handleQuit() {
        NSApplication.shared.terminate(nil)
    }
}

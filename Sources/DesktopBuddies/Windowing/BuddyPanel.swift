import AppKit
import SwiftUI

/// Custom borderless, transparent floating NSPanel for an individual desktop buddy.
public final class BuddyPanel: NSPanel {
    public let buddyId: UUID
    private var initialMouseLocation: CGPoint = .zero
    private var initialWindowOrigin: CGPoint = .zero
    private var isCurrentlyDragging: Bool = false
    private var lastDragPoint: CGPoint = .zero
    private var dragVelocity: CGPoint = .zero
    private var dragStartTime: TimeInterval = 0
    
    public init(buddyId: UUID, initialFrame: NSRect) {
        self.buddyId = buddyId
        
        super.init(
            contentRect: initialFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.isMovableByWindowBackground = false
        self.becomesKeyOnlyIfNeeded = true
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        
        updateWindowLevel(level: BuddyManager.shared.windowLevel)
    }
    
    public override var canBecomeKey: Bool {
        return false
    }
    
    public override var canBecomeMain: Bool {
        return false
    }
    
    public func updateWindowLevel(level: BuddyWindowLevel) {
        switch level {
        case .floating:
            self.level = .floating
        case .desktop:
            // Sits directly on desktop wallpaper, behind normal application windows
            self.level = NSWindow.Level(Int(CGWindowLevelForKey(.desktopWindow)) + 1)
        }
    }
    
    // MARK: - Master Event Routing
    
    public override func sendEvent(_ event: NSEvent) {
        switch event.type {
        case .leftMouseDown:
            initialMouseLocation = NSEvent.mouseLocation
            initialWindowOrigin = self.frame.origin
            lastDragPoint = initialMouseLocation
            dragVelocity = .zero
            dragStartTime = ProcessInfo.processInfo.systemUptime
            isCurrentlyDragging = false
            super.sendEvent(event)
            
        case .leftMouseDragged:
            let currentLocation = NSEvent.mouseLocation
            let dx = currentLocation.x - initialMouseLocation.x
            let dy = currentLocation.y - initialMouseLocation.y
            let distance = hypot(dx, dy)
            
            if distance > 4.0 && !isCurrentlyDragging {
                isCurrentlyDragging = true
                BuddyManager.shared.startDragging(id: buddyId)
            }
            
            if isCurrentlyDragging {
                let newOrigin = CGPoint(
                    x: initialWindowOrigin.x + dx,
                    y: initialWindowOrigin.y + dy
                )
                self.setFrameOrigin(newOrigin)
                
                // Track velocity for throw impulse
                dragVelocity = CGPoint(
                    x: currentLocation.x - lastDragPoint.x,
                    y: currentLocation.y - lastDragPoint.y
                )
                lastDragPoint = currentLocation
                
                BuddyManager.shared.updateDragPosition(id: buddyId, newX: newOrigin.x, newY: newOrigin.y)
                return
            }
            super.sendEvent(event)
            
        case .leftMouseUp:
            let duration = ProcessInfo.processInfo.systemUptime - dragStartTime
            
            if isCurrentlyDragging {
                isCurrentlyDragging = false
                BuddyManager.shared.endDragging(id: buddyId, throwVelocity: dragVelocity)
                return
            } else if duration < 0.4 {
                if event.clickCount >= 2 {
                    // Double click -> Cheer and Dance!
                    BuddyManager.shared.cheer(id: buddyId)
                } else {
                    // Single click -> Poke or Wake buddy up!
                    BuddyManager.shared.pokeBuddy(id: buddyId)
                }
            }
            super.sendEvent(event)
            
        default:
            super.sendEvent(event)
        }
    }
}

import SwiftUI
import AppKit

/// Top-level view for a desktop buddy inside its individual transparent window.
public struct BuddyView: View {
    public let buddy: Buddy
    @ObservedObject private var manager = BuddyManager.shared
    
    public init(buddy: Buddy) {
        self.buddy = buddy
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Emote bubble (not flipped)
            EmoteOverlayView(emote: buddy.emote, state: buddy.state)
                .frame(height: 32)
            
            // Character body and head (flipped based on direction)
            VStack(spacing: -6) {
                // Head / Face
                FaceView(buddy: buddy, faceSize: 56)
                    .zIndex(2)
                
                // Torso & Limbs
                BuddyBodyView(buddy: buddy)
                    .zIndex(1)
            }
            .scaleEffect(x: buddy.direction.isRight ? 1.0 : -1.0, y: 1.0)
            
            // Soft ground contact shadow
            if buddy.state != .dragged && buddy.state != .falling {
                Ellipse()
                    .fill(Color.black.opacity(0.18))
                    .frame(width: 44, height: 8)
                    .blur(radius: 1.5)
                    .offset(y: 4)
            } else {
                Spacer().frame(height: 12)
            }
        }
        .scaleEffect(CGFloat(buddy.scale))
        .frame(width: 160, height: 180)
        .contentShape(Rectangle())
        .contextMenu {
            buddyContextMenu
        }
    }
    
    // MARK: - Context Menu
    
    @ViewBuilder
    private var buddyContextMenu: some View {
        Button {
            if let photoURL = FaceStorage.shared.promptUserForPhoto() {
                manager.setFacePhoto(id: buddy.id, imageURL: photoURL)
            }
        } label: {
            Label("Upload Face Photo...", systemImage: "photo.badge.plus")
        }
        
        if buddy.faceImagePath != nil {
            Button {
                manager.resetFacePhoto(id: buddy.id)
            } label: {
                Label("Reset to Cartoon Face", systemImage: "arrow.counterclockwise")
            }
        } else {
            Button {
                manager.resetFacePhoto(id: buddy.id)
            } label: {
                Label("Cycle Cartoon Avatar", systemImage: "person.crop.circle.badge.plus")
            }
        }
        
        Divider()
        
        Button {
            manager.pokeBuddy(id: buddy.id)
        } label: {
            Label(buddy.state == .sleeping ? "Wake Up!" : "Poke / Push!", systemImage: "hand.point.up.left.fill")
        }
        
        Button {
            manager.giveBigPush(id: buddy.id, rightward: buddy.direction.isRight)
        } label: {
            Label("Big Push Forward 💨", systemImage: "wind")
        }
        
        Button {
            manager.cheer(id: buddy.id)
        } label: {
            Label("Dance & Cheer ✨", systemImage: "sparkles")
        }
        
        Button {
            manager.toggleSleep(id: buddy.id)
        } label: {
            Label(buddy.state == .sleeping ? "Wake Up ⏰" : "Put to Nap 😴", systemImage: buddy.state == .sleeping ? "alarm" : "moon.zzz")
        }
        
        Divider()
        
        Menu("Shirt Color") {
            Button("🔵 Cool Blue") { manager.setBodyColor(id: buddy.id, hex: "#3B82F6") }
            Button("🔴 Crimson Red") { manager.setBodyColor(id: buddy.id, hex: "#EF4444") }
            Button("🟢 Mint Green") { manager.setBodyColor(id: buddy.id, hex: "#10B981") }
            Button("🟡 Sunny Gold") { manager.setBodyColor(id: buddy.id, hex: "#F59E0B") }
            Button("🟣 Electric Purple") { manager.setBodyColor(id: buddy.id, hex: "#8B5CF6") }
            Button("🌸 Bubblegum Pink") { manager.setBodyColor(id: buddy.id, hex: "#EC4899") }
            Button("⚫ Sleek Charcoal") { manager.setBodyColor(id: buddy.id, hex: "#374151") }
        }
        
        Menu("Size") {
            Button("Small (80%)") { manager.setScale(id: buddy.id, scale: 0.8) }
            Button("Normal (100%)") { manager.setScale(id: buddy.id, scale: 1.0) }
            Button("Large (125%)") { manager.setScale(id: buddy.id, scale: 1.25) }
            Button("Jumbo (150%)") { manager.setScale(id: buddy.id, scale: 1.5) }
        }
        
        Menu("Display Layer") {
            Button(manager.windowLevel == .floating ? "✓ Float Over Windows" : "Float Over Windows") {
                manager.windowLevel = .floating
            }
            Button(manager.windowLevel == .desktop ? "✓ Desktop Wallpaper" : "Desktop Wallpaper") {
                manager.windowLevel = .desktop
            }
        }
        
        Divider()
        
        Button {
            manager.addBuddy()
        } label: {
            Label("Add Another Buddy", systemImage: "person.badge.plus")
        }
        
        if manager.buddies.count > 1 {
            Button(role: .destructive) {
                manager.removeBuddy(id: buddy.id)
            } label: {
                Label("Remove \(buddy.name)", systemImage: "trash")
            }
        }
    }
}

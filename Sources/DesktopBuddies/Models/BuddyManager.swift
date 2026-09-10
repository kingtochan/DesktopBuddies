import Foundation
import CoreGraphics
import AppKit
import Combine

/// Layer preference for displaying buddies on the screen.
public enum BuddyWindowLevel: String, Codable, CaseIterable, Sendable {
    case floating = "Float Above All Windows"
    case desktop = "On Desktop Wallpaper (Behind Windows)"
}

/// Central state coordinator and physics/AI engine for Desktop Buddies.
@MainActor
public final class BuddyManager: ObservableObject {
    public static let shared = BuddyManager()
    
    @Published public var buddies: [Buddy] = []
    @Published public var windowLevel: BuddyWindowLevel = .floating {
        didSet {
            UserDefaults.standard.set(windowLevel.rawValue, forKey: "DesktopBuddies_WindowLevel")
            onWindowLevelChanged?(windowLevel)
        }
    }
    
    public var onWindowLevelChanged: ((BuddyWindowLevel) -> Void)?
    public var onBuddyPositionChanged: ((UUID, CGPoint) -> Void)?
    
    private var timer: AnyCancellable?
    private let gravity: CGFloat = 0.55
    private let bounceDamping: CGFloat = 0.35
    private let friction: CGFloat = 0.94
    
    private let storageKey = "DesktopBuddies_SavedBuddies_v1"
    
    private init() {
        if let savedLevel = UserDefaults.standard.string(forKey: "DesktopBuddies_WindowLevel"),
           let level = BuddyWindowLevel(rawValue: savedLevel) {
            self.windowLevel = level
        }
        
        loadBuddies()
        
        if buddies.isEmpty {
            // Create default friendly starter buddy
            let starter = Buddy(
                id: UUID(),
                name: "Pip",
                faceImagePath: nil,
                defaultAvatarIndex: 0,
                bodyColorHex: "#3B82F6",
                scale: 1.0,
                x: 400,
                y: 120,
                direction: .right,
                state: .idle
            )
            buddies.append(starter)
            saveBuddies()
        }
        
        startSimulation()
    }
    
    // MARK: - Screen Awareness
    
    private func screenFor(point: CGPoint) -> NSScreen {
        for screen in NSScreen.screens {
            if screen.frame.contains(point) {
                return screen
            }
        }
        return NSScreen.main ?? NSScreen.screens.first ?? NSScreen()
    }
    
    // MARK: - Simulation Loop
    
    public func startSimulation() {
        timer?.cancel()
        timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTick()
            }
    }
    
    public func stopSimulation() {
        timer?.cancel()
        timer = nil
    }
    
    private func updateTick() {
        for i in 0..<buddies.count {
            var b = buddies[i]
            
            let screen = screenFor(point: CGPoint(x: b.x, y: b.y))
            let screenRect = screen.frame
            let visibleRect = screen.visibleFrame
            let floorY = visibleRect.minY + 2
            let minX: CGFloat = screenRect.minX + 10
            let maxX: CGFloat = screenRect.maxX - 160
            
            // 1. Emote timer
            if b.emoteTimer > 0 {
                b.emoteTimer -= 1.0 / 60.0
                if b.emoteTimer <= 0 && b.state != .sleeping {
                    b.emote = nil
                }
            } else if b.state == .sleeping {
                // Periodically pulse Zzz
                b.emote = .zzz
                b.emoteTimer = 2.0
            }
            
            // 2. State & Physics handling
            switch b.state {
            case .dragged:
                b.vx = 0
                b.vy = 0
                b.walkCycle = (b.walkCycle + 0.08).truncatingRemainder(dividingBy: 1.0)
                
            case .falling, .pushed:
                // Gravity
                b.vy -= gravity
                b.x += b.vx
                b.y += b.vy
                b.vx *= friction
                
                // Floor landing
                if b.y <= floorY {
                    b.y = floorY
                    if abs(b.vy) > 2.0 {
                        b.vy = -b.vy * bounceDamping
                        SoundManager.shared.playDrop()
                    } else {
                        b.vy = 0
                        b.vx = 0
                        b.state = .idle
                        b.stateTimer = Double.random(in: 2.0...4.0)
                    }
                }
                
                // Boundary bounces
                if b.x <= minX {
                    b.x = minX
                    b.vx = abs(b.vx) * 0.7
                    b.direction = .right
                } else if b.x >= maxX {
                    b.x = maxX
                    b.vx = -abs(b.vx) * 0.7
                    b.direction = .left
                }
                
            case .walking:
                let speed: CGFloat = 1.8
                b.vx = b.direction.isRight ? speed : -speed
                b.x += b.vx
                b.walkCycle = (b.walkCycle + 0.04).truncatingRemainder(dividingBy: 1.0)
                
                if b.x <= minX {
                    b.x = minX
                    b.direction = .right
                } else if b.x >= maxX {
                    b.x = maxX
                    b.direction = .left
                }
                
                if b.y > floorY + 4 {
                    b.state = .falling
                }
                
                decrementStateTimer(buddy: &b)
                
            case .running:
                let speed: CGFloat = 3.6
                b.vx = b.direction.isRight ? speed : -speed
                b.x += b.vx
                b.walkCycle = (b.walkCycle + 0.09).truncatingRemainder(dividingBy: 1.0)
                
                if b.x <= minX {
                    b.x = minX
                    b.direction = .right
                } else if b.x >= maxX {
                    b.x = maxX
                    b.direction = .left
                }
                
                if b.y > floorY + 4 {
                    b.state = .falling
                }
                
                decrementStateTimer(buddy: &b)
                
            case .idle:
                b.vx = 0
                b.vy = 0
                b.walkCycle = (b.walkCycle + 0.015).truncatingRemainder(dividingBy: 1.0)
                
                if b.y > floorY + 4 {
                    b.state = .falling
                }
                decrementStateTimer(buddy: &b)
                
            case .sitting:
                b.vx = 0
                b.vy = 0
                b.walkCycle = (b.walkCycle + 0.02).truncatingRemainder(dividingBy: 1.0)
                decrementStateTimer(buddy: &b)
                
            case .sleeping:
                b.vx = 0
                b.vy = 0
                if b.emote != .zzz {
                    b.emote = .zzz
                    b.emoteTimer = 3.0
                }
                decrementStateTimer(buddy: &b)
                
            case .cheering:
                b.vx = 0
                b.walkCycle = (b.walkCycle + 0.07).truncatingRemainder(dividingBy: 1.0)
                decrementStateTimer(buddy: &b)
            }
            
            // Keep on-screen safety
            b.x = max(minX - 10, min(b.x, maxX + 10))
            if b.state != .dragged && b.y < floorY {
                b.y = floorY
            }
            
            buddies[i] = b
            onBuddyPositionChanged?(b.id, CGPoint(x: b.x, y: b.y))
        }
    }
    
    private func decrementStateTimer(buddy: inout Buddy) {
        buddy.stateTimer -= 1.0 / 60.0
        if buddy.stateTimer <= 0 {
            transitionToNextAIState(buddy: &buddy)
        }
    }
    
    private func transitionToNextAIState(buddy: inout Buddy) {
        let roll = Double.random(in: 0...100)
        
        switch buddy.state {
        case .sleeping:
            if roll < 15 {
                buddy.state = .idle
                buddy.stateTimer = Double.random(in: 3.0...6.0)
                buddy.emote = .exclamation
                buddy.emoteTimer = 1.5
            } else {
                buddy.stateTimer = Double.random(in: 10.0...25.0)
            }
            
        case .sitting:
            if roll < 60 {
                buddy.state = .walking
                buddy.direction = Bool.random() ? .left : .right
                buddy.stateTimer = Double.random(in: 4.0...9.0)
            } else {
                buddy.state = .idle
                buddy.stateTimer = Double.random(in: 3.0...6.0)
            }
            
        default:
            if roll < 45 {
                buddy.state = .walking
                buddy.direction = Bool.random() ? .left : .right
                buddy.stateTimer = Double.random(in: 3.0...8.0)
            } else if roll < 68 {
                buddy.state = .idle
                buddy.stateTimer = Double.random(in: 2.5...5.5)
            } else if roll < 80 {
                buddy.state = .sitting
                buddy.stateTimer = Double.random(in: 4.0...9.0)
            } else if roll < 90 {
                buddy.state = .running
                buddy.direction = Bool.random() ? .left : .right
                buddy.stateTimer = Double.random(in: 2.0...4.0)
                buddy.emote = .musicalNote
                buddy.emoteTimer = 1.5
            } else if roll < 96 {
                buddy.state = .cheering
                buddy.stateTimer = 2.5
                buddy.emote = .heart
                buddy.emoteTimer = 2.0
            } else {
                buddy.state = .sleeping
                buddy.stateTimer = Double.random(in: 15.0...40.0)
                buddy.emote = .zzz
                buddy.emoteTimer = 2.0
            }
        }
    }
    
    // MARK: - User Interactions
    
    public func pokeBuddy(id: UUID) {
        guard let index = buddies.firstIndex(where: { $0.id == id }) else { return }
        var b = buddies[index]
        
        if b.state == .sleeping {
            b.state = .idle
            b.stateTimer = Double.random(in: 3...6)
            b.emote = .exclamation
            b.emoteTimer = 2.0
            SoundManager.shared.playWake()
        } else {
            let pushDirection: CGFloat = b.direction.isRight ? 1.0 : -1.0
            b.vx = pushDirection * CGFloat.random(in: 7.0...10.0)
            b.vy = CGFloat.random(in: 4.5...7.5)
            b.state = .pushed
            b.emote = .stars
            b.emoteTimer = 1.8
            SoundManager.shared.playPoke()
        }
        
        buddies[index] = b
        saveBuddies()
    }
    
    public func giveBigPush(id: UUID, rightward: Bool) {
        guard let index = buddies.firstIndex(where: { $0.id == id }) else { return }
        var b = buddies[index]
        b.direction = rightward ? .right : .left
        b.vx = (rightward ? 1.0 : -1.0) * 14.0
        b.vy = 8.0
        b.state = .pushed
        b.emote = .stars
        b.emoteTimer = 2.0
        SoundManager.shared.playPoke()
        buddies[index] = b
    }
    
    public func startDragging(id: UUID) {
        guard let index = buddies.firstIndex(where: { $0.id == id }) else { return }
        buddies[index].state = .dragged
        buddies[index].emote = .sweat
        buddies[index].emoteTimer = 3.0
    }
    
    public func updateDragPosition(id: UUID, newX: CGFloat, newY: CGFloat) {
        guard let index = buddies.firstIndex(where: { $0.id == id }) else { return }
        buddies[index].x = newX
        buddies[index].y = newY
    }
    
    public func endDragging(id: UUID, throwVelocity: CGPoint) {
        guard let index = buddies.firstIndex(where: { $0.id == id }) else { return }
        buddies[index].state = .falling
        buddies[index].vx = throwVelocity.x * 0.4
        buddies[index].vy = throwVelocity.y * 0.4
        buddies[index].emote = .question
        buddies[index].emoteTimer = 1.5
        saveBuddies()
    }
    
    public func toggleSleep(id: UUID) {
        guard let index = buddies.firstIndex(where: { $0.id == id }) else { return }
        if buddies[index].state == .sleeping {
            buddies[index].state = .idle
            buddies[index].emote = .exclamation
            buddies[index].emoteTimer = 1.5
            SoundManager.shared.playWake()
        } else {
            buddies[index].state = .sleeping
            buddies[index].emote = .zzz
            buddies[index].emoteTimer = 3.0
            SoundManager.shared.playSleep()
        }
        saveBuddies()
    }
    
    public func cheer(id: UUID) {
        guard let index = buddies.firstIndex(where: { $0.id == id }) else { return }
        buddies[index].state = .cheering
        buddies[index].stateTimer = 3.0
        buddies[index].emote = .heart
        buddies[index].emoteTimer = 2.5
        SoundManager.shared.playCheer()
        saveBuddies()
    }
    
    public func setFacePhoto(id: UUID, imageURL: URL) {
        guard let index = buddies.firstIndex(where: { $0.id == id }) else { return }
        if let savedPath = FaceStorage.shared.saveFaceImage(from: imageURL, for: id) {
            buddies[index].faceImagePath = savedPath
            saveBuddies()
        }
    }
    
    public func resetFacePhoto(id: UUID) {
        guard let index = buddies.firstIndex(where: { $0.id == id }) else { return }
        FaceStorage.shared.removeFaceImage(for: id)
        buddies[index].faceImagePath = nil
        buddies[index].defaultAvatarIndex = (buddies[index].defaultAvatarIndex + 1) % 6
        saveBuddies()
    }
    
    public func setBodyColor(id: UUID, hex: String) {
        guard let index = buddies.firstIndex(where: { $0.id == id }) else { return }
        buddies[index].bodyColorHex = hex
        saveBuddies()
    }
    
    public func setScale(id: UUID, scale: Double) {
        guard let index = buddies.firstIndex(where: { $0.id == id }) else { return }
        buddies[index].scale = max(0.6, min(scale, 1.8))
        saveBuddies()
    }
    
    public func addBuddy(name: String? = nil, faceURL: URL? = nil) {
        let colors = ["#EF4444", "#3B82F6", "#10B981", "#F59E0B", "#8B5CF6", "#EC4899", "#14B8A6"]
        let names = ["Mochi", "Boba", "Felix", "Nori", "Ziggy", "Pippin", "Cleo", "Sprout", "Kiko"]
        let chosenName = name ?? names.randomElement() ?? "Buddy"
        let chosenColor = colors.randomElement() ?? "#3B82F6"
        
        let screen = NSScreen.main ?? NSScreen.screens.first ?? NSScreen()
        let screenRect = screen.frame
        let visibleRect = screen.visibleFrame
        
        let newBuddyId = UUID()
        var facePath: String? = nil
        if let faceURL = faceURL {
            facePath = FaceStorage.shared.saveFaceImage(from: faceURL, for: newBuddyId)
        }
        
        let newBuddy = Buddy(
            id: newBuddyId,
            name: chosenName,
            faceImagePath: facePath,
            defaultAvatarIndex: Int.random(in: 0...5),
            bodyColorHex: chosenColor,
            scale: 1.0,
            x: CGFloat.random(in: (screenRect.midX - 200)...(screenRect.midX + 200)),
            y: visibleRect.minY + 120,
            vx: 0,
            vy: 0,
            direction: Bool.random() ? .right : .left,
            state: .falling,
            emote: .heart,
            emoteTimer: 2.0
        )
        
        buddies.append(newBuddy)
        SoundManager.shared.playCheer()
        saveBuddies()
    }
    
    public func removeBuddy(id: UUID) {
        FaceStorage.shared.removeFaceImage(for: id)
        buddies.removeAll { $0.id == id }
        saveBuddies()
    }
    
    public func resetAllPositions() {
        let screen = NSScreen.main ?? NSScreen.screens.first ?? NSScreen()
        let visibleRect = screen.visibleFrame
        for i in 0..<buddies.count {
            buddies[i].x = visibleRect.midX + CGFloat((i - buddies.count / 2) * 90)
            buddies[i].y = visibleRect.minY + 20
            buddies[i].vx = 0
            buddies[i].vy = 0
            buddies[i].state = .idle
            buddies[i].emote = .musicalNote
            buddies[i].emoteTimer = 1.5
        }
        saveBuddies()
    }
    
    public func setAllSleep(_ sleep: Bool) {
        for i in 0..<buddies.count {
            if sleep {
                buddies[i].state = .sleeping
                buddies[i].emote = .zzz
                buddies[i].emoteTimer = 3.0
            } else {
                buddies[i].state = .idle
                buddies[i].emote = .exclamation
                buddies[i].emoteTimer = 1.5
            }
        }
        if sleep {
            SoundManager.shared.playSleep()
        } else {
            SoundManager.shared.playWake()
        }
        saveBuddies()
    }
    
    // MARK: - Persistence
    
    private func saveBuddies() {
        do {
            let data = try JSONEncoder().encode(buddies)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to save buddies: \(error)")
        }
    }
    
    private func loadBuddies() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let loaded = try? JSONDecoder().decode([Buddy].self, from: data) else {
            return
        }
        self.buddies = loaded
    }
}

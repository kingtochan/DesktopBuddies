import Foundation
import CoreGraphics
import SwiftUI

/// Data model representing an individual desktop walker.
public struct Buddy: Identifiable, Codable, Sendable {
    public var id: UUID
    public var name: String
    
    /// Path to user-uploaded face image (relative or absolute in App Support)
    public var faceImagePath: String?
    
    /// Index for default cartoon avatar when no custom face is uploaded (0 to 5)
    public var defaultAvatarIndex: Int
    
    /// Hex color string for shirt/clothing
    public var bodyColorHex: String
    
    /// Scale factor for size (0.7 to 1.5)
    public var scale: Double
    
    /// Position in screen coordinates (AppKit: bottom-left is 0,0)
    public var x: CGFloat
    public var y: CGFloat
    
    /// Physics velocity
    public var vx: CGFloat
    public var vy: CGFloat
    
    /// Facing direction
    public var direction: Direction
    
    /// Current behavioral state
    public var state: BuddyState
    
    /// Walk cycle phase (0.0 to 1.0) for limb kinematics
    public var walkCycle: Double
    
    /// Active emote bubble (e.g. zzz, heart, exclamation)
    public var emote: BuddyEmote?
    
    /// Remaining seconds for the emote bubble
    public var emoteTimer: Double
    
    /// Timer for current state action (e.g. wandering duration, sitting duration)
    public var stateTimer: Double

    public init(
        id: UUID = UUID(),
        name: String = "Buddy",
        faceImagePath: String? = nil,
        defaultAvatarIndex: Int = 0,
        bodyColorHex: String = "#3B82F6", // bright friendly blue
        scale: Double = 1.0,
        x: CGFloat = 300,
        y: CGFloat = 100,
        vx: CGFloat = 0,
        vy: CGFloat = 0,
        direction: Direction = .right,
        state: BuddyState = .idle,
        walkCycle: Double = 0.0,
        emote: BuddyEmote? = nil,
        emoteTimer: Double = 0.0,
        stateTimer: Double = 3.0
    ) {
        self.id = id
        self.name = name
        self.faceImagePath = faceImagePath
        self.defaultAvatarIndex = defaultAvatarIndex
        self.bodyColorHex = bodyColorHex
        self.scale = scale
        self.x = x
        self.y = y
        self.vx = vx
        self.vy = vy
        self.direction = direction
        self.state = state
        self.walkCycle = walkCycle
        self.emote = emote
        self.emoteTimer = emoteTimer
        self.stateTimer = stateTimer
    }
}

import Foundation
import SwiftUI

/// States a desktop buddy can be in.
public enum BuddyState: String, Codable, CaseIterable, Sendable {
    case idle
    case walking
    case running
    case sitting
    case sleeping
    case dragged
    case falling
    case pushed
    case cheering

    public var displayName: String {
        switch self {
        case .idle: return "Idle"
        case .walking: return "Walking"
        case .running: return "Running"
        case .sitting: return "Sitting"
        case .sleeping: return "Sleeping"
        case .dragged: return "Picked Up"
        case .falling: return "Falling"
        case .pushed: return "Pushed!"
        case .cheering: return "Cheering"
        }
    }
}

/// Emotes displayed above buddy's head.
public enum BuddyEmote: String, Codable, Sendable {
    case zzz
    case exclamation
    case heart
    case stars
    case question
    case sweat
    case musicalNote

    public var symbol: String {
        switch self {
        case .zzz: return "💤"
        case .exclamation: return "❗"
        case .heart: return "💖"
        case .stars: return "💫"
        case .question: return "❓"
        case .sweat: return "💦"
        case .musicalNote: return "🎵"
        }
    }
}

/// Horizontal facing direction.
public enum Direction: String, Codable, Sendable {
    case left
    case right

    public var isRight: Bool {
        return self == .right
    }
}

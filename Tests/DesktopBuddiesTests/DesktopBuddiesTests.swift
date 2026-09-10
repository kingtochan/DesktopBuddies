import Testing
import Foundation
import CoreGraphics
import SwiftUI
@testable import DesktopBuddies

@Suite("Desktop Buddies Tests")
struct DesktopBuddiesTests {
    
    @Test("Buddy Model Codable JSON Roundtrip")
    func testBuddySerialization() throws {
        let originalBuddy = Buddy(
            id: UUID(),
            name: "TestBot",
            faceImagePath: "/path/to/face.png",
            defaultAvatarIndex: 3,
            bodyColorHex: "#EF4444",
            scale: 1.2,
            x: 500,
            y: 200,
            vx: 3.5,
            vy: -1.2,
            direction: .left,
            state: .walking,
            walkCycle: 0.5,
            emote: .heart,
            emoteTimer: 2.0,
            stateTimer: 4.5
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalBuddy)
        
        let decoder = JSONDecoder()
        let decodedBuddy = try decoder.decode(Buddy.self, from: data)
        
        #expect(decodedBuddy.id == originalBuddy.id)
        #expect(decodedBuddy.name == "TestBot")
        #expect(decodedBuddy.faceImagePath == "/path/to/face.png")
        #expect(decodedBuddy.defaultAvatarIndex == 3)
        #expect(decodedBuddy.bodyColorHex == "#EF4444")
        #expect(decodedBuddy.scale == 1.2)
        #expect(decodedBuddy.direction == .left)
        #expect(decodedBuddy.state == .walking)
        #expect(decodedBuddy.emote == .heart)
    }
    
    @Test("Color Hex Parser")
    func testColorHexParser() {
        let colorRed = Color(hex: "#EF4444")
        let colorBlue = Color(hex: "3B82F6")
        let colorShort = Color(hex: "#F00")
        
        #expect(colorRed != colorBlue)
        #expect(colorShort != colorBlue)
    }
    
    @Test("Buddy State & Emote Names")
    func testBuddyStates() {
        #expect(BuddyState.idle.displayName == "Idle")
        #expect(BuddyState.walking.displayName == "Walking")
        #expect(BuddyState.sleeping.displayName == "Sleeping")
        #expect(BuddyState.pushed.displayName == "Pushed!")
        #expect(BuddyEmote.zzz.symbol == "💤")
        #expect(BuddyEmote.heart.symbol == "💖")
    }
    
    @Test("Buddy Manager Interactions", .serialized)
    @MainActor
    func testBuddyManagerInteractions() {
        let manager = BuddyManager.shared
        
        let testBuddyId = UUID()
        let testBuddy = Buddy(
            id: testBuddyId,
            name: "UnitTestBuddy",
            defaultAvatarIndex: 0,
            bodyColorHex: "#3B82F6",
            state: .idle
        )
        manager.buddies.append(testBuddy)
        
        // Test poke (awake buddy gets pushed)
        manager.pokeBuddy(id: testBuddyId)
        if let updated = manager.buddies.first(where: { $0.id == testBuddyId }) {
            #expect(updated.state == .pushed)
            #expect(updated.emote == .stars)
        }
        
        // Test toggle sleep
        manager.toggleSleep(id: testBuddyId)
        if let sleeping = manager.buddies.first(where: { $0.id == testBuddyId }) {
            #expect(sleeping.state == .sleeping)
            #expect(sleeping.emote == .zzz)
        }
        
        // Test waking up via poke
        manager.pokeBuddy(id: testBuddyId)
        if let awake = manager.buddies.first(where: { $0.id == testBuddyId }) {
            #expect(awake.state == .idle)
            #expect(awake.emote == .exclamation)
        }
        
        // Clean up
        manager.removeBuddy(id: testBuddyId)
        #expect(!manager.buddies.contains(where: { $0.id == testBuddyId }))
    }
}

import AppKit

/// Plays subtle macOS system sound effects for interactive events.
@MainActor
public final class SoundManager {
    public static let shared = SoundManager()
    
    public var isMuted: Bool {
        get { UserDefaults.standard.bool(forKey: "DesktopBuddies_Muted") }
        set { UserDefaults.standard.set(newValue, forKey: "DesktopBuddies_Muted") }
    }
    
    private init() {}
    
    public func playPoke() {
        guard !isMuted else { return }
        NSSound(named: "Pop")?.play()
    }
    
    public func playWake() {
        guard !isMuted else { return }
        NSSound(named: "Tink")?.play()
    }
    
    public func playSleep() {
        guard !isMuted else { return }
        NSSound(named: "Bottle")?.play()
    }
    
    public func playDrop() {
        guard !isMuted else { return }
        NSSound(named: "Basso")?.play()
    }
    
    public func playCheer() {
        guard !isMuted else { return }
        NSSound(named: "Hero")?.play()
    }
}

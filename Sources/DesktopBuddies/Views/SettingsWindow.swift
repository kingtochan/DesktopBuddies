import SwiftUI
import AppKit

/// Settings and Buddy Management window allowing users to customize faces, colors, sizes, and behaviors.
public struct SettingsWindow: View {
    @ObservedObject private var manager = BuddyManager.shared
    @State private var soundMuted: Bool = SoundManager.shared.isMuted
    
    private let availableColors = [
        ("#3B82F6", "Blue"),
        ("#EF4444", "Red"),
        ("#10B981", "Green"),
        ("#F59E0B", "Gold"),
        ("#8B5CF6", "Purple"),
        ("#EC4899", "Pink"),
        ("#374151", "Charcoal"),
        ("#14B8A6", "Teal")
    ]
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            headerBar
            
            Divider()
            
            // Content List
            ScrollView {
                VStack(spacing: 20) {
                    // Global App Controls Card
                    globalControlsCard
                    
                    // Buddy Roster Cards
                    buddyListSection
                }
                .padding(20)
            }
            
            Divider()
            
            // Footer with quick action tips
            footerBar
        }
        .frame(minWidth: 540, minHeight: 600)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Header
    
    private var headerBar: some View {
        HStack {
            Image(systemName: "figure.walk.motion")
                .font(.system(size: 24))
                .foregroundColor(.accentColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Desktop Buddies")
                    .font(.title2.bold())
                Text("Cute walking companions on your Mac desktop")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button {
                manager.addBuddy()
            } label: {
                Label("Add Buddy", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
    
    // MARK: - Global Controls Card
    
    private var globalControlsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("General Settings")
                .font(.headline)
            
            // Window Layer Picker
            HStack {
                Text("Display Layer:")
                    .frame(width: 110, alignment: .leading)
                Picker("", selection: $manager.windowLevel) {
                    ForEach(BuddyWindowLevel.allCases, id: \.self) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            // Sound Effects Toggle
            Toggle("Enable Sound Effects", isOn: Binding(
                get: { !soundMuted },
                set: { enabled in
                    soundMuted = !enabled
                    SoundManager.shared.isMuted = !enabled
                }
            ))
            
            // Batch Actions
            HStack(spacing: 12) {
                Button("⏰ Wake All") {
                    manager.setAllSleep(false)
                }
                .buttonStyle(.bordered)
                
                Button("😴 Sleep All") {
                    manager.setAllSleep(true)
                }
                .buttonStyle(.bordered)
                
                Button("🧹 Reset Positions to Bottom") {
                    manager.resetAllPositions()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
        )
    }
    
    // MARK: - Buddy List Section
    
    private var buddyListSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Your Active Buddies (\(manager.buddies.count))")
                    .font(.headline)
                Spacer()
            }
            
            ForEach(manager.buddies) { buddy in
                buddyCard(buddy: buddy)
            }
        }
    }
    
    private func buddyCard(buddy: Buddy) -> some View {
        VStack(spacing: 14) {
            HStack(spacing: 16) {
                // Interactive Preview
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(NSColor.separatorColor).opacity(0.15))
                        .frame(width: 80, height: 90)
                    
                    FaceView(buddy: buddy, faceSize: 52)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    // Name & State
                    HStack {
                        Text(buddy.name)
                            .font(.title3.bold())
                        
                        Text("• \(buddy.state.displayName)")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color(NSColor.separatorColor).opacity(0.2)))
                        
                        Spacer()
                        
                        if manager.buddies.count > 1 {
                            Button(role: .destructive) {
                                manager.removeBuddy(id: buddy.id)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    
                    // Face Photo upload button
                    HStack(spacing: 8) {
                        Button {
                            if let photoURL = FaceStorage.shared.promptUserForPhoto() {
                                manager.setFacePhoto(id: buddy.id, imageURL: photoURL)
                            }
                        } label: {
                            Label(buddy.faceImagePath != nil ? "Change Photo" : "Upload Face Photo", systemImage: "photo.badge.plus")
                        }
                        .buttonStyle(.bordered)
                        
                        if buddy.faceImagePath != nil {
                            Button("Use Cartoon Face") {
                                manager.resetFacePhoto(id: buddy.id)
                            }
                            .buttonStyle(.borderless)
                            .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Divider()
            
            // Customization Options: Color swatches & size
            HStack(spacing: 20) {
                // Outfit Color
                VStack(alignment: .leading, spacing: 4) {
                    Text("Outfit Color:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 6) {
                        ForEach(availableColors, id: \.0) { hex, _ in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color.white, lineWidth: buddy.bodyColorHex == hex ? 2.5 : 0)
                                )
                                .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 1)
                                .onTapGesture {
                                    manager.setBodyColor(id: buddy.id, hex: hex)
                                }
                        }
                    }
                }
                
                Spacer()
                
                // Size Slider
                VStack(alignment: .leading, spacing: 4) {
                    Text("Size: \(Int(buddy.scale * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Slider(
                        value: Binding(
                            get: { buddy.scale },
                            set: { manager.setScale(id: buddy.id, scale: $0) }
                        ),
                        in: 0.7...1.5,
                        step: 0.1
                    )
                    .frame(width: 120)
                }
            }
            
            // Quick action buttons
            HStack(spacing: 10) {
                Button("Poke / Push") {
                    manager.pokeBuddy(id: buddy.id)
                }
                .buttonStyle(.bordered)
                
                Button(buddy.state == .sleeping ? "Wake Up" : "Take Nap") {
                    manager.toggleSleep(id: buddy.id)
                }
                .buttonStyle(.bordered)
                
                Button("Big Push 💨") {
                    manager.giveBigPush(id: buddy.id, rightward: buddy.direction.isRight)
                }
                .buttonStyle(.bordered)
                
                Button("Dance ✨") {
                    manager.cheer(id: buddy.id)
                }
                .buttonStyle(.bordered)
                
                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
        )
    }
    
    // MARK: - Footer
    
    private var footerBar: some View {
        HStack {
            Image(systemName: "info.circle")
                .foregroundColor(.secondary)
            Text("Tip: Click on any buddy on your desktop to poke them. Drag to move or throw them. Right-click for quick actions!")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

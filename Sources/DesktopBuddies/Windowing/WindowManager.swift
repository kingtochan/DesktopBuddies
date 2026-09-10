import AppKit
import SwiftUI
import Combine

/// Container view that looks up the buddy by ID and observes updates.
public struct BuddyContainerView: View {
    public let buddyId: UUID
    @ObservedObject private var manager = BuddyManager.shared
    
    public init(buddyId: UUID) {
        self.buddyId = buddyId
    }
    
    public var body: some View {
        if let buddy = manager.buddies.first(where: { $0.id == buddyId }) {
            BuddyView(buddy: buddy)
        } else {
            EmptyView()
        }
    }
}

/// Manages the collection of BuddyPanel floating windows for each active buddy.
@MainActor
public final class WindowManager {
    public static let shared = WindowManager()
    
    private var panels: [UUID: BuddyPanel] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupBindings()
    }
    
    public func start() {
        syncPanels(with: BuddyManager.shared.buddies)
    }
    
    private func setupBindings() {
        // Observe buddy list additions and removals
        BuddyManager.shared.$buddies
            .map { Set($0.map { $0.id }) }
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.syncPanels(with: BuddyManager.shared.buddies)
            }
            .store(in: &cancellables)
        
        // Observe position updates from physics/AI
        BuddyManager.shared.onBuddyPositionChanged = { [weak self] id, position in
            guard let self = self, let panel = self.panels[id] else { return }
            // Only update origin if not currently dragged by user
            if let buddy = BuddyManager.shared.buddies.first(where: { $0.id == id }),
               buddy.state != .dragged {
                panel.setFrameOrigin(position)
            }
        }
        
        // Observe window level changes
        BuddyManager.shared.onWindowLevelChanged = { [weak self] level in
            guard let self = self else { return }
            for panel in self.panels.values {
                panel.updateWindowLevel(level: level)
            }
        }
    }
    
    private func syncPanels(with buddies: [Buddy]) {
        let currentIds = Set(buddies.map { $0.id })
        let panelIds = Set(panels.keys)
        
        // Remove panels for deleted buddies
        for id in panelIds.subtracting(currentIds) {
            if let panel = panels.removeValue(forKey: id) {
                panel.orderOut(nil)
            }
        }
        
        // Create panels for new buddies (hosting views created only once)
        for buddy in buddies {
            if panels[buddy.id] == nil {
                let frame = NSRect(x: buddy.x, y: buddy.y, width: 160, height: 180)
                let panel = BuddyPanel(buddyId: buddy.id, initialFrame: frame)
                let hostingView = NSHostingView(rootView: BuddyContainerView(buddyId: buddy.id))
                panel.contentView = hostingView
                panel.orderFront(nil)
                panels[buddy.id] = panel
            }
        }
    }
}

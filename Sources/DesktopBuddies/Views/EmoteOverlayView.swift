import SwiftUI

/// Animated speech bubble and emotion icons floating above the buddy.
public struct EmoteOverlayView: View {
    public let emote: BuddyEmote?
    public let state: BuddyState
    
    public init(emote: BuddyEmote?, state: BuddyState) {
        self.emote = emote
        self.state = state
    }
    
    public var body: some View {
        Group {
            if let emote = emote {
                content(for: emote)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity).combined(with: .move(edge: .bottom)),
                        removal: .opacity.combined(with: .move(edge: .top))
                    ))
            } else {
                Spacer().frame(height: 28)
            }
        }
        .frame(height: 28)
    }
    
    @ViewBuilder
    private func content(for emote: BuddyEmote) -> some View {
        switch emote {
        case .zzz:
            ZzzView()
        case .exclamation:
            EmoteBadge(symbol: "❗", backgroundColor: Color.red.opacity(0.85))
        case .heart:
            EmoteBadge(symbol: "💖", backgroundColor: Color.pink.opacity(0.85))
        case .stars:
            EmoteBadge(symbol: "💫", backgroundColor: Color.yellow.opacity(0.85))
        case .question:
            EmoteBadge(symbol: "❓", backgroundColor: Color.blue.opacity(0.85))
        case .sweat:
            EmoteBadge(symbol: "💦", backgroundColor: Color.cyan.opacity(0.85))
        case .musicalNote:
            EmoteBadge(symbol: "🎵", backgroundColor: Color.purple.opacity(0.85))
        }
    }
}

struct EmoteBadge: View {
    let symbol: String
    let backgroundColor: Color
    
    var body: some View {
        HStack(spacing: 2) {
            Text(symbol)
                .font(.system(size: 14))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(Color.white)
                .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
        )
        .overlay(
            Capsule()
                .strokeBorder(backgroundColor.opacity(0.5), lineWidth: 1.5)
        )
    }
}

struct ZzzView: View {
    @State private var phase: Double = 0
    
    var body: some View {
        HStack(spacing: 2) {
            Text("Z")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(.blue.opacity(0.7))
                .offset(y: phase > 0.5 ? -2 : 0)
            Text("z")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.blue.opacity(0.85))
                .offset(y: phase > 0.5 ? -4 : -2)
            Text("z")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundColor(.indigo)
                .offset(y: phase > 0.5 ? -6 : -4)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.9))
                .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                phase = 1.0
            }
        }
    }
}

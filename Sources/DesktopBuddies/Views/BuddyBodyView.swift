import SwiftUI

/// Renders the animated body, arms, legs, and outfit for a buddy.
public struct BuddyBodyView: View {
    public let buddy: Buddy
    
    public init(buddy: Buddy) {
        self.buddy = buddy
    }
    
    private var bodyColor: Color {
        Color(hex: buddy.bodyColorHex)
    }
    
    public var body: some View {
        ZStack {
            // Legs (behind torso)
            legsView
            
            // Torso / Hoodie
            torsoView
            
            // Arms
            armsView
        }
        .frame(width: 60, height: 50)
    }
    
    // MARK: - Torso
    
    private var torsoView: some View {
        VStack(spacing: 0) {
            // Sweater / Hoodie
            RoundedRectangle(cornerRadius: 10)
                .fill(bodyColor)
                .frame(width: 34, height: 28)
                .overlay(
                    // Collar / Zipper detail
                    VStack(spacing: 2) {
                        Capsule().fill(Color.white.opacity(0.3)).frame(width: 14, height: 4)
                        Spacer()
                    }
                    .padding(.top, 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.black.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
        }
    }
    
    // MARK: - Arms
    
    private var armsView: some View {
        HStack(spacing: 24) {
            // Left arm
            singleArm(angle: leftArmAngle)
            // Right arm
            singleArm(angle: rightArmAngle)
        }
        .offset(y: -4)
    }
    
    private func singleArm(angle: Angle) -> some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(bodyColor)
                .frame(width: 7, height: 18)
                .overlay(
                    // Little hand at the end
                    Circle()
                        .fill(Color(red: 1.0, green: 0.88, blue: 0.77))
                        .frame(width: 7, height: 7)
                        .offset(y: 8)
                )
        }
        .rotationEffect(angle, anchor: .top)
    }
    
    // MARK: - Legs
    
    private var legsView: some View {
        HStack(spacing: 12) {
            singleLeg(angle: leftLegAngle)
            singleLeg(angle: rightLegAngle)
        }
        .offset(y: 20)
    }
    
    private func singleLeg(angle: Angle) -> some View {
        VStack(spacing: 0) {
            // Pants leg
            Capsule()
                .fill(Color(red: 0.22, green: 0.25, blue: 0.32)) // Navy / denim
                .frame(width: 7, height: 16)
            
            // Sneaker / Shoe
            shoeView
        }
        .rotationEffect(angle, anchor: .top)
    }
    
    private var shoeView: some View {
        HStack(spacing: 0) {
            Capsule()
                .fill(Color.white)
                .frame(width: 11, height: 6)
                .overlay(
                    Capsule().fill(Color.red).frame(width: 6, height: 3)
                )
        }
        .offset(x: buddy.direction.isRight ? 2 : -2, y: -2)
    }
    
    // MARK: - Dynamic Angles
    
    private var leftLegAngle: Angle {
        switch buddy.state {
        case .walking:
            return .degrees(sin(buddy.walkCycle * 2 * .pi) * 32)
        case .running:
            return .degrees(sin(buddy.walkCycle * 2 * .pi) * 48)
        case .dragged:
            // Flailing legs in air!
            return .degrees(sin(buddy.walkCycle * 4 * .pi) * 35)
        case .sitting:
            return .degrees(buddy.direction.isRight ? 75 : -75)
        case .sleeping:
            return .degrees(15)
        case .pushed, .falling:
            return .degrees(sin(buddy.walkCycle * 3 * .pi) * 25)
        case .cheering:
            return .degrees(sin(buddy.walkCycle * 3 * .pi) * 15)
        default:
            return .degrees(0)
        }
    }
    
    private var rightLegAngle: Angle {
        switch buddy.state {
        case .walking:
            return .degrees(-sin(buddy.walkCycle * 2 * .pi) * 32)
        case .running:
            return .degrees(-sin(buddy.walkCycle * 2 * .pi) * 48)
        case .dragged:
            return .degrees(-sin(buddy.walkCycle * 4 * .pi) * 35)
        case .sitting:
            return .degrees(buddy.direction.isRight ? 75 : -75)
        case .sleeping:
            return .degrees(-15)
        case .pushed, .falling:
            return .degrees(-sin(buddy.walkCycle * 3 * .pi) * 25)
        case .cheering:
            return .degrees(-sin(buddy.walkCycle * 3 * .pi) * 15)
        default:
            return .degrees(0)
        }
    }
    
    private var leftArmAngle: Angle {
        switch buddy.state {
        case .dragged:
            // Arms thrown up in excitement/shock (\o/)
            return .degrees(-130 + sin(buddy.walkCycle * 3 * .pi) * 15)
        case .cheering:
            return .degrees(-135 + sin(buddy.walkCycle * 4 * .pi) * 20)
        case .pushed:
            return .degrees(buddy.direction.isRight ? 60 : -60)
        case .walking:
            return .degrees(-sin(buddy.walkCycle * 2 * .pi) * 28)
        case .running:
            return .degrees(-sin(buddy.walkCycle * 2 * .pi) * 45)
        case .sitting:
            return .degrees(15)
        case .sleeping:
            return .degrees(25)
        default:
            return .degrees(sin(buddy.walkCycle * 2 * .pi) * 4)
        }
    }
    
    private var rightArmAngle: Angle {
        switch buddy.state {
        case .dragged:
            return .degrees(130 - sin(buddy.walkCycle * 3 * .pi) * 15)
        case .cheering:
            return .degrees(135 - sin(buddy.walkCycle * 4 * .pi) * 20)
        case .pushed:
            return .degrees(buddy.direction.isRight ? 60 : -60)
        case .walking:
            return .degrees(sin(buddy.walkCycle * 2 * .pi) * 28)
        case .running:
            return .degrees(sin(buddy.walkCycle * 2 * .pi) * 45)
        case .sitting:
            return .degrees(-15)
        case .sleeping:
            return .degrees(-25)
        default:
            return .degrees(-sin(buddy.walkCycle * 2 * .pi) * 4)
        }
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hexClean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hexClean).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hexClean.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 59, 130, 246)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

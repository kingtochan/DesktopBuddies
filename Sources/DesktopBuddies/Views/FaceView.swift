import SwiftUI
import AppKit

/// View that renders the buddy's face — either a user-uploaded custom photo or a built-in cute cartoon face.
public struct FaceView: View {
    public let buddy: Buddy
    public let faceSize: CGFloat
    
    public init(buddy: Buddy, faceSize: CGFloat = 56) {
        self.buddy = buddy
        self.faceSize = faceSize
    }
    
    public var body: some View {
        ZStack {
            if let customPath = buddy.faceImagePath,
               let nsImage = FaceStorage.shared.loadImage(at: customPath) {
                // User-uploaded custom face photo
                customPhotoFace(image: nsImage)
            } else {
                // Procedural cute cartoon face
                proceduralFace(index: buddy.defaultAvatarIndex)
            }
            
            // Expression overlays (dizzy stars, sweat drops, sleepy eyes)
            expressionOverlay
        }
        .frame(width: faceSize, height: faceSize)
        .rotationEffect(headTilt)
        .scaleEffect(headScale)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: buddy.state)
    }
    
    // MARK: - Custom Photo
    
    @ViewBuilder
    private func customPhotoFace(image: NSImage) -> some View {
        Image(nsImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: faceSize, height: faceSize)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .strokeBorder(Color.white.opacity(0.85), lineWidth: 2.5)
                    .shadow(color: .black.opacity(0.18), radius: 2, x: 0, y: 1)
            )
            .overlay(
                // Cute blush on cheeks over the photo
                HStack {
                    Circle().fill(Color.pink.opacity(0.25)).frame(width: 8, height: 8)
                    Spacer()
                    Circle().fill(Color.pink.opacity(0.25)).frame(width: 8, height: 8)
                }
                .padding(.horizontal, 8)
                .offset(y: 8)
            )
    }
    
    // MARK: - Procedural Cartoon Faces
    
    @ViewBuilder
    private func proceduralFace(index: Int) -> some View {
        let avatarIndex = index % 6
        ZStack {
            // Base head circle
            Circle()
                .fill(headColor(for: avatarIndex))
                .shadow(color: .black.opacity(0.12), radius: 2, x: 0, y: 1)
            
            // Hair / Hat / Ears
            switch avatarIndex {
            case 0:
                // Classic hair swoop
                hairSwoop(color: Color(red: 0.35, green: 0.20, blue: 0.10))
            case 1:
                // Cute bob bangs
                hairBangs(color: Color(red: 0.85, green: 0.45, blue: 0.20))
            case 2:
                // Cool spiky hair
                coolHair(color: Color(red: 0.2, green: 0.2, blue: 0.25))
            case 3:
                // Cat ears!
                catEars
            case 4:
                // Cozy beanie hat
                beanieHat
            case 5:
                // Cute robot antenna
                robotAntenna
            default:
                EmptyView()
            }
            
            // Eyes & Mouth based on state
            faceFeatures(avatarIndex: avatarIndex)
            
            // Blush cheeks
            if buddy.state != .sleeping {
                HStack {
                    Circle().fill(Color.pink.opacity(0.4)).frame(width: 7, height: 7)
                    Spacer()
                    Circle().fill(Color.pink.opacity(0.4)).frame(width: 7, height: 7)
                }
                .padding(.horizontal, 10)
                .offset(y: 4)
            }
        }
        .overlay(
            Circle()
                .strokeBorder(Color.white.opacity(0.3), lineWidth: 1.5)
        )
    }
    
    private func headColor(for index: Int) -> Color {
        switch index {
        case 0: return Color(red: 1.0, green: 0.88, blue: 0.77) // Peach
        case 1: return Color(red: 0.98, green: 0.84, blue: 0.72) // Fair
        case 2: return Color(red: 0.94, green: 0.78, blue: 0.62) // Tan
        case 3: return Color(red: 1.0, green: 0.92, blue: 0.80) // Cream
        case 4: return Color(red: 0.65, green: 0.48, blue: 0.35) // Deep warm
        case 5: return Color(red: 0.85, green: 0.90, blue: 0.95) // Soft cyan robot
        default: return Color(red: 1.0, green: 0.88, blue: 0.77)
        }
    }
    
    // MARK: - Hair & Hats
    
    private func hairSwoop(color: Color) -> some View {
        Path { path in
            path.addArc(center: CGPoint(x: faceSize/2, y: faceSize/2), radius: faceSize/2, startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
        }
        .fill(color)
        .offset(y: -faceSize * 0.18)
    }
    
    private func hairBangs(color: Color) -> some View {
        HStack(spacing: 3) {
            ForEach(0..<4) { _ in
                Capsule()
                    .fill(color)
                    .frame(width: 10, height: 16)
            }
        }
        .offset(y: -faceSize * 0.32)
    }
    
    private func coolHair(color: Color) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<5) { i in
                Capsule()
                    .fill(color)
                    .frame(width: 8, height: i == 2 ? 18 : 14)
            }
        }
        .offset(y: -faceSize * 0.35)
    }
    
    private var catEars: some View {
        HStack {
            Triangle()
                .fill(Color(red: 0.95, green: 0.75, blue: 0.6))
                .frame(width: 16, height: 16)
            Spacer()
            Triangle()
                .fill(Color(red: 0.95, green: 0.75, blue: 0.6))
                .frame(width: 16, height: 16)
        }
        .padding(.horizontal, 4)
        .offset(y: -faceSize * 0.46)
    }
    
    private var beanieHat: some View {
        VStack(spacing: 0) {
            Circle()
                .fill(Color.orange)
                .frame(width: 10, height: 10)
                .offset(y: 4)
            Capsule()
                .fill(Color(red: 0.25, green: 0.65, blue: 0.60))
                .frame(width: faceSize * 0.92, height: faceSize * 0.42)
        }
        .offset(y: -faceSize * 0.32)
    }
    
    private var robotAntenna: some View {
        VStack(spacing: 0) {
            Circle()
                .fill(Color.yellow)
                .frame(width: 9, height: 9)
            Rectangle()
                .fill(Color.gray)
                .frame(width: 3, height: 8)
        }
        .offset(y: -faceSize * 0.48)
    }
    
    // MARK: - Features (Eyes & Mouth)
    
    @ViewBuilder
    private func faceFeatures(avatarIndex: Int) -> some View {
        VStack(spacing: 3) {
            // Eyes
            switch buddy.state {
            case .sleeping:
                // Sleeping closed eyelids (-.-)
                HStack(spacing: 12) {
                    SleepingEye()
                    SleepingEye()
                }
            case .dragged:
                // Wide shocked eyes (O_O)
                HStack(spacing: 10) {
                    Circle().fill(Color.white).frame(width: 11, height: 11)
                        .overlay(Circle().fill(Color.black).frame(width: 5, height: 5))
                    Circle().fill(Color.white).frame(width: 11, height: 11)
                        .overlay(Circle().fill(Color.black).frame(width: 5, height: 5))
                }
            case .pushed:
                // Dizzy eyes (@_@)
                HStack(spacing: 10) {
                    Text("🌀").font(.system(size: 10))
                    Text("🌀").font(.system(size: 10))
                }
            case .cheering:
                // Joyful crescent eyes ( ^ - ^ )
                HStack(spacing: 12) {
                    HappyEye()
                    HappyEye()
                }
            default:
                if avatarIndex == 2 {
                    // Cool sunglasses
                    SunglassesView()
                } else {
                    // Regular cute shiny eyes
                    HStack(spacing: 12) {
                        NormalEye()
                        NormalEye()
                    }
                }
            }
            
            // Mouth
            switch buddy.state {
            case .sleeping:
                Capsule().fill(Color.black.opacity(0.5)).frame(width: 5, height: 2)
            case .dragged:
                Circle().fill(Color(red: 0.8, green: 0.3, blue: 0.3)).frame(width: 8, height: 8)
            case .pushed:
                Capsule().fill(Color.black.opacity(0.7)).frame(width: 9, height: 3)
            case .cheering:
                MouthSmile(open: true)
            default:
                MouthSmile(open: false)
            }
        }
        .offset(y: 2)
    }
    
    // MARK: - Expression Overlays
    
    @ViewBuilder
    private var expressionOverlay: some View {
        if buddy.faceImagePath != nil {
            // Overlays on top of custom photos for sleeping / surprised
            if buddy.state == .sleeping {
                // Semi-transparent night veil with closed eyes
                Circle()
                    .fill(Color.black.opacity(0.28))
                    .overlay(
                        HStack(spacing: 12) {
                            SleepingEye()
                            SleepingEye()
                        }
                    )
            } else if buddy.state == .dragged {
                // Shocked sweat drop
                VStack {
                    HStack {
                        Spacer()
                        Text("💧").font(.system(size: 14)).offset(x: 4, y: -8)
                    }
                    Spacer()
                }
            }
        }
    }
    
    // Dynamic Head Tilt / Bob
    private var headTilt: Angle {
        switch buddy.state {
        case .sleeping:
            return .degrees(buddy.direction.isRight ? 16 : -16)
        case .dragged:
            return .degrees(sin(buddy.walkCycle * 2 * .pi) * 12)
        case .pushed:
            return .degrees(buddy.direction.isRight ? -18 : 18)
        case .cheering:
            return .degrees(sin(buddy.walkCycle * 4 * .pi) * 8)
        case .walking, .running:
            return .degrees(sin(buddy.walkCycle * 2 * .pi) * 5)
        default:
            return .degrees(0)
        }
    }
    
    private var headScale: CGFloat {
        if buddy.state == .dragged { return 1.08 }
        if buddy.state == .cheering { return 1.1 }
        return 1.0
    }
}

// MARK: - Eye & Mouth Helper Shapes

struct NormalEye: View {
    var body: some View {
        Circle()
            .fill(Color.black.opacity(0.85))
            .frame(width: 6, height: 7)
            .overlay(
                Circle()
                    .fill(Color.white)
                    .frame(width: 2.2, height: 2.2)
                    .offset(x: 1, y: -1.5)
            )
    }
}

struct SleepingEye: View {
    var body: some View {
        Path { p in
            p.move(to: CGPoint(x: 0, y: 3))
            p.addQuadCurve(to: CGPoint(x: 8, y: 3), control: CGPoint(x: 4, y: 7))
        }
        .stroke(Color.black.opacity(0.8), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
        .frame(width: 8, height: 6)
    }
}

struct HappyEye: View {
    var body: some View {
        Path { p in
            p.move(to: CGPoint(x: 0, y: 4))
            p.addQuadCurve(to: CGPoint(x: 8, y: 4), control: CGPoint(x: 4, y: 0))
        }
        .stroke(Color.black.opacity(0.85), style: StrokeStyle(lineWidth: 2.0, lineCap: .round))
        .frame(width: 8, height: 6)
    }
}

struct SunglassesView: View {
    var body: some View {
        HStack(spacing: 1) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.black)
                .frame(width: 14, height: 8)
            Rectangle()
                .fill(Color.black)
                .frame(width: 4, height: 2)
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.black)
                .frame(width: 14, height: 8)
        }
        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
    }
}

struct MouthSmile: View {
    let open: Bool
    var body: some View {
        if open {
            Path { p in
                p.move(to: CGPoint(x: 0, y: 0))
                p.addQuadCurve(to: CGPoint(x: 10, y: 0), control: CGPoint(x: 5, y: 6))
                p.closeSubpath()
            }
            .fill(Color(red: 0.85, green: 0.35, blue: 0.35))
            .frame(width: 10, height: 6)
        } else {
            Path { p in
                p.move(to: CGPoint(x: 0, y: 1))
                p.addQuadCurve(to: CGPoint(x: 8, y: 1), control: CGPoint(x: 4, y: 5))
            }
            .stroke(Color.black.opacity(0.75), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            .frame(width: 8, height: 4)
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

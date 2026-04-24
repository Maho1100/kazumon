import SwiftUI
import UIKit

private struct ParallaxLayout {
    var distantY: CGFloat = 0
    var middleY: CGFloat = 0
    var foregroundY: CGFloat = 0
    var groundY: CGFloat = 0
    var distantScale: CGFloat = 1.0
    var middleScale: CGFloat = 1.0
    var foregroundScale: CGFloat = 1.0
    var groundScale: CGFloat = 1.0

    static let grassland = ParallaxLayout(
        distantY: -154, middleY: -71, foregroundY: -433, groundY: -420,
        distantScale: 3.57, middleScale: 1.01, foregroundScale: 0.64, groundScale: 1.68
    )
    static let cave = ParallaxLayout(
        distantY: -277, middleY: -283, foregroundY: -477, groundY: -420,
        distantScale: 2.37, middleScale: 3.00, foregroundScale: 1.77, groundScale: 1.58
    )
    static let castle = ParallaxLayout(
        distantY: -276, middleY: -222, foregroundY: -479, groundY: -358,
        distantScale: 3.91, middleScale: 2.70, foregroundScale: 1.46, groundScale: 1.95
    )
    static let darkCastle = ParallaxLayout(
        distantY: -238, middleY: -106, foregroundY: -435, groundY: -317,
        distantScale: 2.93, middleScale: 1.91, foregroundScale: 1.00, groundScale: 2.00
    )
    static let darkness = ParallaxLayout(
        distantY: 0, middleY: 0, foregroundY: -106, groundY: -372,
        distantScale: 1.02, middleScale: 1.00, foregroundScale: 3.53, groundScale: 0.89
    )

    static func forTheme(_ theme: String) -> ParallaxLayout {
        switch theme {
        case "grassland": return .grassland
        case "cave": return .cave
        case "castle": return .castle
        case "dark_castle": return .darkCastle
        case "darkness": return .darkness
        default: return ParallaxLayout()
        }
    }
}

struct BattleParallaxBackground: View {
    let floor: Int
    let isMistakeBossMode: Bool
    let isTimeBossMode: Bool
    let bgTop: Color
    let bgBottom: Color
    var speedMultiplier: CGFloat = 1.0

    var debugDistantY: CGFloat = 0
    var debugMiddleY: CGFloat = 0
    var debugForegroundY: CGFloat = 0
    var debugGroundY: CGFloat = 0
    var debugDistantScale: CGFloat = 0
    var debugMiddleScale: CGFloat = 0
    var debugForegroundScale: CGFloat = 0
    var debugGroundScale: CGFloat = 0

    private var theme: String {
        if isMistakeBossMode { return "dark_castle" }
        if isTimeBossMode { return "darkness" }
        switch floor {
        case 1...5: return "grassland"
        case 6...10: return "cave"
        case 11...15: return "castle"
        case 16...20: return "dark_castle"
        default: return "darkness"
        }
    }

    private var layout: ParallaxLayout {
        ParallaxLayout.forTheme(theme)
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [bgTop, bgBottom], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            parallaxLayers
                .id(theme)
                .transition(.opacity)
                .animation(.easeInOut(duration: 1.2), value: theme)
        }
    }

    private var parallaxLayers: some View {
        let l = layout
        return ZStack {
            ParallaxScrollLayer(
                imageName: "parallax_\(theme)_distant", speed: 8, alignment: .center,
                scale: l.distantScale + debugDistantScale, speedMultiplier: speedMultiplier
            )
            .offset(y: l.distantY + debugDistantY)

            ParallaxScrollLayer(
                imageName: "parallax_\(theme)_middle", speed: 20, alignment: .center,
                scale: l.middleScale + debugMiddleScale, speedMultiplier: speedMultiplier
            )
            .opacity(0.85)
            .offset(y: l.middleY + debugMiddleY)

            ParallaxScrollLayer(
                imageName: "parallax_\(theme)_foreground", speed: 35, alignment: .bottom,
                scale: l.foregroundScale + debugForegroundScale, speedMultiplier: speedMultiplier
            )
            .opacity(0.7)
            .offset(y: l.foregroundY + debugForegroundY)

            ParallaxScrollLayer(
                imageName: "parallax_\(theme)_ground", speed: 50, alignment: .bottom,
                scale: l.groundScale + debugGroundScale, speedMultiplier: speedMultiplier
            )
            .opacity(0.85)
            .offset(y: l.groundY + debugGroundY)
        }
        .ignoresSafeArea()
    }
}

private struct ParallaxScrollLayer: View {
    let imageName: String
    let speed: CGFloat
    let alignment: Alignment
    var scale: CGFloat = 1.0
    var speedMultiplier: CGFloat = 1.0

    @State private var startDate = Date()
    @State private var imageAspect: CGFloat = 1.5

    var body: some View {
        GeometryReader { geo in
            let w = max(1, geo.size.width)
            let h = (w / imageAspect) * max(0.2, scale)

            TimelineView(.animation) { ctx in
                let elapsed = ctx.date.timeIntervalSince(startDate)
                let offset = CGFloat(elapsed) * speed * speedMultiplier
                let x = -(offset.truncatingRemainder(dividingBy: w))

                HStack(spacing: 0) {
                    tile(w: w, h: h)
                    tile(w: w, h: h)
                }
                .offset(x: x)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
            }
        }
        .clipped()
        .onAppear {
            if let img = UIImage(named: imageName), img.size.height > 0 {
                imageAspect = img.size.width / img.size.height
            }
        }
    }

    private func tile(w: CGFloat, h: CGFloat) -> some View {
        Image(imageName)
            .resizable()
            .frame(width: w, height: h)
    }
}

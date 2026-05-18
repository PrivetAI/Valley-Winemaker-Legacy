import SwiftUI

// MARK: - Estate Monogram

struct ValleyEstateMonogram: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cx = rect.midX, cy = rect.midY
        let r = min(rect.width, rect.height) * 0.4
        path.addEllipse(in: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))

        // Inner V (valley) constructed from lines
        path.move(to: CGPoint(x: cx - r * 0.55, y: cy - r * 0.55))
        path.addLine(to: CGPoint(x: cx, y: cy + r * 0.55))
        path.addLine(to: CGPoint(x: cx + r * 0.55, y: cy - r * 0.55))

        // Crossbar
        path.move(to: CGPoint(x: cx - r * 0.35, y: cy + r * 0.05))
        path.addLine(to: CGPoint(x: cx + r * 0.35, y: cy + r * 0.05))

        // Spokes outside the circle
        for i in 0..<8 {
            let angle = Double(i) * .pi / 4
            let x1 = cx + cos(angle) * r * 1.05
            let y1 = cy + sin(angle) * r * 1.05
            let x2 = cx + cos(angle) * r * 1.18
            let y2 = cy + sin(angle) * r * 1.18
            path.move(to: CGPoint(x: x1, y: y1))
            path.addLine(to: CGPoint(x: x2, y: y2))
        }
        return path
    }
}

// MARK: - Barrel Icon

struct BarrelIcon: View {
    var size: CGFloat = 28
    var fillColor: Color = ValleyPalette.terracotta
    var strokeColor: Color = ValleyPalette.burgundy

    var body: some View {
        ZStack {
            BarrelShape()
                .fill(fillColor)
            BarrelShape()
                .stroke(strokeColor, lineWidth: 1.4)
            BarrelHoops()
                .stroke(strokeColor, lineWidth: 1.0)
        }
        .frame(width: size, height: size * 0.85)
    }
}

struct BarrelShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        let bulge = w * 0.12
        path.move(to: CGPoint(x: rect.minX + bulge, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - bulge, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY),
                          control: CGPoint(x: rect.maxX + bulge * 0.6, y: rect.minY + h * 0.25))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - bulge, y: rect.maxY),
                          control: CGPoint(x: rect.maxX + bulge * 0.6, y: rect.maxY - h * 0.25))
        path.addLine(to: CGPoint(x: rect.minX + bulge, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.midY),
                          control: CGPoint(x: rect.minX - bulge * 0.6, y: rect.maxY - h * 0.25))
        path.addQuadCurve(to: CGPoint(x: rect.minX + bulge, y: rect.minY),
                          control: CGPoint(x: rect.minX - bulge * 0.6, y: rect.minY + h * 0.25))
        return path
    }
}

struct BarrelHoops: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let h = rect.height
        let y1 = rect.minY + h * 0.28
        let y2 = rect.minY + h * 0.72
        path.move(to: CGPoint(x: rect.minX, y: y1))
        path.addLine(to: CGPoint(x: rect.maxX, y: y1))
        path.move(to: CGPoint(x: rect.minX, y: y2))
        path.addLine(to: CGPoint(x: rect.maxX, y: y2))
        return path
    }
}

// MARK: - Bottle Icon

struct BottleIcon: View {
    var size: CGFloat = 28
    var fillColor: Color = ValleyPalette.burgundy
    var capColor: Color = ValleyPalette.terracotta

    var body: some View {
        ZStack {
            BottleShape()
                .fill(fillColor)
            BottleShape()
                .stroke(ValleyPalette.burgundyDark, lineWidth: 1.0)
            BottleCap()
                .fill(capColor)
        }
        .frame(width: size * 0.55, height: size)
    }
}

struct BottleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let neck = w * 0.45
        let neckHeight = h * 0.32
        let shoulderHeight = h * 0.1
        path.move(to: CGPoint(x: rect.midX - neck/2, y: rect.minY + 2))
        path.addLine(to: CGPoint(x: rect.midX + neck/2, y: rect.minY + 2))
        path.addLine(to: CGPoint(x: rect.midX + neck/2, y: rect.minY + neckHeight))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + neckHeight + shoulderHeight + 4),
                          control: CGPoint(x: rect.midX + neck/2 + w * 0.18, y: rect.minY + neckHeight + 2))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 4))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - 4),
                          control: CGPoint(x: rect.midX, y: rect.maxY + 4))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + neckHeight + shoulderHeight + 4))
        path.addQuadCurve(to: CGPoint(x: rect.midX - neck/2, y: rect.minY + neckHeight),
                          control: CGPoint(x: rect.midX - neck/2 - w * 0.18, y: rect.minY + neckHeight + 2))
        path.closeSubpath()
        return path
    }
}

struct BottleCap: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let capWidth = rect.width * 0.55
        let capHeight = rect.height * 0.12
        path.addRoundedRect(in: CGRect(x: rect.midX - capWidth/2, y: rect.minY,
                                       width: capWidth, height: capHeight),
                            cornerSize: CGSize(width: 2, height: 2))
        return path
    }
}

// MARK: - Leaf Icon

struct LeafIcon: View {
    var size: CGFloat = 24
    var fillColor: Color = ValleyPalette.leaf

    var body: some View {
        LeafShape()
            .fill(fillColor)
            .frame(width: size, height: size)
    }
}

struct LeafShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY * 0.65),
                          control: CGPoint(x: rect.maxX + rect.width * 0.1, y: rect.minY + rect.height * 0.2))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY),
                          control: CGPoint(x: rect.maxX, y: rect.maxY * 1.05))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY * 0.65),
                          control: CGPoint(x: rect.minX, y: rect.maxY * 1.05))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY),
                          control: CGPoint(x: rect.minX - rect.width * 0.1, y: rect.minY + rect.height * 0.2))
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}

// MARK: - Weather Icons

struct SunIcon: View {
    var size: CGFloat = 24
    var color: Color = ValleyPalette.terracotta

    var body: some View {
        ZStack {
            ForEach(0..<8) { i in
                Capsule()
                    .fill(color)
                    .frame(width: size * 0.08, height: size * 0.22)
                    .offset(y: -size * 0.42)
                    .rotationEffect(.degrees(Double(i) * 45))
            }
            Circle()
                .fill(color)
                .frame(width: size * 0.55, height: size * 0.55)
        }
        .frame(width: size, height: size)
    }
}

struct CloudIcon: View {
    var size: CGFloat = 24
    var color: Color = ValleyPalette.sky

    var body: some View {
        CloudShape()
            .fill(color)
            .frame(width: size, height: size * 0.7)
    }
}

struct CloudShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let h = rect.height
        path.addEllipse(in: CGRect(x: rect.minX, y: rect.minY + h * 0.25, width: rect.width * 0.5, height: h * 0.7))
        path.addEllipse(in: CGRect(x: rect.minX + rect.width * 0.25, y: rect.minY, width: rect.width * 0.5, height: h * 0.85))
        path.addEllipse(in: CGRect(x: rect.minX + rect.width * 0.5, y: rect.minY + h * 0.2, width: rect.width * 0.5, height: h * 0.75))
        return path
    }
}

struct RainIcon: View {
    var size: CGFloat = 24
    var body: some View {
        VStack(spacing: 0) {
            CloudIcon(size: size * 0.9, color: ValleyPalette.sky)
            HStack(spacing: 2) {
                ForEach(0..<3) { _ in
                    Capsule().fill(ValleyPalette.sky.opacity(0.85))
                        .frame(width: 2, height: size * 0.18)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

struct SnowIcon: View {
    var size: CGFloat = 24
    var body: some View {
        ZStack {
            ForEach(0..<6) { i in
                Capsule()
                    .fill(ValleyPalette.frost)
                    .frame(width: size * 0.06, height: size * 0.7)
                    .rotationEffect(.degrees(Double(i) * 30))
            }
        }
        .frame(width: size, height: size)
    }
}

struct WindIcon: View {
    var size: CGFloat = 24
    var body: some View {
        VStack(spacing: size * 0.15) {
            Capsule().fill(ValleyPalette.olive).frame(width: size * 0.75, height: size * 0.08)
            Capsule().fill(ValleyPalette.olive).frame(width: size * 0.55, height: size * 0.08)
            Capsule().fill(ValleyPalette.olive).frame(width: size * 0.85, height: size * 0.08)
        }
        .frame(width: size, height: size)
    }
}

struct HailIcon: View {
    var size: CGFloat = 24
    var body: some View {
        VStack(spacing: 0) {
            CloudIcon(size: size * 0.9, color: ValleyPalette.dust)
            HStack(spacing: 2) {
                ForEach(0..<3) { _ in
                    Circle().fill(ValleyPalette.frost)
                        .frame(width: size * 0.14, height: size * 0.14)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

struct WeatherIcon: View {
    let weather: Weather
    var size: CGFloat = 28

    var body: some View {
        Group {
            switch weather {
            case .mild: SunIcon(size: size, color: ValleyPalette.olive)
            case .hot: SunIcon(size: size, color: ValleyPalette.terracotta)
            case .cold: SnowIcon(size: size)
            case .wet: RainIcon(size: size)
            case .drought: SunIcon(size: size, color: ValleyPalette.dust)
            case .hail: HailIcon(size: size)
            case .frost: SnowIcon(size: size)
            case .heatwave: SunIcon(size: size, color: ValleyPalette.burgundy)
            }
        }
    }
}

// MARK: - Person Silhouette

struct PersonIcon: View {
    var size: CGFloat = 24
    var color: Color = ValleyPalette.burgundy

    var body: some View {
        VStack(spacing: 0) {
            Circle().fill(color).frame(width: size * 0.42, height: size * 0.42)
            Capsule().fill(color)
                .frame(width: size * 0.7, height: size * 0.5)
                .offset(y: -size * 0.04)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Coin Icon

struct CoinIcon: View {
    var size: CGFloat = 22
    var body: some View {
        ZStack {
            Circle()
                .fill(ValleyPalette.goldMedal)
            Circle()
                .stroke(ValleyPalette.burgundy.opacity(0.6), lineWidth: 1)
                .padding(2)
            Capsule()
                .fill(ValleyPalette.burgundy.opacity(0.8))
                .frame(width: size * 0.35, height: size * 0.1)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Scale Icon

struct ScaleIcon: View {
    var size: CGFloat = 24
    var color: Color = ValleyPalette.burgundy
    var body: some View {
        ZStack {
            Capsule().fill(color).frame(width: size * 0.06, height: size)
            Capsule().fill(color).frame(width: size * 0.75, height: size * 0.08).offset(y: -size * 0.35)
            Triangle().fill(color).frame(width: size * 0.3, height: size * 0.18).offset(y: -size * 0.1)
            HStack(spacing: size * 0.5) {
                Circle().stroke(color, lineWidth: 1.4).frame(width: size * 0.18, height: size * 0.18)
                Circle().stroke(color, lineWidth: 1.4).frame(width: size * 0.18, height: size * 0.18)
            }.offset(y: -size * 0.27)
        }
        .frame(width: size, height: size)
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

// MARK: - Padlock

struct PadlockIcon: View {
    var size: CGFloat = 24
    var color: Color = ValleyPalette.burgundy
    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .stroke(color, lineWidth: 2)
                .frame(width: size * 0.5, height: size * 0.5)
                .offset(y: size * 0.06)
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: size * 0.7, height: size * 0.5)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Gear

struct GearIcon: View {
    var size: CGFloat = 24
    var color: Color = ValleyPalette.burgundy
    var body: some View {
        ZStack {
            ForEach(0..<8) { i in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(color)
                    .frame(width: size * 0.18, height: size * 0.32)
                    .offset(y: -size * 0.32)
                    .rotationEffect(.degrees(Double(i) * 45))
            }
            Circle().fill(color).frame(width: size * 0.5, height: size * 0.5)
            Circle().fill(ValleyPalette.cream).frame(width: size * 0.22, height: size * 0.22)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Check / X / Plus / Minus

struct CheckIcon: View {
    var size: CGFloat = 18
    var color: Color = ValleyPalette.olive
    var body: some View {
        CheckShape()
            .stroke(color, style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
            .frame(width: size, height: size)
    }
}

struct CheckShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.15, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.42, y: rect.maxY - rect.height * 0.18))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.12, y: rect.minY + rect.height * 0.22))
        return path
    }
}

struct XIcon: View {
    var size: CGFloat = 18
    var color: Color = ValleyPalette.burgundy
    var body: some View {
        ZStack {
            Capsule().fill(color).frame(width: size * 0.85, height: size * 0.16).rotationEffect(.degrees(45))
            Capsule().fill(color).frame(width: size * 0.85, height: size * 0.16).rotationEffect(.degrees(-45))
        }
        .frame(width: size, height: size)
    }
}

struct PlusIcon: View {
    var size: CGFloat = 18
    var color: Color = ValleyPalette.burgundy
    var body: some View {
        ZStack {
            Capsule().fill(color).frame(width: size * 0.85, height: size * 0.18)
            Capsule().fill(color).frame(width: size * 0.18, height: size * 0.85)
        }
        .frame(width: size, height: size)
    }
}

struct MinusIcon: View {
    var size: CGFloat = 18
    var color: Color = ValleyPalette.burgundy
    var body: some View {
        Capsule().fill(color).frame(width: size * 0.85, height: size * 0.18)
            .frame(width: size, height: size)
    }
}

// MARK: - Medal Icon

struct MedalIcon: View {
    let medal: Medal
    var size: CGFloat = 30

    var body: some View {
        VStack(spacing: 0) {
            Triangle()
                .fill(ValleyPalette.burgundy.opacity(0.8))
                .frame(width: size * 0.55, height: size * 0.35)
            Circle()
                .fill(medalColor)
                .frame(width: size * 0.9, height: size * 0.9)
                .overlay(Circle().stroke(ValleyPalette.burgundy, lineWidth: 1))
        }
        .frame(width: size, height: size * 1.2)
    }

    var medalColor: Color {
        switch medal {
        case .gold: return ValleyPalette.goldMedal
        case .silver: return ValleyPalette.silverMedal
        case .bronze: return ValleyPalette.bronzeMedal
        case .none: return ValleyPalette.creamWarm
        }
    }
}

// MARK: - Tab Icons

struct VineyardTabIcon: View {
    var size: CGFloat = 26
    var color: Color = ValleyPalette.burgundy
    var body: some View {
        ZStack {
            HStack(spacing: size * 0.06) {
                ForEach(0..<3) { _ in
                    Capsule().fill(color).frame(width: size * 0.08, height: size * 0.65)
                }
            }
            .offset(y: size * 0.12)
            LeafIcon(size: size * 0.55, fillColor: color)
                .offset(y: -size * 0.18)
        }
        .frame(width: size, height: size)
    }
}

struct CellarTabIcon: View {
    var size: CGFloat = 26
    var color: Color = ValleyPalette.burgundy
    var body: some View {
        VStack(spacing: 1) {
            HStack(spacing: 2) {
                BarrelIcon(size: size * 0.4, fillColor: color.opacity(0.7), strokeColor: color)
                BarrelIcon(size: size * 0.4, fillColor: color.opacity(0.7), strokeColor: color)
            }
            HStack(spacing: 2) {
                BarrelIcon(size: size * 0.4, fillColor: color.opacity(0.7), strokeColor: color)
                BarrelIcon(size: size * 0.4, fillColor: color.opacity(0.7), strokeColor: color)
            }
        }
        .frame(width: size, height: size)
    }
}

struct MarketTabIcon: View {
    var size: CGFloat = 26
    var color: Color = ValleyPalette.burgundy
    var body: some View {
        ZStack {
            ScaleIcon(size: size, color: color)
        }
    }
}

struct AlmanacTabIcon: View {
    var size: CGFloat = 26
    var color: Color = ValleyPalette.burgundy
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2).stroke(color, lineWidth: 1.6)
                .frame(width: size * 0.7, height: size * 0.85)
            Capsule().fill(color).frame(width: size * 0.04, height: size * 0.85)
                .offset(x: 0)
            VStack(spacing: 2) {
                ForEach(0..<4) { _ in
                    Capsule().fill(color).frame(width: size * 0.4, height: 1.5)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

struct MoreTabIcon: View {
    var size: CGFloat = 26
    var color: Color = ValleyPalette.burgundy
    var body: some View {
        HStack(spacing: size * 0.12) {
            Circle().fill(color).frame(width: size * 0.16, height: size * 0.16)
            Circle().fill(color).frame(width: size * 0.16, height: size * 0.16)
            Circle().fill(color).frame(width: size * 0.16, height: size * 0.16)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Cellar Rack visualization

struct CellarRack: View {
    let barrels: [Barrel]
    let screenSize: CGSize
    let onTapBarrel: (Barrel) -> Void

    var body: some View {
        let columns = max(3, min(5, Int(screenSize.width / 110)))
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: columns), spacing: 12) {
            ForEach(barrels) { barrel in
                Button(action: { onTapBarrel(barrel) }) {
                    VStack(spacing: 4) {
                        BarrelIcon(size: 56, fillColor: barrelColor(barrel),
                                   strokeColor: ValleyPalette.burgundyDark)
                        Text(barrel.name)
                            .font(.system(size: 11, weight: .semibold, design: .serif))
                            .foregroundColor(ValleyPalette.inkText)
                            .lineLimit(1)
                        Text("\(barrel.monthsAged) mo")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(ValleyPalette.olive)
                    }
                    .padding(8)
                    .background(ValleyPalette.ivory)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8).stroke(ValleyPalette.parchmentLine, lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    private func barrelColor(_ b: Barrel) -> Color {
        // Color tint by variety
        switch b.varietyID {
        case "v_aurelan_noir", "v_black_tipple", "v_carmene_carrare": return ValleyPalette.burgundy
        case "v_lambruvinia", "v_fioretta", "v_mistralia", "v_velrune", "v_tasselino": return ValleyPalette.terracotta
        case "v_petrov_blanc", "v_trebbio", "v_volkrein_riesling", "v_helvar_sauvage": return ValleyPalette.olive
        default: return ValleyPalette.terracotta
        }
    }
}

// MARK: - Profile bar (Body/Tannin/Acidity/Aroma)

struct ProfileBars: View {
    let profile: TasteProfile
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 3 : 6) {
            profileBar(label: "Body", value: profile.body, color: ValleyPalette.burgundy)
            profileBar(label: "Tannin", value: profile.tannin, color: ValleyPalette.terracotta)
            profileBar(label: "Acidity", value: profile.acidity, color: ValleyPalette.olive)
            profileBar(label: "Aroma", value: profile.aroma, color: ValleyPalette.sky)
        }
    }

    private func profileBar(label: String, value: Double, color: Color) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: compact ? 10 : 12, weight: .semibold, design: .serif))
                .foregroundColor(ValleyPalette.inkText)
                .frame(width: compact ? 48 : 60, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(ValleyPalette.creamWarm)
                    Capsule()
                        .fill(color)
                        .frame(width: max(2, geo.size.width * CGFloat(min(100, max(0, value))) / 100.0))
                }
            }
            .frame(height: compact ? 6 : 10)
            Text("\(Int(value))")
                .font(.system(size: compact ? 10 : 11, weight: .medium))
                .foregroundColor(ValleyPalette.olive)
                .frame(width: 28, alignment: .trailing)
        }
    }
}

// MARK: - Plot card

struct PlotCardView: View {
    let plot: VineyardPlot

    var body: some View {
        let variety = ValleyTables.variety(plot.varietyID)
        let terroir = ValleyTables.terroir(plot.terroirID)
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                LeafIcon(size: 18)
                Text(variety.name)
                    .font(.system(size: 15, weight: .bold, design: .serif))
                    .foregroundColor(ValleyPalette.inkText)
                Spacer()
                Text("\(plot.rows) rows")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(ValleyPalette.olive)
            }
            Text(terroir.name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(ValleyPalette.terracotta)
            HStack(spacing: 6) {
                Text("Prune")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(ValleyPalette.olive)
                ForEach(0..<4) { i in
                    Circle()
                        .fill(i <= plot.pruneLevel ? ValleyPalette.terracotta : ValleyPalette.creamWarm)
                        .frame(width: 8, height: 8)
                }
                Spacer()
                if plot.disease > 0.1 {
                    Text("Disease \(Int(plot.disease * 100))%")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(ValleyPalette.burgundy)
                }
            }
        }
        .padding(10)
        .background(ValleyPalette.ivory)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(ValleyPalette.parchmentLine, lineWidth: 1))
    }
}

// MARK: - Abstract Vineyard Canvas

struct VineyardCanvas: View {
    let plots: [VineyardPlot]
    let screenSize: CGSize

    var body: some View {
        Canvas { context, _ in
            // Anchor to parent-passed screenSize, not closure size.
            let canvasWidth = screenSize.width - 32
            let canvasHeight: CGFloat = 160
            let rowsPerPlot = 5
            let plotWidth = canvasWidth / CGFloat(max(plots.count, 1))
            // Sky gradient
            var skyRect = CGRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight * 0.4)
            context.fill(Path(skyRect),
                         with: .linearGradient(
                            Gradient(colors: [ValleyPalette.frost, ValleyPalette.ivory]),
                            startPoint: CGPoint(x: 0, y: 0),
                            endPoint: CGPoint(x: 0, y: skyRect.height)))
            // Hill silhouette
            var hill = Path()
            hill.move(to: CGPoint(x: 0, y: canvasHeight * 0.55))
            hill.addQuadCurve(to: CGPoint(x: canvasWidth, y: canvasHeight * 0.55),
                              control: CGPoint(x: canvasWidth / 2, y: canvasHeight * 0.35))
            hill.addLine(to: CGPoint(x: canvasWidth, y: canvasHeight))
            hill.addLine(to: CGPoint(x: 0, y: canvasHeight))
            hill.closeSubpath()
            context.fill(hill, with: .color(ValleyPalette.olive.opacity(0.5)))

            // Draw plots as vertical row stripes
            for (i, plot) in plots.enumerated() {
                let xStart = CGFloat(i) * plotWidth
                let stripeWidth = plotWidth / CGFloat(rowsPerPlot + 1)
                let baseY = canvasHeight * 0.55
                let varietyColor = colorFor(varietyID: plot.varietyID)
                for r in 0..<rowsPerPlot {
                    let x = xStart + CGFloat(r + 1) * stripeWidth - stripeWidth * 0.4
                    var rowPath = Path()
                    rowPath.addRect(CGRect(x: x, y: baseY, width: stripeWidth * 0.6, height: canvasHeight - baseY))
                    context.fill(rowPath, with: .color(varietyColor.opacity(0.6)))
                }
                // Disease overlay
                if plot.disease > 0.4 {
                    var d = Path()
                    d.addRect(CGRect(x: xStart, y: baseY, width: plotWidth, height: (canvasHeight - baseY) * CGFloat(plot.disease)))
                    context.fill(d, with: .color(ValleyPalette.burgundy.opacity(0.15)))
                }
            }
            _ = skyRect
        }
        .frame(height: 160)
        .padding(.horizontal, 16)
        .background(ValleyPalette.ivory)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(ValleyPalette.parchmentLine, lineWidth: 1))
        .padding(.horizontal, 16)
    }

    private func colorFor(varietyID: String) -> Color {
        switch varietyID {
        case "v_aurelan_noir", "v_carmene_carrare", "v_black_tipple": return ValleyPalette.burgundy
        case "v_lambruvinia", "v_fioretta", "v_mistralia", "v_velrune", "v_tasselino": return ValleyPalette.terracotta
        default: return ValleyPalette.olive
        }
    }
}

// MARK: - Status pill

struct StatusPill: View {
    let icon: AnyView
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                icon
                Text(title)
                    .font(.system(size: 11, weight: .semibold, design: .serif))
                    .foregroundColor(ValleyPalette.olive)
            }
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .serif))
                .foregroundColor(ValleyPalette.inkText)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(ValleyPalette.ivory)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(ValleyPalette.parchmentLine, lineWidth: 1))
    }
}

// MARK: - Section heading

struct ValleySectionHeader: View {
    let title: String
    var body: some View {
        HStack {
            Capsule().fill(ValleyPalette.terracotta).frame(width: 24, height: 3)
            Text(title)
                .font(.system(size: 16, weight: .black, design: .serif))
                .foregroundColor(ValleyPalette.burgundy)
            Capsule().fill(ValleyPalette.parchmentLine).frame(height: 1)
        }
        .padding(.bottom, 4)
    }
}

// MARK: - Primary button

struct ValleyPrimaryButton: View {
    let title: String
    var disabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: { if !disabled { action() } }) {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .serif))
                .foregroundColor(ValleyPalette.cream)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: disabled
                            ? [ValleyPalette.parchmentLine, ValleyPalette.dust]
                            : [ValleyPalette.terracotta, ValleyPalette.burgundy],
                        startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ValleySecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundColor(ValleyPalette.burgundy)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(ValleyPalette.creamWarm)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(ValleyPalette.burgundy.opacity(0.4), lineWidth: 1))
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

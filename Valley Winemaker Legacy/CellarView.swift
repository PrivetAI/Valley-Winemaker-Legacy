import SwiftUI

struct CellarView: View {
    @EnvironmentObject var store: ValleyStore
    @Binding var activeSheet: ValleyActiveSheet?
    @State private var section: Int = 0  // 0=Barrels, 1=Bottles

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    sectionSwitcher

                    if section == 0 {
                        barrelSection(screenSize: geo.size)
                    } else {
                        bottleSection
                    }

                    ValleySectionHeader(title: "Owned Cooperage")
                    cooperageGrid
                }
                .padding(16)
            }
        }
        .background(ValleyPalette.cream.edgesIgnoringSafeArea(.all))
        .navigationBarTitle("Cellar", displayMode: .inline)
    }

    private var sectionSwitcher: some View {
        HStack(spacing: 0) {
            Button(action: { section = 0 }) {
                Text("Aging Barrels")
                    .font(.system(size: 13, weight: .bold, design: .serif))
                    .foregroundColor(section == 0 ? ValleyPalette.cream : ValleyPalette.burgundy)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(section == 0 ? ValleyPalette.burgundy : ValleyPalette.ivory)
            }
            .buttonStyle(PlainButtonStyle())
            Button(action: { section = 1 }) {
                Text("Bottled Lots")
                    .font(.system(size: 13, weight: .bold, design: .serif))
                    .foregroundColor(section == 1 ? ValleyPalette.cream : ValleyPalette.burgundy)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(section == 1 ? ValleyPalette.burgundy : ValleyPalette.ivory)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(ValleyPalette.parchmentLine, lineWidth: 1))
        .cornerRadius(8)
    }

    private func barrelSection(screenSize: CGSize) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ValleySectionHeader(title: "Aging Rack")
            if store.state.barrels.isEmpty {
                Text("No barrels aging. Press a harvest bin to start.")
                    .font(.system(size: 13, design: .serif))
                    .foregroundColor(ValleyPalette.olive)
                    .padding(.leading, 4)
            } else {
                CellarRack(barrels: store.state.barrels, screenSize: screenSize) { barrel in
                    activeSheet = .ageBarrel(barrel.id)
                }
            }
        }
    }

    private var bottleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ValleySectionHeader(title: "Library of Bottled Lots")
            if store.state.bottledLots.isEmpty {
                Text("No bottled lots yet. Bottle a mature barrel from the Aging Rack.")
                    .font(.system(size: 13, design: .serif))
                    .foregroundColor(ValleyPalette.olive)
                    .padding(.leading, 4)
            } else {
                ForEach(store.state.bottledLots) { lot in
                    bottleLotRow(lot)
                }
            }
        }
    }

    private func bottleLotRow(_ lot: BottledLot) -> some View {
        let variety = ValleyTables.variety(lot.varietyID)
        let bt = ValleyTables.barrelType(lot.barrelTypeID)
        return Button(action: { activeSheet = .sellLot(lot.id) }) {
            HStack(spacing: 12) {
                BottleIcon(size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(lot.labelName)
                        .font(.system(size: 14, weight: .bold, design: .serif))
                        .foregroundColor(ValleyPalette.inkText)
                    Text("\(variety.name) Y\(lot.vintageYear) · \(bt.name)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(ValleyPalette.olive)
                    HStack(spacing: 6) {
                        Text("\(lot.bottles) bottles")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(ValleyPalette.terracotta)
                        Text("\(lot.monthsAgedInBarrel + lot.monthsAgedInBottle) mo total")
                            .font(.system(size: 10))
                            .foregroundColor(ValleyPalette.olive)
                    }
                    ProfileBars(profile: lot.profile, compact: true).padding(.top, 2)
                }
                Spacer()
            }
            .padding(10)
            .background(ValleyPalette.ivory)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(ValleyPalette.parchmentLine, lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var cooperageGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            ForEach(ValleyTables.barrelTypes) { bt in
                let owned = store.state.ownedBarrelTypes.contains(bt.id)
                Button(action: {
                    if !owned { store.purchaseBarrelType(bt.id) }
                    activeSheet = .barrelTypeDetail(bt.id)
                }) {
                    VStack(spacing: 6) {
                        BarrelIcon(size: 48)
                        Text(bt.name)
                            .font(.system(size: 12, weight: .bold, design: .serif))
                            .foregroundColor(ValleyPalette.inkText)
                            .multilineTextAlignment(.center)
                        if owned {
                            HStack(spacing: 4) {
                                CheckIcon(size: 12)
                                Text("Owned").font(.system(size: 10, weight: .semibold)).foregroundColor(ValleyPalette.olive)
                            }
                        } else {
                            HStack(spacing: 4) {
                                CoinIcon(size: 12)
                                Text("\(bt.purchaseCost)").font(.system(size: 10, weight: .semibold)).foregroundColor(ValleyPalette.terracotta)
                            }
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .background(ValleyPalette.ivory)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(ValleyPalette.parchmentLine, lineWidth: 1))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Press Sheet

struct PressBinSheet: View {
    @EnvironmentObject var store: ValleyStore
    let binID: UUID
    @Binding var activeSheet: ValleyActiveSheet?
    @State private var pressStyle: PressStyle = .balanced
    @State private var barrelType: String = "bt_light_oak"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Press & Begin Aging")
                    .font(.system(size: 20, weight: .black, design: .serif))
                    .foregroundColor(ValleyPalette.burgundy)
                if let bin = store.state.harvestBins.first(where: { $0.id == binID }) {
                    let v = ValleyTables.variety(bin.varietyID)
                    Text("\(v.name) Y\(bin.vintageYear) — \(bin.kilograms) kg")
                        .font(.system(size: 14, weight: .semibold, design: .serif))
                        .foregroundColor(ValleyPalette.terracotta)
                }

                ValleySectionHeader(title: "Press Style")
                ForEach(PressStyle.allCases, id: \.self) { style in
                    Button(action: { pressStyle = style }) {
                        HStack {
                            Text(style.label)
                                .font(.system(size: 14, weight: .bold, design: .serif))
                                .foregroundColor(ValleyPalette.inkText)
                            Spacer()
                            if pressStyle == style { CheckIcon() }
                        }
                        .padding(12)
                        .background(pressStyle == style ? ValleyPalette.creamWarm : ValleyPalette.ivory)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(pressStyle == style ? ValleyPalette.terracotta : ValleyPalette.parchmentLine, lineWidth: 1))
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                ValleySectionHeader(title: "Choose Barrel")
                ForEach(ValleyTables.barrelTypes.filter { store.state.ownedBarrelTypes.contains($0.id) }) { bt in
                    Button(action: { barrelType = bt.id }) {
                        HStack {
                            BarrelIcon(size: 30)
                            Text(bt.name)
                                .font(.system(size: 14, weight: .bold, design: .serif))
                                .foregroundColor(ValleyPalette.inkText)
                            Spacer()
                            if barrelType == bt.id { CheckIcon() }
                        }
                        .padding(12)
                        .background(barrelType == bt.id ? ValleyPalette.creamWarm : ValleyPalette.ivory)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(barrelType == bt.id ? ValleyPalette.terracotta : ValleyPalette.parchmentLine, lineWidth: 1))
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                ValleyPrimaryButton(title: "Press into Barrel") {
                    store.pressBin(binID: binID, style: pressStyle, intoBarrelType: barrelType)
                    activeSheet = nil
                }
                ValleySecondaryButton(title: "Discard Bin (no press)") {
                    store.discardBin(binID); activeSheet = nil
                }
                ValleySecondaryButton(title: "Cancel") { activeSheet = nil }
            }
            .padding(16)
        }
        .background(ValleyPalette.cream)
        .navigationBarTitle("Press", displayMode: .inline)
    }
}

// MARK: - Age Barrel Sheet

struct AgeBarrelSheet: View {
    @EnvironmentObject var store: ValleyStore
    let barrelID: UUID
    @Binding var activeSheet: ValleyActiveSheet?
    @State private var newName: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if let barrel = store.state.barrels.first(where: { $0.id == barrelID }) {
                    let v = ValleyTables.variety(barrel.varietyID)
                    let t = ValleyTables.terroir(barrel.terroirID)
                    let bt = ValleyTables.barrelType(barrel.barrelTypeID)
                    HStack(alignment: .top) {
                        BarrelIcon(size: 72, fillColor: ValleyPalette.terracotta, strokeColor: ValleyPalette.burgundy)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(barrel.name)
                                .font(.system(size: 20, weight: .black, design: .serif))
                                .foregroundColor(ValleyPalette.burgundy)
                            Text("\(v.name) · \(t.name)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(ValleyPalette.olive)
                            Text("\(bt.name) · \(barrel.monthsAged) months · \(barrel.liters) L")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(ValleyPalette.terracotta)
                        }
                    }
                    ValleySectionHeader(title: "Current Profile")
                    ProfileBars(profile: barrel.profile)

                    ValleySectionHeader(title: "Origin")
                    HStack {
                        Text("Press: \(barrel.pressStyle.label)").font(.system(size: 12, design: .serif))
                        Spacer()
                        Text("Pick: \(barrel.harvestTiming.label)").font(.system(size: 12, design: .serif))
                    }.foregroundColor(ValleyPalette.olive)

                    ValleySectionHeader(title: "Rename")
                    TextField("Custom label name", text: $newName)
                        .font(.system(size: 13, design: .serif))
                        .padding(10)
                        .background(ValleyPalette.ivory)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(ValleyPalette.parchmentLine, lineWidth: 1))

                    ValleySecondaryButton(title: "Save Label") {
                        store.renameBarrel(barrelID, to: newName)
                        newName = ""
                    }

                    ValleySectionHeader(title: "Decision")
                    Text("Continue aging quietly, or bottle now to begin selling.")
                        .font(.system(size: 12, design: .serif))
                        .foregroundColor(ValleyPalette.olive)

                    ValleyPrimaryButton(title: "Bottle this Barrel") {
                        activeSheet = .bottleBarrel(barrelID)
                    }
                }
                ValleySecondaryButton(title: "Close") { activeSheet = nil }
            }
            .padding(16)
        }
        .background(ValleyPalette.cream)
        .navigationBarTitle("Barrel", displayMode: .inline)
    }
}

// MARK: - Bottle Sheet

struct BottleBarrelSheet: View {
    @EnvironmentObject var store: ValleyStore
    let barrelID: UUID
    @Binding var activeSheet: ValleyActiveSheet?
    @State private var label: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Bottle this Barrel")
                .font(.system(size: 20, weight: .black, design: .serif))
                .foregroundColor(ValleyPalette.burgundy)
            if let b = store.state.barrels.first(where: { $0.id == barrelID }) {
                Text("\(b.name) — aged \(b.monthsAged) months")
                    .font(.system(size: 14, weight: .semibold, design: .serif))
                    .foregroundColor(ValleyPalette.terracotta)
                ProfileBars(profile: b.profile, compact: true)
                    .padding(.vertical, 4)
            }
            Text("Choose a label name (or leave blank to keep the barrel name).")
                .font(.system(size: 12, design: .serif))
                .foregroundColor(ValleyPalette.olive)
            TextField("Label name", text: $label)
                .font(.system(size: 13, design: .serif))
                .padding(10)
                .background(ValleyPalette.ivory)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(ValleyPalette.parchmentLine, lineWidth: 1))

            ValleyPrimaryButton(title: "Bottle Now") {
                store.bottleBarrel(barrelID, label: label)
                activeSheet = nil
            }
            ValleySecondaryButton(title: "Cancel") { activeSheet = nil }
            Spacer()
        }
        .padding(16)
        .background(ValleyPalette.cream)
        .navigationBarTitle("Bottle", displayMode: .inline)
    }
}

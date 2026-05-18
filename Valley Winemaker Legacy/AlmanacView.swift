import SwiftUI

struct AlmanacView: View {
    @EnvironmentObject var store: ValleyStore
    @Binding var activeSheet: ValleyActiveSheet?
    @State private var section: Int = 0
    // 0 = Varieties, 1 = Terroirs, 2 = Barrels, 3 = Recipes

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                tabBar
                content
            }
            .padding(16)
        }
        .background(ValleyPalette.cream.edgesIgnoringSafeArea(.all))
        .navigationBarTitle("Almanac", displayMode: .inline)
    }

    private var tabBar: some View {
        HStack(spacing: 6) {
            tabPill("Grapes", index: 0)
            tabPill("Terroirs", index: 1)
            tabPill("Barrels", index: 2)
            tabPill("Recipes", index: 3)
        }
    }

    private func tabPill(_ label: String, index: Int) -> some View {
        Button(action: { section = index }) {
            Text(label)
                .font(.system(size: 12, weight: .bold, design: .serif))
                .foregroundColor(section == index ? ValleyPalette.cream : ValleyPalette.burgundy)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(section == index ? ValleyPalette.burgundy : ValleyPalette.ivory)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(ValleyPalette.parchmentLine, lineWidth: 1))
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private var content: some View {
        switch section {
        case 0:
            ForEach(ValleyTables.varieties) { v in
                Button(action: { activeSheet = .varietyDetail(v.id) }) {
                    HStack(spacing: 12) {
                        LeafIcon(size: 30)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(v.name).font(.system(size: 14, weight: .bold, design: .serif))
                                .foregroundColor(ValleyPalette.inkText)
                            Text(v.aromaFamily.label).font(.system(size: 11, weight: .semibold))
                                .foregroundColor(ValleyPalette.olive)
                            Text(v.description).font(.system(size: 11, design: .serif))
                                .foregroundColor(ValleyPalette.inkText.opacity(0.7))
                                .lineLimit(2)
                        }
                        Spacer()
                    }
                    .padding(10)
                    .background(ValleyPalette.ivory)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(ValleyPalette.parchmentLine, lineWidth: 1))
                }
                .buttonStyle(PlainButtonStyle())
            }
        case 1:
            ForEach(ValleyTables.terroirs) { t in
                Button(action: { activeSheet = .terroirDetail(t.id) }) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(t.name)
                            .font(.system(size: 14, weight: .bold, design: .serif))
                            .foregroundColor(ValleyPalette.burgundy)
                        Text(t.blurb)
                            .font(.system(size: 12, design: .serif))
                            .foregroundColor(ValleyPalette.olive)
                        ProfileBars(profile: TasteProfile(body: t.modifier.body + 50, tannin: t.modifier.tannin + 50,
                                                          acidity: t.modifier.acidity + 50, aroma: t.modifier.aroma + 50),
                                    compact: true)
                    }
                    .padding(10)
                    .background(ValleyPalette.ivory)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(ValleyPalette.parchmentLine, lineWidth: 1))
                }
                .buttonStyle(PlainButtonStyle())
            }
        case 2:
            ForEach(ValleyTables.barrelTypes) { bt in
                Button(action: { activeSheet = .barrelTypeDetail(bt.id) }) {
                    HStack {
                        BarrelIcon(size: 36)
                        VStack(alignment: .leading) {
                            Text(bt.name).font(.system(size: 14, weight: .bold, design: .serif))
                                .foregroundColor(ValleyPalette.inkText)
                            Text(bt.blurb).font(.system(size: 11, design: .serif))
                                .foregroundColor(ValleyPalette.olive)
                                .lineLimit(2)
                        }
                        Spacer()
                    }
                    .padding(10)
                    .background(ValleyPalette.ivory)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(ValleyPalette.parchmentLine, lineWidth: 1))
                }
                .buttonStyle(PlainButtonStyle())
            }
        default:
            ForEach(ValleyTables.recipes) { r in
                Button(action: { activeSheet = .recipeDetail(r.id) }) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(r.name)
                                .font(.system(size: 14, weight: .bold, design: .serif))
                                .foregroundColor(ValleyPalette.burgundy)
                            Spacer()
                            if !store.state.unlockedRecipes.contains(r.id) {
                                PadlockIcon(size: 14)
                            } else {
                                CheckIcon(size: 14)
                            }
                        }
                        Text(r.blurb)
                            .font(.system(size: 11, design: .serif))
                            .foregroundColor(ValleyPalette.olive)
                            .lineLimit(2)
                        ProfileBars(profile: r.target, compact: true)
                    }
                    .padding(10)
                    .background(ValleyPalette.ivory)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(ValleyPalette.parchmentLine, lineWidth: 1))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Variety Detail Sheet

struct VarietyDetailSheet: View {
    @EnvironmentObject var store: ValleyStore
    let varietyID: String
    @Binding var activeSheet: ValleyActiveSheet?

    var body: some View {
        let v = ValleyTables.variety(varietyID)
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    LeafIcon(size: 44)
                    VStack(alignment: .leading) {
                        Text(v.name)
                            .font(.system(size: 22, weight: .black, design: .serif))
                            .foregroundColor(ValleyPalette.burgundy)
                        Text(v.aromaFamily.label)
                            .font(.system(size: 12, weight: .semibold)).foregroundColor(ValleyPalette.olive)
                    }
                }
                Text(v.description).font(.system(size: 13, design: .serif)).foregroundColor(ValleyPalette.inkText)
                ValleySectionHeader(title: "Baseline Profile")
                ProfileBars(profile: v.baseline)
                ValleySectionHeader(title: "Vineyard Traits")
                HStack { Text("Yield"); Spacer(); Text("\(v.yield) kg/row") }
                    .font(.system(size: 12, design: .serif)).foregroundColor(ValleyPalette.inkText)
                HStack { Text("Disease Resistance"); Spacer(); Text("\(v.diseaseResistance) / 10") }
                    .font(.system(size: 12, design: .serif)).foregroundColor(ValleyPalette.inkText)
                HStack { Text("Cold Tolerance"); Spacer(); Text("\(v.coldTolerance) / 10") }
                    .font(.system(size: 12, design: .serif)).foregroundColor(ValleyPalette.inkText)
                ValleySecondaryButton(title: "Close") { activeSheet = nil }
            }
            .padding(16)
        }
        .background(ValleyPalette.cream)
        .navigationBarTitle("Variety", displayMode: .inline)
    }
}

// MARK: - Terroir Detail

struct TerroirDetailSheet: View {
    let terroirID: String
    @Binding var activeSheet: ValleyActiveSheet?

    var body: some View {
        let t = ValleyTables.terroir(terroirID)
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(t.name).font(.system(size: 22, weight: .black, design: .serif)).foregroundColor(ValleyPalette.burgundy)
                Text(t.blurb).font(.system(size: 13, design: .serif)).foregroundColor(ValleyPalette.inkText)
                ValleySectionHeader(title: "Profile Modifier")
                ProfileBars(profile: TasteProfile(body: t.modifier.body + 50, tannin: t.modifier.tannin + 50,
                                                  acidity: t.modifier.acidity + 50, aroma: t.modifier.aroma + 50))
                Text("Yield Factor: \(String(format: "%.2f", t.yieldFactor))×")
                    .font(.system(size: 12, design: .serif)).foregroundColor(ValleyPalette.terracotta)
                ValleySecondaryButton(title: "Close") { activeSheet = nil }
            }
            .padding(16)
        }
        .background(ValleyPalette.cream)
        .navigationBarTitle("Terroir", displayMode: .inline)
    }
}

// MARK: - Barrel Type Detail

struct BarrelTypeDetailSheet: View {
    @EnvironmentObject var store: ValleyStore
    let barrelTypeID: String
    @Binding var activeSheet: ValleyActiveSheet?

    var body: some View {
        let bt = ValleyTables.barrelType(barrelTypeID)
        let owned = store.state.ownedBarrelTypes.contains(bt.id)
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    BarrelIcon(size: 48)
                    VStack(alignment: .leading) {
                        Text(bt.name).font(.system(size: 22, weight: .black, design: .serif)).foregroundColor(ValleyPalette.burgundy)
                        if owned {
                            HStack(spacing: 4) { CheckIcon(); Text("Owned").font(.system(size: 12)).foregroundColor(ValleyPalette.olive) }
                        } else {
                            HStack(spacing: 4) { CoinIcon(); Text("\(bt.purchaseCost) coin").font(.system(size: 12, weight: .bold)).foregroundColor(ValleyPalette.terracotta) }
                        }
                    }
                }
                Text(bt.blurb).font(.system(size: 13, design: .serif)).foregroundColor(ValleyPalette.inkText)
                ValleySectionHeader(title: "Per-Month Modifier")
                Text("Body \(String(format: "%+.1f", bt.monthlyModifier.body))  · Tannin \(String(format: "%+.1f", bt.monthlyModifier.tannin))  · Acidity \(String(format: "%+.1f", bt.monthlyModifier.acidity))  · Aroma \(String(format: "%+.1f", bt.monthlyModifier.aroma))")
                    .font(.system(size: 12, design: .serif)).foregroundColor(ValleyPalette.olive)
                if !owned {
                    ValleyPrimaryButton(title: "Purchase (\(bt.purchaseCost) coin)",
                                         disabled: store.state.coins < bt.purchaseCost) {
                        store.purchaseBarrelType(bt.id); activeSheet = nil
                    }
                }
                ValleySecondaryButton(title: "Close") { activeSheet = nil }
            }
            .padding(16)
        }
        .background(ValleyPalette.cream)
        .navigationBarTitle("Barrel Type", displayMode: .inline)
    }
}

// MARK: - Recipe Detail

struct RecipeDetailSheet: View {
    @EnvironmentObject var store: ValleyStore
    let recipeID: String
    @Binding var activeSheet: ValleyActiveSheet?

    var body: some View {
        if let r = ValleyTables.recipe(recipeID) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(r.name).font(.system(size: 22, weight: .black, design: .serif)).foregroundColor(ValleyPalette.burgundy)
                    Text(r.blurb).font(.system(size: 13, design: .serif)).foregroundColor(ValleyPalette.inkText)
                    ValleySectionHeader(title: "Target Profile")
                    ProfileBars(profile: r.target)
                    ValleySectionHeader(title: "Suggested Varieties")
                    ForEach(r.varietyHints, id: \.self) { vid in
                        Text("• \(ValleyTables.variety(vid).name)")
                            .font(.system(size: 12, design: .serif))
                            .foregroundColor(ValleyPalette.olive)
                    }
                    if !store.state.unlockedRecipes.contains(r.id) {
                        ValleySecondaryButton(title: "Mark as Discovered") {
                            var u = store.state.unlockedRecipes
                            u.append(r.id)
                            store.state.unlockedRecipes = u
                            store.evaluateAchievements()
                            store.persist()
                        }
                    } else {
                        HStack { CheckIcon(); Text("Discovered").font(.system(size: 12, design: .serif)).foregroundColor(ValleyPalette.olive) }
                    }
                    ValleySecondaryButton(title: "Close") { activeSheet = nil }
                }
                .padding(16)
            }
            .background(ValleyPalette.cream)
            .navigationBarTitle("Recipe", displayMode: .inline)
        } else {
            Text("Recipe not found")
        }
    }
}

// MARK: - Decision Log Detail

struct DecisionLogDetailSheet: View {
    @EnvironmentObject var store: ValleyStore
    let entryID: UUID
    @Binding var activeSheet: ValleyActiveSheet?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let entry = store.state.decisionLog.first(where: { $0.id == entryID }) {
                Text(entry.title).font(.system(size: 18, weight: .black, design: .serif)).foregroundColor(ValleyPalette.burgundy)
                Text("Year \(entry.year) · " + (Season(rawValue: entry.season)?.label ?? "?"))
                    .font(.system(size: 12, weight: .semibold)).foregroundColor(ValleyPalette.olive)
                Text(entry.detail).font(.system(size: 13, design: .serif)).foregroundColor(ValleyPalette.inkText)
            }
            ValleySecondaryButton(title: "Close") { activeSheet = nil }
            Spacer()
        }
        .padding(16)
        .background(ValleyPalette.cream)
        .navigationBarTitle("Ledger Entry", displayMode: .inline)
    }
}

// MARK: - Event Card Sheet

struct EventCardSheet: View {
    @EnvironmentObject var store: ValleyStore
    let eventID: String
    @Binding var activeSheet: ValleyActiveSheet?

    var body: some View {
        if let evt = ValleyTables.event(eventID) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(evt.name)
                        .font(.system(size: 22, weight: .black, design: .serif))
                        .foregroundColor(ValleyPalette.burgundy)
                    Text(evt.description)
                        .font(.system(size: 14, design: .serif))
                        .foregroundColor(ValleyPalette.inkText)
                    optionCard(evt.optionA, isA: true)
                    optionCard(evt.optionB, isA: false)
                }
                .padding(16)
            }
            .background(ValleyPalette.cream)
            .navigationBarTitle("Decision", displayMode: .inline)
        } else {
            Text("Event missing.")
        }
    }

    private func optionCard(_ option: EventOption, isA: Bool) -> some View {
        Button(action: {
            store.resolveEvent(optionA: isA)
            activeSheet = nil
        }) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(option.label)
                        .font(.system(size: 14, weight: .bold, design: .serif))
                        .foregroundColor(ValleyPalette.cream)
                    Spacer()
                    if option.coinDelta != 0 {
                        Text("\(option.coinDelta) coin")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(ValleyPalette.cream)
                    }
                }
                Text(option.note)
                    .font(.system(size: 11, design: .serif))
                    .foregroundColor(ValleyPalette.cream.opacity(0.85))
            }
            .padding(12)
            .background(LinearGradient(colors: [ValleyPalette.terracotta, ValleyPalette.burgundy],
                                       startPoint: .leading, endPoint: .trailing))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

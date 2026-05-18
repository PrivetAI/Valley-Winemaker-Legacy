import SwiftUI

struct VineyardView: View {
    @EnvironmentObject var store: ValleyStore
    @Binding var activeSheet: ValleyActiveSheet?

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if harvestWindowMissed {
                        harvestMissedBanner
                    }

                    headerCard

                    statusRow

                    if let eid = store.state.pendingEventID,
                       let evt = ValleyTables.event(eid) {
                        eventBanner(event: evt)
                    }

                    ValleySectionHeader(title: "The Valley Today")
                    VineyardCanvas(plots: store.state.plots, screenSize: geo.size)

                    ValleySectionHeader(title: "Plots Under Cultivation")
                    if store.state.plots.isEmpty {
                        emptyState
                    } else {
                        plotsList
                    }

                    ValleySectionHeader(title: "Pending Harvest Bins")
                    if store.state.harvestBins.isEmpty {
                        Text("No fruit awaiting press.")
                            .font(.system(size: 13, design: .serif))
                            .foregroundColor(ValleyPalette.olive)
                            .padding(.leading, 4)
                    } else {
                        ForEach(store.state.harvestBins) { bin in
                            harvestBinRow(bin)
                        }
                    }

                    if let summary = store.lastSeasonSummary {
                        ValleySectionHeader(title: "Last Season Summary")
                        seasonSummaryCard(summary)
                    }

                    ValleySectionHeader(title: "Estate Ledger")
                    if store.state.decisionLog.isEmpty {
                        Text("The ledger is blank — for now.")
                            .font(.system(size: 13, design: .serif))
                            .foregroundColor(ValleyPalette.olive)
                            .padding(.leading, 4)
                    } else {
                        ForEach(store.state.decisionLog.suffix(8).reversed()) { entry in
                            logRow(entry)
                        }
                    }
                }
                .padding(16)
            }
        }
        .background(ValleyPalette.cream.edgesIgnoringSafeArea(.all))
        .navigationBarTitle("Vineyard", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                advanceButton
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { activeSheet = .plantPlot }) {
                    HStack(spacing: 4) {
                        PlusIcon(size: 14, color: ValleyPalette.burgundy)
                        Text("Plant").font(.system(size: 13, weight: .bold, design: .serif))
                            .foregroundColor(ValleyPalette.burgundy)
                    }
                }
            }
        }
    }

    private var advanceButton: some View {
        Button(action: {
            store.advanceSeason()
            if let eid = store.state.pendingEventID {
                activeSheet = .eventCard(eid)
            }
        }) {
            HStack(spacing: 4) {
                Text("Advance")
                    .font(.system(size: 13, weight: .bold, design: .serif))
                CheckIcon(size: 14, color: ValleyPalette.terracotta)
            }
            .foregroundColor(ValleyPalette.terracotta)
        }
        .disabled(store.isCampaignOver)
        .opacity(store.isCampaignOver ? 0.4 : 1.0)
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Vintage \(store.state.currentYear) of 25")
                    .font(.system(size: 22, weight: .black, design: .serif))
                    .foregroundColor(ValleyPalette.burgundy)
                Spacer()
                HStack(spacing: 6) {
                    WeatherIcon(weather: store.state.currentWeather)
                    Text(store.state.currentWeather.label)
                        .font(.system(size: 13, weight: .semibold, design: .serif))
                        .foregroundColor(ValleyPalette.olive)
                }
            }
            Text("Season: \(store.currentSeason.label)")
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundColor(ValleyPalette.terracotta)
            if store.isCampaignOver {
                Text("Your tenure is complete. Visit More → Settings to begin again.")
                    .font(.system(size: 12, weight: .semibold, design: .serif))
                    .foregroundColor(ValleyPalette.burgundy)
            }
        }
        .padding(14)
        .background(LinearGradient(colors: [ValleyPalette.ivory, ValleyPalette.creamWarm],
                                   startPoint: .topLeading, endPoint: .bottomTrailing))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(ValleyPalette.parchmentLine, lineWidth: 1))
        .cornerRadius(10)
    }

    private var statusRow: some View {
        HStack(spacing: 10) {
            StatusPill(icon: AnyView(CoinIcon(size: 18)), title: "Coins", value: "\(store.state.coins)")
            StatusPill(icon: AnyView(MedalIcon(medal: .gold, size: 18)), title: "Prestige", value: "\(store.state.prestigePoints)")
            StatusPill(icon: AnyView(BarrelIcon(size: 18)), title: "Barrels", value: "\(store.state.barrels.count)")
            StatusPill(icon: AnyView(BottleIcon(size: 18)), title: "Lots", value: "\(store.state.bottledLots.count)")
        }
    }

    private func eventBanner(event: GameEvent) -> some View {
        Button(action: { activeSheet = .eventCard(event.id) }) {
            HStack(spacing: 10) {
                XIcon(size: 18, color: ValleyPalette.burgundy)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Decision Required: \(event.name)")
                        .font(.system(size: 14, weight: .bold, design: .serif))
                        .foregroundColor(ValleyPalette.burgundy)
                    Text("Tap to resolve")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(ValleyPalette.olive)
                }
                Spacer()
            }
            .padding(12)
            .background(ValleyPalette.terracotta.opacity(0.15))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(ValleyPalette.terracotta, lineWidth: 1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var plotsList: some View {
        VStack(spacing: 10) {
            ForEach(store.state.plots) { plot in
                VStack(spacing: 8) {
                    PlotCardView(plot: plot)
                    HStack(spacing: 8) {
                        if store.currentSeason.isPrune {
                            ValleySecondaryButton(title: "Prune") {
                                activeSheet = .prunePlot(plot.id)
                            }
                        }
                        if store.currentSeason.isHarvest {
                            ValleyPrimaryButton(title: "Harvest") {
                                activeSheet = .harvestPlot(plot.id)
                            }
                        }
                        if plot.disease > 0.2 {
                            ValleySecondaryButton(title: "Treat (60c)") {
                                store.treatDisease(plotID: plot.id)
                            }
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            LeafIcon(size: 36)
            Text("No plots yet — tap Plant above to begin.")
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundColor(ValleyPalette.olive)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(ValleyPalette.ivory)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(ValleyPalette.parchmentLine, lineWidth: 1))
    }

    private func harvestBinRow(_ bin: HarvestBin) -> some View {
        let variety = ValleyTables.variety(bin.varietyID)
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(variety.name) Y\(bin.vintageYear)")
                    .font(.system(size: 14, weight: .bold, design: .serif))
                    .foregroundColor(ValleyPalette.inkText)
                Text("\(bin.kilograms) kg · \(bin.harvestTiming.label)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(ValleyPalette.olive)
            }
            Spacer()
            ValleyPrimaryButton(title: "Press") {
                activeSheet = .pressBin(bin.id)
            }
            .frame(maxWidth: 90)
        }
        .padding(10)
        .background(ValleyPalette.ivory)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(ValleyPalette.parchmentLine, lineWidth: 1))
    }

    private func logRow(_ entry: DecisionLog) -> some View {
        Button(action: { activeSheet = .eventLogEntry(entry.id) }) {
            HStack(alignment: .top, spacing: 8) {
                Capsule().fill(ValleyPalette.terracotta).frame(width: 3)
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.title)
                        .font(.system(size: 13, weight: .bold, design: .serif))
                        .foregroundColor(ValleyPalette.inkText)
                    Text("Y\(entry.year) · " + (Season(rawValue: entry.season)?.label ?? "?"))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(ValleyPalette.olive)
                    Text(entry.detail)
                        .font(.system(size: 11, design: .serif))
                        .foregroundColor(ValleyPalette.inkText.opacity(0.85))
                }
                Spacer()
            }
            .padding(10)
            .background(ValleyPalette.ivory)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(ValleyPalette.parchmentLine, lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Harvest window closed warning

    private var harvestWindowMissed: Bool {
        // Past mid-fall this year, with plots planted but no fruit pending
        // press. Hides automatically once the next year begins.
        let pastHarvest = store.state.seasonIndex > Season.midFall.rawValue
        let hasPlots = !store.state.plots.isEmpty
        let noPendingFruit = store.state.harvestBins.isEmpty
        return pastHarvest && hasPlots && noPendingFruit && !store.isCampaignOver
    }

    private var harvestMissedBanner: some View {
        HStack(spacing: 10) {
            XIcon(size: 18, color: ValleyPalette.burgundy)
            VStack(alignment: .leading, spacing: 2) {
                Text("Harvest window closed. Year's yield was lost.")
                    .font(.system(size: 13, weight: .bold, design: .serif))
                    .foregroundColor(ValleyPalette.burgundy)
                Text("Harvest only fires during Early Fall and Mid Fall.")
                    .font(.system(size: 11, weight: .medium, design: .serif))
                    .foregroundColor(ValleyPalette.olive)
            }
            Spacer()
        }
        .padding(12)
        .background(ValleyPalette.burgundy.opacity(0.12))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(ValleyPalette.burgundy, lineWidth: 1))
        .cornerRadius(8)
    }

    // MARK: - Season summary card

    private func seasonSummaryCard(_ summary: SeasonSummary) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(summary.headerText)
                .font(.system(size: 14, weight: .bold, design: .serif))
                .foregroundColor(ValleyPalette.burgundy)
            ForEach(summary.lines, id: \.self) { line in
                HStack(alignment: .top, spacing: 6) {
                    Capsule().fill(ValleyPalette.terracotta).frame(width: 3, height: 14)
                    Text(line)
                        .font(.system(size: 12, design: .serif))
                        .foregroundColor(ValleyPalette.inkText)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ValleyPalette.creamWarm)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(ValleyPalette.terracotta.opacity(0.55), lineWidth: 1))
        .cornerRadius(8)
    }
}

// MARK: - Plant Sheet

struct PlantPlotSheet: View {
    @EnvironmentObject var store: ValleyStore
    @Binding var activeSheet: ValleyActiveSheet?
    @State private var varietyID: String = "v_lambruvinia"
    @State private var terroirID: String = "t_clay_bench"
    @State private var rows: Int = 3

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Plant a New Plot")
                    .font(.system(size: 20, weight: .black, design: .serif))
                    .foregroundColor(ValleyPalette.burgundy)
                Text("Match the variety to the terroir for best results. Yields scale with rows.")
                    .font(.system(size: 12, weight: .medium, design: .serif))
                    .foregroundColor(ValleyPalette.olive)

                ValleySectionHeader(title: "Variety")
                ForEach(ValleyTables.varieties) { v in
                    Button(action: { varietyID = v.id }) {
                        HStack {
                            LeafIcon(size: 18)
                            VStack(alignment: .leading) {
                                Text(v.name)
                                    .font(.system(size: 14, weight: .bold, design: .serif))
                                    .foregroundColor(ValleyPalette.inkText)
                                Text(v.aromaFamily.label)
                                    .font(.system(size: 11)).foregroundColor(ValleyPalette.olive)
                            }
                            Spacer()
                            if varietyID == v.id { CheckIcon() }
                        }
                        .padding(10)
                        .background(varietyID == v.id ? ValleyPalette.creamWarm : ValleyPalette.ivory)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(varietyID == v.id ? ValleyPalette.terracotta : ValleyPalette.parchmentLine, lineWidth: 1))
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                ValleySectionHeader(title: "Terroir")
                ForEach(ValleyTables.terroirs) { t in
                    Button(action: { terroirID = t.id }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(t.name)
                                    .font(.system(size: 14, weight: .bold, design: .serif))
                                    .foregroundColor(ValleyPalette.inkText)
                                Text(t.blurb)
                                    .font(.system(size: 11, design: .serif)).foregroundColor(ValleyPalette.olive)
                            }
                            Spacer()
                            if terroirID == t.id { CheckIcon() }
                        }
                        .padding(10)
                        .background(terroirID == t.id ? ValleyPalette.creamWarm : ValleyPalette.ivory)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(terroirID == t.id ? ValleyPalette.terracotta : ValleyPalette.parchmentLine, lineWidth: 1))
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                ValleySectionHeader(title: "Rows")
                HStack(spacing: 12) {
                    Button(action: { if rows > 1 { rows -= 1 } }) {
                        MinusIcon().padding(10).background(ValleyPalette.creamWarm).cornerRadius(8)
                    }.buttonStyle(PlainButtonStyle())
                    Text("\(rows) rows  — cost \(rows * 40) c")
                        .font(.system(size: 14, weight: .bold, design: .serif))
                        .foregroundColor(ValleyPalette.inkText)
                    Button(action: { if rows < 10 { rows += 1 } }) {
                        PlusIcon().padding(10).background(ValleyPalette.creamWarm).cornerRadius(8)
                    }.buttonStyle(PlainButtonStyle())
                }

                ValleyPrimaryButton(title: "Plant (Cost \(rows * 40))",
                                     disabled: store.state.coins < rows * 40) {
                    store.plantPlot(varietyID: varietyID, terroirID: terroirID, rows: rows)
                    activeSheet = nil
                }
                ValleySecondaryButton(title: "Cancel") { activeSheet = nil }
            }
            .padding(16)
        }
        .background(ValleyPalette.cream)
        .navigationBarTitle("Plant", displayMode: .inline)
    }
}

// MARK: - Prune Sheet

struct PrunePlotSheet: View {
    @EnvironmentObject var store: ValleyStore
    let plotID: UUID
    @Binding var activeSheet: ValleyActiveSheet?

    var body: some View {
        let plot = store.state.plots.first(where: { $0.id == plotID })
        VStack(alignment: .leading, spacing: 14) {
            Text("Pruning Decision")
                .font(.system(size: 20, weight: .black, design: .serif))
                .foregroundColor(ValleyPalette.burgundy)
            if let p = plot {
                Text("\(ValleyTables.variety(p.varietyID).name) on \(ValleyTables.terroir(p.terroirID).name)")
                    .font(.system(size: 14, weight: .semibold, design: .serif))
                    .foregroundColor(ValleyPalette.terracotta)
            }
            Text("Light pruning grows more fruit at lower concentration. Heavy pruning concentrates flavor and lifts quality, but yields fall.")
                .font(.system(size: 12, design: .serif))
                .foregroundColor(ValleyPalette.olive)

            VStack(spacing: 8) {
                ForEach(0..<4) { level in
                    Button(action: {
                        store.setPruneLevel(plotID: plotID, level: level)
                        activeSheet = nil
                    }) {
                        HStack {
                            Text(pruneLabel(level))
                                .font(.system(size: 14, weight: .bold, design: .serif))
                                .foregroundColor(ValleyPalette.inkText)
                            Spacer()
                            Text("Cost \(20 * (level + 1))c")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(ValleyPalette.olive)
                        }
                        .padding(12)
                        .background(ValleyPalette.ivory)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(ValleyPalette.parchmentLine, lineWidth: 1))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            ValleySecondaryButton(title: "Cancel") { activeSheet = nil }
            Spacer()
        }
        .padding(16)
        .background(ValleyPalette.cream)
        .navigationBarTitle("Prune", displayMode: .inline)
    }

    private func pruneLabel(_ level: Int) -> String {
        switch level {
        case 0: return "Skip Pruning (Heavy Yield, Loose Flavor)"
        case 1: return "Light Pruning (Balanced)"
        case 2: return "Hard Pruning (Concentrated)"
        default: return "Master Pruning (Vine Sculpting)"
        }
    }
}

// MARK: - Harvest Sheet

struct HarvestPlotSheet: View {
    @EnvironmentObject var store: ValleyStore
    let plotID: UUID
    @Binding var activeSheet: ValleyActiveSheet?

    var body: some View {
        let plot = store.state.plots.first(where: { $0.id == plotID })
        VStack(alignment: .leading, spacing: 14) {
            Text("Choose Harvest Timing")
                .font(.system(size: 20, weight: .black, design: .serif))
                .foregroundColor(ValleyPalette.burgundy)
            if let p = plot {
                Text("\(ValleyTables.variety(p.varietyID).name) on \(ValleyTables.terroir(p.terroirID).name)")
                    .font(.system(size: 14, weight: .semibold, design: .serif))
                    .foregroundColor(ValleyPalette.terracotta)
            }
            Text("Early picks lift acidity and aromatics. Late picks build body and tannin at the cost of acidity.")
                .font(.system(size: 12, design: .serif))
                .foregroundColor(ValleyPalette.olive)

            ForEach(HarvestTiming.allCases, id: \.self) { timing in
                Button(action: {
                    store.harvest(plotID: plotID, timing: timing)
                    activeSheet = nil
                }) {
                    HStack(spacing: 8) {
                        Capsule().fill(ValleyPalette.terracotta).frame(width: 3, height: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(timing.label)
                                .font(.system(size: 14, weight: .bold, design: .serif))
                                .foregroundColor(ValleyPalette.inkText)
                            Text(timingHint(timing))
                                .font(.system(size: 11, design: .serif))
                                .foregroundColor(ValleyPalette.olive)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(ValleyPalette.ivory)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(ValleyPalette.parchmentLine, lineWidth: 1))
                }
                .buttonStyle(PlainButtonStyle())
            }
            ValleySecondaryButton(title: "Cancel") { activeSheet = nil }
            Spacer()
        }
        .padding(16)
        .background(ValleyPalette.cream)
        .navigationBarTitle("Harvest", displayMode: .inline)
    }

    private func timingHint(_ t: HarvestTiming) -> String {
        switch t {
        case .early: return "Bright acidity, racy aromatics, moderate body."
        case .optimal: return "Balanced. Often the safest, most flexible pick."
        case .late: return "Plush body, deep tannin. Risk of overripe character."
        }
    }
}

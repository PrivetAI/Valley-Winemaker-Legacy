import Foundation
import SwiftUI

final class ValleyStore: ObservableObject {
    static let persistenceKey = "vwl.state.v1"
    static let entropyKey = "vwl.entropy"

    @Published var state: ValleyState

    // Transient (not persisted) snapshot of the most recent advanceSeason
    // result. Surfaced in the Vineyard ledger.
    @Published var lastSeasonSummary: SeasonSummary?

    private var saveTimer: Timer?

    private let installEntropy: UInt64

    init() {
        // Load or generate per-install entropy. Stored as UInt64 in UserDefaults
        // so the same device sees a stable but unique random seed series.
        let defaults = UserDefaults.standard
        let token: UInt64
        if defaults.object(forKey: ValleyStore.entropyKey) != nil {
            // UserDefaults stores Int64 (no UInt64 type); bit-pattern round-trip.
            let raw = defaults.object(forKey: ValleyStore.entropyKey) as? NSNumber
            if let n = raw {
                token = UInt64(bitPattern: n.int64Value)
            } else {
                token = UInt64.random(in: UInt64.min...UInt64.max)
                defaults.set(NSNumber(value: Int64(bitPattern: token)), forKey: ValleyStore.entropyKey)
            }
        } else {
            token = UInt64.random(in: UInt64.min...UInt64.max)
            defaults.set(NSNumber(value: Int64(bitPattern: token)), forKey: ValleyStore.entropyKey)
        }
        self.installEntropy = token

        if let data = UserDefaults.standard.data(forKey: ValleyStore.persistenceKey),
           let decoded = try? JSONDecoder().decode(ValleyState.self, from: data) {
            self.state = decoded
        } else {
            self.state = ValleyState.defaults
            // Seed initial plot for newcomers
            self.state.plots = [
                VineyardPlot(varietyID: "v_lambruvinia", terroirID: "t_clay_bench", rows: 4),
                VineyardPlot(varietyID: "v_petrov_blanc", terroirID: "t_limestone", rows: 3)
            ]
            persist()
        }
    }

    func persist() {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: ValleyStore.persistenceKey)
        }
    }

    // MARK: - Time / Seasons

    var currentSeason: Season { Season(rawValue: state.seasonIndex) ?? .earlySpring }

    var seasonsRemaining: Int {
        let totalSeasons = 25 * 12
        let used = (state.currentYear - 1) * 12 + state.seasonIndex
        return max(0, totalSeasons - used)
    }

    var isCampaignOver: Bool {
        state.currentYear > 25
    }

    func advanceSeason() {
        guard !isCampaignOver else { return }
        state.advanceCounter += 1

        // Snapshot for the post-advance summary card.
        let summaryStartYear = state.currentYear
        let summarySeasonIndexBefore = state.seasonIndex
        let preDiseaseByPlot: [UUID: Double] = Dictionary(uniqueKeysWithValues:
            state.plots.map { ($0.id, $0.disease) })
        let preBarrelCount = state.barrels.count
        let preTastingCount = state.tastingResults.count
        let preCoins = state.coins
        let preEventID = state.pendingEventID

        // 1. Roll seeded weather for this season.
        // Seed blends year/season with per-install entropy and an advance counter
        // so two installs see different sequences but a given save stays
        // deterministic.
        let mainSeed: UInt64 = UInt64(state.currentYear) &* 100
            &+ UInt64(state.seasonIndex)
            &+ installEntropy
            &+ UInt64(state.advanceCounter)
        var rng = SeededRNG(seed: mainSeed)
        let weatherStates = Weather.allCases
        let pick = rng.intInRange(0...(weatherStates.count - 1))
        state.currentWeather = weatherStates[pick]
        state.weatherHistory.append(state.currentWeather)
        if state.weatherHistory.count > 240 {
            state.weatherHistory.removeFirst(state.weatherHistory.count - 240)
        }

        // 2. Age barrels.
        let monthShift = state.currentWeather.profileShift * 0.05
        for i in state.barrels.indices {
            state.barrels[i].monthsAged += 1
            let bt = ValleyTables.barrelType(state.barrels[i].barrelTypeID)
            var p = state.barrels[i].profile
            p = p + bt.monthlyModifier
            p = p + monthShift
            state.barrels[i].profile = p.clamped()
        }

        // 3. Bottle aging.
        for i in state.bottledLots.indices {
            state.bottledLots[i].monthsAgedInBottle += 1
        }

        // 4. Disease progression / mildew spread.
        let weather = state.currentWeather
        let pressureBoost: Double
        switch weather {
        case .wet, .heatwave: pressureBoost = 0.04
        case .mild, .hot, .drought: pressureBoost = 0.01
        case .cold, .frost, .hail: pressureBoost = 0.02
        }
        var nextPlots = state.plots
        for i in nextPlots.indices {
            let variety = ValleyTables.variety(nextPlots[i].varietyID)
            let resist = Double(variety.diseaseResistance) / 10.0
            let raw = nextPlots[i].disease + pressureBoost * (1.0 - resist)
            nextPlots[i].disease = min(1.0, max(0.0, raw))
        }
        // Neighbor spread.
        for i in nextPlots.indices {
            if nextPlots[i].disease > 0.5 {
                let neighborA = i - 1
                let neighborB = i + 1
                if neighborA >= 0 {
                    nextPlots[neighborA].disease = min(1.0, nextPlots[neighborA].disease + 0.04)
                }
                if neighborB < nextPlots.count {
                    nextPlots[neighborB].disease = min(1.0, nextPlots[neighborB].disease + 0.04)
                }
            }
        }
        state.plots = nextPlots

        // 5. Roll events 0..2.
        let eventRoll = rng.double01()
        if eventRoll < 0.5 && state.pendingEventID == nil {
            // Prefer events the player has not yet resolved so the pool rotates,
            // but fall back to the full table once most events are exhausted.
            let unresolved = ValleyTables.events.filter { !state.resolvedEventIDs.contains($0.id) }
            let pool = unresolved.count >= 3 ? unresolved : ValleyTables.events
            let evt = rng.choice(pool)
            state.pendingEventID = evt.id
            state.decisionLog.append(DecisionLog(
                year: state.currentYear, season: state.seasonIndex,
                title: "Event: \(evt.name)", detail: evt.description))
        }

        // 6. Generate market orders during selling window.
        // Use an independent RNG so market buyer rotation does not consume
        // entropy from the weather/event rolls (and vice versa).
        if currentSeason.isSellingWindow {
            var marketRng = SeededRNG(seed: mainSeed &+ 9007)
            generateMarketOrders(rng: &marketRng)
        }

        // 7. Annual tasting at lateWinter.
        if currentSeason.isTasting {
            performAnnualTastings()
        }

        // 8. Auto-harvest hint logs.
        if currentSeason.isHarvest {
            state.decisionLog.append(DecisionLog(
                year: state.currentYear, season: state.seasonIndex,
                title: "Harvest Window", detail: "Pickers ready; tap any plot to harvest."))
        }
        if currentSeason.isPrune {
            state.decisionLog.append(DecisionLog(
                year: state.currentYear, season: state.seasonIndex,
                title: "Pruning Window", detail: "Set pruning intensity per plot."))
        }

        // 9. Tick time forward.
        state.seasonIndex += 1
        if state.seasonIndex >= 12 {
            state.seasonIndex = 0
            state.currentYear += 1
            state.pendingOrders.removeAll(where: { $0.expiresOnYear < state.currentYear })
            // Decrement yield-shock timer once per year; restore multiplier when it expires.
            if state.yieldShockTimer > 0 {
                state.yieldShockTimer -= 1
                if state.yieldShockTimer <= 0 {
                    state.yieldShockTimer = 0
                    state.yieldShockMultiplier = 1.0
                }
            }
        }

        // 10. Expire old orders.
        let curY = state.currentYear
        let curS = state.seasonIndex
        state.pendingOrders.removeAll(where: {
            $0.expiresOnYear < curY ||
            ($0.expiresOnYear == curY && $0.expiresOnSeason < curS)
        })

        // 11. Update prestige.
        updatePrestige()

        // 12. Check achievements.
        evaluateAchievements()

        // 13. Build the post-advance season summary card.
        let summarySeasonName = Season(rawValue: summarySeasonIndexBefore)?.label ?? "Season"
        var summaryLines: [String] = []
        summaryLines.append("Weather: \(state.currentWeather.label)")
        if preBarrelCount > 0 {
            summaryLines.append("Aging: +1 month on \(preBarrelCount) barrel\(preBarrelCount == 1 ? "" : "s")")
        }
        var plotsWorsened = 0
        for plot in state.plots {
            let prior = preDiseaseByPlot[plot.id] ?? 0
            if plot.disease > prior + 0.001 { plotsWorsened += 1 }
        }
        if plotsWorsened > 0 {
            summaryLines.append("Plots: +mildew pressure on \(plotsWorsened) plot\(plotsWorsened == 1 ? "" : "s")")
        }
        if state.tastingResults.count > preTastingCount {
            let newResults = state.tastingResults.count - preTastingCount
            summaryLines.append("Annual tasting: \(newResults) result\(newResults == 1 ? "" : "s") recorded")
        }
        let coinDelta = state.coins - preCoins
        if coinDelta != 0 {
            summaryLines.append("Treasury: \(coinDelta > 0 ? "+" : "")\(coinDelta) coin")
        }
        if let eid = state.pendingEventID, eid != preEventID, let evt = ValleyTables.event(eid) {
            summaryLines.append("Event arrived: \(evt.name)")
        }
        // Keep card compact: cap at 4 lines.
        if summaryLines.count > 4 {
            summaryLines = Array(summaryLines.prefix(4))
        }
        lastSeasonSummary = SeasonSummary(
            headerText: "Season \(summarySeasonName) Y\(summaryStartYear)",
            lines: summaryLines)

        persist()
    }

    // MARK: - Market

    private func generateMarketOrders(rng: inout SeededRNG) {
        let desired = 4 + rng.intInRange(0...3)
        var generated = 0
        while generated < desired && state.pendingOrders.count < 16 {
            let buyer = rng.choice(ValleyTables.buyers)
            let bottles = rng.intInRange(2...10)
            let quality = 35.0 + Double(rng.intInRange(0...30))
            let exp = state.currentYear + (rng.intInRange(0...1))
            let expSeason = (state.seasonIndex + rng.intInRange(1...3)) % 12
            let order = MarketOrder(buyerID: buyer.id, bottlesWanted: bottles,
                                    minQuality: quality, expiresOnYear: exp, expiresOnSeason: expSeason)
            state.pendingOrders.append(order)
            generated += 1
        }
    }

    func bestMatchScore(order: MarketOrder, lot: BottledLot) -> Double {
        let buyer = ValleyTables.buyer(order.buyerID)
        let ageMonths = lot.monthsAgedInBarrel + lot.monthsAgedInBottle
        guard ageMonths >= buyer.minAgeMonths && ageMonths <= buyer.maxAgeMonths else { return 0 }
        let dist = buyer.preference.distance(to: lot.profile)
        let match = max(0, 100.0 - dist)
        return match
    }

    func fulfillOrder(orderID: UUID, lotID: UUID) {
        guard let oIdx = state.pendingOrders.firstIndex(where: { $0.id == orderID }) else { return }
        guard let lIdx = state.bottledLots.firstIndex(where: { $0.id == lotID }) else { return }
        let order = state.pendingOrders[oIdx]
        let lot = state.bottledLots[lIdx]
        let match = bestMatchScore(order: order, lot: lot)
        // Reject sales where buyer requirements (age window etc.) are not met.
        guard match > 0 else { return }
        let buyer = ValleyTables.buyer(order.buyerID)
        let bottlesToSell = min(order.bottlesWanted, lot.bottles)
        guard bottlesToSell > 0 else { return }
        // payment per bottle
        let basePrice = Double(buyer.basePrice)
        let matchFactor = 0.5 + (match / 200.0)  // 0.5..1.0
        let qualityFactor = (match >= order.minQuality) ? 1.0 : 0.6
        let estatePresetBonus = state.nextPaymentBonus
        let shockFactor = state.yieldShockMultiplier
        let total = Int(basePrice * matchFactor * qualityFactor * Double(bottlesToSell) * estatePresetBonus * shockFactor)

        state.bottledLots[lIdx].bottles -= bottlesToSell
        if state.bottledLots[lIdx].bottles <= 0 {
            state.bottledLots.remove(at: lIdx)
        }
        // partial completion logic
        if bottlesToSell >= order.bottlesWanted {
            state.pendingOrders.remove(at: oIdx)
            state.completedOrders += 1
            state.completedBuyerIDs.insert(order.buyerID)
        } else {
            state.pendingOrders[oIdx].bottlesWanted -= bottlesToSell
        }
        state.coins += total
        state.lifetimeRevenue += total
        state.decisionLog.append(DecisionLog(
            year: state.currentYear, season: state.seasonIndex,
            title: "Sold to \(buyer.name)",
            detail: "Lot \(lot.labelName), \(bottlesToSell) bottles for \(total) coin."))
        evaluateAchievements()
        persist()
    }

    // MARK: - Plant

    func plantPlot(varietyID: String, terroirID: String, rows: Int) {
        let cost = max(80, rows * 40)
        guard state.coins >= cost else { return }
        state.coins -= cost
        state.plots.append(VineyardPlot(varietyID: varietyID, terroirID: terroirID, rows: rows, planted: state.currentYear))
        state.decisionLog.append(DecisionLog(
            year: state.currentYear, season: state.seasonIndex,
            title: "Planted \(ValleyTables.variety(varietyID).name)",
            detail: "On \(ValleyTables.terroir(terroirID).name), \(rows) rows."))
        evaluateAchievements()
        persist()
    }

    func uprootPlot(_ plotID: UUID) {
        state.plots.removeAll(where: { $0.id == plotID })
        persist()
    }

    // MARK: - Prune

    func setPruneLevel(plotID: UUID, level: Int) {
        guard let idx = state.plots.firstIndex(where: { $0.id == plotID }) else { return }
        state.plots[idx].pruneLevel = max(0, min(3, level))
        let cost = 20 * (level + 1)
        if state.coins >= cost {
            state.coins -= cost
        }
        state.decisionLog.append(DecisionLog(
            year: state.currentYear, season: state.seasonIndex,
            title: "Pruned plot",
            detail: "Set pruning level to \(level) on \(ValleyTables.variety(state.plots[idx].varietyID).name)."))
        persist()
    }

    func treatDisease(plotID: UUID) {
        guard let idx = state.plots.firstIndex(where: { $0.id == plotID }) else { return }
        guard state.coins >= 60 else { return }
        state.coins -= 60
        state.plots[idx].disease = max(0, state.plots[idx].disease - 0.5)
        state.decisionLog.append(DecisionLog(
            year: state.currentYear, season: state.seasonIndex,
            title: "Treated disease",
            detail: "Sprayed copper on \(ValleyTables.variety(state.plots[idx].varietyID).name) rows."))
        persist()
    }

    // MARK: - Harvest

    func harvest(plotID: UUID, timing: HarvestTiming) {
        guard let idx = state.plots.firstIndex(where: { $0.id == plotID }) else { return }
        let plot = state.plots[idx]
        let variety = ValleyTables.variety(plot.varietyID)
        let terroir = ValleyTables.terroir(plot.terroirID)
        let weather = state.currentWeather

        // Yield: rows * baseYield * terroir * weather * (1-disease) * prune
        let pruneFactor: Double
        switch plot.pruneLevel {
        case 0: pruneFactor = 1.2
        case 1: pruneFactor = 1.0
        case 2: pruneFactor = 0.8
        default: pruneFactor = 0.6
        }
        let baseYield = Double(variety.yield) * Double(plot.rows)
        let kilograms = Int(baseYield * terroir.yieldFactor * weather.yieldMultiplier * pruneFactor * (1.0 - plot.disease * 0.7))

        guard kilograms > 0 else {
            state.decisionLog.append(DecisionLog(
                year: state.currentYear, season: state.seasonIndex,
                title: "Failed harvest",
                detail: "\(variety.name) plot yielded nothing this year."))
            persist()
            return
        }

        // Quality shift from pruning: heavy pruning concentrates flavor
        let pruneProfileShift: TasteProfile
        switch plot.pruneLevel {
        case 0: pruneProfileShift = TasteProfile(body: -4, tannin: -3, acidity: 2, aroma: -2)
        case 1: pruneProfileShift = TasteProfile.zero
        case 2: pruneProfileShift = TasteProfile(body: 3, tannin: 3, acidity: 0, aroma: 4)
        default: pruneProfileShift = TasteProfile(body: 6, tannin: 5, acidity: -1, aroma: 8)
        }

        let weatherShift = weather.profileShift + pruneProfileShift

        let bin = HarvestBin(
            varietyID: plot.varietyID,
            terroirID: plot.terroirID,
            vintageYear: state.currentYear,
            harvestTiming: timing,
            kilograms: kilograms,
            weatherShift: weatherShift)
        state.harvestBins.append(bin)

        state.decisionLog.append(DecisionLog(
            year: state.currentYear, season: state.seasonIndex,
            title: "Harvested \(variety.name)",
            detail: "\(timing.label) yielded \(kilograms) kg under \(weather.label) weather."))
        evaluateAchievements()
        persist()
    }

    // MARK: - Press

    func pressBin(binID: UUID, style: PressStyle, intoBarrelType: String) {
        guard let idx = state.harvestBins.firstIndex(where: { $0.id == binID }) else { return }
        let bin = state.harvestBins[idx]
        guard state.ownedBarrelTypes.contains(intoBarrelType) else { return }
        let variety = ValleyTables.variety(bin.varietyID)
        let terroir = ValleyTables.terroir(bin.terroirID)

        var profile = variety.baseline
        profile = profile + terroir.modifier
        profile = profile + bin.weatherShift
        profile = profile + style.modifier
        profile = profile + bin.harvestTiming.modifier
        profile = profile.clamped()

        // Liters: roughly kg * 0.7
        let liters = max(10, Int(Double(bin.kilograms) * 0.7))

        let barrelName = "\(variety.name) Y\(bin.vintageYear)"

        let barrel = Barrel(
            name: barrelName,
            barrelTypeID: intoBarrelType,
            varietyID: bin.varietyID,
            terroirID: bin.terroirID,
            vintageYear: bin.vintageYear,
            pressStyle: style,
            harvestTiming: bin.harvestTiming,
            monthsAged: 0,
            liters: liters,
            profile: profile,
            label: nil)

        state.barrels.append(barrel)
        state.harvestBins.remove(at: idx)

        state.decisionLog.append(DecisionLog(
            year: state.currentYear, season: state.seasonIndex,
            title: "Pressed & barrelled",
            detail: "\(style.label) of \(variety.name) into \(ValleyTables.barrelType(intoBarrelType).name)."))
        evaluateAchievements()
        persist()
    }

    func discardBin(_ binID: UUID) {
        state.harvestBins.removeAll(where: { $0.id == binID })
        persist()
    }

    // MARK: - Age / Bottle

    func renameBarrel(_ barrelID: UUID, to newName: String) {
        guard let idx = state.barrels.firstIndex(where: { $0.id == barrelID }) else { return }
        state.barrels[idx].name = newName.isEmpty ? state.barrels[idx].name : newName
        persist()
    }

    func bottleBarrel(_ barrelID: UUID, label: String) {
        guard let idx = state.barrels.firstIndex(where: { $0.id == barrelID }) else { return }
        let barrel = state.barrels[idx]
        // Use 0.75L bottles => roughly liters / 0.75
        // /4 = casks-to-cases scaling; one cask yields four cases for market;
        // intentional for game pacing so a single barrel does not flood the
        // buyer roster (orders top out around 10 bottles each).
        let realBottles = max(1, Int(Double(barrel.liters) / 0.75 / 4))
        let lot = BottledLot(
            labelName: label.isEmpty ? barrel.name : label,
            varietyID: barrel.varietyID,
            terroirID: barrel.terroirID,
            barrelTypeID: barrel.barrelTypeID,
            vintageYear: barrel.vintageYear,
            monthsAgedInBarrel: barrel.monthsAged,
            monthsAgedInBottle: 0,
            bottles: realBottles,
            profile: barrel.profile,
            bottledOnYear: state.currentYear)
        state.bottledLots.append(lot)
        state.barrels.remove(at: idx)
        state.decisionLog.append(DecisionLog(
            year: state.currentYear, season: state.seasonIndex,
            title: "Bottled lot",
            detail: "Released \(realBottles) bottles of \(lot.labelName) (barrel age \(barrel.monthsAged) mo).")
        )
        evaluateAchievements()
        persist()
    }

    // MARK: - Blending Recipe discovery

    func evaluateRecipeMatch(_ profile: TasteProfile) -> BlendingRecipe? {
        for recipe in ValleyTables.recipes {
            if recipe.target.distance(to: profile) < 12 {
                return recipe
            }
        }
        return nil
    }

    // MARK: - Events

    func resolveEvent(optionA: Bool) {
        guard let eid = state.pendingEventID,
              let evt = ValleyTables.event(eid) else { return }
        let opt = optionA ? evt.optionA : evt.optionB
        state.coins += opt.coinDelta
        state.prestigePoints += opt.prestigeDelta
        for i in state.plots.indices {
            let new = state.plots[i].disease + opt.cellarDiseaseDelta
            state.plots[i].disease = max(0.0, min(1.0, new))
        }
        if opt.yieldShockYears > 0 {
            state.yieldShockMultiplier = opt.yieldShockFactor
            state.yieldShockTimer = opt.yieldShockYears
        }
        if let resolved = state.pendingEventID {
            state.resolvedEventIDs.insert(resolved)
        }
        state.pendingEventID = nil
        state.decisionLog.append(DecisionLog(
            year: state.currentYear, season: state.seasonIndex,
            title: "Resolved: \(evt.name)",
            detail: "Chose \"\(opt.label)\". \(opt.note)"))
        evaluateAchievements()
        persist()
    }

    // MARK: - Upgrades

    func purchaseUpgrade(_ upgradeID: String) {
        guard let up = ValleyTables.upgrade(upgradeID) else { return }
        guard !state.ownedUpgrades.contains(upgradeID) else { return }
        guard state.coins >= up.cost else { return }
        state.coins -= up.cost
        state.ownedUpgrades.append(upgradeID)
        state.decisionLog.append(DecisionLog(
            year: state.currentYear, season: state.seasonIndex,
            title: "Acquired Upgrade",
            detail: up.name))
        evaluateAchievements()
        persist()
    }

    func purchaseBarrelType(_ id: String) {
        guard let bt = ValleyTables.barrelTypes.first(where: { $0.id == id }) else { return }
        guard !state.ownedBarrelTypes.contains(id) else { return }
        guard state.coins >= bt.purchaseCost else { return }
        state.coins -= bt.purchaseCost
        state.ownedBarrelTypes.append(id)
        state.decisionLog.append(DecisionLog(
            year: state.currentYear, season: state.seasonIndex,
            title: "Cooperage Acquisition",
            detail: "Unlocked \(bt.name) barrels."))
        evaluateAchievements()
        persist()
    }

    // MARK: - Tastings

    func performAnnualTastings() {
        guard !state.bottledLots.isEmpty else { return }
        // For each tasting, score every available bottled lot against THAT
        // tasting's judge panel, pick the highest-scoring lot for that tasting,
        // and record its medal. Different tastings may select different lots.
        for tasting in ValleyTables.tastings {
            // Score every lot against this specific tasting's judges.
            let scored: [(lot: BottledLot, score: Double)] = state.bottledLots.map { lot in
                (lot, avgMatch(lot: lot, judges: tasting.judges))
            }
            guard let best = scored.max(by: { $0.score < $1.score }) else { continue }
            let bestLot = best.lot
            let score = best.score
            let medal: Medal
            switch score {
            case 85...: medal = .gold
            case 72..<85: medal = .silver
            case 60..<72: medal = .bronze
            default: medal = .none
            }
            switch medal {
            case .gold: state.medalsGold += 1
            case .silver: state.medalsSilver += 1
            case .bronze: state.medalsBronze += 1
            case .none: break
            }
            let result = TastingResult(year: state.currentYear, eventID: tasting.id,
                                        entryLabel: bestLot.labelName, score: score, medal: medal)
            state.tastingResults.append(result)
        }
        state.decisionLog.append(DecisionLog(
            year: state.currentYear, season: state.seasonIndex,
            title: "Annual Tasting Circuit",
            detail: "Eight tastings completed; see Tasting log."))
    }

    private func avgMatch(lot: BottledLot, judges: [TastingJudge]) -> Double {
        let scores = judges.map { judge -> Double in
            let dist = judge.preference.distance(to: lot.profile)
            return max(0, 100 - dist)
        }
        return scores.reduce(0, +) / Double(judges.count)
    }

    // MARK: - Prestige

    func updatePrestige() {
        let total = state.medalsGold * 3 + state.medalsSilver * 2 + state.medalsBronze
        state.prestigePoints = total
    }

    var currentTier: PrestigeTier {
        ValleyTables.prestigeTier(forMedals: state.prestigePoints, revenue: state.lifetimeRevenue)
    }

    // MARK: - Achievements

    func evaluateAchievements() {
        var unlocks = Set(state.unlockedAchievements)

        func unlock(_ id: String) { unlocks.insert(id) }

        if !state.harvestBins.isEmpty || !state.barrels.isEmpty || !state.bottledLots.isEmpty {
            unlock("a_first_harvest")
        }
        if !state.barrels.isEmpty || !state.bottledLots.isEmpty {
            unlock("a_first_press")
            unlock("a_first_barrel")
        }
        if !state.bottledLots.isEmpty {
            unlock("a_first_bottle")
        }
        if state.completedOrders >= 1 { unlock("a_first_sale") }
        if state.completedOrders >= 100 { unlock("a_hundred_buyers") }

        // Variety / terroir / barrel diversity (count via planted/used)
        let plantedVarieties = Set(state.plots.map { $0.varietyID })
        if plantedVarieties.count >= 12 { unlock("a_all_varieties") }
        if Set(state.plots.map { $0.terroirID }).count >= 5 { unlock("a_all_terroirs") }
        let usedBarrels = Set(state.barrels.map { $0.barrelTypeID }).union(Set(state.bottledLots.map { $0.barrelTypeID }))
        if usedBarrels.count >= 8 { unlock("a_all_barrels") }

        if state.medalsBronze >= 1 { unlock("a_medal_bronze") }
        if state.medalsSilver >= 1 { unlock("a_medal_silver") }
        if state.medalsGold >= 1 { unlock("a_medal_gold") }

        if state.coins >= 5000 { unlock("a_estate_rich") }
        if state.ownedUpgrades.count >= 10 { unlock("a_ten_upgrades") }
        if state.bottledLots.count >= 20 { unlock("a_twenty_lots") }
        if state.barrels.count >= 10 { unlock("a_full_cellar") }

        // 10-year barrel
        if state.barrels.contains(where: { $0.monthsAged >= 120 }) {
            unlock("a_ten_year_age")
        }

        if state.currentYear >= 25 { unlock("a_quarter_century") }

        let tier = currentTier
        if tier.id == "pt_master" || tier.id == "pt_estate_lord" || tier.id == "pt_region_reference" || tier.id == "pt_national_brand" || tier.id == "pt_legendary" {
            unlock("a_master_tier")
        }
        if tier.id == "pt_legendary" { unlock("a_legendary_tier") }

        // Perfect tasting score >= 95
        if state.tastingResults.contains(where: { $0.score >= 95 }) { unlock("a_grand_cru") }

        if state.unlockedRecipes.count >= 10 { unlock("a_recipe_explorer") }
        if state.unlockedRecipes.count >= 1 { unlock("a_signature") }

        if Set(state.plots.map { $0.varietyID }).count >= 6 { unlock("a_diversified") }

        // Survived events (fire, mildew) — keyed off resolvedEventIDs.
        if state.resolvedEventIDs.contains("e_wildfire") { unlock("a_survive_fire") }
        if state.resolvedEventIDs.contains("e_mildew") { unlock("a_survive_mildew") }

        // Buyer-completion achievements — keyed off completedBuyerIDs.
        if state.completedBuyerIDs.contains("b_royal_somm") { unlock("a_royal_seal") }
        if state.completedBuyerIDs.contains("b_wine_critic") { unlock("a_critic_praise") }
        if state.completedBuyerIDs.contains("b_summer_court") { unlock("a_summer_court") }
        if state.completedBuyerIDs.contains("b_winter_court") { unlock("a_winter_court") }

        state.unlockedAchievements = Array(unlocks)
    }

    // MARK: - Reset

    func resetCampaign() {
        // Clear per-install entropy alongside the save so a brand-new campaign
        // gets a fresh seeded sequence. A new entropy token is generated on the
        // next ValleyStore init.
        UserDefaults.standard.removeObject(forKey: ValleyStore.entropyKey)
        state = ValleyState.defaults
        state.plots = [
            VineyardPlot(varietyID: "v_lambruvinia", terroirID: "t_clay_bench", rows: 4),
            VineyardPlot(varietyID: "v_petrov_blanc", terroirID: "t_limestone", rows: 3)
        ]
        persist()
    }
}

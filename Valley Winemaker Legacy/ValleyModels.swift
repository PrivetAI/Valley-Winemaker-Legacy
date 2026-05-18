import Foundation

// MARK: - Taste Profile

struct TasteProfile: Codable, Hashable {
    var body: Double      // 0..100
    var tannin: Double    // 0..100
    var acidity: Double   // 0..100
    var aroma: Double     // 0..100

    static let zero = TasteProfile(body: 0, tannin: 0, acidity: 0, aroma: 0)

    func clamped() -> TasteProfile {
        TasteProfile(
            body: max(0, min(100, body)),
            tannin: max(0, min(100, tannin)),
            acidity: max(0, min(100, acidity)),
            aroma: max(0, min(100, aroma))
        )
    }

    static func + (lhs: TasteProfile, rhs: TasteProfile) -> TasteProfile {
        TasteProfile(body: lhs.body + rhs.body, tannin: lhs.tannin + rhs.tannin,
                     acidity: lhs.acidity + rhs.acidity, aroma: lhs.aroma + rhs.aroma)
    }
    static func * (lhs: TasteProfile, k: Double) -> TasteProfile {
        TasteProfile(body: lhs.body * k, tannin: lhs.tannin * k,
                     acidity: lhs.acidity * k, aroma: lhs.aroma * k)
    }

    func distance(to other: TasteProfile) -> Double {
        let db = body - other.body
        let dt = tannin - other.tannin
        let da = acidity - other.acidity
        let dr = aroma - other.aroma
        return sqrt(db*db + dt*dt + da*da + dr*dr)
    }
}

// MARK: - Grape Varieties

enum AromaFamily: String, Codable, CaseIterable {
    case redFruit, blackFruit, citrus, stone, floral, herbal, spice, earth

    var label: String {
        switch self {
        case .redFruit: return "Red Fruit"
        case .blackFruit: return "Black Fruit"
        case .citrus: return "Citrus"
        case .stone: return "Stone Fruit"
        case .floral: return "Floral"
        case .herbal: return "Herbal"
        case .spice: return "Spice"
        case .earth: return "Earthy"
        }
    }
}

struct GrapeVariety: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let baseline: TasteProfile
    let aromaFamily: AromaFamily
    let yield: Int           // baseline kg per plot per harvest
    let diseaseResistance: Int  // 0..10
    let coldTolerance: Int   // 0..10
    let description: String
}

// MARK: - Terroir Region

struct Terroir: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let modifier: TasteProfile
    let yieldFactor: Double
    let blurb: String
}

// MARK: - Barrel Types

struct BarrelType: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let monthlyModifier: TasteProfile  // per month of aging
    let purchaseCost: Int
    let blurb: String
}

// MARK: - Weather

enum Weather: String, Codable, CaseIterable {
    case mild, hot, cold, wet, drought, hail, frost, heatwave

    var label: String {
        switch self {
        case .mild: return "Mild"
        case .hot: return "Hot"
        case .cold: return "Cold"
        case .wet: return "Wet"
        case .drought: return "Drought"
        case .hail: return "Hail"
        case .frost: return "Frost"
        case .heatwave: return "Heatwave"
        }
    }

    var yieldMultiplier: Double {
        switch self {
        case .mild: return 1.0
        case .hot: return 0.95
        case .cold: return 0.85
        case .wet: return 0.9
        case .drought: return 0.7
        case .hail: return 0.55
        case .frost: return 0.65
        case .heatwave: return 0.78
        }
    }

    var profileShift: TasteProfile {
        switch self {
        case .mild: return TasteProfile.zero
        case .hot: return TasteProfile(body: 6, tannin: 3, acidity: -6, aroma: -2)
        case .cold: return TasteProfile(body: -4, tannin: -1, acidity: 6, aroma: 2)
        case .wet: return TasteProfile(body: -3, tannin: -2, acidity: 4, aroma: -1)
        case .drought: return TasteProfile(body: 8, tannin: 5, acidity: -3, aroma: 1)
        case .hail: return TasteProfile(body: -5, tannin: -4, acidity: 0, aroma: -4)
        case .frost: return TasteProfile(body: -5, tannin: -3, acidity: 7, aroma: 1)
        case .heatwave: return TasteProfile(body: 10, tannin: 6, acidity: -10, aroma: -3)
        }
    }
}

// MARK: - Seasons

enum Season: Int, Codable, CaseIterable {
    case earlySpring, lateSpring, earlySummer, midSummer
    case lateSummer, earlyFall, midFall, lateFall
    case earlyWinter, midWinter, lateWinter, preSpring

    var label: String {
        switch self {
        case .earlySpring: return "Early Spring"
        case .lateSpring: return "Late Spring"
        case .earlySummer: return "Early Summer"
        case .midSummer: return "Mid Summer"
        case .lateSummer: return "Late Summer"
        case .earlyFall: return "Early Fall"
        case .midFall: return "Mid Fall"
        case .lateFall: return "Late Fall"
        case .earlyWinter: return "Early Winter"
        case .midWinter: return "Mid Winter"
        case .lateWinter: return "Late Winter"
        case .preSpring: return "Pre-Spring"
        }
    }

    var monthsAged: Int { 1 }

    var isHarvest: Bool { self == .midFall || self == .earlyFall }
    var isPrune: Bool { self == .earlySpring }
    var isSellingWindow: Bool {
        switch self {
        case .lateFall, .earlyWinter, .midWinter: return true
        default: return false
        }
    }
    var isTasting: Bool { self == .lateWinter }
}

// MARK: - Plots / Vineyard

struct VineyardPlot: Identifiable, Codable, Hashable {
    let id: UUID
    var varietyID: String
    var terroirID: String
    var rows: Int
    var disease: Double  // 0..1
    var pruneLevel: Int  // 0..3
    var planted: Int

    init(id: UUID = UUID(), varietyID: String, terroirID: String, rows: Int,
         disease: Double = 0, pruneLevel: Int = 1, planted: Int = 1) {
        self.id = id
        self.varietyID = varietyID
        self.terroirID = terroirID
        self.rows = rows
        self.disease = disease
        self.pruneLevel = pruneLevel
        self.planted = planted
    }
}

// MARK: - Press / Juice

enum PressStyle: String, Codable, CaseIterable {
    case light, balanced, hard

    var label: String {
        switch self {
        case .light: return "Light Press"
        case .balanced: return "Balanced Press"
        case .hard: return "Hard Press"
        }
    }

    var modifier: TasteProfile {
        switch self {
        case .light: return TasteProfile(body: -5, tannin: -8, acidity: 2, aroma: 8)
        case .balanced: return TasteProfile(body: 0, tannin: 0, acidity: 0, aroma: 0)
        case .hard: return TasteProfile(body: 6, tannin: 10, acidity: -2, aroma: -4)
        }
    }
}

enum HarvestTiming: String, Codable, CaseIterable {
    case early, optimal, late

    var label: String {
        switch self {
        case .early: return "Early Pick"
        case .optimal: return "Optimal Pick"
        case .late: return "Late Pick"
        }
    }

    var modifier: TasteProfile {
        switch self {
        case .early: return TasteProfile(body: -4, tannin: -3, acidity: 9, aroma: 3)
        case .optimal: return TasteProfile(body: 0, tannin: 0, acidity: 0, aroma: 4)
        case .late: return TasteProfile(body: 8, tannin: 5, acidity: -8, aroma: -2)
        }
    }
}

// MARK: - Barrels (active aging)

struct Barrel: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var barrelTypeID: String
    var varietyID: String
    var terroirID: String
    var vintageYear: Int
    var pressStyle: PressStyle
    var harvestTiming: HarvestTiming
    var monthsAged: Int
    var liters: Int
    var profile: TasteProfile
    var label: String?

    init(id: UUID = UUID(),
         name: String,
         barrelTypeID: String,
         varietyID: String,
         terroirID: String,
         vintageYear: Int,
         pressStyle: PressStyle,
         harvestTiming: HarvestTiming,
         monthsAged: Int,
         liters: Int,
         profile: TasteProfile,
         label: String? = nil) {
        self.id = id
        self.name = name
        self.barrelTypeID = barrelTypeID
        self.varietyID = varietyID
        self.terroirID = terroirID
        self.vintageYear = vintageYear
        self.pressStyle = pressStyle
        self.harvestTiming = harvestTiming
        self.monthsAged = monthsAged
        self.liters = liters
        self.profile = profile
        self.label = label
    }
}

// MARK: - Bottled Lots

struct BottledLot: Identifiable, Codable, Hashable {
    let id: UUID
    var labelName: String
    var varietyID: String
    var terroirID: String
    var barrelTypeID: String
    var vintageYear: Int
    var monthsAgedInBarrel: Int
    var monthsAgedInBottle: Int
    var bottles: Int
    var profile: TasteProfile
    var bottledOnYear: Int

    init(id: UUID = UUID(), labelName: String, varietyID: String, terroirID: String,
         barrelTypeID: String, vintageYear: Int, monthsAgedInBarrel: Int,
         monthsAgedInBottle: Int = 0, bottles: Int, profile: TasteProfile, bottledOnYear: Int) {
        self.id = id
        self.labelName = labelName
        self.varietyID = varietyID
        self.terroirID = terroirID
        self.barrelTypeID = barrelTypeID
        self.vintageYear = vintageYear
        self.monthsAgedInBarrel = monthsAgedInBarrel
        self.monthsAgedInBottle = monthsAgedInBottle
        self.bottles = bottles
        self.profile = profile
        self.bottledOnYear = bottledOnYear
    }
}

// MARK: - Buyer Archetypes

struct BuyerArchetype: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let preference: TasteProfile
    let minAgeMonths: Int
    let maxAgeMonths: Int
    let basePrice: Int      // per bottle baseline
    let blurb: String
}

// MARK: - Market Order

struct MarketOrder: Identifiable, Codable, Hashable {
    let id: UUID
    var buyerID: String
    var bottlesWanted: Int
    var minQuality: Double
    var expiresOnYear: Int
    var expiresOnSeason: Int

    init(id: UUID = UUID(), buyerID: String, bottlesWanted: Int,
         minQuality: Double, expiresOnYear: Int, expiresOnSeason: Int) {
        self.id = id
        self.buyerID = buyerID
        self.bottlesWanted = bottlesWanted
        self.minQuality = minQuality
        self.expiresOnYear = expiresOnYear
        self.expiresOnSeason = expiresOnSeason
    }
}

// MARK: - Events

struct GameEvent: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let description: String
    let optionA: EventOption
    let optionB: EventOption
}

struct EventOption: Hashable, Codable {
    let label: String
    let coinDelta: Int
    let prestigeDelta: Int
    let cellarDiseaseDelta: Double
    let yieldShockYears: Int
    let yieldShockFactor: Double
    let note: String
}

// MARK: - Upgrades

struct Upgrade: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let cost: Int
    let blurb: String
    let category: String
}

// MARK: - Blending Recipe

struct BlendingRecipe: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let target: TasteProfile
    let varietyHints: [String]
    let blurb: String
}

// MARK: - Achievements

struct Achievement: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let blurb: String
}

// MARK: - Tasting Event

struct TastingJudge: Hashable, Codable {
    let name: String
    let preference: TasteProfile
}

struct TastingEvent: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let blurb: String
    let judges: [TastingJudge]
}

enum Medal: String, Codable, Hashable {
    case none, bronze, silver, gold

    var label: String {
        switch self {
        case .none: return "No Medal"
        case .bronze: return "Bronze"
        case .silver: return "Silver"
        case .gold: return "Gold"
        }
    }
}

struct TastingResult: Codable, Hashable, Identifiable {
    let id: String
    let year: Int
    let eventID: String
    let entryLabel: String
    let score: Double
    let medal: Medal

    init(id: String = UUID().uuidString, year: Int, eventID: String,
         entryLabel: String, score: Double, medal: Medal) {
        self.id = id
        self.year = year
        self.eventID = eventID
        self.entryLabel = entryLabel
        self.score = score
        self.medal = medal
    }

    enum CodingKeys: String, CodingKey {
        case id, year, eventID, entryLabel, score, medal
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        self.year = try c.decode(Int.self, forKey: .year)
        self.eventID = try c.decode(String.self, forKey: .eventID)
        self.entryLabel = try c.decode(String.self, forKey: .entryLabel)
        self.score = try c.decode(Double.self, forKey: .score)
        self.medal = try c.decode(Medal.self, forKey: .medal)
    }
}

// MARK: - Prestige Tier

struct PrestigeTier: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let medalsRequired: Int
    let revenueRequired: Int
    let blurb: String
}

// MARK: - Decision Log Entry

struct DecisionLog: Identifiable, Codable, Hashable {
    let id: UUID
    let year: Int
    let season: Int
    let title: String
    let detail: String

    init(id: UUID = UUID(), year: Int, season: Int, title: String, detail: String) {
        self.id = id
        self.year = year
        self.season = season
        self.title = title
        self.detail = detail
    }
}

// MARK: - Season Summary (transient — not persisted)

struct SeasonSummary: Hashable {
    let headerText: String
    let lines: [String]
}

// MARK: - Pending Harvest Bin

struct HarvestBin: Identifiable, Codable, Hashable {
    let id: UUID
    var varietyID: String
    var terroirID: String
    var vintageYear: Int
    var harvestTiming: HarvestTiming
    var kilograms: Int
    var weatherShift: TasteProfile

    init(id: UUID = UUID(), varietyID: String, terroirID: String, vintageYear: Int,
         harvestTiming: HarvestTiming, kilograms: Int, weatherShift: TasteProfile) {
        self.id = id
        self.varietyID = varietyID
        self.terroirID = terroirID
        self.vintageYear = vintageYear
        self.harvestTiming = harvestTiming
        self.kilograms = kilograms
        self.weatherShift = weatherShift
    }
}

// MARK: - Active Sheet pattern

enum ValleyActiveSheet: Identifiable, Hashable {
    case plantPlot
    case prunePlot(UUID)
    case harvestPlot(UUID)
    case pressBin(UUID)
    case ageBarrel(UUID)
    case bottleBarrel(UUID)
    case sellLot(UUID)
    case eventCard(String)
    case buyerDetail(String)
    case varietyDetail(String)
    case terroirDetail(String)
    case barrelTypeDetail(String)
    case recipeDetail(String)
    case achievementDetail(String)
    case tastingDetail(String)
    case eventLogEntry(UUID)
    case privacyWeb
    case help
    case prestigeDetail(String)

    var id: String {
        switch self {
        case .plantPlot: return "plant"
        case .prunePlot(let u): return "prune-\(u.uuidString)"
        case .harvestPlot(let u): return "harvest-\(u.uuidString)"
        case .pressBin(let u): return "press-\(u.uuidString)"
        case .ageBarrel(let u): return "age-\(u.uuidString)"
        case .bottleBarrel(let u): return "bottle-\(u.uuidString)"
        case .sellLot(let u): return "sell-\(u.uuidString)"
        case .eventCard(let s): return "event-\(s)"
        case .buyerDetail(let s): return "buyer-\(s)"
        case .varietyDetail(let s): return "variety-\(s)"
        case .terroirDetail(let s): return "terroir-\(s)"
        case .barrelTypeDetail(let s): return "barrel-\(s)"
        case .recipeDetail(let s): return "recipe-\(s)"
        case .achievementDetail(let s): return "ach-\(s)"
        case .tastingDetail(let s): return "tasting-\(s)"
        case .eventLogEntry(let u): return "log-\(u.uuidString)"
        case .privacyWeb: return "privacy"
        case .help: return "help"
        case .prestigeDetail(let s): return "prestige-\(s)"
        }
    }
}

// MARK: - Saved State (Codable, versioned)

struct ValleyState: Codable {
    var schemaVersion: Int
    var currentYear: Int           // 1...25
    var seasonIndex: Int           // 0..11
    var coins: Int
    var prestigePoints: Int
    var lifetimeRevenue: Int
    var plots: [VineyardPlot]
    var harvestBins: [HarvestBin]
    var barrels: [Barrel]
    var bottledLots: [BottledLot]
    var ownedBarrelTypes: [String]
    var pendingOrders: [MarketOrder]
    var completedOrders: Int
    var ownedUpgrades: [String]
    var unlockedAchievements: [String]
    var unlockedRecipes: [String]
    var tastingResults: [TastingResult]
    var medalsGold: Int
    var medalsSilver: Int
    var medalsBronze: Int
    var weatherHistory: [Weather]
    var currentWeather: Weather
    var pendingEventID: String?
    var decisionLog: [DecisionLog]
    var advanceCounter: Int
    var seenWelcome: Bool
    var nextPaymentBonus: Double
    var yieldShockTimer: Int
    var yieldShockMultiplier: Double
    var resolvedEventIDs: Set<String>
    var completedBuyerIDs: Set<String>

    static let defaults = ValleyState(
        schemaVersion: 1,
        currentYear: 1,
        seasonIndex: 0,
        coins: 1200,
        prestigePoints: 0,
        lifetimeRevenue: 0,
        plots: [],
        harvestBins: [],
        barrels: [],
        bottledLots: [],
        ownedBarrelTypes: ["bt_light_oak", "bt_stainless"],
        pendingOrders: [],
        completedOrders: 0,
        ownedUpgrades: [],
        unlockedAchievements: [],
        unlockedRecipes: [],
        tastingResults: [],
        medalsGold: 0,
        medalsSilver: 0,
        medalsBronze: 0,
        weatherHistory: [],
        currentWeather: .mild,
        pendingEventID: nil,
        decisionLog: [],
        advanceCounter: 0,
        seenWelcome: false,
        nextPaymentBonus: 1.0,
        yieldShockTimer: 0,
        yieldShockMultiplier: 1.0,
        resolvedEventIDs: [],
        completedBuyerIDs: []
    )

    init(schemaVersion: Int, currentYear: Int, seasonIndex: Int, coins: Int, prestigePoints: Int,
         lifetimeRevenue: Int, plots: [VineyardPlot], harvestBins: [HarvestBin], barrels: [Barrel],
         bottledLots: [BottledLot], ownedBarrelTypes: [String], pendingOrders: [MarketOrder],
         completedOrders: Int, ownedUpgrades: [String], unlockedAchievements: [String],
         unlockedRecipes: [String], tastingResults: [TastingResult],
         medalsGold: Int, medalsSilver: Int, medalsBronze: Int,
         weatherHistory: [Weather], currentWeather: Weather, pendingEventID: String?,
         decisionLog: [DecisionLog], advanceCounter: Int, seenWelcome: Bool,
         nextPaymentBonus: Double, yieldShockTimer: Int = 0,
         yieldShockMultiplier: Double = 1.0,
         resolvedEventIDs: Set<String> = [],
         completedBuyerIDs: Set<String> = []) {
        self.schemaVersion = schemaVersion
        self.currentYear = currentYear
        self.seasonIndex = seasonIndex
        self.coins = coins
        self.prestigePoints = prestigePoints
        self.lifetimeRevenue = lifetimeRevenue
        self.plots = plots
        self.harvestBins = harvestBins
        self.barrels = barrels
        self.bottledLots = bottledLots
        self.ownedBarrelTypes = ownedBarrelTypes
        self.pendingOrders = pendingOrders
        self.completedOrders = completedOrders
        self.ownedUpgrades = ownedUpgrades
        self.unlockedAchievements = unlockedAchievements
        self.unlockedRecipes = unlockedRecipes
        self.tastingResults = tastingResults
        self.medalsGold = medalsGold
        self.medalsSilver = medalsSilver
        self.medalsBronze = medalsBronze
        self.weatherHistory = weatherHistory
        self.currentWeather = currentWeather
        self.pendingEventID = pendingEventID
        self.decisionLog = decisionLog
        self.advanceCounter = advanceCounter
        self.seenWelcome = seenWelcome
        self.nextPaymentBonus = nextPaymentBonus
        self.yieldShockTimer = yieldShockTimer
        self.yieldShockMultiplier = yieldShockMultiplier
        self.resolvedEventIDs = resolvedEventIDs
        self.completedBuyerIDs = completedBuyerIDs
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = ValleyState.defaults
        schemaVersion = try c.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? d.schemaVersion
        currentYear = try c.decodeIfPresent(Int.self, forKey: .currentYear) ?? d.currentYear
        seasonIndex = try c.decodeIfPresent(Int.self, forKey: .seasonIndex) ?? d.seasonIndex
        coins = try c.decodeIfPresent(Int.self, forKey: .coins) ?? d.coins
        prestigePoints = try c.decodeIfPresent(Int.self, forKey: .prestigePoints) ?? d.prestigePoints
        lifetimeRevenue = try c.decodeIfPresent(Int.self, forKey: .lifetimeRevenue) ?? d.lifetimeRevenue
        plots = try c.decodeIfPresent([VineyardPlot].self, forKey: .plots) ?? d.plots
        harvestBins = try c.decodeIfPresent([HarvestBin].self, forKey: .harvestBins) ?? d.harvestBins
        barrels = try c.decodeIfPresent([Barrel].self, forKey: .barrels) ?? d.barrels
        bottledLots = try c.decodeIfPresent([BottledLot].self, forKey: .bottledLots) ?? d.bottledLots
        ownedBarrelTypes = try c.decodeIfPresent([String].self, forKey: .ownedBarrelTypes) ?? d.ownedBarrelTypes
        pendingOrders = try c.decodeIfPresent([MarketOrder].self, forKey: .pendingOrders) ?? d.pendingOrders
        completedOrders = try c.decodeIfPresent(Int.self, forKey: .completedOrders) ?? d.completedOrders
        ownedUpgrades = try c.decodeIfPresent([String].self, forKey: .ownedUpgrades) ?? d.ownedUpgrades
        unlockedAchievements = try c.decodeIfPresent([String].self, forKey: .unlockedAchievements) ?? d.unlockedAchievements
        unlockedRecipes = try c.decodeIfPresent([String].self, forKey: .unlockedRecipes) ?? d.unlockedRecipes
        tastingResults = try c.decodeIfPresent([TastingResult].self, forKey: .tastingResults) ?? d.tastingResults
        medalsGold = try c.decodeIfPresent(Int.self, forKey: .medalsGold) ?? d.medalsGold
        medalsSilver = try c.decodeIfPresent(Int.self, forKey: .medalsSilver) ?? d.medalsSilver
        medalsBronze = try c.decodeIfPresent(Int.self, forKey: .medalsBronze) ?? d.medalsBronze
        weatherHistory = try c.decodeIfPresent([Weather].self, forKey: .weatherHistory) ?? d.weatherHistory
        currentWeather = try c.decodeIfPresent(Weather.self, forKey: .currentWeather) ?? d.currentWeather
        pendingEventID = try c.decodeIfPresent(String.self, forKey: .pendingEventID) ?? d.pendingEventID
        decisionLog = try c.decodeIfPresent([DecisionLog].self, forKey: .decisionLog) ?? d.decisionLog
        advanceCounter = try c.decodeIfPresent(Int.self, forKey: .advanceCounter) ?? d.advanceCounter
        seenWelcome = try c.decodeIfPresent(Bool.self, forKey: .seenWelcome) ?? d.seenWelcome
        nextPaymentBonus = try c.decodeIfPresent(Double.self, forKey: .nextPaymentBonus) ?? d.nextPaymentBonus
        yieldShockTimer = try c.decodeIfPresent(Int.self, forKey: .yieldShockTimer) ?? d.yieldShockTimer
        yieldShockMultiplier = try c.decodeIfPresent(Double.self, forKey: .yieldShockMultiplier) ?? d.yieldShockMultiplier
        resolvedEventIDs = try c.decodeIfPresent(Set<String>.self, forKey: .resolvedEventIDs) ?? Set()
        completedBuyerIDs = try c.decodeIfPresent(Set<String>.self, forKey: .completedBuyerIDs) ?? Set()
    }

    enum CodingKeys: String, CodingKey {
        case schemaVersion, currentYear, seasonIndex, coins, prestigePoints, lifetimeRevenue
        case plots, harvestBins, barrels, bottledLots, ownedBarrelTypes
        case pendingOrders, completedOrders, ownedUpgrades, unlockedAchievements, unlockedRecipes
        case tastingResults, medalsGold, medalsSilver, medalsBronze
        case weatherHistory, currentWeather, pendingEventID, decisionLog, advanceCounter
        case seenWelcome, nextPaymentBonus
        case yieldShockTimer, yieldShockMultiplier, resolvedEventIDs, completedBuyerIDs
    }
}

// MARK: - Seeded RNG

struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed == 0 ? 0xCBF29CE484222325 : seed }
    mutating func next() -> UInt64 {
        // splitmix64
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
    mutating func intInRange(_ range: ClosedRange<Int>) -> Int {
        let span = UInt64(range.upperBound - range.lowerBound + 1)
        return range.lowerBound + Int(next() % span)
    }
    mutating func double01() -> Double {
        Double(next() >> 11) * (1.0 / Double(1 << 53))
    }
    mutating func choice<T>(_ array: [T]) -> T {
        array[intInRange(0...(array.count - 1))]
    }
    mutating func chance(_ p: Double) -> Bool { double01() < p }
}

import SwiftUI

// MARK: - More Hub View

struct MoreHubView: View {
    @EnvironmentObject var store: ValleyStore
    @Binding var activeSheet: ValleyActiveSheet?
    @State private var section: Int = 0
    // 0 = Estate, 1 = Achievements, 2 = Tastings, 3 = Prestige, 4 = Upgrades, 5 = Settings

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                sectionSwitcher
                Group {
                    switch section {
                    case 0: estateSection
                    case 1: achievementsSection
                    case 2: tastingsSection
                    case 3: prestigeSection
                    case 4: upgradesSection
                    default: settingsSection
                    }
                }
            }
            .padding(16)
        }
        .background(ValleyPalette.cream.edgesIgnoringSafeArea(.all))
        .navigationBarTitle("More", displayMode: .inline)
    }

    private var sectionSwitcher: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                hubChip("Estate", index: 0)
                hubChip("Awards", index: 1)
                hubChip("Tastings", index: 2)
            }
            HStack(spacing: 6) {
                hubChip("Prestige", index: 3)
                hubChip("Upgrades", index: 4)
                hubChip("Settings", index: 5)
            }
        }
    }

    private func hubChip(_ label: String, index: Int) -> some View {
        Button(action: { section = index }) {
            Text(label)
                .font(.system(size: 12, weight: .bold, design: .serif))
                .foregroundColor(section == index ? ValleyPalette.cream : ValleyPalette.burgundy)
                .padding(.vertical, 9)
                .frame(maxWidth: .infinity)
                .background(section == index ? ValleyPalette.burgundy : ValleyPalette.ivory)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(ValleyPalette.parchmentLine, lineWidth: 1))
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: Estate Summary

    private var estateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ValleySectionHeader(title: "Estate Ledger")
            VStack(spacing: 8) {
                summaryRow(label: "Current Year", value: "\(store.state.currentYear) of 25")
                summaryRow(label: "Season", value: store.currentSeason.label)
                summaryRow(label: "Weather", value: store.state.currentWeather.label)
                summaryRow(label: "Coins on Hand", value: "\(store.state.coins)")
                summaryRow(label: "Lifetime Revenue", value: "\(store.state.lifetimeRevenue)")
                summaryRow(label: "Prestige Points", value: "\(store.state.prestigePoints)")
                summaryRow(label: "Gold Medals", value: "\(store.state.medalsGold)")
                summaryRow(label: "Silver Medals", value: "\(store.state.medalsSilver)")
                summaryRow(label: "Bronze Medals", value: "\(store.state.medalsBronze)")
                summaryRow(label: "Completed Orders", value: "\(store.state.completedOrders)")
                summaryRow(label: "Active Plots", value: "\(store.state.plots.count)")
                summaryRow(label: "Aging Barrels", value: "\(store.state.barrels.count)")
                summaryRow(label: "Bottled Lots", value: "\(store.state.bottledLots.count)")
                summaryRow(label: "Tier", value: store.currentTier.name)
            }

            ValleySectionHeader(title: "Decision Log")
            if store.state.decisionLog.isEmpty {
                Text("The ledger is blank — for now.")
                    .font(.system(size: 12, design: .serif))
                    .foregroundColor(ValleyPalette.olive)
            } else {
                ForEach(store.state.decisionLog.suffix(20).reversed()) { entry in
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
            }
        }
    }

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .serif))
                .foregroundColor(ValleyPalette.olive)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .serif))
                .foregroundColor(ValleyPalette.inkText)
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(ValleyPalette.ivory)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(ValleyPalette.parchmentLine, lineWidth: 1))
    }

    // MARK: Achievements

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ValleySectionHeader(title: "Achievements (\(store.state.unlockedAchievements.count)/\(ValleyTables.achievements.count))")
            ForEach(ValleyTables.achievements) { a in
                let unlocked = store.state.unlockedAchievements.contains(a.id)
                Button(action: { activeSheet = .achievementDetail(a.id) }) {
                    HStack(spacing: 10) {
                        if unlocked {
                            MedalIcon(medal: .gold, size: 28)
                        } else {
                            PadlockIcon(size: 22, color: ValleyPalette.olive)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(a.title)
                                .font(.system(size: 13, weight: .bold, design: .serif))
                                .foregroundColor(unlocked ? ValleyPalette.inkText : ValleyPalette.olive)
                            Text(a.blurb)
                                .font(.system(size: 11, design: .serif))
                                .foregroundColor(ValleyPalette.olive)
                                .lineLimit(2)
                        }
                        Spacer()
                    }
                    .padding(10)
                    .background(unlocked ? ValleyPalette.creamWarm : ValleyPalette.ivory)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(ValleyPalette.parchmentLine, lineWidth: 1))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    // MARK: Tastings

    private var tastingsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            ValleySectionHeader(title: "Annual Tasting Circuit")
            ForEach(ValleyTables.tastings) { t in
                Button(action: { activeSheet = .tastingDetail(t.id) }) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(t.name)
                                .font(.system(size: 14, weight: .bold, design: .serif))
                                .foregroundColor(ValleyPalette.burgundy)
                            Spacer()
                            Text("\(t.judges.count) judges")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(ValleyPalette.olive)
                        }
                        Text(t.blurb)
                            .font(.system(size: 11, design: .serif))
                            .foregroundColor(ValleyPalette.olive)
                            .lineLimit(2)
                    }
                    .padding(10)
                    .background(ValleyPalette.ivory)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(ValleyPalette.parchmentLine, lineWidth: 1))
                }
                .buttonStyle(PlainButtonStyle())
            }

            ValleySectionHeader(title: "Results Archive")
            if store.state.tastingResults.isEmpty {
                Text("No tastings entered yet. Tastings run automatically each Late Winter.")
                    .font(.system(size: 12, design: .serif))
                    .foregroundColor(ValleyPalette.olive)
            } else {
                ForEach(store.state.tastingResults.reversed()) { result in
                    HStack(spacing: 10) {
                        MedalIcon(medal: result.medal, size: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(ValleyTables.tasting(result.eventID)?.name ?? "Tasting")")
                                .font(.system(size: 13, weight: .bold, design: .serif))
                                .foregroundColor(ValleyPalette.inkText)
                            Text("Y\(result.year) · \(result.entryLabel) · Score \(Int(result.score))")
                                .font(.system(size: 11, design: .serif))
                                .foregroundColor(ValleyPalette.olive)
                        }
                        Spacer()
                        Text(result.medal.label)
                            .font(.system(size: 11, weight: .bold, design: .serif))
                            .foregroundColor(ValleyPalette.terracotta)
                    }
                    .padding(10)
                    .background(ValleyPalette.ivory)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(ValleyPalette.parchmentLine, lineWidth: 1))
                }
            }
        }
    }

    // MARK: Prestige

    private var prestigeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            ValleySectionHeader(title: "Prestige Tiers")
            HStack {
                Text("Current Tier:").font(.system(size: 12, weight: .semibold, design: .serif))
                    .foregroundColor(ValleyPalette.olive)
                Text(store.currentTier.name).font(.system(size: 14, weight: .black, design: .serif))
                    .foregroundColor(ValleyPalette.terracotta)
            }
            ForEach(ValleyTables.prestigeTiers) { tier in
                let achieved = (store.state.prestigePoints >= tier.medalsRequired &&
                                store.state.lifetimeRevenue >= tier.revenueRequired)
                Button(action: { activeSheet = .prestigeDetail(tier.id) }) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(tier.name)
                                .font(.system(size: 14, weight: .bold, design: .serif))
                                .foregroundColor(achieved ? ValleyPalette.burgundy : ValleyPalette.olive)
                            Spacer()
                            if achieved { CheckIcon() } else { PadlockIcon(size: 16, color: ValleyPalette.olive) }
                        }
                        Text(tier.blurb)
                            .font(.system(size: 11, design: .serif))
                            .foregroundColor(ValleyPalette.olive)
                        Text("Needs: \(tier.medalsRequired) prestige · \(tier.revenueRequired) revenue")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(ValleyPalette.terracotta)
                    }
                    .padding(10)
                    .background(achieved ? ValleyPalette.creamWarm : ValleyPalette.ivory)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(ValleyPalette.parchmentLine, lineWidth: 1))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    // MARK: Upgrades

    private var upgradesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            ValleySectionHeader(title: "Estate Upgrades")
            Text("Reinvest coin into permanent improvements.")
                .font(.system(size: 12, design: .serif))
                .foregroundColor(ValleyPalette.olive)
            ForEach(ValleyTables.upgrades) { up in
                let owned = store.state.ownedUpgrades.contains(up.id)
                HStack(alignment: .top, spacing: 10) {
                    GearIcon(size: 30, color: owned ? ValleyPalette.olive : ValleyPalette.burgundy)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(up.name)
                                .font(.system(size: 13, weight: .bold, design: .serif))
                                .foregroundColor(ValleyPalette.inkText)
                            Spacer()
                            Text(up.category)
                                .font(.system(size: 10, weight: .semibold, design: .serif))
                                .foregroundColor(ValleyPalette.terracotta)
                        }
                        Text(up.blurb)
                            .font(.system(size: 11, design: .serif))
                            .foregroundColor(ValleyPalette.olive)
                        HStack {
                            CoinIcon(size: 14)
                            Text("\(up.cost) coin").font(.system(size: 11, weight: .bold))
                                .foregroundColor(ValleyPalette.terracotta)
                            Spacer()
                            if owned {
                                HStack(spacing: 4) { CheckIcon(size: 12); Text("Owned").font(.system(size: 11, weight: .bold)).foregroundColor(ValleyPalette.olive) }
                            } else {
                                Button(action: { store.purchaseUpgrade(up.id) }) {
                                    Text("Acquire")
                                        .font(.system(size: 11, weight: .bold, design: .serif))
                                        .foregroundColor(ValleyPalette.cream)
                                        .padding(.vertical, 6).padding(.horizontal, 12)
                                        .background(LinearGradient(colors: store.state.coins >= up.cost
                                                                    ? [ValleyPalette.terracotta, ValleyPalette.burgundy]
                                                                    : [ValleyPalette.parchmentLine, ValleyPalette.dust],
                                                                   startPoint: .leading, endPoint: .trailing))
                                        .cornerRadius(6)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .disabled(store.state.coins < up.cost)
                            }
                        }
                    }
                }
                .padding(10)
                .background(owned ? ValleyPalette.creamWarm : ValleyPalette.ivory)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(ValleyPalette.parchmentLine, lineWidth: 1))
            }
        }
    }

    // MARK: Settings

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SettingsView(activeSheet: $activeSheet)
        }
    }
}

// MARK: - Help Sheet

struct HelpSheet: View {
    @Binding var activeSheet: ValleyActiveSheet?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("How to Play")
                    .font(.system(size: 22, weight: .black, design: .serif))
                    .foregroundColor(ValleyPalette.burgundy)

                ValleySectionHeader(title: "Time")
                Text("Twenty-five vintages stretch ahead, divided into twelve seasons each. Tap Advance in the upper right to move time forward.")
                    .font(.system(size: 13, design: .serif))
                    .foregroundColor(ValleyPalette.inkText)

                ValleySectionHeader(title: "The Yearly Cycle")
                Text("• Prune in Early Spring.\n• Watch the rows through summer.\n• Harvest in Early or Mid Fall.\n• Press fruit into a chosen barrel.\n• Age, blend, and finally bottle a finished lot.\n• Sell during Late Fall, Early Winter, and Mid Winter.\n• Tastings run automatically in Late Winter.")
                    .font(.system(size: 12, design: .serif))
                    .foregroundColor(ValleyPalette.inkText)

                ValleySectionHeader(title: "Profile")
                Text("Every wine tracks Body, Tannin, Acidity, and Aroma on a 0-100 scale. Match the buyer's preferences to maximize price.")
                    .font(.system(size: 12, design: .serif))
                    .foregroundColor(ValleyPalette.inkText)

                ValleySectionHeader(title: "Weather")
                Text("Each season rolls a weather state. Hot weather lifts body, cold weather sharpens acidity. Hail and frost reduce yield.")
                    .font(.system(size: 12, design: .serif))
                    .foregroundColor(ValleyPalette.inkText)

                ValleySectionHeader(title: "Events")
                Text("Decisions arrive at random. Read each card carefully; consequences ripple across years.")
                    .font(.system(size: 12, design: .serif))
                    .foregroundColor(ValleyPalette.inkText)

                ValleySectionHeader(title: "Prestige")
                Text("Win medals at tastings and grow lifetime revenue to ascend prestige tiers. Reach Legendary Domaine to retire in glory.")
                    .font(.system(size: 12, design: .serif))
                    .foregroundColor(ValleyPalette.inkText)

                ValleySecondaryButton(title: "Close") { activeSheet = nil }
            }
            .padding(16)
        }
        .background(ValleyPalette.cream)
        .navigationBarTitle("Help", displayMode: .inline)
    }
}

// MARK: - Privacy Web Sheet

struct PrivacyWebSheet: View {
    @Binding var activeSheet: ValleyActiveSheet?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ValleyWinemakerWebPanel(urlString: "https://valleywinemakerlegacy.org/click.php")
                .edgesIgnoringSafeArea(.all)
            Button(action: { activeSheet = nil }) {
                HStack(spacing: 6) {
                    XIcon(size: 14, color: ValleyPalette.cream)
                    Text("Close")
                        .font(.system(size: 12, weight: .bold, design: .serif))
                        .foregroundColor(ValleyPalette.cream)
                }
                .padding(.vertical, 8).padding(.horizontal, 14)
                .background(ValleyPalette.burgundy)
                .cornerRadius(6)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, 12).padding(.trailing, 12)
        }
        .navigationBarTitle("Privacy Policy", displayMode: .inline)
    }
}

// MARK: - Achievement Detail Sheet

struct AchievementDetailSheet: View {
    @EnvironmentObject var store: ValleyStore
    let achievementID: String
    @Binding var activeSheet: ValleyActiveSheet?

    var body: some View {
        let unlocked = store.state.unlockedAchievements.contains(achievementID)
        VStack(alignment: .leading, spacing: 14) {
            if let a = ValleyTables.achievement(achievementID) {
                HStack(spacing: 12) {
                    MedalIcon(medal: unlocked ? .gold : .none, size: 48)
                    VStack(alignment: .leading) {
                        Text(a.title)
                            .font(.system(size: 22, weight: .black, design: .serif))
                            .foregroundColor(ValleyPalette.burgundy)
                        Text(unlocked ? "Unlocked" : "Locked")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(unlocked ? ValleyPalette.olive : ValleyPalette.terracotta)
                    }
                }
                Text(a.blurb)
                    .font(.system(size: 14, design: .serif))
                    .foregroundColor(ValleyPalette.inkText)
            }
            ValleySecondaryButton(title: "Close") { activeSheet = nil }
            Spacer()
        }
        .padding(16)
        .background(ValleyPalette.cream)
        .navigationBarTitle("Achievement", displayMode: .inline)
    }
}

// MARK: - Tasting Detail Sheet

struct TastingDetailSheet: View {
    @EnvironmentObject var store: ValleyStore
    let tastingID: String
    @Binding var activeSheet: ValleyActiveSheet?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let t = ValleyTables.tasting(tastingID) {
                    Text(t.name)
                        .font(.system(size: 22, weight: .black, design: .serif))
                        .foregroundColor(ValleyPalette.burgundy)
                    Text(t.blurb)
                        .font(.system(size: 13, design: .serif))
                        .foregroundColor(ValleyPalette.inkText)

                    ValleySectionHeader(title: "Judges")
                    ForEach(Array(t.judges.enumerated()), id: \.offset) { _, judge in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                PersonIcon(size: 28)
                                Text(judge.name)
                                    .font(.system(size: 13, weight: .bold, design: .serif))
                                    .foregroundColor(ValleyPalette.inkText)
                            }
                            ProfileBars(profile: judge.preference, compact: true)
                        }
                        .padding(10)
                        .background(ValleyPalette.ivory)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(ValleyPalette.parchmentLine, lineWidth: 1))
                    }

                    let pastResults = store.state.tastingResults.filter { $0.eventID == t.id }
                    if !pastResults.isEmpty {
                        ValleySectionHeader(title: "Past Results")
                        ForEach(pastResults.reversed()) { result in
                            HStack {
                                MedalIcon(medal: result.medal, size: 22)
                                Text("Y\(result.year): \(result.entryLabel)")
                                    .font(.system(size: 12, design: .serif))
                                    .foregroundColor(ValleyPalette.inkText)
                                Spacer()
                                Text("Score \(Int(result.score))")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(ValleyPalette.terracotta)
                            }
                            .padding(8)
                            .background(ValleyPalette.ivory)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(ValleyPalette.parchmentLine, lineWidth: 1))
                        }
                    }
                }
                ValleySecondaryButton(title: "Close") { activeSheet = nil }
            }
            .padding(16)
        }
        .background(ValleyPalette.cream)
        .navigationBarTitle("Tasting", displayMode: .inline)
    }
}

// MARK: - Prestige Detail Sheet

struct PrestigeDetailSheet: View {
    @EnvironmentObject var store: ValleyStore
    let tierID: String
    @Binding var activeSheet: ValleyActiveSheet?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let t = ValleyTables.prestigeTiers.first(where: { $0.id == tierID }) {
                Text(t.name)
                    .font(.system(size: 22, weight: .black, design: .serif))
                    .foregroundColor(ValleyPalette.burgundy)
                Text(t.blurb)
                    .font(.system(size: 13, design: .serif))
                    .foregroundColor(ValleyPalette.inkText)
                ValleySectionHeader(title: "Requirements")
                Text("Prestige points: \(t.medalsRequired)")
                    .font(.system(size: 13, weight: .semibold, design: .serif))
                    .foregroundColor(ValleyPalette.terracotta)
                Text("Lifetime revenue: \(t.revenueRequired)")
                    .font(.system(size: 13, weight: .semibold, design: .serif))
                    .foregroundColor(ValleyPalette.terracotta)
                ValleySectionHeader(title: "Your Progress")
                Text("Prestige: \(store.state.prestigePoints) · Revenue: \(store.state.lifetimeRevenue)")
                    .font(.system(size: 12, design: .serif))
                    .foregroundColor(ValleyPalette.olive)
            }
            ValleySecondaryButton(title: "Close") { activeSheet = nil }
            Spacer()
        }
        .padding(16)
        .background(ValleyPalette.cream)
        .navigationBarTitle("Prestige Tier", displayMode: .inline)
    }
}

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: ValleyStore
    @State private var selectedTab: Int = 0
    @State private var activeSheet: ValleyActiveSheet? = nil
    @State private var showWelcome: Bool = false

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                Group {
                    switch selectedTab {
                    case 0:
                        NavigationView {
                            VineyardView(activeSheet: $activeSheet)
                        }
                        .navigationViewStyle(StackNavigationViewStyle())
                    case 1:
                        NavigationView {
                            CellarView(activeSheet: $activeSheet)
                        }
                        .navigationViewStyle(StackNavigationViewStyle())
                    case 2:
                        NavigationView {
                            MarketView(activeSheet: $activeSheet)
                        }
                        .navigationViewStyle(StackNavigationViewStyle())
                    case 3:
                        NavigationView {
                            AlmanacView(activeSheet: $activeSheet)
                        }
                        .navigationViewStyle(StackNavigationViewStyle())
                    default:
                        NavigationView {
                            MoreHubView(activeSheet: $activeSheet)
                        }
                        .navigationViewStyle(StackNavigationViewStyle())
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                tabBar
            }
            .background(ValleyPalette.cream.ignoresSafeArea())
        }
        .sheet(item: $activeSheet) { sheet in
            sheetContent(sheet)
        }
        .onAppear {
            if !store.state.seenWelcome {
                showWelcome = true
                store.state.seenWelcome = true
                store.persist()
            }
        }
        .overlay(
            Group {
                if showWelcome {
                    WelcomeOverlay { showWelcome = false }
                }
            }
        )
    }

    @ViewBuilder
    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(index: 0, label: "Vineyard",
                      icon: AnyView(VineyardTabIcon(size: 24, color: selectedTab == 0 ? ValleyPalette.terracotta : ValleyPalette.burgundy.opacity(0.45))))
            tabButton(index: 1, label: "Cellar",
                      icon: AnyView(CellarTabIcon(size: 24, color: selectedTab == 1 ? ValleyPalette.terracotta : ValleyPalette.burgundy.opacity(0.45))))
            tabButton(index: 2, label: "Market",
                      icon: AnyView(MarketTabIcon(size: 24, color: selectedTab == 2 ? ValleyPalette.terracotta : ValleyPalette.burgundy.opacity(0.45))))
            tabButton(index: 3, label: "Almanac",
                      icon: AnyView(AlmanacTabIcon(size: 24, color: selectedTab == 3 ? ValleyPalette.terracotta : ValleyPalette.burgundy.opacity(0.45))))
            tabButton(index: 4, label: "More",
                      icon: AnyView(MoreTabIcon(size: 24, color: selectedTab == 4 ? ValleyPalette.terracotta : ValleyPalette.burgundy.opacity(0.45))))
        }
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(ValleyPalette.ivory.edgesIgnoringSafeArea(.bottom))
        .overlay(
            Rectangle().fill(ValleyPalette.parchmentLine).frame(height: 1),
            alignment: .top
        )
    }

    private func tabButton(index: Int, label: String, icon: AnyView) -> some View {
        Button(action: { selectedTab = index }) {
            VStack(spacing: 3) {
                icon
                Text(label)
                    .font(.system(size: 10, weight: .semibold, design: .serif))
                    .foregroundColor(selectedTab == index ? ValleyPalette.terracotta : ValleyPalette.burgundy.opacity(0.55))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private func sheetContent(_ sheet: ValleyActiveSheet) -> some View {
        NavigationView {
            Group {
                switch sheet {
                case .plantPlot:
                    PlantPlotSheet(activeSheet: $activeSheet)
                case .prunePlot(let id):
                    PrunePlotSheet(plotID: id, activeSheet: $activeSheet)
                case .harvestPlot(let id):
                    HarvestPlotSheet(plotID: id, activeSheet: $activeSheet)
                case .pressBin(let id):
                    PressBinSheet(binID: id, activeSheet: $activeSheet)
                case .ageBarrel(let id):
                    AgeBarrelSheet(barrelID: id, activeSheet: $activeSheet)
                case .bottleBarrel(let id):
                    BottleBarrelSheet(barrelID: id, activeSheet: $activeSheet)
                case .sellLot(let id):
                    SellLotSheet(lotID: id, activeSheet: $activeSheet)
                case .eventCard(let id):
                    EventCardSheet(eventID: id, activeSheet: $activeSheet)
                case .buyerDetail(let id):
                    BuyerDetailSheet(buyerID: id, activeSheet: $activeSheet)
                case .varietyDetail(let id):
                    VarietyDetailSheet(varietyID: id, activeSheet: $activeSheet)
                case .terroirDetail(let id):
                    TerroirDetailSheet(terroirID: id, activeSheet: $activeSheet)
                case .barrelTypeDetail(let id):
                    BarrelTypeDetailSheet(barrelTypeID: id, activeSheet: $activeSheet)
                case .recipeDetail(let id):
                    RecipeDetailSheet(recipeID: id, activeSheet: $activeSheet)
                case .achievementDetail(let id):
                    AchievementDetailSheet(achievementID: id, activeSheet: $activeSheet)
                case .tastingDetail(let id):
                    TastingDetailSheet(tastingID: id, activeSheet: $activeSheet)
                case .eventLogEntry(let id):
                    DecisionLogDetailSheet(entryID: id, activeSheet: $activeSheet)
                case .privacyWeb:
                    PrivacyWebSheet(activeSheet: $activeSheet)
                case .help:
                    HelpSheet(activeSheet: $activeSheet)
                case .prestigeDetail(let id):
                    PrestigeDetailSheet(tierID: id, activeSheet: $activeSheet)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Welcome Overlay

struct WelcomeOverlay: View {
    let dismiss: () -> Void

    private let coreLoop: [String] = [
        "Spring: prune your vines",
        "Late summer / fall: harvest grapes",
        "Press to fill a barrel",
        "Age for one or more years",
        "Bottle, then sell in late fall / winter",
        "Annual Tasting at year's end"
    ]

    var body: some View {
        ZStack {
            ValleyPalette.burgundy.opacity(0.7).ignoresSafeArea()
            VStack(spacing: 14) {
                ValleyEstateMonogram()
                    .stroke(ValleyPalette.terracotta, lineWidth: 2)
                    .frame(width: 90, height: 90)
                Text("Welcome to the Estate")
                    .font(.system(size: 22, weight: .black, design: .serif))
                    .foregroundColor(ValleyPalette.burgundy)
                Text("Twenty-five years of vintages stretch before you. Plant carefully, age patiently, and listen to your judges.")
                    .font(.system(size: 13, weight: .medium, design: .serif))
                    .multilineTextAlignment(.center)
                    .foregroundColor(ValleyPalette.inkText)
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(coreLoop, id: \.self) { line in
                        HStack(alignment: .top, spacing: 6) {
                            Circle().fill(ValleyPalette.terracotta).frame(width: 5, height: 5)
                                .padding(.top, 6)
                            Text(line)
                                .font(.system(size: 12, weight: .medium, design: .serif))
                                .foregroundColor(ValleyPalette.inkText)
                        }
                    }
                }
                Text("Seasons advance only when you tap the parchment in the upper right.")
                    .font(.system(size: 11, weight: .medium, design: .serif))
                    .multilineTextAlignment(.center)
                    .foregroundColor(ValleyPalette.olive)
                ValleyPrimaryButton(title: "Begin Vintage I") { dismiss() }
            }
            .padding(22)
            .background(ValleyPalette.cream)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(ValleyPalette.terracotta.opacity(0.5), lineWidth: 1.5))
            .cornerRadius(14)
            .padding(24)
        }
    }
}

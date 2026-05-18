import SwiftUI

struct MarketView: View {
    @EnvironmentObject var store: ValleyStore
    @Binding var activeSheet: ValleyActiveSheet?
    @State private var section: Int = 0 // 0 = Active Orders, 1 = Buyer Roster

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                summaryRow

                tabSwitcher

                if section == 0 {
                    if store.state.pendingOrders.isEmpty {
                        Text("No active orders. New buyers arrive during the selling window (Late Fall through Mid Winter).")
                            .font(.system(size: 13, design: .serif))
                            .foregroundColor(ValleyPalette.olive)
                            .padding(.leading, 4)
                    } else {
                        ForEach(store.state.pendingOrders) { order in
                            orderRow(order)
                        }
                    }
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(ValleyTables.buyers) { buyer in
                            Button(action: { activeSheet = .buyerDetail(buyer.id) }) {
                                HStack(spacing: 10) {
                                    PersonIcon(size: 30)
                                    VStack(alignment: .leading) {
                                        Text(buyer.name).font(.system(size: 13, weight: .bold, design: .serif))
                                            .foregroundColor(ValleyPalette.inkText)
                                        Text(buyer.blurb).font(.system(size: 11, design: .serif))
                                            .foregroundColor(ValleyPalette.olive)
                                            .lineLimit(2)
                                    }
                                    Spacer()
                                    Text("\(buyer.basePrice)c")
                                        .font(.system(size: 12, weight: .bold)).foregroundColor(ValleyPalette.terracotta)
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
            .padding(16)
        }
        .background(ValleyPalette.cream.edgesIgnoringSafeArea(.all))
        .navigationBarTitle("Market", displayMode: .inline)
    }

    private var summaryRow: some View {
        HStack(spacing: 10) {
            StatusPill(icon: AnyView(CoinIcon(size: 18)), title: "Coins", value: "\(store.state.coins)")
            StatusPill(icon: AnyView(BottleIcon(size: 18)), title: "Lots", value: "\(store.state.bottledLots.count)")
            StatusPill(icon: AnyView(ScaleIcon(size: 18)), title: "Orders", value: "\(store.state.pendingOrders.count)")
            StatusPill(icon: AnyView(CheckIcon(size: 18, color: ValleyPalette.olive)), title: "Sales", value: "\(store.state.completedOrders)")
        }
    }

    private var tabSwitcher: some View {
        HStack(spacing: 0) {
            Button(action: { section = 0 }) {
                Text("Active Orders")
                    .font(.system(size: 13, weight: .bold, design: .serif))
                    .foregroundColor(section == 0 ? ValleyPalette.cream : ValleyPalette.burgundy)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(section == 0 ? ValleyPalette.burgundy : ValleyPalette.ivory)
            }
            .buttonStyle(PlainButtonStyle())
            Button(action: { section = 1 }) {
                Text("Buyer Roster")
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

    private func orderRow(_ order: MarketOrder) -> some View {
        let buyer = ValleyTables.buyer(order.buyerID)
        return Button(action: { activeSheet = .sellLot(UUID()) /* placeholder - real flow via buyer card */ }) {
            HStack(spacing: 10) {
                PersonIcon(size: 36)
                VStack(alignment: .leading, spacing: 3) {
                    Text(buyer.name).font(.system(size: 13, weight: .bold, design: .serif))
                        .foregroundColor(ValleyPalette.inkText)
                    Text("Wants \(order.bottlesWanted) bottles · min quality \(Int(order.minQuality))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(ValleyPalette.olive)
                    Text("Expires Y\(order.expiresOnYear) · S\(order.expiresOnSeason)")
                        .font(.system(size: 10, design: .serif))
                        .foregroundColor(ValleyPalette.terracotta)
                    ProfileBars(profile: buyer.preference, compact: true)
                        .padding(.top, 2)
                }
                Spacer()
                Button(action: {
                    // Show buyer's order detail: fulfill via choosing a lot
                    showFulfillFlow(order: order)
                }) {
                    Text("Fulfill")
                        .font(.system(size: 12, weight: .bold, design: .serif))
                        .foregroundColor(ValleyPalette.cream)
                        .padding(.vertical, 8).padding(.horizontal, 14)
                        .background(LinearGradient(colors: [ValleyPalette.terracotta, ValleyPalette.burgundy],
                                                   startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(12)
            .background(ValleyPalette.ivory)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(ValleyPalette.parchmentLine, lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
    }

    @State private var fulfillingOrder: MarketOrder? = nil

    private func showFulfillFlow(order: MarketOrder) {
        // Pick the best matching lot automatically, but only among lots that
        // actually qualify for this buyer's age window.
        let qualified = store.state.bottledLots.filter { lot in
            store.bestMatchScore(order: order, lot: lot) > 0
        }
        guard let bestLot = qualified.max(by: { a, b in
            store.bestMatchScore(order: order, lot: a) < store.bestMatchScore(order: order, lot: b)
        }) else { return }
        store.fulfillOrder(orderID: order.id, lotID: bestLot.id)
    }
}

// MARK: - Sell Lot Sheet

struct SellLotSheet: View {
    @EnvironmentObject var store: ValleyStore
    let lotID: UUID
    @Binding var activeSheet: ValleyActiveSheet?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if let lot = store.state.bottledLots.first(where: { $0.id == lotID }) {
                    Text(lot.labelName)
                        .font(.system(size: 22, weight: .black, design: .serif))
                        .foregroundColor(ValleyPalette.burgundy)
                    Text("\(ValleyTables.variety(lot.varietyID).name) · Y\(lot.vintageYear) · \(lot.bottles) bottles")
                        .font(.system(size: 13, weight: .semibold, design: .serif))
                        .foregroundColor(ValleyPalette.terracotta)
                    ProfileBars(profile: lot.profile)
                        .padding(.vertical, 4)
                    Divider()
                    ValleySectionHeader(title: "Sell to a Pending Buyer")
                    let candidates = store.state.pendingOrders.sorted { a, b in
                        store.bestMatchScore(order: a, lot: lot) > store.bestMatchScore(order: b, lot: lot)
                    }
                    if candidates.isEmpty {
                        Text("No buyers waiting. Try advancing seasons during the selling window.")
                            .font(.system(size: 12, design: .serif))
                            .foregroundColor(ValleyPalette.olive)
                    } else {
                        ForEach(candidates) { order in
                            let buyer = ValleyTables.buyer(order.buyerID)
                            let match = store.bestMatchScore(order: order, lot: lot)
                            let totalAge = lot.monthsAgedInBarrel + lot.monthsAgedInBottle
                            let tooYoung = totalAge < buyer.minAgeMonths
                            let tooOld = totalAge > buyer.maxAgeMonths
                            let disabled = tooYoung || tooOld
                            Button(action: {
                                guard !disabled else { return }
                                store.fulfillOrder(orderID: order.id, lotID: lot.id)
                                activeSheet = nil
                            }) {
                                HStack {
                                    PersonIcon(size: 28)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(buyer.name).font(.system(size: 13, weight: .bold, design: .serif))
                                            .foregroundColor(disabled ? ValleyPalette.olive : ValleyPalette.inkText)
                                        Text("Wants \(order.bottlesWanted) · Match \(Int(match))")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(ValleyPalette.olive)
                                        if tooYoung {
                                            Text("Too young (needs \(buyer.minAgeMonths) months)")
                                                .font(.system(size: 10, weight: .semibold, design: .serif))
                                                .foregroundColor(ValleyPalette.burgundy)
                                        } else if tooOld {
                                            Text("Past peak (max \(buyer.maxAgeMonths) months)")
                                                .font(.system(size: 10, weight: .semibold, design: .serif))
                                                .foregroundColor(ValleyPalette.burgundy)
                                        }
                                    }
                                    Spacer()
                                    Text("\(buyer.basePrice)c")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(ValleyPalette.terracotta)
                                }
                                .padding(10)
                                .background(disabled ? ValleyPalette.creamWarm.opacity(0.4) : ValleyPalette.ivory)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(ValleyPalette.parchmentLine, lineWidth: 1))
                                .opacity(disabled ? 0.55 : 1.0)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(disabled)
                        }
                    }
                }
                ValleySecondaryButton(title: "Close") { activeSheet = nil }
            }
            .padding(16)
        }
        .background(ValleyPalette.cream)
        .navigationBarTitle("Sell", displayMode: .inline)
    }
}

// MARK: - Buyer Detail Sheet

struct BuyerDetailSheet: View {
    @EnvironmentObject var store: ValleyStore
    let buyerID: String
    @Binding var activeSheet: ValleyActiveSheet?

    var body: some View {
        let buyer = ValleyTables.buyer(buyerID)
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    PersonIcon(size: 48)
                    VStack(alignment: .leading) {
                        Text(buyer.name)
                            .font(.system(size: 20, weight: .black, design: .serif))
                            .foregroundColor(ValleyPalette.burgundy)
                        Text("Base price \(buyer.basePrice) coin/bottle")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(ValleyPalette.olive)
                    }
                }
                Text(buyer.blurb)
                    .font(.system(size: 13, design: .serif))
                    .foregroundColor(ValleyPalette.inkText)

                ValleySectionHeader(title: "Preferred Profile")
                ProfileBars(profile: buyer.preference)

                ValleySectionHeader(title: "Preferred Age")
                Text("\(buyer.minAgeMonths) to \(buyer.maxAgeMonths) months total aging")
                    .font(.system(size: 13, design: .serif))
                    .foregroundColor(ValleyPalette.terracotta)

                ValleySecondaryButton(title: "Close") { activeSheet = nil }
            }
            .padding(16)
        }
        .background(ValleyPalette.cream)
        .navigationBarTitle("Buyer", displayMode: .inline)
    }
}

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: ValleyStore
    @Binding var activeSheet: ValleyActiveSheet?
    @State private var confirmReset: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ValleySectionHeader(title: "About the Estate")
            Text("Valley Winemaker Legacy — a quiet twenty-five year simulation of patient cellaring, careful pressing, and well-judged tastings.")
                .font(.system(size: 12, design: .serif))
                .foregroundColor(ValleyPalette.inkText)

            ValleySectionHeader(title: "Help & Reference")
            Button(action: { activeSheet = .help }) {
                HStack(spacing: 10) {
                    GearIcon(size: 22, color: ValleyPalette.burgundy)
                    VStack(alignment: .leading) {
                        Text("How to Play")
                            .font(.system(size: 13, weight: .bold, design: .serif))
                            .foregroundColor(ValleyPalette.inkText)
                        Text("Mechanics, seasonal cycle, scoring.")
                            .font(.system(size: 11, design: .serif))
                            .foregroundColor(ValleyPalette.olive)
                    }
                    Spacer()
                }
                .padding(10)
                .background(ValleyPalette.ivory)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(ValleyPalette.parchmentLine, lineWidth: 1))
            }
            .buttonStyle(PlainButtonStyle())

            ValleySectionHeader(title: "Privacy")
            Button(action: { activeSheet = .privacyWeb }) {
                HStack(spacing: 10) {
                    PadlockIcon(size: 22, color: ValleyPalette.burgundy)
                    VStack(alignment: .leading) {
                        Text("Privacy Policy")
                            .font(.system(size: 13, weight: .bold, design: .serif))
                            .foregroundColor(ValleyPalette.inkText)
                        Text("Opens the estate privacy page.")
                            .font(.system(size: 11, design: .serif))
                            .foregroundColor(ValleyPalette.olive)
                    }
                    Spacer()
                }
                .padding(10)
                .background(ValleyPalette.ivory)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(ValleyPalette.parchmentLine, lineWidth: 1))
            }
            .buttonStyle(PlainButtonStyle())

            ValleySectionHeader(title: "Save Data")
            Text("All progress is stored locally on this device. There is no cloud sync.")
                .font(.system(size: 12, design: .serif))
                .foregroundColor(ValleyPalette.olive)

            if confirmReset {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reset all twenty-five years and start a new estate?")
                        .font(.system(size: 13, weight: .semibold, design: .serif))
                        .foregroundColor(ValleyPalette.burgundy)
                    HStack(spacing: 8) {
                        ValleyPrimaryButton(title: "Yes, Reset Estate") {
                            store.resetCampaign()
                            confirmReset = false
                        }
                        ValleySecondaryButton(title: "Cancel") {
                            confirmReset = false
                        }
                    }
                }
                .padding(10)
                .background(ValleyPalette.terracotta.opacity(0.1))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(ValleyPalette.terracotta, lineWidth: 1))
            } else {
                ValleySecondaryButton(title: "Reset Estate") {
                    confirmReset = true
                }
            }

            ValleySectionHeader(title: "Estate Information")
            VStack(alignment: .leading, spacing: 4) {
                HStack { Text("Version").font(.system(size: 12, weight: .semibold)); Spacer(); Text("1.0").font(.system(size: 12)) }
                    .foregroundColor(ValleyPalette.olive)
                HStack { Text("Bundle").font(.system(size: 12, weight: .semibold)); Spacer(); Text("com.valleywinemaker.legacy").font(.system(size: 11)) }
                    .foregroundColor(ValleyPalette.olive)
            }
            .padding(10)
            .background(ValleyPalette.ivory)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(ValleyPalette.parchmentLine, lineWidth: 1))
        }
    }
}

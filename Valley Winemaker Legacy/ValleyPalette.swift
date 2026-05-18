import SwiftUI

enum ValleyPalette {
    static let terracotta = Color(red: 184/255, green: 97/255, blue: 42/255)   // #B8612A
    static let cream      = Color(red: 241/255, green: 228/255, blue: 198/255) // #F1E4C6
    static let olive      = Color(red: 111/255, green: 125/255, blue: 63/255)  // #6F7D3F
    static let burgundy   = Color(red: 74/255, green: 26/255, blue: 36/255)    // #4A1A24
    static let ivory      = Color(red: 248/255, green: 241/255, blue: 220/255) // #F8F1DC
    static let sky        = Color(red: 103/255, green: 146/255, blue: 173/255) // #6792AD

    // Derived helpers (kept on-brand).
    static let creamWarm  = Color(red: 234/255, green: 217/255, blue: 178/255)
    static let oliveDark  = Color(red: 80/255, green: 92/255, blue: 44/255)
    static let burgundyDark = Color(red: 50/255, green: 14/255, blue: 22/255)
    static let parchmentLine = Color(red: 196/255, green: 178/255, blue: 142/255)
    static let leaf       = Color(red: 132/255, green: 152/255, blue: 70/255)
    static let goldMedal  = Color(red: 208/255, green: 158/255, blue: 56/255)
    static let silverMedal = Color(red: 156/255, green: 162/255, blue: 168/255)
    static let bronzeMedal = Color(red: 162/255, green: 102/255, blue: 56/255)
    static let frost      = Color(red: 196/255, green: 218/255, blue: 230/255)
    static let dust       = Color(red: 162/255, green: 142/255, blue: 100/255)
    static let inkText    = Color(red: 53/255, green: 25/255, blue: 18/255)

    static let cardBackground = ivory
    static let pageBackground = cream
    static let accent = terracotta
}

extension Color {
    static var valleyPage: Color { ValleyPalette.cream }
}

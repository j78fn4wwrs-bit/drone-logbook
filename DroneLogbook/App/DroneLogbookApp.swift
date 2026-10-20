import SwiftUI
import SwiftData
import MJKit

enum AppConfig {
    static let appName = "Drone Logbook"
    static let proID = "com.mikejohnson.dronelogbook.pro"
    static let privacyURL = URL(string: "https://github.com/j78fn4wwrs-bit/drone-logbook/blob/main/PRIVACY.md")!
    static let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let officerCardLine = "Reference copy. Not an official FAA document. Carry your certificate."
    static let disclaimer = "Reference copy only, not an official FAA credential."
    static let proFeatures = [
        "Unlimited drones in your hangar",
        "PDF and CSV export of your pilot log",
        "Expiry reminders: recurrent training, registration, insurance and waivers",
        "Support an independent developer"
    ]
    static let freeTierNote = "Free forever: 1 drone, the full pilot log and the Show Officer card."
}

@main
struct DroneLogbookApp: App {
    @StateObject private var store = MJStore(proProductIDs: [AppConfig.proID])
    @StateObject private var profileStore = PilotProfileStore()

    init() {
        // Kayla: Keychain items survive app deletion, so wipe them on the first launch after install.
        MJSecureStore.wipeIfFreshInstall()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(profileStore)
                .tint(Color.brand)
        }
        .modelContainer(for: [Drone.self, MaintenanceEntry.self, Flight.self, DocumentRecord.self])
    }
}

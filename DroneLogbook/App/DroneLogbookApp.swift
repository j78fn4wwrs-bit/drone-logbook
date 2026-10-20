import SwiftUI
import SwiftData
import MJKit

enum AppConfig {
    static let appName = "Drone Pocket Logbook"
    static let proID = "com.mikejohnson.dronelogbook.pro"
    static let privacyURL = URL(string: "https://github.com/j78fn4wwrs-bit/drone-logbook/blob/main/PRIVACY.md")!
    static let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let referenceCardLine = "Reference copy. Not an official FAA document. Carry your certificate."
    static let disclaimer = "Reference copy only, not an official FAA credential."
    static let proFeatures = [
        "Unlimited drones in your hangar",
        "PDF and CSV export of your pilot log",
        "Expiry reminders: recurrent training, registration, insurance and waivers",
        "Support an independent developer"
    ]
    static let freeTierNote = "Free forever: 1 drone, the full pilot log and the Quick-Reference Card."
}

@main
struct DroneLogbookApp: App {
    @StateObject private var store: MJStore
    @StateObject private var profileStore: PilotProfileStore

    init() {
        // Keychain items survive deletion. Wipe before the profile store can read
        // the Part 107 number. These StateObject closures run on first access.
        MJSecureStore.wipeIfFreshInstall()
        _store = StateObject(wrappedValue: MainActor.assumeIsolated {
            MJStore(proProductIDs: [AppConfig.proID])
        })
        _profileStore = StateObject(wrappedValue: MainActor.assumeIsolated {
            PilotProfileStore()
        })
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

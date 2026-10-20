import SwiftUI
import SwiftData
import MJKit

struct UpgradeSheet: View {
    @EnvironmentObject private var store: MJStore
    var body: some View {
        VStack(spacing: 0) {
            MJPaywallView(store: store,
                          appName: AppConfig.appName,
                          features: AppConfig.proFeatures,
                          privacyURL: AppConfig.privacyURL,
                          termsURL: AppConfig.termsURL)
            Text(AppConfig.freeTierNote)
                .font(.footnote)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding()
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var store: MJStore
    @EnvironmentObject private var profileStore: PilotProfileStore
    @Query private var documents: [DocumentRecord]
    @Query(sort: \Flight.start, order: .reverse) private var flights: [Flight]
    @AppStorage("remindersOn") private var remindersOn = false
    @AppStorage("reminderLeadDays") private var reminderLeadDays = 30
    @State private var showPaywall = false
    @State private var notificationsDenied = false

    var body: some View {
        NavigationStack {
            List {
                if !store.isPro {
                    Section {
                        Button { showPaywall = true } label: {
                            HStack {
                                IconTile(symbol: "star.fill", color: .accentBeacon)
                                VStack(alignment: .leading) {
                                    Text("Upgrade to Pro").font(.headline)
                                    Text(upgradeSubtitle).font(.footnote).foregroundStyle(Color.textSecondary)
                                }
                            }
                        }
                    }
                }
                Section("Pilot") {
                    NavigationLink {
                        PilotProfileEditView()
                    } label: {
                        Label("Pilot Profile", systemImage: "person.text.rectangle")
                    }
                    NavigationLink {
                        IACRAVaultView()
                    } label: {
                        Label("IACRA Login", systemImage: "faceid")
                    }
                }
                Section {
                    Toggle(isOn: Binding(get: { remindersOn && store.isPro }, set: { setReminders($0) })) {
                        Label("Expiry reminders", systemImage: "bell.badge")
                    }
                    .disabled(!store.isPro)
                    if remindersOn && store.isPro {
                        Picker("Remind me", selection: $reminderLeadDays) {
                            Text("7 days before").tag(7)
                            Text("30 days before").tag(30)
                            Text("60 days before").tag(60)
                        }
                        .onChange(of: reminderLeadDays) { _, _ in reschedule() }
                    }
                    if notificationsDenied {
                        Text("Notifications are off for Drone Logbook in iOS Settings.")
                            .font(.footnote).foregroundStyle(Color.warning)
                    }
                } header: {
                    Text("Reminders" + (store.isPro ? "" : " (Pro)"))
                } footer: {
                    Text("Part 107 recurrent training (24 months), FAA registration (3 years), insurance and waivers. Reminders are scheduled on this iPhone only.")
                }
                Section {
                    if store.isPro {
                        if let csv = Exporter.csvFile(flights: flights) {
                            ShareLink(item: csv) { Label("Export Log as CSV", systemImage: "tablecells") }
                        }
                        if let pdf = Exporter.pdfFile(flights: flights, pilotName: profileStore.profile.name) {
                            ShareLink(item: pdf) { Label("Export Log as PDF", systemImage: "doc.richtext") }
                        }
                    } else {
                        Button { showPaywall = true } label: {
                            Label("Export Log (Pro)", systemImage: "square.and.arrow.up")
                        }
                    }
                } header: {
                    Text("Data")
                } footer: {
                    Text("Everything stays on this iPhone. No account, no tracking, no ads. Exports never include your IACRA login or FTN.")
                }
                MJSettingsView(store: store,
                               appName: AppConfig.appName,
                               aboutText: "Drone Pocket Logbook keeps your Part 107 papers, drones and flights together, offline. Made by Michael Johnson in Fort Worth, TX.",
                               privacyURL: AppConfig.privacyURL,
                               termsURL: AppConfig.termsURL)
                Section("Disclaimer") {
                    Text(AppConfig.disclaimer + " Always carry your official FAA documents as required, and check airspace and local rules before you fly.")
                        .font(.footnote)
                }
                Color.clear.frame(height: 60).listRowBackground(Color.clear)
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { UpgradeSheet() }
        }
    }

    private var upgradeSubtitle: String {
        if let price = store.proProduct?.displayPrice {
            return "One-time \(price). Unlimited drones, export, reminders."
        }
        return "One-time purchase. Unlimited drones, export, reminders."
    }

    private func setReminders(_ on: Bool) {
        guard store.isPro else { showPaywall = true; return }
        if on {
            Task {
                let granted = await Reminders.requestPermission()
                notificationsDenied = !granted
                remindersOn = granted
                if granted { reschedule() }
            }
        } else {
            remindersOn = false
            Reminders.cancelAll()
        }
    }

    private func reschedule() {
        let docs = documents.compactMap { d -> (label: String, expiry: Date)? in
            guard let e = d.expiryDate else { return nil }
            return (label: d.kind.label, expiry: e)
        }
        Reminders.reschedule(profile: profileStore.profile, documents: docs, leadDays: reminderLeadDays)
    }
}

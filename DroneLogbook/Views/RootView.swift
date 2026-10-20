import SwiftUI
import SwiftData
import MJKit

struct RootView: View {
    @EnvironmentObject private var store: MJStore
    @EnvironmentObject private var profileStore: PilotProfileStore
    @Environment(\.scenePhase) private var scenePhase
    @Query private var documents: [DocumentRecord]
    @AppStorage("didOnboard") private var didOnboard = false
    @AppStorage("remindersOn") private var remindersOn = false
    @AppStorage("reminderLeadDays") private var reminderLeadDays = 30
    @State private var showReferenceCard = false

    var body: some View {
        TabView {
            VaultView()
                .tabItem { Label("Vault", systemImage: "doc.text.fill") }
            HangarView()
                .tabItem { Label("Hangar", systemImage: "airplane") }
            FlightLogView()
                .tabItem { Label("Log", systemImage: "book.closed.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .overlay(alignment: .bottomTrailing) {
            Button {
                showReferenceCard = true
            } label: {
                Label("Quick-Reference Card", systemImage: "checkmark.shield.fill")
                    .font(.headline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .foregroundStyle(.white)
                    .background(Color.brand, in: Capsule())
                    .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
            }
            .padding(.trailing, 16)
            .padding(.bottom, 64)
            .accessibilityHint("Opens your credentials full screen")
        }
        .fullScreenCover(isPresented: $showReferenceCard) {
            QuickReferenceCardView()
        }
        .fullScreenCover(isPresented: Binding(get: { !didOnboard }, set: { if !$0 { didOnboard = true } })) {
            OnboardingView { didOnboard = true }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                profileStore.reloadSecureFields()
            }
            if phase == .background {
                rescheduleReminders()
            }
        }
    }

    private func rescheduleReminders() {
        guard remindersOn, store.isPro else { return }
        let docs = documents.compactMap { d -> (label: String, expiry: Date)? in
            guard let e = d.expiryDate else { return nil }
            return (label: d.kind.label, expiry: e)
        }
        Reminders.reschedule(profile: profileStore.profile, documents: docs, leadDays: reminderLeadDays)
    }
}

struct OnboardingView: View {
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 24)
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 56, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 120, height: 120)
                .background(LinearGradient(colors: [Color.officerCardTop, Color.officerCardBottom],
                                           startPoint: .top, endPoint: .bottom),
                            in: RoundedRectangle(cornerRadius: 27, style: .continuous))
            VStack(spacing: 8) {
                Text("Drone Pocket Logbook")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                Text("Your Part 107 papers, drones and flights, together and offline.")
                    .font(.body)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
            VStack(alignment: .leading, spacing: 16) {
                Label("Quick-Reference Card with your certificates, ready in one tap", systemImage: "checkmark.shield")
                Label("Hangar with serials, Remote ID and maintenance", systemImage: "airplane")
                Label("Pilot log with location, time and totals", systemImage: "book.closed")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
            Button {
                onDone()
            } label: {
                Text("Get Started").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            Text(AppConfig.disclaimer + " Everything stays on this iPhone.")
                .font(.footnote)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .background(Color.bg.ignoresSafeArea())
    }
}

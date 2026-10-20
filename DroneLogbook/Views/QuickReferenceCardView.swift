import SwiftUI
import SwiftData
import UIKit
import MJKit

struct QuickReferenceCardView: View {
    @EnvironmentObject private var profileStore: PilotProfileStore
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Drone.createdAt) private var drones: [Drone]
    @Query private var documents: [DocumentRecord]
    @AppStorage("referenceCardDroneUUID") private var referenceCardDroneUUID = ""
    @State private var savedBrightness: CGFloat?
    @State private var showCertificate = false
    @State private var showProfileEditor = false

    private var profile: PilotProfile { profileStore.profile }

    private var activeDrone: Drone? {
        drones.first { $0.uuid.uuidString == referenceCardDroneUUID } ?? drones.first
    }

    private var part107Doc: DocumentRecord? {
        documents.first { $0.kind == .part107 && $0.fileName != nil }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    topBar
                    card
                    buttons
                    Text(AppConfig.referenceCardLine)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                .padding(16)
            }
        }
        .environment(\.colorScheme, .dark)
        .onAppear {
            let screen = Self.activeScreen
            if savedBrightness == nil {
                savedBrightness = screen?.brightness
            }
            screen?.brightness = 1
            UIApplication.shared.isIdleTimerDisabled = true
            profileStore.reloadSecureFields()
        }
        .onDisappear {
            if let savedBrightness {
                Self.activeScreen?.brightness = savedBrightness
            }
            savedBrightness = nil
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .sheet(isPresented: $showCertificate) {
            if let doc = part107Doc, let name = doc.fileName {
                NavigationStack {
                    DocumentFileView(fileName: name)
                        .navigationTitle(doc.displayTitle)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") { showCertificate = false }
                            }
                        }
                }
            }
        }
        .sheet(isPresented: $showProfileEditor) {
            NavigationStack { PilotProfileEditView() }
        }
    }

    /// `UIScreen.main` is deprecated. Brightness has to come from the scene that is on screen.
    private static var activeScreen: UIScreen? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.first { $0.activationState == .foregroundActive }?.screen ?? scenes.first?.screen
    }

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Close")
            Spacer()
            Text("Quick-Reference Card").font(.headline)
            Spacer()
            Button { Self.activeScreen?.brightness = 1 } label: {
                Image(systemName: "sun.max.fill")
                    .font(.headline)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Full brightness")
        }
        .foregroundStyle(.white)
    }

    private var initials: String {
        let parts = profile.name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return letters.isEmpty ? "?" : String(letters).uppercased()
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("PILOT REFERENCE")
                    .font(.caption.weight(.semibold))
                    .tracking(1.2)
                Spacer()
                Text("Reference copy")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
            HStack(spacing: 12) {
                Text(initials)
                    .font(.title2.bold())
                    .frame(width: 64, height: 64)
                    .background(Color.white.opacity(0.15), in: Circle())
                Text(profile.name.isEmpty ? "Your name" : profile.name)
                    .font(.title.bold())
                    .minimumScaleFactor(0.6)
                    .lineLimit(2)
            }

            if profile.part107CertNumber.isEmpty {
                Button {
                    showProfileEditor = true
                } label: {
                    Label("Add your Part 107 certificate", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            } else {
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
                    GridRow {
                        field("PART 107 #", profile.part107CertNumber)
                        field("ISSUED", profile.part107IssueDate?.shortDate ?? "—")
                    }
                    GridRow {
                        VStack(alignment: .leading, spacing: 4) {
                            fieldLabel("RECURRENT DUE")
                            Text(profile.recurrentTrainingDue?.shortDate ?? "—")
                                .font(.title3.weight(.semibold).monospacedDigit())
                            expiryChip
                        }
                        field("TRUST", profile.trustCompletionDate?.shortDate ?? "—")
                    }
                }
            }

            if !profile.faaRegistrationNumbers.isEmpty {
                field("FAA REGISTRATION", profile.faaRegistrationNumbers.joined(separator: ", "))
            }

            Divider().overlay(Color.white.opacity(0.2))

            if let drone = activeDrone {
                VStack(alignment: .leading, spacing: 12) {
                    Label(drone.displayName, systemImage: "airplane")
                        .font(.headline)
                    if !drone.makeModel.isEmpty {
                        Text(drone.makeModel).font(.subheadline).foregroundStyle(.white.opacity(0.7))
                    }
                    Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
                        GridRow {
                            field("FAA REG", drone.registrationNumber.isEmpty ? "—" : drone.registrationNumber)
                            field("REMOTE ID SERIAL", drone.remoteIDSerial.isEmpty ? "—" : drone.remoteIDSerial)
                        }
                        GridRow {
                            field("SERIAL", drone.serialNumber.isEmpty ? "—" : drone.serialNumber)
                            Color.clear.frame(height: 1)
                        }
                    }
                }
            } else {
                Text("No drone yet. Add one in the Hangar tab.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .foregroundStyle(.white)
        .padding(20)
        .background(
            LinearGradient(colors: [Color.officerCardTop, Color.officerCardBottom], startPoint: .top, endPoint: .bottom),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var expiryChip: some View {
        let status = ExpiryStatus(profile.recurrentTrainingDue)
        if status == .expired {
            StatusChip(text: "EXPIRED", color: .danger)
        } else if status == .expiring {
            StatusChip(text: "DUE SOON", color: .warning)
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.medium))
            .tracking(1.2)
            .foregroundStyle(.white.opacity(0.65))
    }

    private func field(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            fieldLabel(label)
            Text(value)
                .font(.title3.weight(.semibold).monospacedDigit())
                .textSelection(.enabled)
                .minimumScaleFactor(0.6)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var buttons: some View {
        HStack(spacing: 12) {
            Button {
                showCertificate = true
            } label: {
                Label("View Certificate", systemImage: "doc.text.magnifyingglass")
                    .frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.bordered)
            .disabled(part107Doc == nil)

            Menu {
                ForEach(drones) { drone in
                    Button(drone.displayName) { referenceCardDroneUUID = drone.uuid.uuidString }
                }
            } label: {
                Label("Switch Drone", systemImage: "arrow.left.arrow.right")
                    .frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.bordered)
            .disabled(drones.count < 2)
        }
        .foregroundStyle(.white)
    }
}

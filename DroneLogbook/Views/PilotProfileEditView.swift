import SwiftUI
import MJKit

struct PilotProfileEditView: View {
    @EnvironmentObject private var profileStore: PilotProfileStore
    @Environment(\.dismiss) private var dismiss
    @State private var draft = PilotProfile()
    @State private var registrations = ""
    @State private var loaded = false

    var body: some View {
        Form {
            Section("Pilot") {
                TextField("Full name", text: $draft.name)
                    .textContentType(.name)
            }
            Section {
                TextField("Part 107 certificate number", text: $draft.part107CertNumber)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .monospacedDigit()
                OptionalDateRow(title: "Certificate issue date", date: $draft.part107IssueDate)
                OptionalDateRow(title: "Last recurrent training", date: $draft.lastRecurrentTrainingDate)
                if let due = draft.recurrentTrainingDue {
                    LabeledContent("Recurrent training due", value: due.shortDate)
                }
            } header: {
                Text("Part 107")
            } footer: {
                Text("The certificate number is kept in this iPhone's Keychain. Recurrent training is due by the end of the 24th month.")
            }
            Section("TRUST") {
                OptionalDateRow(title: "TRUST completed", date: $draft.trustCompletionDate)
            }
            Section {
                TextField("e.g. FA3XXXXXXX, FA3YYYYYYY", text: $registrations)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
            } header: {
                Text("FAA registration numbers")
            } footer: {
                Text("Separate several with commas.")
            }
            Section("Notes") {
                TextField("Notes", text: $draft.notes, axis: .vertical)
            }
        }
        .navigationTitle("Pilot Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    draft.faaRegistrationNumbers = registrations
                        .split(separator: ",")
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                        .filter { !$0.isEmpty }
                    profileStore.save(draft)
                    dismiss()
                }
            }
        }
        .onAppear {
            guard !loaded else { return }
            draft = profileStore.profile
            registrations = draft.faaRegistrationNumbers.joined(separator: ", ")
            loaded = true
        }
    }
}

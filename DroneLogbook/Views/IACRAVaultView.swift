import SwiftUI
import UIKit
import MJKit

/// IACRA username + FTN. Stored ONLY in the Keychain (this device only, never synced),
/// shown only after Face ID / passcode, never in SwiftData, exports or logs.
struct IACRAVaultView: View {
    private static let usernameKey = "iacra.username"
    private static let ftnKey = "iacra.ftn"

    @Environment(\.scenePhase) private var scenePhase
    @State private var unlocked = false
    @State private var username = ""
    @State private var ftn = ""
    @State private var revealFTN = false
    @State private var savedNote = false
    @State private var authFailed = false

    var body: some View {
        Group {
            if unlocked {
                Form {
                    Section {
                        HStack {
                            TextField("IACRA username", text: $username)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .textContentType(.username)
                            copyButton(username)
                        }
                        HStack {
                            if revealFTN {
                                TextField("FTN", text: $ftn)
                                    .textInputAutocapitalization(.characters)
                                    .autocorrectionDisabled()
                                    .monospacedDigit()
                            } else {
                                SecureField("FTN", text: $ftn)
                            }
                            Button { revealFTN.toggle() } label: {
                                Image(systemName: revealFTN ? "eye.slash" : "eye")
                            }
                            .buttonStyle(.borderless)
                            copyButton(ftn)
                        }
                    } header: {
                        Text("IACRA Login")
                    } footer: {
                        Text("Saved only in this iPhone's Keychain. Never synced, exported or backed up to other devices.")
                    }
                    .privacySensitive()
                    Section {
                        Button("Save") {
                            persist()
                        }
                        if savedNote {
                            Label("Saved", systemImage: "checkmark.circle.fill").foregroundStyle(Color.success)
                        }
                        Button("Delete IACRA Login", role: .destructive) {
                            MJSecureStore.delete(Self.usernameKey)
                            MJSecureStore.delete(Self.ftnKey)
                            username = ""
                            ftn = ""
                        }
                    }
                }
            } else {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "faceid")
                        .font(.system(size: 72))
                        .foregroundStyle(Color.brand)
                    Text("IACRA Login Locked").font(.title2.bold())
                    Text("Your IACRA username and FTN are protected with Face ID and stay only on this iPhone.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.textSecondary)
                    if authFailed {
                        Text("Couldn't unlock. Try again.").foregroundStyle(Color.danger)
                    }
                    Button {
                        Task { await unlock() }
                    } label: {
                        Label("Unlock", systemImage: "lock.open.fill").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    Spacer()
                }
                .padding(24)
            }
        }
        .navigationTitle("IACRA")
        .navigationBarTitleDisplayMode(.inline)
        .task { await unlock() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { lock() }
        }
        .onDisappear { lock() }
    }

    private func copyButton(_ value: String) -> some View {
        Button {
            // Typed explicitly: a mixed Bool/Date literal often fails to type-check as [OptionsKey: Any].
            let item: [String: Any] = [UIPasteboard.typeAutomatic: value]
            let options: [UIPasteboard.OptionsKey: Any] = [
                .localOnly: true,
                .expirationDate: Date().addingTimeInterval(60)
            ]
            UIPasteboard.general.setItems([item], options: options)
        } label: {
            Image(systemName: "doc.on.doc")
        }
        .buttonStyle(.borderless)
        .disabled(value.isEmpty)
        .accessibilityLabel("Copy")
    }

    private func unlock() async {
        guard !unlocked else { return }
        let ok = await MJBiometricGate.authenticate(reason: "Unlock your IACRA login")
        if ok {
            username = MJSecureStore.get(Self.usernameKey) ?? ""
            ftn = MJSecureStore.get(Self.ftnKey) ?? ""
            unlocked = true
            authFailed = false
        } else {
            authFailed = true
        }
    }

    private func persist() {
        if username.isEmpty { MJSecureStore.delete(Self.usernameKey) } else { MJSecureStore.set(username, for: Self.usernameKey) }
        if ftn.isEmpty { MJSecureStore.delete(Self.ftnKey) } else { MJSecureStore.set(ftn, for: Self.ftnKey) }
        savedNote = true
    }

    private func lock() {
        unlocked = false
        username = ""
        ftn = ""
        revealFTN = false
        savedNote = false
    }
}

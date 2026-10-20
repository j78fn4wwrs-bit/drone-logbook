# Drone Pocket Logbook

SwiftUI + SwiftData iOS 18 app. Bundle ID `com.mikejohnson.dronelogbook`. Free download; one-time **$4.99 Pro** (`com.mikejohnson.dronelogbook.pro`).
Shared code comes from [MJKit](https://github.com/j78fn4wwrs-bit/MJKit) (SPM, branch `main`). Design: `docs/design/SPEC.md` (Jim). Plan: `docs/plan.md`.

## Mike's steps (Mac)
```
cd ~ && git clone https://github.com/j78fn4wwrs-bit/drone-logbook.git && cd drone-logbook && xcodegen && open DroneLogbook.xcodeproj
```
1. Xcode fetches MJKit automatically (File > Packages > Resolve Package Versions if it doesn't).
2. Target DroneLogbook > Signing & Capabilities > pick your Team.
3. Choose your iPhone, press Cmd+R. Purchases in Xcode runs use `Products.storekit` (free test mode).
4. Updates later: `cd ~/drone-logbook && git pull && xcodegen`.

Then follow `TESTING.md`.

## Features
- **Show Officer** floating button on every tab: full-screen dark card, full brightness (restored on close), no auto-lock. Name, Part 107 #, recurrent due, TRUST, FAA registration, active drone's FAA reg, Remote ID serial and serial.
- **Vault**: photo/PDF of Part 107, TRUST, registration, Remote ID declaration, waivers/LAANC, insurance, with issue/expiry and status chips. Files in Application Support/Vault with complete file protection.
- **IACRA login** (username + FTN): Keychain only (this device only, never synced), Face ID/passcode gate, auto-relocks in background. Never in SwiftData, exports or logs.
- **Hangar**: make, model, serial, registration, Remote ID serial, purchase date, firmware, status, photo; maintenance/mod log (batteries with cycles, props, firmware…).
- **Pilot log**: date/time, "when in use" location with manual fallback, drone, duration, purpose, weather (typed by hand), notes, totals, search.
- **Free**: 1 drone with its full maintenance log (batteries, props, mods), the pilot log, the officer card and the vault. **Pro**: unlimited drones, CSV/PDF export, expiry reminders.
- Widget: **skipped for v1** (needs an App Group + extension target; add in v1.1).

No networking except StoreKit, no analytics, no accounts.

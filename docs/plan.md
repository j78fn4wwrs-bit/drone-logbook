# Drone Pocket Logbook: plan (Nihar, Oct 19 2026)

## What it is
An offline iPhone app that holds a Part 107 pilot's documents, drones and flight log in one place. It has a "Show Officer" card for law enforcement or agency checks in the field.

## v1.0 features
- **Show Officer card:** full screen with the pilot's name, Part 107 certificate number and expiry, TRUST certificate, FAA registration numbers, and the drone's Remote ID. It works offline and there's a widget for quick access.
- **Documents vault:** photos or PDFs of the Part 107, TRUST, FAA DroneZone registration, Remote ID declaration, waivers and authorizations (including LAANC approvals), and insurance. Each one has issue and expiry dates.
- **IACRA record:** the username and FTN, locked behind Face ID and stored in the Keychain.
- **Hangar:** make, model, serial number, registration number, Remote ID, purchase date and firmware for each drone, plus a log of mods and maintenance for the drone, batteries and props.
- **Pilot log:** date and time, location (from the phone's GPS), drone, duration, purpose, weather and notes. It exports to PDF or CSV.
- **Reminders:** the 24-month Part 107 recurrent training, the 3-year registration renewal, and when insurance or a waiver expires.
- **Privacy:** everything is stored on the phone (SwiftData plus files), with no account and no backend. Data Not Collected.

## Monetization
Mike's pricing (Oct 19): the app is a free download and includes 1 drone, the log and the Show Officer card. A one-time $4.99 in-app upgrade unlocks the full app: unlimited drones, PDF export, the widget and reminders. It uses StoreKit 2, the same as the teleprompter.

## Effort and cost
About 3-4 weeks to App Store submission, and it reuses the teleprompter's StoreKit and paywall code. $0 beyond the $99 Apple fee.

## Synergy
It pairs with the drone location app that's in progress. The location app shows where you can fly, and this app records what you flew and holds your proof.

## Risks
- Wording: the app is a reference only, not an official FAA credential. 14 CFR 107.7 requires the physical certificate. The app must never say a digital copy is acceptable. The Quick-Reference Card says "Reference copy. Not an official FAA document. Carry your certificate." and shows no FAA seal or logo.
- The App Store already has drone logging apps, so the "Show Officer" card and offline privacy need to stand out.
- Sensitive IDs need the Keychain and Face ID.

## Sequence
The teleprompter ships first: core app pushed, waiting on Mike's first build and Apple enrollment. This app starts after the teleprompter is submitted.

## Chief's input (Oct 19)
- The drone spot app is Chief's, in the research stage, with data in /workspace/drone-spots/. Accuracy first: no_city_rule_found is NOT allowed, the stricter rule wins, and nothing unclear is recommended.
- Shared pieces: drone and pilot profile, Part 107 status, location and airspace layer, and spot tags in the flight log. Decide after the teleprompter ships whether they share a Swift package or become one app with two modes.
- The IACRA/FTN vault is strictly on-device and user-entered: never synced, logged, or included in a backup or export. Kayla reviews it before launch.

## UPDATED DIRECTION (Oct 19, Michael approved via Chief). This supersedes the pricing above.
- The Drone Pocket Logbook and the drone spot finder ship as ONE app with two modes.
- Free download. Pro costs $19.99 a year or $39.99 lifetime.
- Free tier: basic logbook, hangar, and local spot rules.
- Pro tier: sunrise/sunset alignment, directions, saved spots, permit reminders, regional and national coverage, and spot-tagged flight logs.
- Napoleon's note (MARKET.md): lead the positioning with the Show Officer credentials wallet, and launch spot data as a DFW beta while it's mostly unverified.
- Timing is unchanged: work starts after the teleprompter is submitted.

## FINAL DIRECTION (Oct 19, 10:26 PM, Michael via Chief). This supersedes the one-app section above.
- SEPARATE apps. The Drone Pocket Logbook comes after the teleprompter: a free download with a one-time $4.99 upgrade.
- The drone spot finder is its own DFW-only beta, later. Shared Swift code between the two is welcome.

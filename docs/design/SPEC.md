# Drone Pocket Logbook: Design Spec v1 (Jim Design, Oct 19 2026)
For Nihar. Follows plan.md FINAL DIRECTION: a separate app, free download, one-time $4.99 upgrade. **All data in the mockups is placeholder. No real license or registration numbers.**

## 1. Visual direction
- **Mood:** aviation instrument panel. Night-navy, "horizon blue" primary, beacon-orange accent kept for one highlight per screen. Status colors follow airfield language: clearance green, caution amber, restricted red.
- **Font:** SF Pro, the system font, set with `Font.TextStyle` so Dynamic Type works. The mockups use Inter as a stand-in because SF Pro can't be rendered on Linux. Use `.monospacedDigit()` for IDs and durations.
- **Icons:** SF Symbols, free with the system. The mockups use line stand-ins; the real symbol names are in §6.
- **Light and dark** come from the colorsets. The Show Officer card is ALWAYS dark (high contrast, so it's easy to show in sunlight) and pushes screen brightness to max while it's shown.

## 2. Color tokens (Assets.xcassets/Colors/*.colorset, ready to drop in)
| Token | Light | Dark |
|---|---|---|
| `bg` | #F4F6F9 | #0A0F16 |
| `surface` | #FFFFFF | #151C26 |
| `surface2` | #EBEEF3 | #1E2733 |
| `textPrimary` | #0B1B2B | #F2F5F9 |
| `textSecondary` | #5A6B7E | #93A3B5 |
| `separator` | #D7DDE5 | #2A3542 |
| `brand` | #0A66C2 | #4C9EFF |
| `accent` | #FF8A00 | #FF9F33 |
| `success` | #1E9E5A | #34C77B |
| `warning` | #C98F00 | #FFC93C |
| `danger` | #D93025 | #FF6B5E |
| `officerCardTop` | #0B1B2B | #0B1B2B |
| `officerCardBottom` | #123A63 | #123A63 |

```swift
extension Color { static let brand = Color("brand"); static let accentBeacon = Color("accent"); static let surface = Color("surface") /* …one per token */ }
```

## 3. Type scale → SwiftUI
| Role | SwiftUI | Size/weight (default DT) | Use |
|---|---|---|---|
| Large title | `.largeTitle.bold()` | 34 bold | Tab root titles (system nav large title) |
| Card name | `.title.bold()` (title1 is 28 pt; 26 in the mockup) | 26–28 bold | Officer card pilot name |
| Title 2 | `.title2.bold()` | 22 bold | Empty-state headings, Drone detail name |
| Stat value | `.title2.weight(.bold).monospacedDigit()` | 22–24 | Log summary tiles |
| Credential value | `.title3.weight(.semibold).monospacedDigit()` | 19–20 | Officer card values |
| Headline | `.headline` | 17 semibold | Card titles, buttons |
| Body | `.body` | 17 | List rows |
| Subhead | `.subheadline` | 15 | Values, secondary |
| Footnote | `.footnote` | 13 | Row subtitles, section headers (List does this) |
| Caption | `.caption.weight(.medium)` + `.tracking(1.2)` uppercase | 12 | Officer card field labels |
| Caption 2 | `.caption2` | 10–11 | Tab labels, the date-badge month |

## 4. Spacing and radius
- Spacing: `xs 4, s 8, m 12, l 16 (screen margin), xl 24, xxl 32`.
- Radius: `chip 999 (Capsule), tile 8 (icon tile 30×30), control 14 (buttons 50pt tall), card 16 (hangar cards), officerCard 22, iconPreview 24`. Use `.continuous` corner style.
- Lists: `.insetGrouped` (12 pt radius comes from the system). The tab bar is a system `TabView`.
- Status chip: `Text` in caption-semibold with 8/3 padding on a `Capsule` filled with the status color at 16% opacity, plus foreground text.

## 5. Screens (PNG name → SwiftUI breakdown)
Root `TabView` with 5 tabs: **Officer** (shield.checkered), **Vault** (folder.badge.person.crop… or doc.text), **Hangar** (airplane… see §6), **Log** (book.closed), **Settings** (gearshape). The Officer tab opens the full-screen card.

1. **01_onboarding**: one page shown on first launch. `VStack`: app icon at 120 (radius 27), title, subtitle, 3 `Label` feature rows, then a `Spacer`, the "Get Started" button (`.borderedProminent`, controlSize .large) and the disclaimer footnote. Next it asks for Location ("When In Use") on the first logged flight, NOT during onboarding. Notification permission is only asked when the user turns on a reminder.
2. **02_show_officer** (dark only): a `.fullScreenCover`. `ZStack` with a black background; `VStack`: top bar (close xmark, title, sun.max to force max brightness); the card is a `VStack(alignment:.leading)` on a `LinearGradient(officerCardTop→officerCardBottom)` with radius 22 and a 1pt white 12% stroke. Inside: header row, avatar (initials `Circle` 64) and name, a `Grid` of 2×2 credential fields, a `Divider`, the active drone and a 2-col Grid (FAA Reg, Remote ID). Below it: an `HStack` with 2 buttons (View Certificate opens the document image in a zoomable viewer; Switch Drone opens a Menu or sheet), then the disclaimer. Set `UIScreen.main.brightness = 1` on appear and restore it on disappear, and turn off idle sleep. **States:** no Part 107 entered → the card shows a "Add your Part 107 certificate" CTA in place of the grid. No drone → the drone section is hidden and there's an "Add drone" link. Certificate expired → a red "EXPIRED" chip by EXPIRES. Recurrent training within 30 days → an amber chip. Widget (Pro): small/medium widgets show the name, cert # and expiry, and deep-link here.
3. **03_vault**: `List(.insetGrouped)` with sections Certificates / Waivers & Insurance / Secure. Row = `HStack`: a 30pt color tile with the symbol, a `VStack` with title and subtitle, `Spacer`, then the status chip. The toolbar "+" opens a sheet to add a document (type picker, then `PhotosPicker`/`fileImporter`/VNDocumentCamera, then issue and expiry DatePickers). Status logic: Valid, Expiring (≤30 days, amber), Expired (red), or "No expiry". **Empty:** `ContentUnavailableView("No documents", systemImage:"doc.text", description: "Scan your Part 107, TRUST and registration.")`.
4. **04_document**: a `ScrollView`/`Form`: the preview image (radius 14, tap for full screen and pinch-to-zoom; PDF via PDFKit), a Details section (LabeledContent rows), then a Share Copy button (ShareLink). Edit is a toolbar button.
5. **05_iacra_locked**: `VStack` centered: faceid at 72, title, explainer, and an Unlock button → `LAContext.evaluatePolicy(.deviceOwnerAuthentication)`. Once unlocked it's a `Form` with Username and FTN as SecureField/Text with copy buttons, and it auto-relocks when the app goes to the background. Keychain with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` + `kSecAttrSynchronizable=false` and no backup. It's excluded from every export.
6. **06_hangar**: a `ScrollView` with a `LazyVStack` of drone cards (radius 16, surface). Each card is an `HStack`: a 72pt thumb (user photo, falling back to the symbol), a `VStack` with name, make·model, and Reg·hours, then a status chip (Active / Service due / Grounded). Then a "Batteries & Props" inset list. Free tier allows 1 drone, and adding a 2nd shows the paywall (13).
7. **07_hangar_empty**: `ContentUnavailableView` with an "Add Drone" button.
8. **08_drone_detail**: a `List`: a header (photo, name, totals), an Aircraft section (Serial, FAA Reg, Remote ID, Firmware, Purchased) using `LabeledContent`, and Recent maintenance (3 rows, then "See all" → 09). A toolbar Menu has "Set as active drone for Officer card".
9. **09_maintenance**: a segmented `Picker` (All/Aircraft/Batteries/Props) above a `List` grouped by month. Row: a tile color by type (props=accent, battery=success, firmware=brand, retired=danger). "+" opens a sheet with type, component, date, cycles (batteries) and notes.
10. **10_pilot_log**: an `HStack` of 3 stat tiles (Flights, Hours, This month), then a `List` sectioned by month. Row: a date badge (month in caption2 red, day title2), a `VStack` with location and drone·purpose, then the duration (monospaced). The leading toolbar Export (ShareLink → PDF is Pro, CSV is free). The trailing "+" opens 11. Use `.searchable`.
11. **11_add_flight**: a sheet with a `NavigationStack` + `Form`: a MapKit `Map` snapshot 130pt tall with a pin (current GPS, editable), then a Flight section (DatePicker, Drone Picker, Duration with a start/stop timer option, Purpose Picker plus custom, Weather that's manual or WeatherKit*), then Notes in a TextEditor. Cancel / Save (disabled until a drone is set).
12. **12_log_empty**: `ContentUnavailableView` with a "Log a Flight" button.
13. **13_paywall**: a sheet. `VStack`: icon, title, "One-time purchase", a 4-row benefit list, then a `Spacer`, the "Unlock for $4.99" button (StoreKit 2 `Product.displayPrice`, never hardcode it) and the free-tier footnote. Restore goes in the toolbar. Reuse the teleprompter paywall code.
14. **14_settings**: a `List`: Upgrade row (hidden once Pro is unlocked), Reminders (Toggle and lead time; Pro), Data (Export, Privacy explainer). Also add About and Disclaimer.

Every screen except 02 has light and dark PNGs (`*_dark.png`). The PNGs are 1179×2556 (393×852 @3x).

## 6. SF Symbols
| Use | Symbol |
|---|---|
| Officer tab / card badge | `checkmark.shield.fill` |
| Vault tab | `doc.text.fill` (or `wallet.pass.fill`) |
| Hangar tab / drone | `airplane` (there's no built-in drone symbol; the custom drone in the mockups can ship as a custom SF Symbol from the icon SVG. Otherwise use `fan.fill` or `airplane`) |
| Log tab | `book.closed.fill` |
| Settings | `gearshape.fill` |
| Part 107 / insurance | `checkmark.shield` |
| TRUST | `star.circle` / `graduationcap` |
| Registration | `number.square` |
| Remote ID | `dot.radiowaves.left.and.right` |
| Waiver / LAANC | `doc.badge.clock` |
| IACRA / Face ID | `faceid`, `lock.fill` |
| Maintenance | `wrench.and.screwdriver` |
| Battery | `battery.75percent` |
| Props | `fanblades` |
| Firmware | `arrow.triangle.2.circlepath` |
| Flight location / time / weather | `location.fill`, `clock`, `cloud.sun` |
| Export / share | `square.and.arrow.up` |
| Add / close / brightness | `plus`, `xmark`, `sun.max.fill` |
| Reminders | `bell.badge` |

## 7. App icon
`icon/AppIcon.svg` (master), `icon/AppIcon-1024.png` (RGB, no alpha, square corners), and `icon/AppIcon.appiconset` (iPhone/iPad sizes plus ios-marketing 1024, with Contents.json). It's also copied into `Assets.xcassets`. On Xcode 15+ you can use just the single 1024 if you like.

## 8. Open questions for Nihar
1. Tabs: should Officer be a tab that opens the full-screen card, or a floating button on every tab? (Mockups: a tab.)
2. Weather: is WeatherKit OK? It's free up to 500k calls a month with the existing developer account, but needs a capability. Otherwise it's manual entry only.
3. Should screen brightness be forced to max on the Officer card, or should that be a toggle?
4. Does the Remote ID field hold the serial-number broadcast ID or the declaration number (for standard vs. broadcast module)?
5. A custom drone SF Symbol vs `airplane`?
6. Kayla's review of the wording "Reference copy only. Not an official FAA credential."

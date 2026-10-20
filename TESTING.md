# Drone Logbook: iPhone test checklist

Build: `cd ~/drone-logbook && git pull && xcodegen`, then Cmd+R on your iPhone. Use fake numbers.

1. [ ] First launch shows the onboarding page; "Get Started" closes it and it doesn't come back.
2. [ ] Settings > Pilot Profile: enter name, a fake Part 107 #, issue date, TRUST date and a registration number. Save. "Recurrent training due" shows ~24 months later.
3. [ ] Tap **Show Officer** (floating button) from each tab: the card opens full screen, the screen jumps to full brightness, and closing it restores your old brightness.
4. [ ] Officer card shows name, cert #, recurrent due, TRUST and FAA registration. With no Part 107 # it shows "Add your Part 107 certificate".
5. [ ] Hangar: add a drone (make, model, serial, FAA reg, Remote ID serial, purchase date, firmware, photo). It appears on the Officer card.
6. [ ] Hangar: tap + again: the $4.99 upgrade sheet appears (free tier = 1 drone). Price shows $4.99.
7. [ ] Buy Pro in the sheet (test mode, free). The sheet closes; adding a second drone now works. Switch Drone on the Officer card picks between them.
8. [ ] Drone detail: log a battery entry with cycles and a props entry. "See all" filters by All/Aircraft/Batteries/Props.
9. [ ] Log: tap + > "Use Current Location". Allow "While Using". Map pin and coordinates appear. Deny on a second test: you can still type a location.
10. [ ] Save a flight with duration, purpose, weather and notes. Stats tiles (Flights, Hours, This month) update; search finds it.
11. [ ] Vault: add a Part 107 photo with an expiry date in 20 days: chip shows **Expiring**. Add a PDF from Files (insurance): it opens and scrolls. Pinch-zoom works on the photo.
12. [ ] Officer card "View Certificate" opens the Part 107 photo.
13. [ ] Vault > IACRA Login: Face ID prompt; enter a fake username/FTN, Save. Leave the app to the home screen and come back: it's locked again. Copy button works.
14. [ ] Pro: Log export menu > CSV and PDF share sheets open; files contain flights and NO IACRA data.
15. [ ] Settings > Expiry reminders on: iOS asks for notifications. (Optional: set a document expiry 8 days out with "7 days before" and check tomorrow.)
16. [ ] Settings shows the disclaimer "Reference copy only, not an official FAA credential.", version, Restore Purchases and Privacy/Terms links.
17. [ ] Delete the app, reinstall from Xcode: the IACRA login is gone (Keychain wiped on fresh install).
18. [ ] Officer card bottom line reads "Reference copy. Not an official FAA document. Carry your certificate."
19. [ ] Free tier (before buying Pro, or on a fresh install): battery and props maintenance logging works for your 1 drone.
20. [ ] Airplane mode: everything except purchases still works.

Report any Xcode errors by pasting the red error text.

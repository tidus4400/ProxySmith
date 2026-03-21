# Changelog

## Unreleased

### Added

- Added a per-deck bleed slider from `0.0 mm` to `2.0 mm` that feeds both preview and PDF export.
- Added a per-deck `Sheet Corners` selector so each sheet can render with rounded or straight card corners.
- Added border-color propagation from Scryfall through deck export so black, white, gold, and other border styles can drive bleed rendering.
- Added click-to-preview zoom popovers for deck-list card art.
- Added deterministic sample-deck seeding for Goblin Sharpshooter and Serra Angel rows.
- Added an in-app PDF sheet preview before export.
- Added a persistent Scryfall card-image cache under `~/.proxysmith/cache/card-images` with configurable retention in Settings.
- Added unit coverage for the PDF render path and a UI test covering outside-click dismissal for the add-cards popover.
- Added a Settings window for deck-numbering controls, including a global numbering toggle and a counter reset action.
- Added UI tests for default deck numbering and settings-driven number reuse.
- Added unit tests for deck-name generation, app-preference persistence, and card-image cache refresh behavior.

### Changed

- Print layout math now separates trim and bleed bounds so cards stay physically spaced apart, shared bleed gaps split half-and-half per neighboring card, and cut guides stay on the final trim line.
- PDF export bleed now samples real per-edge colors from each card image when available, blends corner bleed blocks from adjacent sampled edges, and falls back to Scryfall border-color metadata when image sampling is unavailable.
- Deck selection now tracks stable deck IDs so workspace state and UI automation stay consistent while SwiftData refreshes live query results.
- Add-cards search results now use the same tighter card corners and click-to-preview zoom popovers as deck-list rows.
- Deck deletion now asks for confirmation before removing the selected deck and its cards.
- The sidebar `Delete Deck` button now uses an explicit filled destructive treatment so it stays visible against the glass panel.
- Deck-list card preview popovers now render 40% larger with high-resolution art, open at their original framing, support pinch or `Command` + scroll zooming from that default view, and close when you click the same thumbnail again.
- PDF cut guides now render outside the card frame and continue the exact rectangular trim-edge trajectory instead of using an inset heuristic.
- Preview Sheets now uses an explicit filled treatment so it stays visible against the glass panel.
- Deck workspace print controls now group preview/export actions together, and the redundant card-scale metric is gone.
- Add Cards now opens as a dismissable popover instead of a blocking sheet.
- Settings window lifecycle observation now preserves its existing close/reset behavior while avoiding Swift sendability warnings in the AppKit bridge.
- Deck list rows now show an explicit quantity badge and use tighter card corners to better match MTG card framing.
- Untitled deck names now use explicit numeric suffixes.
- Global deck numbering now behaves like a monotonic row ID when enabled, so deleting `Untitled Deck 6` still advances the next generated deck to `Untitled Deck 7`.
- App preferences now live in `~/.proxysmith/settings/preferences.json` instead of `UserDefaults`, and all artwork loading paths now share the same disk-backed cache policy.
- macOS UI tests now launch ProxySmith with persistence disabled so the main window opens deterministically during automation.
- Removed the internal changelog workflow notice from the Settings screen.

## 0.1.0 - 2026-03-11

### Added

- Initial ProxySmith macOS app scaffold with SwiftUI, SwiftData, Scryfall search, PDF export, and baseline unit tests.

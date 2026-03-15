# Changelog

## Unreleased

### Added

- Added click-to-preview zoom popovers for deck-list card art.
- Added deterministic sample-deck seeding for Goblin Sharpshooter and Serra Angel rows.
- Added an in-app PDF sheet preview before export.
- Added unit coverage for the PDF render path and a UI test covering outside-click dismissal for the add-cards popover.
- Added a Settings window for deck-numbering controls, including a global numbering toggle and a counter reset action.
- Added UI tests for default deck numbering and settings-driven number reuse.
- Added unit tests for deck-name generation and app-preference persistence.

### Changed

- Deck-list card preview popovers now render 40% larger with high-resolution art, open at their original framing, support pinch or `Command` + scroll zooming from that default view, and close when you click the same thumbnail again.
- PDF cut guides now render outside the card frame and continue the exact rectangular trim-edge trajectory instead of using an inset heuristic.
- Preview Sheets now uses an explicit filled treatment so it stays visible against the glass panel.
- Deck workspace print controls now group preview/export actions together, and the redundant card-scale metric is gone.
- Add Cards now opens as a dismissable popover instead of a blocking sheet.
- Deck list rows now show an explicit quantity badge and use tighter card corners to better match MTG card framing.
- Untitled deck names now use explicit numeric suffixes.
- Global deck numbering now behaves like a monotonic row ID when enabled, so deleting `Untitled Deck 6` still advances the next generated deck to `Untitled Deck 7`.
- macOS UI tests now launch ProxySmith with persistence disabled so the main window opens deterministically during automation.
- Removed the internal changelog workflow notice from the Settings screen.

## 0.1.0 - 2026-03-11

### Added

- Initial ProxySmith macOS app scaffold with SwiftUI, SwiftData, Scryfall search, PDF export, and baseline unit tests.

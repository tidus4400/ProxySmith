# Changelog

## Unreleased

### Added

- Added a Settings window for deck-numbering controls, including a global numbering toggle and a counter reset action.
- Added UI tests for default deck numbering and settings-driven number reuse.
- Added unit tests for deck-name generation and app-preference persistence.

### Changed

- Untitled deck names now use explicit numeric suffixes.
- Global deck numbering now behaves like a monotonic row ID when enabled, so deleting `Untitled Deck 6` still advances the next generated deck to `Untitled Deck 7`.
- macOS UI tests now launch ProxySmith with persistence disabled so the main window opens deterministically during automation.

## 0.1.0 - 2026-03-11

### Added

- Initial ProxySmith macOS app scaffold with SwiftUI, SwiftData, Scryfall search, PDF export, and baseline unit tests.

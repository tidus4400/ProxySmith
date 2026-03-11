# Copilot Instructions for ProxySmith

ProxySmith is a macOS-native app for building Magic: The Gathering proxy print sheets. The core workflow is: create a deck → search Scryfall → add cards → tune print scale → export A4 PDF with cut guides.

## Build & Test

```bash
# Regenerate .xcodeproj from source of truth (required after any project.yml change)
xcodegen generate

# Build
xcodebuild -scheme ProxySmith -destination 'platform=macOS' build

# Run all tests
xcodebuild -scheme ProxySmith -destination 'platform=macOS' test

# Run a single unit test class
xcodebuild -scheme ProxySmith -destination 'platform=macOS' test -only-testing:ProxySmithTests/PrintLayoutTests

# Run a single UI test
xcodebuild -scheme ProxySmith -destination 'platform=macOS' test -only-testing:ProxySmithUITests/ProxySmithUITests/testGlobalDeckNumbering
```

**Never hand-edit `ProxySmith.xcodeproj/project.pbxproj` directly.** All project structure changes go in `project.yml`, then run `xcodegen generate`.

## Architecture

The app is structured in clean layers with no third-party dependencies — only Apple frameworks (SwiftUI, SwiftData, CoreGraphics).

```
App/         → @main entry, SwiftData ModelContainer, scene config
Models/      → SwiftData @Model classes (Deck, DeckCard) + API DTOs (ScryfallCard)
Services/    → Actor-based async services (ScryfallClient, CardImageRepository, PDFExportService)
Views/       → SwiftUI views; no ViewModel classes — logic lives in Services or Models
Utilities/   → Pure stateless functions (PrintLayout, DeckNameGenerator)
Support/     → Environment wiring (AppServices), preferences, shared UI components
```

Services are injected via a custom environment value (`@Environment(\.appServices)`). Views never instantiate services directly.

## Key Conventions

**Project file**: `project.yml` is the single source of truth. Update it for any target, file, or setting change, then regenerate.

**Print math**: `PrintLayout` (a static enum in `Utilities/`) owns all A4 page and MTG card sizing calculations. Any feature touching card dimensions or PDF layout must go through it — never hardcode sizes.

**Scryfall throttling**: All Scryfall API calls go through `ScryfallClient`, which enforces a 150ms minimum between requests via `RequestThrottler`. Do not bypass or reduce this delay.

**Concurrency**: Use Swift actors for any new stateful async work, following the pattern in `ScryfallClient` and `CardImageRepository`. The app uses structured concurrency (async/await) throughout — no Combine.

**SwiftData**: `Deck` and `DeckCard` are `@Model` classes. `DeckExportSnapshot` is a transient value type for export — never persist export state onto the model.

**Deck naming**: `DeckNameGenerator` (a static enum) has two strategies: `nextGlobalDeckNumber()` (monotonic, never reuses) and `nextReusableDeckNumber()` (fills lowest gap). The active strategy is controlled by `AppPreferences.useGlobalDeckNumbering`.

**Image fallback**: `ScryfallCard.preferredImage()` handles double-faced and split cards by falling back to `card_faces[0].image_uris` when root `image_uris` is absent. Preserve this logic.

**Accessibility identifiers**: All interactive UI elements must have `.accessibilityIdentifier(...)` set — the UI test suite depends on them.

**CHANGELOG.md**: Update it before every commit. It is part of the deliverable, not optional documentation.

**Native-first**: No new dependencies without strong justification. Prefer SwiftUI, SwiftData, and Apple frameworks.

## Testing Approach

Unit tests use the **Swift Testing** framework (`@Test`, `#expect`). UI tests use **XCTest**. UI tests pass `--uitesting` and `--uitesting-reset-state` launch arguments; the app responds by using an in-memory SwiftData store for deterministic state.

When changing deck naming, print math, Scryfall behavior, or export logic — add or update tests. The covered test files are:
- `ProxySmithTests/PrintLayoutTests.swift`
- `ProxySmithTests/DeckNameGeneratorTests.swift`
- `ProxySmithTests/AppPreferencesTests.swift`
- `ProxySmithTests/ScryfallCardTests.swift`
- `ProxySmithUITests/ProxySmithUITests.swift`

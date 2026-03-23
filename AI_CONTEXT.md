# AI Context

This file is the working map for future agents making changes in ProxySmith. Read this before editing the app.

## Product Intent

ProxySmith is a macOS-native deck-to-print workflow for Magic: The Gathering proxies.

The intended flow is:

1. Create a deck.
2. Add cards from Scryfall.
3. Tune print scale, bleed, and sheet corner style.
4. Export A4 sheets as PDF for physical printing.

The app should feel polished and Mac-native, not like a thin CRUD shell.

## Non-Negotiables

- Keep Scryfall traffic conservative.
  API calls currently flow through `ScryfallClient` and `RequestThrottler`.
  Card art now also uses a persistent disk cache with a default 7-day refresh window that can be adjusted in Settings.
- Preserve print accuracy.
  `PrintLayout` owns the canonical A4 and MTG card sizing math.
- Keep the app native-first.
  Prefer SwiftUI, SwiftData, and Apple frameworks over extra dependencies.
- Keep the visual system semantic and centralized.
  Prefer shared theme tokens, button styles, and surface helpers over one-off RGB values or decorative wrappers.
- Avoid replacing XcodeGen with hand-edited `.pbxproj` changes.
  Update `project.yml`, then regenerate.

## Repo Map

- `project.yml`
  Source of truth for the Xcode project.
- `CHANGELOG.md`
  Must be updated for every commit-worthy change before committing.
- `ProxySmith/App/ProxySmithApp.swift`
  App bootstrap, scene configuration, SwiftData container.
- `ProxySmith/App/ContentView.swift`
  Root navigation and deck selection.
- `ProxySmith/Support/AppBackgroundView.swift`
  Shared workshop-style canvas used behind the main app surfaces.
- `ProxySmith/Support/GlassPanelModifier.swift`
  Semantic theme tokens plus shared surface, button, and input styling helpers.
- `ProxySmith/Support/AppPreferences.swift`
  Persistent app-level preferences, stored at `~/.proxysmith/settings/preferences.json`.
- `ProxySmith/Utilities/DeckNameGenerator.swift`
  Canonical logic for untitled deck numbering and sequence handling.
- `ProxySmith/Models/Deck.swift`
  Deck persistence model and deck-level helpers.
- `ProxySmith/Models/DeckCard.swift`
  Stored card data used for deck editing and export.
- `ProxySmith/Models/ScryfallCard.swift`
  API DTOs and image selection logic.
- `ProxySmith/Services/ScryfallClient.swift`
  Rate-limited Scryfall metadata access.
- `ProxySmith/Services/CardImageRepository.swift`
  Shared image fetcher used by previews and export, backed by `~/.proxysmith/cache/card-images`.
- `ProxySmith/Services/PDFExportService.swift`
  PDF generation and cut-guide drawing.
- `ProxySmith/Utilities/PrintLayout.swift`
  Canonical page/card sizing calculations.
- `TestAssets/CardPreviewFixtures`
  Local high-resolution card PNG fixtures used by seeded UI preview testing.

## Current UX Shape

- Sidebar for deck library.
- Light-first print-studio theme with dark-mode support and restrained use of blur/material.
- Sidebar actions should follow a strict hierarchy:
  one primary action per region
  support/secondary actions for utility flows
  destructive only for destructive actions
- Deck deletion requires confirmation before removing the selected deck and its cards.
- Main deck workspace with:
  editable name
  scale slider
  bleed slider
  sheet corner selector
  add-cards popover
  preview and export actions
  deck list with quantity control and click-to-preview card art that opens at its original framing, supports magnification gestures in the enlarged preview, and can be closed by clicking the same thumbnail again
- Add-cards search results should use the same card-art corner treatment and click-to-preview zoom behavior as deck-list rows.
- Settings window for app-level options such as deck numbering and card-image cache retention.
- Search sheet for Scryfall-driven card lookup.

## Known Constraints

- Double-faced and special-layout cards currently use the first face image when root `image_uris` are absent.
- Export currently renders the chosen face art with a fixed 3x3 grid, deck-level bleed support, deck-level rounded or straight sheet corners, and cut guides.
- Export bleed now samples each card image per edge when possible and uses those exact edge colors to fill the owned gap around the trim frame, blending corner bleed blocks from adjacent sampled sides; when image sampling is unavailable it falls back to Scryfall border-color metadata so adjacent cards still split the shared spacing half-and-half without moving cut guides off the trim line.
- Export cut guides now sit outside the trim frame and align to the exact rectangular trim-edge trajectory of the card frame, even when bleed expands the surrounding per-card bleed bounds.
- Search currently uses Scryfall search syntax directly rather than a curated autocomplete domain model.
- PDF preview now renders from the same in-memory export pipeline as saved files, so preview and export should stay visually aligned.
- UI launches can use `--uitesting-seed-sample-deck` to preload Goblin Sharpshooter and Serra Angel rows backed by local high-resolution PNG fixtures for deterministic preview/debug validation without live network dependence.

## Likely Next Features

- Better card search filtering and sorting
- Deck import from pasted lists
- Duplicate card collapsing and batch quantity editing
- More print presets and paper sizes
- Finer crop and registration controls

## Workflow Rules For Future Agents

- Use `rg` for searches.
- Use `apply_patch` for manual edits.
- Regenerate the Xcode project after `project.yml` changes.
- Run `xcodebuild -scheme ProxySmith -destination 'platform=macOS' test` before handing off when changes affect app behavior, persistence, or UI flows.
- Update `CHANGELOG.md` before every commit. Treat it as part of the deliverable, not optional documentation.
- Treat any user request to commit as an implicit request to refresh `CHANGELOG.md` and the relevant context files before creating the commit.
- Keep confirmation around destructive deck deletion so users do not remove decks accidentally.
- Keep deck-list and add-cards search card previews visually and behaviorally aligned.
- Keep the reduced-glass theme direction intact; do not reintroduce layered glass cards as the default surface treatment.
- If you change print math, bleed sampling, corner-style handling, border-color handling, or Scryfall behavior, update this file.
